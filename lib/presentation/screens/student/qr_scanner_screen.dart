import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:convert';
import '../../../core/theme/app_theme.dart';
import '../admin/geofence_settings_screen.dart';

class QrScannerScreen extends StatefulWidget {
  const QrScannerScreen({super.key});

  @override
  State<QrScannerScreen> createState() => _QrScannerScreenState();
}

class _QrScannerScreenState extends State<QrScannerScreen> {
  final MobileScannerController controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.normal,
    facing: CameraFacing.back,
  );

  bool _isProcessing = false;
  String _statusMessage =
      'Scan the QR code shown by your teacher\nto mark your attendance.';
  bool _isSuccess = false;

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) async {
    if (_isProcessing) return;

    final List<Barcode> barcodes = capture.barcodes;
    if (barcodes.isEmpty) return;

    final barcode = barcodes.first;
    if (barcode.rawValue == null) return;

    setState(() {
      _isProcessing = true;
      _statusMessage = 'Processing...';
    });
    controller.stop();

    try {
      final String rawValue = barcode.rawValue!;

      // ─── Step 1: Validate QR Format ───────────────────────────
      Map<String, dynamic> data;
      try {
        data = Map<String, dynamic>.from(jsonDecode(rawValue));
      } catch (_) {
        throw Exception('Invalid QR Code. This is not a TapIn attendance QR.');
      }

      if (!data.containsKey('subject_id') ||
          !data.containsKey('date') ||
          !data.containsKey('teacher_id')) {
        throw Exception('Invalid QR Code. This is not a TapIn attendance QR.');
      }

      // ─── Step 2: Geofence check ────────────────────────────────
      setState(() => _statusMessage = 'Checking your location...');
      final geoResult = await GeofenceService.checkLocation();
      if (geoResult != null && geoResult.isNotEmpty) {
        // Outside geofence — block attendance
        throw Exception(geoResult);
      }

      final String subjectId = data['subject_id'].toString();
      final String date = data['date'].toString();
      final String teacherId = data['teacher_id'].toString();
      final String studentId = Supabase.instance.client.auth.currentUser!.id;
      final String now = DateTime.now().toIso8601String();

      // ─── Step 2: Check if already marked present ──────────────
      final existing = await Supabase.instance.client
          .from('attendance_logs')
          .select('id, status')
          .eq('student_id', studentId)
          .eq('subject_id', subjectId)
          .eq('date', date)
          .maybeSingle();

      if (existing != null && existing['status'] == 'present') {
        if (mounted) {
          setState(() {
            _isSuccess = true;
            _statusMessage =
                '✓ Attendance already marked!\nYou\'re good to go.';
          });
          await Future.delayed(const Duration(seconds: 2));
          if (mounted) Navigator.pop(context, false);
        }
        return;
      }

      // ─── Step 3: Upsert attendance record ────────────────────
      // Use upsert with onConflict to safely handle duplicates
      if (existing != null) {
        // Row exists but was 'absent' - update it
        await Supabase.instance.client
            .from('attendance_logs')
            .update({
              'status': 'present',
              'entry_time': now,
              'marked_by': teacherId,
            })
            .eq('id', existing['id']);
      } else {
        // New record
        await Supabase.instance.client.from('attendance_logs').insert({
          'student_id': studentId,
          'subject_id': subjectId,
          'date': date,
          'status': 'present',
          'entry_time': now,
          'marked_by': teacherId,
        });
      }

      // ─── Step 4: Success ─────────────────────────────────────
      if (mounted) {
        setState(() {
          _isSuccess = true;
          _statusMessage = '✓ Attendance marked successfully!';
        });
        await Future.delayed(const Duration(seconds: 2));
        if (mounted) Navigator.pop(context, true);
      }
    } catch (e) {
      // Show real error so we can diagnose issues, not a generic message
      final msg = e.toString().replaceAll('Exception:', '').trim();
      if (mounted) {
        setState(() {
          _isProcessing = false;
          _isSuccess = false;
          _statusMessage = msg;
        });

        await Future.delayed(const Duration(seconds: 3));
        if (mounted) {
          setState(() {
            _statusMessage =
                'Scan the QR code shown by your teacher\nto mark your attendance.';
          });
          controller.start();
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final Color overlayColor = _isSuccess
        ? AppTheme.success
        : _isProcessing
        ? AppTheme.primary
        : Colors.white;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan Attendance QR'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.white,
      ),
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          // Camera
          MobileScanner(controller: controller, onDetect: _onDetect),

          // Dark overlay
          Container(color: Colors.black.withOpacity(0.35)),

          // Scanner cutout (fake, purely visual)
          Center(
            child: Container(
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                border: Border.all(
                  color: _isSuccess ? AppTheme.success : AppTheme.primary,
                  width: 3,
                ),
                borderRadius: BorderRadius.circular(16),
                color: Colors.transparent,
              ),
            ),
          ),

          // UI Overlay
          SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 80),

                // Status message
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 14,
                    ),
                    decoration: BoxDecoration(
                      color: overlayColor.withOpacity(0.92),
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: Text(
                      _statusMessage,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: _isSuccess ? Colors.white : Colors.black87,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),

                const Spacer(),

                // Processing spinner
                if (_isProcessing)
                  Container(
                    margin: const EdgeInsets.only(bottom: 60),
                    child: const CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 3,
                    ),
                  )
                else
                  const SizedBox(height: 60),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
