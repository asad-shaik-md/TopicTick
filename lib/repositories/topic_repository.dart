import 'package:hive/hive.dart';
import '../models/topic.dart';

class TopicRepository {
  static const topicsBoxName = 'topicsBox';

  Future<Box<Topic>> _openBox() async {
    if (Hive.isBoxOpen(topicsBoxName)) {
      return Hive.box<Topic>(topicsBoxName);
    }
    return Hive.openBox<Topic>(topicsBoxName);
  }

  Future<List<Topic>> getAll() async {
    final box = await _openBox();
    return box.values.toList();
  }

  Future<void> add(Topic topic) async {
    final box = await _openBox();
    await box.add(topic);
  }

  Future<void> update(Topic topic) async {
    await topic.save();
  }

  Future<void> delete(Topic topic) async {
    await topic.delete();
  }
}
