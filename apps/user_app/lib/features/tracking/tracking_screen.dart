import 'package:flutter/material.dart';

class TrackingScreen extends StatelessWidget {
  const TrackingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Live Tracking'), centerTitle: true),
      body: Column(
        children: [
          // Map placeholder
          Expanded(
            flex: 3,
            child: Container(
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFE2E8F0),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Stack(
                children: [
                  // Fake map grid
                  CustomPaint(
                    size: Size.infinite,
                    painter: _MapGridPainter(),
                  ),
                  // Center pin
                  Center(
                    child: Icon(Icons.local_shipping, size: 40, color: Colors.blue.shade700),
                  ),
                  // Status pill
                  Positioned(
                    top: 12,
                    left: 12,
                    right: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 8)],
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.circle, color: Colors.green, size: 10),
                          SizedBox(width: 8),
                          Text('Partner arriving in 5 min', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Partner card
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 12, offset: const Offset(0, 2))],
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 26,
                  backgroundColor: const Color(0xFF2563EB).withValues(alpha: 0.12),
                  child: const Icon(Icons.person, color: Color(0xFF2563EB)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Ramesh K.', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                      Row(
                        children: [
                          const Icon(Icons.star, color: Colors.amber, size: 14),
                          const SizedBox(width: 4),
                          Text('4.8 · Honda Activa · KA01AB1234', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                        ],
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.phone, color: Color(0xFF10B981)),
                  onPressed: () {},
                ),
                IconButton(
                  icon: const Icon(Icons.chat_bubble_outline, color: Color(0xFF2563EB)),
                  onPressed: () {},
                ),
              ],
            ),
          ),
          // Status timeline
          Expanded(
            flex: 2,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: const [
                _TimelineItem(title: 'Order confirmed', time: '2:30 PM', done: true),
                _TimelineItem(title: 'Partner assigned', time: '2:31 PM', done: true),
                _TimelineItem(title: 'Partner arrived at pickup', time: '2:35 PM', done: true),
                _TimelineItem(title: 'Package picked up', time: '2:38 PM', done: true, active: true),
                _TimelineItem(title: 'In transit', time: '—', done: false),
                _TimelineItem(title: 'Delivered', time: '—', done: false),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MapGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..strokeWidth = 1;
    for (double x = 0; x < size.width; x += 30) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += 30) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
    // Fake route
    final routePaint = Paint()
      ..color = const Color(0xFF2563EB)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;
    final path = Path()
      ..moveTo(size.width * 0.2, size.height * 0.8)
      ..cubicTo(
        size.width * 0.4, size.height * 0.6,
        size.width * 0.5, size.height * 0.4,
        size.width * 0.8, size.height * 0.2,
      );
    canvas.drawPath(path, routePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _TimelineItem extends StatelessWidget {
  final String title;
  final String time;
  final bool done;
  final bool active;
  const _TimelineItem({required this.title, required this.time, required this.done, this.active = false});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 14,
              height: 14,
              decoration: BoxDecoration(
                color: done ? const Color(0xFF10B981) : (active ? const Color(0xFF2563EB) : const Color(0xFFE2E8F0)),
                shape: BoxShape.circle,
                border: active ? Border.all(color: const Color(0xFF2563EB).withValues(alpha: 0.3), width: 4) : null,
              ),
            ),
            Container(
              width: 2,
              height: 28,
              color: done ? const Color(0xFF10B981) : const Color(0xFFE2E8F0),
            ),
          ],
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: TextStyle(fontWeight: active ? FontWeight.w700 : FontWeight.w500, fontSize: 14, color: done || active ? Colors.black87 : Colors.grey.shade500)),
              Text(time, style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
            ],
          ),
        ),
      ],
    );
  }
}
