class Flashcard {
  final String id;
  String frontQuestion;
  String backAnswer;
  String category; // e.g. "Physics", "Chemistry", "CS"
  
  // SM-2 Spaced Repetition parameters
  double easeFactor; // Starts at 2.5, min 1.3
  int intervalDays; // Interval until next review in days
  int repetitions; // Consecutive successful reviews
  DateTime nextReviewDate;
  DateTime lastReviewed;

  Flashcard({
    required this.id,
    required this.frontQuestion,
    required this.backAnswer,
    required this.category,
    this.easeFactor = 2.5,
    this.intervalDays = 1,
    this.repetitions = 0,
    DateTime? nextReviewDate,
    DateTime? lastReviewed,
  })  : nextReviewDate = nextReviewDate ?? DateTime.now(),
        lastReviewed = lastReviewed ?? DateTime.now();

  bool get isDueToday {
    final now = DateTime.now();
    return nextReviewDate.isBefore(now) ||
        (nextReviewDate.year == now.year &&
            nextReviewDate.month == now.month &&
            nextReviewDate.day == now.day);
  }

  /// Implements SuperMemo SM-2 Algorithm (FR-06)
  /// q: Recall rating from 0 (Blackout) to 5 (Perfect recall)
  void applySm2Review(int q) {
    lastReviewed = DateTime.now();

    if (q < 3) {
      // Failed recall -> reset interval
      repetitions = 0;
      intervalDays = 1;
    } else {
      // Successful recall
      if (repetitions == 0) {
        intervalDays = 1;
      } else if (repetitions == 1) {
        intervalDays = 6;
      } else {
        intervalDays = (intervalDays * easeFactor).round();
      }
      repetitions++;
    }

    // Update Ease Factor (EF)
    // Formula: EF' = EF + (0.1 - (5 - q) * (0.08 + (5 - q) * 0.02))
    final double efChange = 0.1 - (5 - q) * (0.08 + (5 - q) * 0.02);
    easeFactor = easeFactor + efChange;
    if (easeFactor < 1.3) {
      easeFactor = 1.3; // Minimum floor value
    }

    nextReviewDate = DateTime.now().add(Duration(days: intervalDays));
  }
}
