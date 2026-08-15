import 'dart:async';
import 'dart:math';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import "package:flutter/services.dart";
import 'package:flutter_animate/flutter_animate.dart';


/// Full-screen incoming order overlay with sound + pulse animation.
/// Covers the entire screen when a new order comes in, plays a sound,
/// and shows a pulsing ring + countdown timer.
class IncomingOrderOverlay extends StatefulWidget {
  final Map<String, dynamic> order;
  final VoidCallback onAccept;
  final VoidCallback onReject;
  final int durationSeconds;

  const IncomingOrderOverlay({
    super.key,
    required this.order,
    required this.onAccept,
    required this.onReject,
    this.durationSeconds = 15,
  });

  @override
  State<IncomingOrderOverlay> createState() => _IncomingOrderOverlayState();
}

class _IncomingOrderOverlayState extends State<IncomingOrderOverlay>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _progressController;
  late AnimationController _shakeController;
  Timer? _timer;
  int _secondsLeft = 15;
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _soundLoaded = false;

  @override
  void initState() {
    super.initState();
    _secondsLeft = widget.durationSeconds;

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();

    _progressController = AnimationController(
      vsync: this,
      duration: Duration(seconds: widget.durationSeconds),
    )..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          widget.onReject();
        }
      });
    _progressController.forward();

    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    )..repeat(reverse: true);

    _startTimer();
    _playSound();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      setState(() => _secondsLeft--);
      HapticFeedback.lightImpact();
      if (_secondsLeft <= 5) {
        HapticFeedback.heavyImpact();
      }
      if (_secondsLeft <= 0) {
        t.cancel();
      }
    });
  }

  Future<void> _playSound() async {
    try {
      // Try to play a notification sound. If the asset doesn't exist,
      // we fall back to a system sound.
      await _audioPlayer.play(AssetSource('sounds/notification.mp3'));
      _soundLoaded = true;
    } catch (_) {
      // Sound file not found — that's OK, the visual animation is enough.
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _progressController.dispose();
    _shakeController.dispose();
    _timer?.cancel();
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isUrgent = _secondsLeft <= 5;

    return Scaffold(
      backgroundColor: Colors.black.withValues(alpha: 0.9),
      body: Stack(
        children: [
          // Pulsing rings background
          Center(
            child: Stack(
              alignment: Alignment.center,
              children: List.generate(3, (i) {
                return AnimatedBuilder(
                  animation: _pulseController,
                  builder: (_, child) {
                    final progress = (_pulseController.value + i * 0.33) % 1.0;
                    return Transform.scale(
                      scale: 1.0 + progress * 2.5,
                      child: Opacity(
                        opacity: (1 - progress) * 0.4,
                        child: Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isUrgent
                                  ? const Color(0xFFEF4444).withValues(alpha: 0.5)
                                  : const Color(0xFF14B8A6).withValues(alpha: 0.5),
                              width: 2,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                );
              }),
            ),
          ),

          // Main content
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  const Spacer(),
                  // Header icon with pulse
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: isUrgent
                            ? [const Color(0xFFEF4444), const Color(0xFFDC2626)]
                            : [const Color(0xFF0F766E), const Color(0xFF14B8A6)],
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: (isUrgent ? const Color(0xFFEF4444) : const Color(0xFF14B8A6))
                              .withValues(alpha: 0.5),
                          blurRadius: 30,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    child: const Icon(Icons.local_shipping_rounded, color: Colors.white, size: 48),
                  )
                      .animate(target: isUrgent ? 1 : 0)
                      .shake(duration: 300.ms, hz: 4)
                      .then()
                      .shake(delay: 300.ms, duration: 300.ms, hz: 4),

                  const SizedBox(height: 24),

                  // New delivery text
                  Text(
                    'NEW DELIVERY REQUEST',
                    style: TextStyle(
                      color: isUrgent ? const Color(0xFFEF4444) : Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 2,
                    ),
                  )
                      .animate(onPlay: (c) => c.repeat(reverse: true))
                      .fadeIn(duration: 500.ms)
                      .then()
                      .fadeOut(duration: 500.ms),

                  const SizedBox(height: 8),

                  // Countdown
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox(
                        width: 80,
                        height: 80,
                        child: CircularProgressIndicator(
                          value: _secondsLeft / widget.durationSeconds,
                          color: isUrgent ? const Color(0xFFEF4444) : const Color(0xFF14B8A6),
                          strokeWidth: 4,
                          backgroundColor: Colors.white10,
                        ),
                      ),
                      Text(
                        '${_secondsLeft}s',
                        style: TextStyle(
                          color: isUrgent ? const Color(0xFFEF4444) : Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),

                  const Spacer(),

                  // Order details card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E293B),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white10),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.circle, color: Color(0xFF10B981), size: 12),
                            const SizedBox(width: 8),
                            const Text(
                              'Pickup',
                              style: TextStyle(color: Color(0xFF94A3B8), fontSize: 11, fontWeight: FontWeight.w600),
                            ),
                            const Spacer(),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFF10B981).withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                '${widget.order['distance'] ?? '0.5'} km away',
                                style: const TextStyle(color: Color(0xFF10B981), fontSize: 11, fontWeight: FontWeight.w700),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.order['pickup'] ?? 'Pickup address',
                          style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600),
                        ),
                        const Padding(
                          padding: EdgeInsets.only(left: 5),
                          child: SizedBox(
                            height: 24,
                            child: VerticalDivider(color: Color(0xFF475569), width: 1),
                          ),
                        ),
                        Row(
                          children: [
                            const Icon(Icons.circle, color: Color(0xFFEF4444), size: 12),
                            const SizedBox(width: 8),
                            const Text(
                              'Drop',
                              style: TextStyle(color: Color(0xFF94A3B8), fontSize: 11, fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.order['drop'] ?? 'Drop address',
                          style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600),
                        ),
                        const Divider(color: Color(0xFF334155), height: 28),
                        Row(
                          children: [
                            _InfoChip(label: 'Distance', value: '${widget.order['distance'] ?? '0.5'} km'),
                            const SizedBox(width: 16),
                            _InfoChip(label: 'ETA', value: '${widget.order['eta'] ?? '5'} min'),
                            const SizedBox(width: 16),
                            _InfoChip(label: 'Package', value: widget.order['package'] ?? 'Small'),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF10B981), Color(0xFF059669)],
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.account_balance_wallet, color: Colors.white, size: 20),
                              const SizedBox(width: 8),
                              Text(
                                'You earn ₹${widget.order['earnings'] ?? '89'}',
                                style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  )
                      .animate()
                      .fadeIn(delay: 200.ms, duration: 400.ms)
                      .slideY(begin: 0.1, end: 0, curve: Curves.easeOutCubic),

                  const Spacer(),

                  // Action buttons
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          height: 56,
                          decoration: BoxDecoration(
                            color: Colors.white10,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: const Color(0xFFEF4444).withValues(alpha: 0.5)),
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () {
                                HapticFeedback.heavyImpact();
                                widget.onReject();
                              },
                              borderRadius: BorderRadius.circular(16),
                              child: const Center(
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.close, color: Color(0xFFEF4444), size: 20),
                                    SizedBox(width: 8),
                                    Text('Reject', style: TextStyle(color: Color(0xFFEF4444), fontWeight: FontWeight.w700, fontSize: 15)),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: Container(
                          height: 56,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF10B981), Color(0xFF059669)],
                            ),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF10B981).withValues(alpha: 0.4),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () {
                                HapticFeedback.heavyImpact();
                                widget.onAccept();
                              },
                              borderRadius: BorderRadius.circular(16),
                              child: const Center(
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.check_circle, color: Colors.white, size: 20),
                                    SizedBox(width: 8),
                                    Text('Accept', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16)),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        )
                            .animate(onPlay: (c) => c.repeat(reverse: true))
                            .scale(duration: 800.ms, begin: const Offset(1, 1), end: const Offset(1.03, 1.03)),
                      ),
                    ],
                  )
                      .animate()
                      .fadeIn(delay: 400.ms, duration: 400.ms)
                      .slideY(begin: 0.1, end: 0),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final String label;
  final String value;
  const _InfoChip({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Color(0xFF64748B), fontSize: 10, fontWeight: FontWeight.w600)),
        const SizedBox(height: 2),
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w700)),
      ],
    );
  }
}
