import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/network/api_service.dart';
import 'floating_emoji_rating.dart';

class RatingScreen extends StatefulWidget {
  final String orderId;
  const RatingScreen({super.key, required this.orderId});

  @override
  State<RatingScreen> createState() => _RatingScreenState();
}

class _RatingScreenState extends State<RatingScreen> {
  Map<String, dynamic>? _order;
  bool _loading = true;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _loadOrder();
  }

  Future<void> _loadOrder() async {
    try {
      final res = await ApiService.instance.dio.get('/api/orders/${widget.orderId}');
      setState(() {
        _order = res.data['order'] as Map<String, dynamic>?;
        _loading = false;
      });
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  Future<void> _submitRating(int score) async {
    setState(() => _submitting = true);
    try {
      await ApiService.instance.dio.post('/api/ratings', data: {
        'orderId': widget.orderId,
        'score': score,
      });
      await Future.delayed(const Duration(milliseconds: 1500));
      if (!mounted) return;
      context.go('/orders');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Rating failed: $e')),
        );
        context.go('/orders');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final partnerName = _order?['partner'] != null
        ? '${_order!['partner']['firstName']} ${_order!['partner']['lastName']}'
        : 'your partner';

    return Scaffold(
      appBar: AppBar(),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  FloatingEmojiRating(
                    partnerName: partnerName,
                    onRated: _submitting ? (_) {} : _submitRating,
                  ),
                ],
              ),
            ),
    );
  }
}
