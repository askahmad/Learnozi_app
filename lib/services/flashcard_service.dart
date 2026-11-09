import 'package:flutter/foundation.dart';
import '../models/flashcard_model.dart';
import 'user_service.dart';

class FlashcardService extends ChangeNotifier {
  static final FlashcardService _instance = FlashcardService._internal();
  factory FlashcardService() => _instance;
  FlashcardService._internal() {
    _initSampleCards();
  }

  final List<Flashcard> _cards = [];
  List<Flashcard> get cards => List.unmodifiable(_cards);

  List<Flashcard> get dueTodayCards =>
      _cards.where((c) => c.isDueToday).toList();

  int _totalReviewsCompleted = 8;
  int get totalReviewsCompleted => _totalReviewsCompleted;

  void _initSampleCards() {
    _cards.addAll([
      Flashcard(
        id: 'fc_1',
        category: 'Physics',
        frontQuestion: 'What is the formula for Centripetal Acceleration (ac)?',
        backAnswer: 'ac = v² / r  (or ac = r * ω² in terms of angular velocity)',
        easeFactor: 2.5,
        intervalDays: 1,
        repetitions: 1,
        nextReviewDate: DateTime.now(), // Due today
      ),
      Flashcard(
        id: 'fc_2',
        category: 'Computer Science',
        frontQuestion: 'What is the worst-case time complexity of QuickSort?',
        backAnswer: 'O(n²) occurs when the chosen pivot is the smallest or largest element repeatedly (unbalanced partitions).',
        easeFactor: 2.6,
        intervalDays: 3,
        repetitions: 2,
        nextReviewDate: DateTime.now().add(const Duration(days: 2)),
      ),
      Flashcard(
        id: 'fc_3',
        category: 'Chemistry',
        frontQuestion: 'State Le Chatelier\'s Principle in one sentence.',
        backAnswer: 'If a chemical system at dynamic equilibrium experiences a change in pressure, temperature, or concentration, the equilibrium shifts in a direction that counteracts that change.',
        easeFactor: 2.4,
        intervalDays: 1,
        repetitions: 0,
        nextReviewDate: DateTime.now(), // Due today
      ),
      Flashcard(
        id: 'fc_4',
        category: 'Biology',
        frontQuestion: 'What is the difference between Mitosis and Meiosis chromosome count?',
        backAnswer: 'Mitosis produces 2 diploid (2n) identical daughter cells. Meiosis produces 4 haploid (1n) genetically distinct gametes.',
        easeFactor: 2.5,
        intervalDays: 1,
        repetitions: 0,
        nextReviewDate: DateTime.now(), // Due today
      ),
    ]);
  }

  void addFlashcard({
    required String front,
    required String back,
    required String category,
  }) {
    _cards.add(
      Flashcard(
        id: 'fc_${DateTime.now().millisecondsSinceEpoch}',
        frontQuestion: front,
        backAnswer: back,
        category: category,
      ),
    );
    notifyListeners();
  }

  void addCard({
    required String front,
    required String back,
    required String category,
  }) => addFlashcard(front: front, back: back, category: category);

  void reviewCard(Flashcard card, int rating) {
    card.applySm2Review(rating);
    _totalReviewsCompleted++;

    if (_totalReviewsCompleted >= 20) {
      UserService().unlockBadge('flashcard_champ');
    }

    notifyListeners();
  }

  void deleteFlashcard(String id) {
    _cards.removeWhere((c) => c.id == id);
    notifyListeners();
  }
}
