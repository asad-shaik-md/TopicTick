class ScheduleService {
  // Stages in days from study date
  static const List<int> stages = [3, 10, 24];

  DateTime? nextDueDate(DateTime studyDate, int currentStageIndex) {
    if (currentStageIndex >= stages.length) return null; // completed
    final days = stages[currentStageIndex];
    return DateTime(studyDate.year, studyDate.month, studyDate.day).add(Duration(days: days));
  }

  int nextStageIndex(int currentStageIndex) {
    return currentStageIndex + 1;
  }
}
