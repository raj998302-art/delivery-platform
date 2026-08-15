import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';

import '../../core/network/api_service.dart';

class BookingScreen extends StatefulWidget {
  const BookingScreen({super.key});
  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  int _step = 0;
  String _vehicleType = 'BIKE';
  String _packageType = 'SMALL_PARCEL';
  String _pickupAddress = '';
  String _dropAddress = '';
  double _packageWeightKg = 1;
  bool _fragile = false;

  // Real quote from backend
  Map<String, dynamic>? _quote;
  bool _loadingQuote = false;
  String? _quoteError;

  // Demo coordinates for Bengaluru (in production these come from map picker)
  final double _pickupLat = 12.9719;
  final double _pickupLng = 77.5937;
  final double _dropLat = 12.9352;
  final double _dropLng = 77.6245;

  final _steps = ['Pickup', 'Drop', 'Package', 'Vehicle', 'Fare', 'Confirm'];

  Future<void> _fetchQuote() async {
    setState(() {
      _loadingQuote = true;
      _quoteError = null;
      _quote = null;
    });
    try {
      final res = await ApiService.instance.getFareQuote(
        serviceType: 'PARCEL',
        vehicleType: _vehicleType,
        pickupLat: _pickupLat,
        pickupLng: _pickupLng,
        dropLat: _dropLat,
        dropLng: _dropLng,
      );
      setState(() {
        _quote = res;
        _loadingQuote = false;
      });
    } catch (e) {
      setState(() {
        _quoteError = '$e';
        _loadingQuote = false;
      });
    }
  }

  Future<void> _createOrder() async {
    if (_quote == null) return;
    setState(() => _loadingQuote = true);
    try {
      final res = await ApiService.instance.createOrder(
        quoteId: _quote!['quoteId'] as String,
        serviceType: 'PARCEL',
        vehicleType: _vehicleType,
        pickupLat: _pickupLat,
        pickupLng: _pickupLng,
        pickupAddress: _pickupAddress.isNotEmpty ? _pickupAddress : '100 MG Road, Bengaluru',
        dropLat: _dropLat,
        dropLng: _dropLng,
        dropAddress: _dropAddress.isNotEmpty ? _dropAddress : '200 Brigade Road, Bengaluru',
        packageType: _packageType,
        packageWeightKg: _packageWeightKg,
        fragile: _fragile,
        paymentMethod: 'UPI',
      );
      if (!mounted) return;
      // Show success and go to tracking
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Order ${res['order']['code']} created!'),
          backgroundColor: Colors.green,
        ),
      );
      context.go('/tracking');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to create order: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _loadingQuote = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Book Parcel')),
      body: Column(
        children: [
          // Stepper
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: Colors.white,
            child: Row(
              children: List.generate(_steps.length * 2 - 1, (i) {
                if (i.isOdd) {
                  final done = i ~/ 2 < _step;
                  return Expanded(
                    child: Container(
                      height: 2,
                      color: done ? const Color(0xFF2563EB) : const Color(0xFFE2E8F0),
                    ),
                  );
                }
                final idx = i ~/ 2;
                final active = idx == _step;
                final done = idx < _step;
                return Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: done || active ? const Color(0xFF2563EB) : const Color(0xFFE2E8F0),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: done
                        ? const Icon(Icons.check, color: Colors.white, size: 16)
                        : Text(
                            '${idx + 1}',
                            style: TextStyle(
                              color: active ? Colors.white : Colors.grey.shade600,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                  ),
                );
              }),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: _buildStep(),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  if (_step > 0)
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => setState(() => _step--),
                        child: const Text('Back'),
                      ),
                    ),
                  if (_step > 0) const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: () async {
                        if (_step < _steps.length - 1) {
                          // If moving to fare step, fetch quote
                          if (_step == 3) {
                            await _fetchQuote();
                          }
                          setState(() => _step++);
                        } else {
                          // Final step — create the order
                          await _createOrder();
                        }
                      },
                      child: _loadingQuote
                          ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : Text(_step == _steps.length - 1 ? 'Confirm & Pay' : 'Continue'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStep() {
    switch (_step) {
      case 0:
        return _AddressForm(
          title: 'Pickup location',
          hint: 'Enter pickup address',
          onChanged: (v) => setState(() => _pickupAddress = v),
          lat: _pickupLat,
          lng: _pickupLng,
        );
      case 1:
        return _AddressForm(
          title: 'Drop location',
          hint: 'Enter drop address',
          onChanged: (v) => setState(() => _dropAddress = v),
          lat: _dropLat,
          lng: _dropLng,
        );
      case 2:
        return _PackageForm(
          packageType: _packageType,
          weight: _packageWeightKg,
          fragile: _fragile,
          onTypeChanged: (v) => setState(() => _packageType = v),
          onWeightChanged: (v) => setState(() => _packageWeightKg = v),
          onFragileChanged: (v) => setState(() => _fragile = v),
        );
      case 3:
        return _VehicleForm(
          vehicleType: _vehicleType,
          onChanged: (v) => setState(() => _vehicleType = v),
        );
      case 4:
        return _FareSummary(
          quote: _quote,
          loading: _loadingQuote,
          error: _quoteError,
          onRetry: _fetchQuote,
        );
      default:
        return _ConfirmSummary(
          quote: _quote,
          vehicleType: _vehicleType,
          packageType: _packageType,
          pickupAddress: _pickupAddress.isNotEmpty ? _pickupAddress : '100 MG Road, Bengaluru',
          dropAddress: _dropAddress.isNotEmpty ? _dropAddress : '200 Brigade Road, Bengaluru',
        );
    }
  }
}

class _AddressForm extends StatelessWidget {
  final String title;
  final String hint;
  final ValueChanged<String> onChanged;
  final double lat;
  final double lng;
  const _AddressForm({required this.title, required this.hint, required this.onChanged, required this.lat, required this.lng});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        const Text('Search for an address or use current location.',
            style: TextStyle(color: Colors.grey, fontSize: 13)),
        const SizedBox(height: 20),
        TextField(
          decoration: InputDecoration(
            labelText: title,
            hintText: hint,
            prefixIcon: const Icon(Icons.search),
          ),
          onChanged: onChanged,
        ),
        const SizedBox(height: 12),
        ListTile(
          leading: const CircleAvatar(child: Icon(Icons.my_location, size: 18)),
          title: const Text('Use current location'),
          subtitle: Text('Lat: ${lat.toStringAsFixed(4)}, Lng: ${lng.toStringAsFixed(4)}'),
          onTap: () => onChanged('Current location ($lat, $lng)'),
        ),
      ],
    );
  }
}

class _PackageForm extends StatelessWidget {
  final String packageType;
  final double weight;
  final bool fragile;
  final ValueChanged<String> onTypeChanged;
  final ValueChanged<double> onWeightChanged;
  final ValueChanged<bool> onFragileChanged;
  const _PackageForm({
    required this.packageType,
    required this.weight,
    required this.fragile,
    required this.onTypeChanged,
    required this.onWeightChanged,
    required this.onFragileChanged,
  });

  @override
  Widget build(BuildContext context) {
    final types = [
      ('DOCUMENT', 'Document', Icons.description),
      ('SMALL_PARCEL', 'Small Parcel', Icons.inventory_2),
      ('MEDIUM_PARCEL', 'Medium Parcel', Icons.inventory),
      ('LARGE_PARCEL', 'Large Parcel', Icons.all_inbox),
      ('FOOD', 'Food', Icons.restaurant),
      ('OTHER', 'Other', Icons.more_horiz),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Package details', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
        const SizedBox(height: 16),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: types.map((t) {
            final selected = packageType == t.$1;
            return GestureDetector(
              onTap: () => onTypeChanged(t.$1),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: selected ? const Color(0xFF2563EB) : Colors.white,
                  border: Border.all(
                    color: selected ? const Color(0xFF2563EB) : const Color(0xFFE2E8F0),
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(t.$3, size: 18, color: selected ? Colors.white : Colors.grey.shade700),
                    const SizedBox(width: 8),
                    Text(t.$2, style: TextStyle(color: selected ? Colors.white : Colors.black87, fontSize: 13, fontWeight: FontWeight.w500)),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 20),
        TextField(
          decoration: const InputDecoration(labelText: 'Approximate weight (kg)'),
          keyboardType: TextInputType.number,
          onChanged: (v) => onWeightChanged(double.tryParse(v) ?? 0),
        ),
        const SizedBox(height: 12),
        SwitchListTile(
          title: const Text('Fragile package'),
          subtitle: const Text('Mark if the package contains breakable items'),
          value: fragile,
          onChanged: onFragileChanged,
          activeColor: const Color(0xFF2563EB),
        ),
      ],
    );
  }
}

class _VehicleForm extends StatelessWidget {
  final String vehicleType;
  final ValueChanged<String> onChanged;
  const _VehicleForm({required this.vehicleType, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    // Static list — in production this would come from /api/public/services
    final vehicles = [
      ('BIKE', 'Bike', Icons.two_wheeler, 'Up to 10 kg'),
      ('SCOOTER', 'Scooter', Icons.bike_scooter, 'Up to 15 kg'),
      ('AUTO', 'Auto', Icons.directions_car, 'Up to 100 kg'),
      ('MINI_TRUCK', 'Mini Truck', Icons.local_shipping, 'Up to 500 kg'),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Choose vehicle', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
        const SizedBox(height: 16),
        ...vehicles.map((v) {
          final selected = vehicleType == v.$1;
          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            decoration: BoxDecoration(
              border: Border.all(
                color: selected ? const Color(0xFF2563EB) : const Color(0xFFE2E8F0),
                width: selected ? 1.5 : 1,
              ),
              borderRadius: BorderRadius.circular(12),
              color: selected ? const Color(0xFF2563EB).withValues(alpha: 0.04) : Colors.white,
            ),
            child: RadioListTile<String>(
              value: v.$1,
              groupValue: vehicleType,
              onChanged: (val) => onChanged(val ?? v.$1),
              activeColor: const Color(0xFF2563EB),
              title: Row(
                children: [
                  Icon(v.$3, color: Colors.grey.shade700),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(v.$2, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                        Text(v.$4, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }
}

class _FareSummary extends StatelessWidget {
  final Map<String, dynamic>? quote;
  final bool loading;
  final String? error;
  final VoidCallback onRetry;
  const _FareSummary({required this.quote, required this.loading, required this.error, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Center(child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 12),
          Text('Calculating fare...'),
        ],
      ));
    }
    if (error != null) {
      return Center(child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, color: Colors.red.shade700, size: 40),
          const SizedBox(height: 8),
          Text('Failed to fetch fare', style: TextStyle(color: Colors.red.shade900, fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text(error!, style: const TextStyle(fontSize: 12, color: Colors.grey), textAlign: TextAlign.center),
          const SizedBox(height: 16),
          OutlinedButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ));
    }
    if (quote == null) {
      return const Center(child: Text('No quote available'));
    }
    final q = quote!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Fare estimate', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
        const SizedBox(height: 4),
        Text(
          'Quote ID: ${q['quoteId']}',
          style: const TextStyle(fontSize: 10, color: Colors.grey, fontFamily: 'monospace'),
        ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _row('Distance', '${(q['distanceKm'] as num).toStringAsFixed(1)} km'),
                _row('Estimated time', '${q['estimatedMinutes']} min'),
                _row('Base fare', '₹${q['baseFare']}'),
                _row('Distance fare', '₹${q['distanceFare']}'),
                _row('Time fare', '₹${q['timeFare']}'),
                _row('Platform fee', '₹${q['platformFee']}'),
                _row('Tax', '₹${q['taxAmount']}'),
                if ((q['surgeFee'] as num?)?.toInt() != 0)
                  _row('Surge', '₹${q['surgeFee']}', color: Colors.red),
                if ((q['discountAmount'] as num?)?.toInt() != 0)
                  _row('Discount', '-₹${q['discountAmount']}', color: Colors.green),
                const Divider(),
                _row('Total', '₹${q['totalAmount']}', bold: true),
              ],
            ),
          ),
        ).animate().fadeIn().slideY(begin: 0.1, end: 0),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.amber.shade50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.amber.shade200),
          ),
          child: Row(
            children: [
              Icon(Icons.schedule, color: Colors.amber.shade700, size: 18),
              const SizedBox(width: 8),
              const Expanded(
                child: Text('Quote expires in 10 minutes', style: TextStyle(fontSize: 12, color: Colors.black87)),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _row(String label, String value, {bool bold = false, Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 13, color: bold ? Colors.black : Colors.grey.shade700, fontWeight: bold ? FontWeight.w700 : FontWeight.normal)),
          Text(value, style: TextStyle(fontSize: 14, fontWeight: bold ? FontWeight.w700 : FontWeight.w500, color: color)),
        ],
      ),
    );
  }
}

class _ConfirmSummary extends StatelessWidget {
  final Map<String, dynamic>? quote;
  final String vehicleType;
  final String packageType;
  final String pickupAddress;
  final String dropAddress;
  const _ConfirmSummary({
    required this.quote,
    required this.vehicleType,
    required this.packageType,
    required this.pickupAddress,
    required this.dropAddress,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Order summary', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _kv('Service', 'Parcel Delivery'),
                _kv('Vehicle', vehicleType.replaceAll('_', ' ')),
                _kv('Package', packageType.replaceAll('_', ' ')),
                _kv('Pickup', pickupAddress),
                _kv('Drop', dropAddress),
                _kv('Payment', 'UPI'),
                if (quote != null)
                  _kv('Total', '₹${quote!['totalAmount']}', bold: true),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        const Text(
          'By confirming, you agree to the fare above. A delivery partner will be assigned shortly.',
          style: TextStyle(fontSize: 12, color: Colors.grey),
        ),
      ],
    );
  }

  Widget _kv(String k, String v, {bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(k, style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              v,
              style: TextStyle(fontWeight: bold ? FontWeight.w700 : FontWeight.w600, fontSize: 13),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }
}
