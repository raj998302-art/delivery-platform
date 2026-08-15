import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/network/api_service.dart';

class SupportScreen extends StatefulWidget {
  const SupportScreen({super.key});
  @override
  State<SupportScreen> createState() => _SupportScreenState();
}

class _SupportScreenState extends State<SupportScreen> {
  List<dynamic> _tickets = [];
  bool _loading = true;
  bool _showNewTicket = false;
  final _subjectCtrl = TextEditingController();
  final _messageCtrl = TextEditingController();
  String _category = 'OTHER';
  String _priority = 'NORMAL';
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _loadTickets();
  }

  Future<void> _loadTickets() async {
    setState(() => _loading = true);
    try {
      final res = await ApiService.instance.dio.get('/api/support/me');
      setState(() {
        _tickets = res.data['tickets'] as List? ?? [];
        _loading = false;
      });
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  Future<void> _submitTicket() async {
    if (_subjectCtrl.text.isEmpty || _messageCtrl.text.isEmpty) return;
    setState(() => _submitting = true);
    try {
      await ApiService.instance.dio.post('/api/support', data: {
        'subject': _subjectCtrl.text,
        'message': _messageCtrl.text,
        'category': _category,
        'priority': _priority,
      });
      _subjectCtrl.clear();
      _messageCtrl.clear();
      setState(() => _showNewTicket = false);
      _loadTickets();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ticket created! Our team will respond shortly.'), backgroundColor: Color(0xFF0F766E)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e')));
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  void dispose() {
    _subjectCtrl.dispose();
    _messageCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Help & Support'),
        actions: [IconButton(icon: const Icon(Icons.refresh), onPressed: _loadTickets)],
      ),
      body: Column(
        children: [
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFF0F766E), Color(0xFF14B8A6)]),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(14)),
                  child: const Icon(Icons.support_agent, color: Colors.white, size: 24),
                ),
                const SizedBox(width: 16),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('24/7 Partner Support', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)),
                      SizedBox(height: 4),
                      Text('We\'re here to help anytime', style: TextStyle(color: Colors.white70, fontSize: 12)),
                    ],
                  ),
                ),
              ],
            ),
          ).animate().fadeIn().slideY(begin: -0.05, end: 0),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(child: _QuickAction(icon: Icons.phone, label: 'Call Us', color: const Color(0xFF10B981), onTap: () => launchUrl(Uri.parse('tel:+918000000000')))),
                const SizedBox(width: 12),
                Expanded(child: _QuickAction(icon: Icons.chat, label: 'WhatsApp', color: const Color(0xFF25D366), onTap: () => launchUrl(Uri.parse('https://wa.me/918000000000')))),
                const SizedBox(width: 12),
                Expanded(child: _QuickAction(icon: Icons.email, label: 'Email', color: const Color(0xFF0F766E), onTap: () => launchUrl(Uri.parse('mailto:partners@delivery.app')))),
              ],
            ),
          ),

          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => setState(() => _showNewTicket = !_showNewTicket),
                icon: Icon(_showNewTicket ? Icons.close : Icons.add_circle_outline),
                label: Text(_showNewTicket ? 'Cancel' : 'Raise New Ticket'),
              ),
            ),
          ),

          if (_showNewTicket) ...[
            const SizedBox(height: 16),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFFE2E8F0))),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(controller: _subjectCtrl, decoration: const InputDecoration(labelText: 'Subject')),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: _category,
                    decoration: const InputDecoration(labelText: 'Category'),
                    items: const [
                      DropdownMenuItem(value: 'ORDER_ISSUE', child: Text('Order Issue')),
                      DropdownMenuItem(value: 'PAYMENT', child: Text('Payment')),
                      DropdownMenuItem(value: 'PARTNER', child: Text('Partner')),
                      DropdownMenuItem(value: 'APP_BUG', child: Text('App Bug')),
                      DropdownMenuItem(value: 'ACCOUNT', child: Text('Account')),
                      DropdownMenuItem(value: 'OTHER', child: Text('Other')),
                    ],
                    onChanged: (v) => setState(() => _category = v ?? 'OTHER'),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: _priority,
                    decoration: const InputDecoration(labelText: 'Priority'),
                    items: const [
                      DropdownMenuItem(value: 'LOW', child: Text('Low')),
                      DropdownMenuItem(value: 'NORMAL', child: Text('Normal')),
                      DropdownMenuItem(value: 'HIGH', child: Text('High')),
                      DropdownMenuItem(value: 'URGENT', child: Text('Urgent')),
                    ],
                    onChanged: (v) => setState(() => _priority = v ?? 'NORMAL'),
                  ),
                  const SizedBox(height: 12),
                  TextField(controller: _messageCtrl, decoration: const InputDecoration(labelText: 'Message'), maxLines: 3),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _submitting ? null : _submitTicket,
                      child: _submitting ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Text('Submit Ticket'),
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn().slideY(begin: 0.05, end: 0),
          ],

          const SizedBox(height: 16),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Your Tickets', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _tickets.isEmpty
                    ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.support_agent, color: Colors.grey.shade400, size: 48), const SizedBox(height: 12), const Text('No tickets yet')]))
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: _tickets.length,
                        itemBuilder: (_, i) {
                          final t = _tickets[i];
                          final status = t['status'] as String? ?? 'OPEN';
                          final colorMap = {'OPEN': const Color(0xFF3B82F6), 'IN_PROGRESS': const Color(0xFFF59E0B), 'RESOLVED': const Color(0xFF10B981), 'CLOSED': const Color(0xFF94A3B8)};
                          final color = colorMap[status] ?? Colors.grey;
                          return Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: const Color(0xFFE2E8F0))),
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              title: Row(children: [Text(t['code'] as String? ?? '', style: const TextStyle(fontFamily: 'monospace', fontSize: 12, fontWeight: FontWeight.w700)), const SizedBox(width: 8), Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(4)), child: Text(status.replaceAll('_', ' '), style: TextStyle(fontSize: 9, color: color, fontWeight: FontWeight.w600)))]),
                              subtitle: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const SizedBox(height: 4), Text(t['subject'] as String? ?? '', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600))]),
                            ),
                          ).animate().fadeIn(delay: (i * 50).ms).slideX(begin: 0.05, end: 0);
                        },
                      ),
          ),
        ],
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _QuickAction({required this.icon, required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFFE2E8F0))),
        child: Column(children: [
          Container(width: 40, height: 40, decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(12)), child: Icon(icon, color: color, size: 20)),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
        ]),
      ).animate().fadeIn().scale(duration: 300.ms, curve: Curves.easeOutBack),
    );
  }
}
