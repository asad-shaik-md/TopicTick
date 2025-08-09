import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'models/topic.dart';
import 'repositories/topic_repository.dart';
import 'services/schedule_service.dart';
import 'services/notification_service.dart';

class TopicProvider extends ChangeNotifier {
  final TopicRepository repo;
  final ScheduleService schedule;
  final NotificationService notifications;

  TopicProvider({required this.repo, required this.schedule, required this.notifications});

  List<Topic> _topics = [];
  List<Topic> get topics => _topics;

  Future<void> load() async {
    _topics = await repo.getAll();
    notifyListeners();
  }

  List<Topic> get dueToday {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return _topics.where((t) {
      if (t.nextDueDate == null) return false;
      final d = DateTime(t.nextDueDate!.year, t.nextDueDate!.month, t.nextDueDate!.day);
      return !d.isAfter(today);
    }).toList();
  }

  Future<void> addTopic(String name, DateTime studyDate) async {
    final nextDue = schedule.nextDueDate(studyDate, 0);
    final topic = Topic(name: name, studyDate: studyDate, nextDueDate: nextDue, isDone: nextDue == null, stageIndex: 0);
    await repo.add(topic);
    _topics = await repo.getAll();

    if (nextDue != null) {
      await notifications.scheduleNotification(
        id: topic.key is int ? topic.key as int : DateTime.now().millisecondsSinceEpoch % 1000000,
        title: 'Revision due',
        body: '"$name" is due today',
        scheduledDate: DateTime(nextDue.year, nextDue.month, nextDue.day, 9, 0),
      );
    }

    notifyListeners();
  }

  Future<void> markDone(Topic topic) async {
    // Advance to next stage
    final nextStage = schedule.nextStageIndex(topic.stageIndex);
    final nextDue = schedule.nextDueDate(topic.studyDate, nextStage);

    topic.stageIndex = nextStage;
    topic.nextDueDate = nextDue;
    topic.isDone = nextDue == null; // only done when all stages completed

    await repo.update(topic);

    if (topic.nextDueDate != null) {
      await notifications.scheduleNotification(
        id: topic.key is int ? topic.key as int : DateTime.now().millisecondsSinceEpoch % 1000000,
        title: 'Next revision due',
        body: '"${topic.name}" next due',
        scheduledDate: DateTime(topic.nextDueDate!.year, topic.nextDueDate!.month, topic.nextDueDate!.day, 9, 0),
      );
    }

    notifyListeners();
  }
}

class MyApp extends StatelessWidget {
  final NotificationService notifications;
  const MyApp({super.key, required this.notifications});

  @override
  Widget build(BuildContext context) {
    final repo = TopicRepository();
    final schedule = ScheduleService();

    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => TopicProvider(repo: repo, schedule: schedule, notifications: notifications)..load()),
      ],
      child: MaterialApp(
        title: 'TopicTick',
        theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.indigo),
        darkTheme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.indigo, brightness: Brightness.dark),
        themeMode: ThemeMode.system,
        home: const HomePage(),
      ),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TopicProvider>();
    final topics = provider.topics;

    return Scaffold(
      appBar: AppBar(title: const Text('TopicTick')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              children: [
                Text('Today: ${DateTime.now().toLocal().toString().split(' ').first}'),
                const Spacer(),
                ElevatedButton.icon(
                  onPressed: () => _showAddDialog(context),
                  icon: const Icon(Icons.add),
                  label: const Text('Add Topic'),
                ),
              ],
            ),
          ),
          Expanded(
            child: topics.isEmpty
                ? const Center(child: Text('No topics yet. Add one to get started.'))
                : SingleChildScrollView(
                    child: DataTable(
                      columns: const [
                        DataColumn(label: Text('Topic')),
                        DataColumn(label: Text('Studied')),
                        DataColumn(label: Text('Next Due')),
                        DataColumn(label: Text('Status')),
                        DataColumn(label: Text('Actions')),
                      ],
                      rows: topics.map((t) {
                        final studied = _fmtDate(t.studyDate);
                        final next = t.nextDueDate != null ? _fmtDate(t.nextDueDate!) : '—';
                        final isDue = provider.dueToday.contains(t);
                        final status = (t.nextDueDate == null)
                            ? 'Done'
                            : (isDue ? 'Pending' : 'Scheduled');
                        return DataRow(cells: [
                          DataCell(Text(t.name)),
                          DataCell(Text(studied)),
                          DataCell(Text(next)),
                          DataCell(Text(status)),
                          DataCell(Row(
                            children: [
                              if (isDue)
                                TextButton(
                                  onPressed: () => provider.markDone(t),
                                  child: const Text('Mark Done'),
                                ),
                            ],
                          )),
                        ]);
                      }).toList(),
                    ),
                  ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text('Due Today (${provider.dueToday.length})', style: Theme.of(context).textTheme.titleMedium),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: provider.dueToday.length,
              itemBuilder: (context, index) {
                final t = provider.dueToday[index];
                return ListTile(
                  title: Text(t.name),
                  subtitle: Text('Due: ${_fmtDate(t.nextDueDate!)}'),
                  trailing: TextButton(
                    onPressed: () => provider.markDone(t),
                    child: const Text('Done'),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  String _fmtDate(DateTime d) => '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  Future<void> _showAddDialog(BuildContext context) async {
    final nameCtrl = TextEditingController();
    DateTime? studyDate = DateTime.now();

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Add Topic'),
          content: SizedBox(
            width: 400,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(labelText: 'Topic name'),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Text('Studied on: '),
                    const SizedBox(width: 8),
                    TextButton(
                      onPressed: () async {
                        final now = DateTime.now();
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: studyDate ?? now,
                          firstDate: DateTime(now.year - 5),
                          lastDate: DateTime(now.year + 5),
                        );
                        if (picked != null) {
                          setState(() => studyDate = picked);
                        }
                      },
                      child: Text(_fmtDate(studyDate!)),
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                if (nameCtrl.text.trim().isEmpty) return;
                await context.read<TopicProvider>().addTopic(nameCtrl.text.trim(), studyDate!);
                if (context.mounted) Navigator.pop(context);
              },
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
  }
}
