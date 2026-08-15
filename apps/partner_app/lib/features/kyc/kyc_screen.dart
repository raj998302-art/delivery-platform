import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../core/network/api_service.dart';

class KycScreen extends StatefulWidget {
  const KycScreen({super.key});
  @override
  State<KycScreen> createState() => _KycScreenState();
}

class _KycScreenState extends State<KycScreen> {
  Map<String, dynamic>? _kycStatus;
  bool _loading = true;
  bool _submitting = false;

  // Form controllers
  final _aadhaarCtrl = TextEditingController();
  final _panCtrl = TextEditingController();
  final _licenseCtrl = TextEditingController();
  final _bankCtrl = TextEditingController();
  final _ifscCtrl = TextEditingController();
  final _upiCtrl = TextEditingController();
  final Map<String, String> _uploadedDocs = {}; // type -> url (mock)

  static const _requiredDocs = [
    {'type': 'PHOTO', 'label': 'Profile Photo', 'icon': Icons.person_outline},
    {'type': 'AADHAAR', 'label': 'Aadhaar Card', 'icon': Icons.badge_outlined},
    {'type': 'PAN', 'label': 'PAN Card', 'icon': Icons.credit_card_outlined},
    {'type': 'LICENSE', 'label': 'Driving License', 'icon': Icons.drive_eta_outlined},
    {'type': 'RC', 'label': 'Vehicle RC', 'icon': Icons.directions_car_outlined},
    {'type': 'INSURANCE', 'label': 'Insurance', 'icon': Icons.shield_outlined},
  ];

  @override
  void initState() {
    super.initState();
    _loadKycStatus();
  }

  Future<void> _loadKycStatus() async {
    setState(() => _loading = true);
    try {
      final res = await ApiService.instance.dio.get('/api/partner/kyc/status');
      setState(() {
        _kycStatus = res.data as Map<String, dynamic>?;
        _loading = false;
        // Pre-fill form if profile exists
        final profile = _kycStatus?['profile'] as Map<String, dynamic>?;
        if (profile != null) {
          _aadhaarCtrl.text = profile['aadhaarNumber'] ?? '';
          _panCtrl.text = profile['panNumber'] ?? '';
          _licenseCtrl.text = profile['drivingLicense'] ?? '';
          _bankCtrl.text = profile['bankAccount'] ?? '';
          _ifscCtrl.text = profile['ifsc'] ?? '';
          _upiCtrl.text = profile['upiId'] ?? '';
        }
        // Mark uploaded docs
        final docs = _kycStatus?['documents'] as List?;
        if (docs != null) {
          for (final d in docs) {
            _uploadedDocs[d['type'] as String] = d['url'] as String;
          }
        }
      });
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  Future<void> _submitKyc() async {
    setState(() => _submitting = true);
    try {
      final documents = _uploadedDocs.entries.map((e) => {'type': e.key, 'url': e.value}).toList();
      await ApiService.instance.dio.post('/api/partner/kyc', data: {
        'aadhaarNumber': _aadhaarCtrl.text,
        'panNumber': _panCtrl.text,
        'drivingLicense': _licenseCtrl.text,
        'bankAccount': _bankCtrl.text,
        'ifsc': _ifscCtrl.text,
        'upiId': _upiCtrl.text,
        'documents': documents,
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('KYC submitted! Verification in progress.'), backgroundColor: Color(0xFF0F766E)),
        );
        _loadKycStatus();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e')));
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  void _uploadDoc(String type) {
    // Mock upload — in production this would use image_picker + upload to S3/Cloudinary
    setState(() {
      _uploadedDocs[type] = 'https://delivery.app/docs/$type-${DateTime.now().millisecondsSinceEpoch}.jpg';
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$type uploaded'), backgroundColor: const Color(0xFF10B981)),
    );
  }

  @override
  void dispose() {
    _aadhaarCtrl.dispose();
    _panCtrl.dispose();
    _licenseCtrl.dispose();
    _bankCtrl.dispose();
    _ifscCtrl.dispose();
    _upiCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final progress = _kycStatus?['progress'] as int? ?? 0;
    final isVerified = _kycStatus?['isVerified'] as bool? ?? false;
    final kycStatus = _kycStatus?['kycStatus'] as String? ?? 'PENDING';
    final summary = _kycStatus?['summary'] as Map<String, dynamic>?;

    return Scaffold(
      appBar: AppBar(title: const Text('KYC Verification')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isVerified
                      ? [const Color(0xFF10B981), const Color(0xFF059669)]
                      : kycStatus == 'PENDING'
                          ? [const Color(0xFFF59E0B), const Color(0xFFD97706)]
                          : [const Color(0xFF6366F1), const Color(0xFF8B5CF6)],
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                children: [
                  Icon(
                    isVerified ? Icons.verified : (kycStatus == 'PENDING' ? Icons.pending : Icons.upload_file),
                    color: Colors.white,
                    size: 48,
                  ).animate().scale(duration: 500.ms, curve: Curves.easeOutBack),
                  const SizedBox(height: 12),
                  Text(
                    isVerified ? 'Verified!' : (kycStatus == 'PENDING' ? 'Under Review' : 'Submit KYC'),
                    style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    isVerified ? 'Your KYC is complete' : (kycStatus == 'PENDING' ? 'Verification in progress' : 'Complete your KYC to start earning'),
                    style: TextStyle(color: Colors.white.withValues(alpha: 0.85), fontSize: 12),
                  ),
                  const SizedBox(height: 16),
                  // Progress bar
                  Row(
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: LinearProgressIndicator(
                            value: progress / 100,
                            backgroundColor: Colors.white.withValues(alpha: 0.2),
                            valueColor: const AlwaysStoppedAnimation(Colors.white),
                            minHeight: 8,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text('$progress%', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                    ],
                  ),
                  if (summary != null) ...[
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _ProgressStat(label: 'Verified', value: summary['verified'] as int, color: Colors.white),
                        _ProgressStat(label: 'Pending', value: summary['pending'] as int, color: Colors.white),
                        _ProgressStat(label: 'Missing', value: summary['missing'] as int, color: Colors.white),
                      ],
                    ),
                  ],
                ],
              ),
            ).animate().fadeIn().slideY(begin: 0.05, end: 0),

            const SizedBox(height: 24),

            // Documents section
            const Text('Required Documents', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            const SizedBox(height: 12),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.1,
              children: _requiredDocs.map((doc) {
                final type = doc['type'] as String;
                final isUploaded = _uploadedDocs.containsKey(type);
                final docStatus = (_kycStatus?['documents'] as List?)?.cast<Map<String, dynamic>?>().firstWhere(
                  (d) => d?['type'] == type,
                  orElse: () => null,
                );
                final status = docStatus?['status'] as String?;

                return GestureDetector(
                  onTap: isVerified ? null : () => _uploadDoc(type),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isUploaded ? const Color(0xFF10B981) : const Color(0xFFE2E8F0),
                        width: isUploaded ? 1.5 : 1,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: isUploaded ? const Color(0xFF10B981).withValues(alpha: 0.12) : const Color(0xFF0F766E).withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            isUploaded ? Icons.check_circle : doc['icon'] as IconData,
                            color: isUploaded ? const Color(0xFF10B981) : const Color(0xFF0F766E),
                            size: 20,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(doc['label'] as String, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600), textAlign: TextAlign.center),
                        const SizedBox(height: 4),
                        if (status == 'VERIFIED')
                          const Text('Verified', style: TextStyle(fontSize: 9, color: Color(0xFF10B981), fontWeight: FontWeight.w600))
                        else if (status == 'PENDING')
                          const Text('Pending', style: TextStyle(fontSize: 9, color: Color(0xFFF59E0B), fontWeight: FontWeight.w600))
                        else if (isUploaded)
                          const Text('Uploaded', style: TextStyle(fontSize: 9, color: Color(0xFF10B981)))
                        else
                          const Text('Tap to upload', style: TextStyle(fontSize: 9, color: Color(0xFF94A3B8))),
                      ],
                    ),
                  ),
                ).animate().fadeIn().scale(duration: 300.ms, curve: Curves.easeOutBack);
              }).toList(),
            ),

            const SizedBox(height: 24),

            // Bank details form
            const Text('Bank & Personal Details', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFFE2E8F0))),
              child: Column(
                children: [
                  _TextField(controller: _aadhaarCtrl, label: 'Aadhaar Number', hint: 'XXXX XXXX XXXX'),
                  const SizedBox(height: 12),
                  _TextField(controller: _panCtrl, label: 'PAN Number', hint: 'ABCDE1234F'),
                  const SizedBox(height: 12),
                  _TextField(controller: _licenseCtrl, label: 'Driving License', hint: 'DL-XXXXXXXX'),
                  const SizedBox(height: 12),
                  _TextField(controller: _bankCtrl, label: 'Bank Account Number', hint: 'XXXXXXXXXX'),
                  const SizedBox(height: 12),
                  _TextField(controller: _ifscCtrl, label: 'IFSC Code', hint: 'HDFC0001234'),
                  const SizedBox(height: 12),
                  _TextField(controller: _upiCtrl, label: 'UPI ID', hint: 'name@bank'),
                ],
              ),
            ).animate().fadeIn().slideY(begin: 0.05, end: 0),

            const SizedBox(height: 24),

            // Submit button
            if (!isVerified)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _submitting ? null : _submitKyc,
                  child: _submitting
                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Text('Submit for Verification'),
                ),
              ),

            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

class _ProgressStat extends StatelessWidget {
  final String label;
  final int value;
  final Color color;
  const _ProgressStat({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text('$value', style: TextStyle(color: color, fontSize: 20, fontWeight: FontWeight.w800)),
        Text(label, style: TextStyle(color: color.withValues(alpha: 0.7), fontSize: 10)),
      ],
    );
  }
}

class _TextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  const _TextField({required this.controller, required this.label, required this.hint});

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(labelText: label, hintText: hint),
    );
  }
}
