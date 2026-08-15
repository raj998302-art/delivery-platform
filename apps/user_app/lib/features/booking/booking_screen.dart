import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class BookingScreen extends StatefulWidget {
  const BookingScreen({super.key});
  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  int _step = 0;
  String _vehicleType = 'BIKE';
  String _packageType = 'SMALL_PARCEL';

  final _steps = ['Pickup', 'Drop', 'Package', 'Vehicle', 'Fare', 'Confirm'];

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
          // Body
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: _buildStep(),
            ),
          ),
          // Footer
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
                      onPressed: () {
                        if (_step < _steps.length - 1) {
                          setState(() => _step++);
                        }
                      },
                      child: Text(_step == _steps.length - 1 ? 'Confirm & Pay' : 'Continue'),
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
        return _AddressForm(title: 'Pickup location', hint: 'Enter pickup address');
      case 1:
        return _AddressForm(title: 'Drop location', hint: 'Enter drop address');
      case 2:
        return _PackageForm(
          packageType: _packageType,
          onChanged: (v) => setState(() => _packageType = v),
        );
      case 3:
        return _VehicleForm(
          vehicleType: _vehicleType,
          onChanged: (v) => setState(() => _vehicleType = v),
        );
      case 4:
        return _FareSummary(vehicleType: _vehicleType);
      default:
        return _ConfirmSummary(
          vehicleType: _vehicleType,
          packageType: _packageType,
        );
    }
  }
}

class _AddressForm extends StatelessWidget {
  final String title;
  final String hint;
  const _AddressForm({required this.title, required this.hint});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        Text('Search for an address or use current location.',
            style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
        const SizedBox(height: 20),
        TextField(
          decoration: InputDecoration(
            labelText: title,
            hintText: hint,
            prefixIcon: const Icon(Icons.search),
          ),
        ),
        const SizedBox(height: 12),
        ListTile(
          leading: const CircleAvatar(child: Icon(Icons.my_location, size: 18)),
          title: const Text('Use current location'),
          subtitle: const Text('Bengaluru, India'),
          onTap: () {},
        ),
      ],
    );
  }
}

class _PackageForm extends StatelessWidget {
  final String packageType;
  final ValueChanged<String> onChanged;
  const _PackageForm({required this.packageType, required this.onChanged});

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
              onTap: () => onChanged(t.$1),
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
        ),
        const SizedBox(height: 12),
        TextField(
          decoration: const InputDecoration(labelText: 'Special instructions (optional)'),
          maxLines: 2,
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
    final vehicles = [
      ('BIKE', 'Bike', '₹89', 'Arrives in 5 min', 'Up to 10 kg', Icons.two_wheeler),
      ('SCOOTER', 'Scooter', '₹99', 'Arrives in 6 min', 'Up to 15 kg', Icons.bike_scooter),
      ('AUTO', 'Auto', '₹149', 'Arrives in 8 min', 'Up to 100 kg', Icons.directions_car),
      ('MINI_TRUCK', 'Mini Truck', '₹299', 'Arrives in 12 min', 'Up to 500 kg', Icons.local_shipping),
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
                  Icon(v.$6, color: Colors.grey.shade700),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(v.$2, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                        Text('${v.$4} · ${v.$5}', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                      ],
                    ),
                  ),
                  Text(v.$3, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
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
  final String vehicleType;
  const _FareSummary({required this.vehicleType});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Fare estimate', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _row('Distance', '8.4 km'),
                _row('Estimated time', '24 min'),
                _row('Base fare', '₹40'),
                _row('Distance fare', '₹84'),
                _row('Platform fee', '₹10'),
                _row('Tax (5%)', '₹5'),
                const Divider(),
                _row('Total', '₹139', bold: true),
              ],
            ),
          ),
        ).animate().fadeIn().slideY(begin: 0.1, end: 0),
        const SizedBox(height: 12),
        const Text('Quote expires in 10 minutes', style: TextStyle(fontSize: 12, color: Colors.grey)),
      ],
    );
  }

  Widget _row(String label, String value, {bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 13, color: bold ? Colors.black : Colors.grey.shade700, fontWeight: bold ? FontWeight.w700 : FontWeight.normal)),
          Text(value, style: TextStyle(fontSize: 14, fontWeight: bold ? FontWeight.w700 : FontWeight.w500)),
        ],
      ),
    );
  }
}

class _ConfirmSummary extends StatelessWidget {
  final String vehicleType;
  final String packageType;
  const _ConfirmSummary({required this.vehicleType, required this.packageType});

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
                _kv('Vehicle', vehicleType),
                _kv('Package', packageType.replaceAll('_', ' ')),
                _kv('Payment', 'UPI'),
                _kv('Total', '₹139'),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _kv(String k, String v) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(k, style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
          Text(v, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
        ],
      ),
    );
  }
}
