import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:geolocator/geolocator.dart';
import '../../../core/theme/app_theme.dart';

class GeofenceSettingsScreen extends StatefulWidget {
  const GeofenceSettingsScreen({super.key});

  @override
  State<GeofenceSettingsScreen> createState() => _GeofenceSettingsScreenState();
}

class _GeofenceSettingsScreenState extends State<GeofenceSettingsScreen> {
  final _latController = TextEditingController();
  final _lonController = TextEditingController();
  bool _isEnabled = true;
  double _radius = 200;
  bool _isLoading = true;
  bool _isSaving = false;
  bool _isDetecting = false;
  bool _hasExistingRow = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  @override
  void dispose() {
    _latController.dispose();
    _lonController.dispose();
    super.dispose();
  }

  // ─── Load current settings from Supabase ──────────────────
  Future<void> _loadSettings() async {
    setState(() => _isLoading = true);
    try {
      final res = await Supabase.instance.client
          .from('app_settings')
          .select()
          .eq('id', 1)
          .maybeSingle();

      if (res != null) {
        _hasExistingRow = true;
        _latController.text = (res['campus_latitude'] ?? '').toString();
        _lonController.text = (res['campus_longitude'] ?? '').toString();
        _radius = ((res['geofence_radius_meters'] ?? 200) as num).toDouble();
        _isEnabled = res['geofence_enabled'] ?? true;
      }
    } catch (e) {
      // Table might not exist yet — we'll create row on save
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ─── Auto-detect GPS location ──────────────────────────────
  Future<void> _detectLocation() async {
    setState(() => _isDetecting = true);
    try {
      // Check permission
      LocationPermission perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
        if (perm == LocationPermission.denied) {
          throw Exception('Location permission denied.');
        }
      }
      if (perm == LocationPermission.deniedForever) {
        throw Exception(
          'Location permanently denied. Please enable in settings.',
        );
      }

      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 15),
        ),
      );

      _latController.text = pos.latitude.toStringAsFixed(6);
      _lonController.text = pos.longitude.toStringAsFixed(6);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '📍 Location detected: ${pos.latitude.toStringAsFixed(4)}, ${pos.longitude.toStringAsFixed(4)}',
            ),
            backgroundColor: AppTheme.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppTheme.error),
        );
      }
    } finally {
      if (mounted) setState(() => _isDetecting = false);
    }
  }

  // ─── Save settings to Supabase ────────────────────────────
  Future<void> _saveSettings() async {
    final latStr = _latController.text.trim();
    final lonStr = _lonController.text.trim();

    if (latStr.isEmpty || lonStr.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter latitude and longitude.'),
          backgroundColor: AppTheme.error,
        ),
      );
      return;
    }

    final lat = double.tryParse(latStr);
    final lon = double.tryParse(lonStr);

    if (lat == null ||
        lon == null ||
        lat < -90 ||
        lat > 90 ||
        lon < -180 ||
        lon > 180) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Invalid coordinates. Latitude: -90 to 90, Longitude: -180 to 180.',
          ),
          backgroundColor: AppTheme.error,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);
    try {
      final data = {
        'id': 1,
        'campus_latitude': lat,
        'campus_longitude': lon,
        'geofence_radius_meters': _radius.round(),
        'geofence_enabled': _isEnabled,
      };

      if (_hasExistingRow) {
        await Supabase.instance.client
            .from('app_settings')
            .update(data)
            .eq('id', 1);
      } else {
        await Supabase.instance.client.from('app_settings').insert(data);
        _hasExistingRow = true;
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✓ Geofence settings saved!'),
            backgroundColor: AppTheme.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Save error: $e'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  // ─── Build ─────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppTheme.darkBg : AppTheme.lightBg;
    final textColor = isDark ? AppTheme.darkText : AppTheme.lightText;
    final subTextColor = isDark
        ? AppTheme.darkTextSecondary
        : AppTheme.lightTextSecondary;
    final cardColor = isDark ? AppTheme.darkCard : AppTheme.lightSurface;
    final borderColor = isDark ? AppTheme.darkBorder : AppTheme.lightBorder;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        elevation: 0,
        iconTheme: IconThemeData(color: textColor),
        title: Text(
          'Geofence Settings',
          style: TextStyle(color: textColor, fontWeight: FontWeight.bold),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.primary),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Info card ────────────────────────────
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: AppTheme.primary.withValues(alpha: 0.25),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.info_outline, color: AppTheme.primary),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Students can only mark attendance when they are within the defined campus area. Disable to allow attendance from anywhere (for testing).',
                            style: TextStyle(color: textColor, fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // ── Enable toggle ─────────────────────────
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: cardColor,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: borderColor),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.location_on_outlined,
                          color: _isEnabled ? AppTheme.success : subTextColor,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Enable Geofencing',
                                style: TextStyle(
                                  color: textColor,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                _isEnabled
                                    ? 'Students must be on campus to mark attendance'
                                    : 'Anyone can mark attendance from anywhere',
                                style: TextStyle(
                                  color: subTextColor,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Switch(
                          value: _isEnabled,
                          onChanged: (v) => setState(() => _isEnabled = v),
                          activeColor: AppTheme.success,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // ── Coordinates section ───────────────────
                  Text(
                    'Campus Location',
                    style: TextStyle(
                      color: textColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Set the center point of the attendance zone.',
                    style: TextStyle(color: subTextColor, fontSize: 13),
                  ),
                  const SizedBox(height: 12),

                  // Auto-detect button
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _isDetecting ? null : _detectLocation,
                      icon: _isDetecting
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.my_location, size: 18),
                      label: Text(
                        _isDetecting
                            ? 'Detecting GPS...'
                            : '📍 Use My Current Location (Auto-fill)',
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.primary,
                        side: BorderSide(color: AppTheme.primary),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Manual input
                  Row(
                    children: [
                      Expanded(
                        child: _inputField(
                          controller: _latController,
                          label: 'Latitude',
                          hint: 'e.g. 23.8103',
                          textColor: textColor,
                          cardColor: cardColor,
                          borderColor: borderColor,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _inputField(
                          controller: _lonController,
                          label: 'Longitude',
                          hint: 'e.g. 90.4125',
                          textColor: textColor,
                          cardColor: cardColor,
                          borderColor: borderColor,
                        ),
                      ),
                    ],
                  ),

                  // Google Maps tip
                  const SizedBox(height: 8),
                  Text(
                    '💡 Tip: Open Google Maps → Long press on campus location → Copy the coordinates shown.',
                    style: TextStyle(color: subTextColor, fontSize: 11),
                  ),
                  const SizedBox(height: 20),

                  // ── Radius section ───────────────────────
                  Text(
                    'Geofence Radius',
                    style: TextStyle(
                      color: textColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Students must be within this distance from campus center.',
                    style: TextStyle(color: subTextColor, fontSize: 13),
                  ),
                  const SizedBox(height: 12),

                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: cardColor,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: borderColor),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '50 m',
                              style: TextStyle(
                                color: subTextColor,
                                fontSize: 12,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: AppTheme.primary.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                '${_radius.round()} meters',
                                style: const TextStyle(
                                  color: AppTheme.primary,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                ),
                              ),
                            ),
                            Text(
                              '500 m',
                              style: TextStyle(
                                color: subTextColor,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                        Slider(
                          value: _radius,
                          min: 50,
                          max: 500,
                          divisions: 45,
                          activeColor: AppTheme.primary,
                          inactiveColor: AppTheme.primary.withValues(
                            alpha: 0.2,
                          ),
                          onChanged: (v) => setState(() => _radius = v),
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _radiusPreset('100m', 100),
                            _radiusPreset('200m', 200),
                            _radiusPreset('300m', 300),
                            _radiusPreset('500m', 500),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 28),

                  // ── Save button ──────────────────────────
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _isSaving ? null : _saveSettings,
                      icon: _isSaving
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Icon(
                              Icons.save_outlined,
                              color: Colors.white,
                            ),
                      label: Text(
                        _isSaving ? 'Saving...' : 'Save Settings',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primary,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        elevation: 0,
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _inputField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required Color textColor,
    required Color cardColor,
    required Color borderColor,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: textColor,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(
            decimal: true,
            signed: true,
          ),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[-0-9.]')),
          ],
          style: TextStyle(color: textColor),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: textColor.withValues(alpha: 0.4)),
            filled: true,
            fillColor: cardColor,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: borderColor),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: borderColor),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppTheme.primary, width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 12,
            ),
          ),
        ),
      ],
    );
  }

  Widget _radiusPreset(String label, double value) {
    final isActive = _radius == value;
    return GestureDetector(
      onTap: () => setState(() => _radius = value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isActive
              ? AppTheme.primary
              : AppTheme.primary.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: AppTheme.primary.withValues(alpha: isActive ? 1.0 : 0.3),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isActive ? Colors.white : AppTheme.primary,
            fontWeight: FontWeight.w600,
            fontSize: 12,
          ),
        ),
      ),
    );
  }
}

// ─── Geofence Service — shared helper ─────────────────────────
class GeofenceService {
  /// Returns null if geofencing is disabled or not configured.
  /// Returns an error string if student is outside the geofence.
  /// Returns empty string '' if student is inside the geofence (OK).
  static Future<String?> checkLocation() async {
    try {
      // Load settings
      final res = await Supabase.instance.client
          .from('app_settings')
          .select()
          .eq('id', 1)
          .maybeSingle();

      if (res == null) return null; // No settings → skip check
      if (res['geofence_enabled'] != true) return null; // Disabled → skip

      final campusLat = (res['campus_latitude'] as num?)?.toDouble();
      final campusLon = (res['campus_longitude'] as num?)?.toDouble();
      final radius = ((res['geofence_radius_meters'] ?? 200) as num).toDouble();

      if (campusLat == null || campusLon == null) return null;

      // Check GPS permission
      LocationPermission perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
        if (perm == LocationPermission.denied) {
          return 'Location permission is required to mark attendance.';
        }
      }
      if (perm == LocationPermission.deniedForever) {
        return 'Location permission permanently denied. Please enable in phone settings.';
      }

      // Get position
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 15),
        ),
      );

      // Calculate distance using Haversine formula
      final dist = _haversineDistance(
        campusLat,
        campusLon,
        pos.latitude,
        pos.longitude,
      );

      if (dist > radius) {
        final distM = dist.round();
        return 'You are ${distM}m away from campus. Must be within ${radius.round()}m to mark attendance.';
      }

      return ''; // Inside geofence — OK
    } catch (e) {
      // If GPS fails (e.g. emulator), allow attendance with a note
      return null;
    }
  }

  static double _haversineDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const R = 6371000.0; // Earth radius in meters
    final dLat = _toRad(lat2 - lat1);
    final dLon = _toRad(lon2 - lon1);
    final a =
        sin(dLat / 2) * sin(dLat / 2) +
        cos(_toRad(lat1)) * cos(_toRad(lat2)) * sin(dLon / 2) * sin(dLon / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return R * c;
  }

  static double _toRad(double deg) => deg * pi / 180;
}
