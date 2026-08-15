import 'package:flutter/material.dart';

class EarningsScreen extends StatelessWidget {
  const EarningsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Earnings')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF0F766E), Color(0xFF115E59)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Wallet Balance', style: TextStyle(color: Colors.white70, fontSize: 13)),
                SizedBox(height: 8),
                Text('₹3,250', style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w800)),
                SizedBox(height: 16),
                Row(
                  children: [
                    Icon(Icons.trending_up, color: Colors.white70, size: 16),
                    SizedBox(width: 4),
                    Text('+₹1,250 this week', style: TextStyle(color: Colors.white70, fontSize: 12)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.account_balance_wallet),
                  label: const Text('Withdraw'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          const Text('Recent Transactions', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          _Txn(title: 'Order DP-DEMO001', subtitle: 'Delivery earnings', amount: '+₹89', date: 'Today, 2:35 PM', isCredit: true),
          _Txn(title: 'Order DP-DEMO002', subtitle: 'Delivery earnings', amount: '+₹220', date: 'Today, 1:15 PM', isCredit: true),
          _Txn(title: 'Withdrawal', subtitle: 'To bank account', amount: '-₹2,000', date: 'Yesterday', isCredit: false),
          _Txn(title: 'Order DP-DEMO003', subtitle: 'Delivery earnings', amount: '+₹89', date: 'Yesterday', isCredit: true),
          _Txn(title: 'Incentive bonus', subtitle: 'Weekly target reached', amount: '+₹500', date: '2 days ago', isCredit: true),
        ],
      ),
    );
  }
}

class _Txn extends StatelessWidget {
  final String title, subtitle, amount, date;
  final bool isCredit;
  const _Txn({required this.title, required this.subtitle, required this.amount, required this.date, required this.isCredit});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: (isCredit ? Colors.green : Colors.red).withValues(alpha: 0.12),
          child: Icon(isCredit ? Icons.add : Icons.remove, color: isCredit ? Colors.green : Colors.red),
        ),
        title: Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
        subtitle: Text('$subtitle · $date', style: const TextStyle(fontSize: 12)),
        trailing: Text(
          amount,
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: isCredit ? Colors.green : Colors.red,
          ),
        ),
      ),
    );
  }
}
