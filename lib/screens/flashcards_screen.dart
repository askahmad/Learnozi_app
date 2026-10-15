import 'package:flutter/material.dart';
import '../models/flashcard_model.dart';
import '../services/flashcard_service.dart';

class FlashcardsScreen extends StatefulWidget {
  const FlashcardsScreen({super.key});

  @override
  State<FlashcardsScreen> createState() => _FlashcardsScreenState();
}

class _FlashcardsScreenState extends State<FlashcardsScreen> {
  final _flashcardService = FlashcardService();
  String _selectedCategory = 'All';
  bool _onlyDueToday = false;

  // Active review card flip state
  int _currentReviewIndex = 0;
  bool _isAnswerRevealed = false;

  List<Flashcard> get _filteredCards {
    var list = _flashcardService.cards;
    if (_onlyDueToday) {
      list = list.where((c) => c.isDueToday).toList();
    }
    if (_selectedCategory != 'All') {
      list = list.where((c) => c.category == _selectedCategory).toList();
    }
    return list;
  }

  void _showAddCardDialog() {
    final frontController = TextEditingController();
    final backController = TextEditingController();
    String category = 'Physics';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          return Container(
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 20,
              bottom: MediaQuery.of(context).viewInsets.bottom + 20,
            ),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text('Create New Flashcard', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 14),
                  DropdownButtonFormField<String>(
                    initialValue: category,
                    decoration: InputDecoration(
                      labelText: 'Category',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    items: ['Physics', 'Chemistry', 'Computer Science', 'Biology', 'General']
                        .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                        .toList(),
                    onChanged: (val) {
                      if (val != null) setModalState(() => category = val);
                    },
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: frontController,
                    maxLines: 2,
                    decoration: InputDecoration(
                      labelText: 'Question / Prompt (Front)',
                      hintText: 'e.g. Formula for kinetic energy?',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: backController,
                    maxLines: 3,
                    decoration: InputDecoration(
                      labelText: 'Model Answer (Back)',
                      hintText: 'e.g. KE = 1/2 * m * v²',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 18),
                  ElevatedButton(
                    onPressed: () {
                      final front = frontController.text.trim();
                      final back = backController.text.trim();
                      if (front.isEmpty || back.isEmpty) return;

                      _flashcardService.addFlashcard(
                        front: front,
                        back: back,
                        category: category,
                      );
                      Navigator.pop(ctx);
                      setState(() {});
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4F46E5),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Add to SM-2 Deck', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _handleRateRecall(Flashcard card, int rating) {
    setState(() {
      _flashcardService.reviewCard(card, rating);
      _isAnswerRevealed = false;
      if (_currentReviewIndex < _filteredCards.length - 1) {
        _currentReviewIndex++;
      } else {
        _currentReviewIndex = 0;
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'SM-2 Updated: Next review in ${card.intervalDays} day(s) (EF: ${card.easeFactor.toStringAsFixed(2)})',
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cards = _filteredCards;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Active Recall Flashcards',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
            ),
            Text(
              'SuperMemo SM-2 Spaced Repetition (FR-06)',
              style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline_rounded, color: Color(0xFF4F46E5)),
            onPressed: _showAddCardDialog,
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter Row
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            color: Colors.white,
            child: Row(
              children: [
                FilterChip(
                  label: Text('Due Today (${_flashcardService.dueTodayCards.length})'),
                  selected: _onlyDueToday,
                  selectedColor: const Color(0xFFEEF2FF),
                  checkmarkColor: const Color(0xFF4F46E5),
                  onSelected: (val) => setState(() {
                    _onlyDueToday = val;
                    _currentReviewIndex = 0;
                  }),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: ['All', 'Physics', 'Computer Science', 'Chemistry', 'Biology'].map((cat) {
                        final isSel = _selectedCategory == cat;
                        return Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: ChoiceChip(
                            label: Text(cat, style: TextStyle(fontSize: 11.5, color: isSel ? Colors.white : Colors.black87)),
                            selected: isSel,
                            selectedColor: const Color(0xFF4F46E5),
                            onSelected: (val) {
                              if (val) {
                                setState(() {
                                  _selectedCategory = cat;
                                  _currentReviewIndex = 0;
                                });
                              }
                            },
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, thickness: 1, color: Color(0xFFE2E8F0)),

          // Main Review Deck Area
          Expanded(
            child: cards.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.done_all_rounded, size: 54, color: Color(0xFF10B981)),
                        const SizedBox(height: 12),
                        const Text('Deck Complete!', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        const SizedBox(height: 6),
                        const Text('No cards due right now for this filter.', style: TextStyle(color: Color(0xFF64748B))),
                        const SizedBox(height: 12),
                        ElevatedButton(
                          onPressed: () => setState(() {
                            _onlyDueToday = false;
                            _selectedCategory = 'All';
                          }),
                          child: const Text('Show All Cards'),
                        ),
                      ],
                    ),
                  )
                : _buildCardReviewDeck(cards),
          ),
        ],
      ),
    );
  }

  Widget _buildCardReviewDeck(List<Flashcard> cards) {
    if (_currentReviewIndex >= cards.length) {
      _currentReviewIndex = 0;
    }
    final card = cards[_currentReviewIndex];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Card ${_currentReviewIndex + 1} of ${cards.length}',
                style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF64748B), fontSize: 13),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  card.category,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF334155)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Flip Flashcard Container
          GestureDetector(
            onTap: () => setState(() => _isAnswerRevealed = !_isAnswerRevealed),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              height: 260,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: _isAnswerRevealed ? const Color(0xFFEEF2FF) : Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: _isAnswerRevealed ? const Color(0xFF818CF8) : const Color(0xFFE2E8F0),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF0F172A).withValues(alpha: 0.05),
                    blurRadius: 16,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    _isAnswerRevealed ? Icons.lightbulb_rounded : Icons.help_outline_rounded,
                    color: _isAnswerRevealed ? const Color(0xFFD97706) : const Color(0xFF4F46E5),
                    size: 32,
                  ),
                  const SizedBox(height: 14),
                  Text(
                    _isAnswerRevealed ? card.backAnswer : card.frontQuestion,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16.5,
                      fontWeight: FontWeight.w700,
                      color: _isAnswerRevealed ? const Color(0xFF1E1B4B) : const Color(0xFF0F172A),
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 18),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.touch_app_rounded, size: 14, color: Colors.grey.shade500),
                      const SizedBox(width: 4),
                      Text(
                        _isAnswerRevealed ? 'Tap to view question' : 'Tap to flip & reveal answer',
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // SM-2 Spaced Repetition Stats Pill
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildSm2Pill('Ease Factor', card.easeFactor.toStringAsFixed(2)),
                _buildSm2Pill('Interval', '${card.intervalDays} days'),
                _buildSm2Pill('Repetitions', '${card.repetitions}'),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // SM-2 Rating Buttons (0 to 5)
          const Text(
            'Rate Recall Difficulty (SM-2 Algorithm):',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF334155)),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _buildRatingBtn(card, 0, '0 Blackout', const Color(0xFFEF4444)),
              const SizedBox(width: 6),
              _buildRatingBtn(card, 2, '2 Hard', const Color(0xFFF59E0B)),
              const SizedBox(width: 6),
              _buildRatingBtn(card, 3, '3 Good', const Color(0xFF3B82F6)),
              const SizedBox(width: 6),
              _buildRatingBtn(card, 5, '5 Perfect', const Color(0xFF10B981)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSm2Pill(String label, String val) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
        const SizedBox(height: 2),
        Text(val, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF0F172A))),
      ],
    );
  }

  Widget _buildRatingBtn(Flashcard card, int rating, String label, Color color) {
    return Expanded(
      child: ElevatedButton(
        onPressed: () => _handleRateRecall(card, rating),
        style: ElevatedButton.styleFrom(
          backgroundColor: color.withValues(alpha: 0.1),
          foregroundColor: color,
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 12),
          side: BorderSide(color: color.withValues(alpha: 0.3)),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
        child: Text(label, style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold)),
      ),
    );
  }
}
