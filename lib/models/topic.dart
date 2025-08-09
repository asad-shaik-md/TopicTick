import 'package:hive/hive.dart';

part 'topic.g.dart';

@HiveType(typeId: 0)
class Topic extends HiveObject {
  @HiveField(0)
  String name;

  @HiveField(1)
  DateTime studyDate;

  @HiveField(2)
  DateTime? nextDueDate; // null when all stages completed

  @HiveField(3)
  bool isDone;

  @HiveField(4)
  int stageIndex; // 0: Day3, 1: Day10, 2: Day24, 3+: completed

  Topic({
    required this.name,
    required this.studyDate,
    this.nextDueDate,
    this.isDone = false,
    this.stageIndex = 0,
  });
}
