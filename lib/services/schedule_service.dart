class ScheduleService {
  // New staged schedule:
  // Stage 0: +3 days from study date
  // Stage 1: +7 days from the day user marked previous stage as done
  // Stage 2: +14 days from the day user marked previous stage as done
  DateTime? nextDueDate(
    DateTime studyDate,
    int stageIndex, {
    DateTime? completionDate,
  }) {
    DateTime dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

    switch (stageIndex) {
      case 0:
        return dateOnly(studyDate).add(const Duration(days: 3));
      case 1:
        final base = dateOnly(completionDate ?? DateTime.now());
        return base.add(const Duration(days: 7));
      case 2:
        final base = dateOnly(completionDate ?? DateTime.now());
        return base.add(const Duration(days: 14));
      default:
        return null; // completed
    }
  }

  int nextStageIndex(int currentStageIndex) => currentStageIndex + 1;
}
