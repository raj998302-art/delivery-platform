import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

/// Floating emoji rating widget — when the user selects a rating,
/// emojis float up from the bottom of the screen like a celebration.
class FloatingEmojiRating extends StatefulWidget {
  final ValueChanged<int> onRated;
  final String partnerName;

  const FloatingEmojiRating({
    super.key,
    required this.onRated,
    required this.partnerName,
  });

  @override
  State<FloatingEmojiRating> createState() => _FloatingEmojiRatingState();
}

class _FloatingEmojiRatingState extends State<FloatingEmojiRating>
    with TickerProviderStateMixin {
  int _selectedRating = 0;
  int _hoveredRating = 0;
  bool _submitted = false;
  late AnimationController _emojiController;
  final List<_FloatingEmoji> _emojis = [];

  static const _ratingEmojis = ['😡', '😕', '😐', '😊', '🤩'];
  static const _ratingLabels = ['Terrible', 'Poor', 'OK', 'Good', 'Amazing!'];
  static const _celebrationEmojis = ['🎉', '⭐', '✨', '🌟', '💫', '🥳', '👏', '❤️'];

  @override
  void initState() {
    super.initState();
    _emojiController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..addListener(() {
        setState(() {});
      });
  }

  @override
  void dispose() {
    _emojiController.dispose();
    super.dispose();
  }

  void _spawnEmojis(int count) {
    final rand = Random();
    for (int i = 0; i < count; i++) {
      _emojis.add(_FloatingEmoji(
        emoji: _celebrationEmojis[rand.nextInt(_celebrationEmojis.length)],
        startX: rand.nextDouble() * MediaQuery.of(context).size.width,
        delay: i * 0.08,
        size: 30.0 + rand.nextDouble() * 24,
      ));
    }
    _emojiController.forward(from: 0);
  }

  void _submitRating(int rating) {
    if (_submitted) return;
    setState(() {
      _selectedRating = rating;
      _submitted = true;
    });
    _spawnEmojis(rating * 8); // more emojis for higher rating
    Future.delayed(const Duration(milliseconds: 800), () {
      widget.onRated(rating);
    });
  }

  @override
  Widget build(BuildContext context) {
    final displayRating = _hoveredRating > 0 ? _hoveredRating : _selectedRating;
    return Stack(
      children: [
        // Floating emojis layer
        ..._emojis.map((e) {
          final progress = (_emojiController.value - e.delay).clamp(0.0, 1.0);
          if (progress <= 0 || progress >= 1) return const SizedBox.shrink();
          final screenHeight = MediaQuery.of(context).size.height;
          return Positioned(
            left: e.startX,
            top: screenHeight - 100 - (progress * screenHeight * 0.7),
            child: Opacity(
              opacity: (1 - progress).clamp(0.0, 1.0),
              child: Transform.rotate(
                angle: sin(progress * pi * 2) * 0.3,
                child: Text(
                  e.emoji,
                  style: TextStyle(fontSize: e.size),
                ),
              ),
            ),
          );
        }),

        // Main content
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (!_submitted) ...[
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: const Color(0xFF6366F1).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: const Icon(Icons.person, color: Color(0xFF6366F1), size: 40),
                )
                    .animate()
                    .fadeIn(duration: 400.ms)
                    .scale(delay: 100.ms, duration: 500.ms, curve: Curves.easeOutBack),
                const SizedBox(height: 16),
                Text(
                  'Rate your delivery',
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
                )
                    .animate()
                    .fadeIn(delay: 200.ms, duration: 400.ms)
                    .slideY(begin: 0.1, end: 0),
                const SizedBox(height: 8),
                Text(
                  'How was ${widget.partnerName}?',
                  style: const TextStyle(color: Color(0xFF64748B), fontSize: 14),
                )
                    .animate()
                    .fadeIn(delay: 300.ms, duration: 400.ms),
                const SizedBox(height: 32),
                // Emoji rating row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: List.generate(5, (i) {
                    final rating = i + 1;
                    final isSelected = rating <= displayRating;
                    final isHovered = rating == _hoveredRating;
                    return GestureDetector(
                      onTapDown: (_) => setState(() => _hoveredRating = rating),
                      onTapCancel: () => setState(() => _hoveredRating = 0),
                      onTap: () => _submitRating(rating),
                      child: AnimatedContainer(
                        duration: 200.ms,
                        width: isHovered ? 56 : 48,
                        height: isHovered ? 56 : 48,
                        decoration: BoxDecoration(
                          color: isSelected
                              ? const Color(0xFF6366F1).withValues(alpha: 0.1)
                              : Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isSelected ? const Color(0xFF6366F1) : Colors.transparent,
                            width: 2,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            _ratingEmojis[i],
                            style: TextStyle(
                              fontSize: isHovered ? 32 : 26,
                            ),
                          ),
                        ),
                      ),
                    )
                        .animate(delay: (400 + i * 60).ms)
                        .fadeIn(duration: 400.ms)
                        .slideY(begin: 0.2, end: 0, curve: Curves.easeOutBack);
                  }),
                ),
                const SizedBox(height: 16),
                if (displayRating > 0)
                  Text(
                    _ratingLabels[displayRating - 1],
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF6366F1),
                    ),
                  ).animate().fadeIn().slideY(begin: 0.1, end: 0),
              ] else ...[
                // Submitted state
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF10B981), Color(0xFF059669)],
                    ),
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF10B981).withValues(alpha: 0.4),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.check, color: Colors.white, size: 50),
                )
                    .animate()
                    .scale(duration: 500.ms, curve: Curves.easeOutBack),
                const SizedBox(height: 24),
                const Text(
                  'Thank you!',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
                )
                    .animate(delay: 200.ms)
                    .fadeIn()
                    .slideY(begin: 0.1, end: 0),
                const SizedBox(height: 8),
                Text(
                  'Your feedback helps us improve',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                )
                    .animate(delay: 300.ms)
                    .fadeIn(),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _FloatingEmoji {
  final String emoji;
  final double startX;
  final double delay;
  final double size;
  _FloatingEmoji({
    required this.emoji,
    required this.startX,
    required this.delay,
    required this.size,
  });
}
