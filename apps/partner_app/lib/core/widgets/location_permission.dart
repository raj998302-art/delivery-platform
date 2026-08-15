import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';

/// Location permission helper for partner app.
class LocationPermissionHelper {
  LocationPermissionHelper._();

  static Future<bool> ensurePermission(BuildContext context) async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      final opened = await _showServiceDisabledDialog(context);
      if (!opened) return false;
      return await ensurePermission(context);
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.whileInUse || permission == LocationPermission.always) {
      return true;
    }

    final shouldRequest = await _showPermissionExplanationDialog(context);
    if (!shouldRequest) return false;

    permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.whileInUse || permission == LocationPermission.always) {
      return true;
    }

    if (permission == LocationPermission.deniedForever) {
      await _showPermanentlyDeniedDialog(context);
      return false;
    }

    return false;
  }

  static Future<Position?> getCurrentLocation(BuildContext context) async {
    final granted = await ensurePermission(context);
    if (!granted) return null;
    try {
      return await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
    } catch (_) {
      return null;
    }
  }

  static Future<bool> _showPermissionExplanationDialog(BuildContext context) async {
    return await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            contentPadding: const EdgeInsets.all(24),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [Color(0xFF0F766E), Color(0xFF14B8A6)]),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Icon(Icons.location_on, color: Colors.white, size: 36),
                ),
                const SizedBox(height: 20),
                const Text('Enable Location', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                const Text(
                  'We need your location to:\n'
                  '• Receive nearby delivery requests\n'
                  '• Navigate to pickup & drop\n'
                  '• Track your live location during delivery',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 13, color: Color(0xFF64748B), height: 1.5),
                ),
              ],
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Not now', style: TextStyle(color: Color(0xFF94A3B8)))),
              ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Allow')),
            ],
          ),
        ) ??
        false;
  }

  static Future<bool> _showServiceDisabledDialog(BuildContext context) async {
    return await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: const Row(children: [Icon(Icons.location_disabled, color: Color(0xFFEF4444)), SizedBox(width: 12), Text('Location Off', style: TextStyle(fontSize: 18))]),
            content: const Text('Your device location service is disabled. Please enable it to receive delivery requests.', style: TextStyle(fontSize: 13, color: Color(0xFF64748B))),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
              ElevatedButton(
                onPressed: () async { await Geolocator.openLocationSettings(); if (ctx.mounted) Navigator.pop(ctx, true); },
                child: const Text('Open Settings'),
              ),
            ],
          ),
        ) ??
        false;
  }

  static Future<void> _showPermanentlyDeniedDialog(BuildContext context) async {
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(children: [Icon(Icons.privacy_tip, color: Color(0xFF0F766E)), SizedBox(width: 12), Text('Permission Required', style: TextStyle(fontSize: 18))]),
        content: const Text('Location permission was permanently denied. Please enable it from app settings to receive delivery requests.', style: TextStyle(fontSize: 13, color: Color(0xFF64748B))),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(onPressed: () { openAppSettings(); Navigator.pop(ctx); }, child: const Text('Open Settings')),
        ],
      ),
    );
  }
}
