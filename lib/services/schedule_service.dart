import 'package:hive/hive.dart';

class ScheduleService {
  static const _settingsBox = 'settingsBox';
  static const _intervalsKey = 'intervalsDays';
  static const List<int> _defaultIntervals = [3, 7, 14];

  List<int> intervals = List<int>.from(_defaultIntervals);

  Future<void> load() async {
    final box = await _openSettings();
    final stored = box.get(_intervalsKey);
    if (stored is List) {
      intervals = stored.map((e) => int.tryParse(e.toString()) ?? 0).where((v) => v > 0).toList();
      if (intervals.isEmpty) intervals = List<int>.from(_defaultIntervals);
    }
  }

  Future<void> saveIntervals(List<int> days) async {
    intervals = days.where((d) => d > 0).toList();
    if (intervals.isEmpty) {
      intervals = List<int>.from(_defaultIntervals);
    }
    final box = await _openSettings();
    await box.put(_intervalsKey, intervals);
  }

  Future<Box> _openSettings() async {
    if (Hive.isBoxOpen(_settingsBox)) return Hive.box(_settingsBox);
    return Hive.openBox(_settingsBox);
  }

  // Stage 0 uses study date; subsequent stages use completion date (when user marked previous stage as done)
  DateTime? nextDueDate(
    DateTime studyDate,
    int stageIndex, {
    DateTime? completionDate,
  }) {
    if (stageIndex >= intervals.length) return null; // completed

    DateTime dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

    final days = intervals[stageIndex];
    final base = (stageIndex == 0) ? dateOnly(studyDate) : dateOnly(completionDate ?? DateTime.now());
    return base.add(Duration(days: days));
  }

  int nextStageIndex(int currentStageIndex) => currentStageIndex + 1;
}
