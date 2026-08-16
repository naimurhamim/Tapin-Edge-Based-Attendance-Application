import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'dart:convert';
import 'dart:async';
import '../../../core/theme/app_theme.dart';

class TeacherQrAttendanceScreen extends StatefulWidget {
  final List<String> subjectIds;
  const TeacherQrAttendanceScreen({super.key, required this.subjectIds});

  @override
  State<TeacherQrAttendanceScreen> createState() =>
      _TeacherQrAttendanceScreenState();
}

class _TeacherQrAttendanceScreenState extends State<TeacherQrAttendanceScreen> {
  bool _isLoading = true;
  bool _isFinishing = false;
  List<Map<String, dynamic>> _subjects = [];
  String? _selectedSubjectId;
  String _qrPayload = '';

  Timer? _pollingTimer;
  List<Map<String, dynamic>> _presentLogs = [];
  bool _isPolling = false;
  String _debugError = '';

  @override
  void initState() {
    super.initState();
    _loadSubjects();
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadSubjects() async {
    if (widget.subjectIds.isEmpty) {
      setState(() => _isLoading = false);
      return;
    }
    try {
      final res = await Supabase.instance.client
          .from('subjects')
          .select()
          .inFilter('id', widget.subjectIds);

      setState(() {
        _subjects = List<Map<String, dynamic>>.from(res);
        if (_subjects.isNotEmpty) {
          _selectedSubjectId = _subjects.first['id'];
          _generateQrAndListen();
        }
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  void _generateQrAndListen() {
    if (_selectedSubjectId == null) return;

    final today = DateTime.now().toIso8601String().split('T')[0];
    final teacherId = Supabase.instance.client.auth.currentUser!.id;

    // Create the JSON payload that students will scan
    final payloadMap = {
      'subject_id': _selectedSubjectId,
      'date': today,
      'teacher_id': teacherId,
    };

    setState(() {
      _qrPayload = jsonEncode(payloadMap);
      _presentLogs = [];
    });

    // Start polling attendance logs
    _pollingTimer?.cancel();
    _pollAttendance();
    _pollingTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      _pollAttendance();
    });
  }

  Future<void> _pollAttendance() async {
    if (_selectedSubjectId == null || _isPolling) return;
    _isPolling = true;

    try {
      final today = DateTime.now().toIso8601String().split('T')[0];
      final teacherId = Supabase.instance.client.auth.currentUser!.id;

      final res = await Supabase.instance.client
          .from('attendance_logs')
          .select(
            'id, student_id, entry_time, users!attendance_logs_student_id_fkey(name, university_id)',
          )
          .eq('subject_id', _selectedSubjectId!)
          .eq('date', today)
          .eq('status', 'present')
          .eq('marked_by', teacherId)
          .order('entry_time', ascending: false);

      if (mounted) {
        setState(() {
          _presentLogs = List<Map<String, dynamic>>.from(res);
          _debugError = '';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _debugError = 'Poll error: $e';
        });
      }
    } finally {
      _isPolling = false;
    }
  }

  Future<void> _finishAttendance() async {
    if (_selectedSubjectId == null) return;

    setState(() => _isFinishing = true);
    _pollingTimer?.cancel();

    try {
      final today = DateTime.now().toIso8601String().split('T')[0];
      final subject = _subjects.firstWhere(
        (s) => s['id'] == _selectedSubjectId,
      );

      // Get all students enrolled in this subject's dept and section
      final students = await Supabase.instance.client
          .from('users')
          .select()
          .eq('role', 'student')
          .eq('department', subject['department'])
          .eq('section', subject['section']);

      // Get all current logs for today (including absent if any)
      final logs = await Supabase.instance.client
          .from('attendance_logs')
          .select()
          .eq('subject_id', _selectedSubjectId!)
          .eq('date', today);

      final loggedStudentIds = logs.map((l) => l['student_id']).toSet();
      final now = DateTime.now().toIso8601String();

      List<Map<String, dynamic>> toInsert = [];

      for (final student in students) {
        if (!loggedStudentIds.contains(student['id'])) {
          toInsert.add({
            'student_id': student['id'],
            'subject_id': _selectedSubjectId,
            'date': today,
            'status': 'absent',
            'entry_time': now,
          });
        }
      }

      if (toInsert.isNotEmpty) {
        await Supabase.instance.client.from('attendance_logs').insert(toInsert);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Attendance Session Finished!'),
            backgroundColor: AppTheme.success,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error finishing: $e'),
            backgroundColor: AppTheme.error,
          ),
        );
        setState(() => _isFinishing = false);
      }
    }
  }

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
          'QR Attendance',
          style: TextStyle(color: textColor, fontWeight: FontWeight.bold),
        ),
      ),
      body: _subjects.isEmpty && !_isLoading
          ? Center(
              child: Text(
                'No courses assigned.',
                style: TextStyle(color: subTextColor),
              ),
            )
          : Column(
              children: [
                if (_subjects.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: cardColor,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: borderColor),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _selectedSubjectId,
                          isExpanded: true,
                          dropdownColor: cardColor,
                          icon: Icon(
                            Icons.keyboard_arrow_down,
                            color: subTextColor,
                          ),
                          items: _subjects.map((s) {
                            return DropdownMenuItem<String>(
                              value: s['id'],
                              child: Text(
                                '${s['name']} (${s['code']})',
                                style: TextStyle(
                                  color: textColor,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            );
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) {
                              setState(() => _selectedSubjectId = val);
                              _generateQrAndListen();
                            }
                          },
                        ),
                      ),
                    ),
                  ),

                if (_qrPayload.isNotEmpty)
                  Expanded(
                    child: Column(
                      children: [
                        const SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors
                                .white, // QR codes usually look best on white backgrounds
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 20,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: QrImageView(
                            data: _qrPayload,
                            version: QrVersions.auto,
                            size: 250.0,
                            eyeStyle: const QrEyeStyle(
                              eyeShape: QrEyeShape.square,
                              color: Colors.black,
                            ),
                            dataModuleStyle: const QrDataModuleStyle(
                              dataModuleShape: QrDataModuleShape.square,
                              color: Colors.black,
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          'Ask students to scan this QR Code',
                          style: TextStyle(
                            color: subTextColor,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 24),

                        Expanded(
                          child: Container(
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: cardColor,
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(30),
                                topRight: Radius.circular(30),
                              ),
                              border: Border.all(color: borderColor),
                            ),
                            child: Column(
                              children: [
                                const SizedBox(height: 12),
                                Container(
                                  width: 40,
                                  height: 4,
                                  decoration: BoxDecoration(
                                    color: borderColor,
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                ),
                                const SizedBox(height: 20),
                                Text(
                                  'Recently Scanned Students (${_presentLogs.length})',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: textColor,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Expanded(
                                  child: _presentLogs.isEmpty
                                      ? Center(
                                          child: Text(
                                            _debugError.isNotEmpty
                                                ? _debugError
                                                : (_isPolling
                                                      ? 'Listening for scans...'
                                                      : 'No scans yet. Waiting for students...'),
                                            style: TextStyle(
                                              color: _debugError.isNotEmpty
                                                  ? AppTheme.error
                                                  : subTextColor,
                                            ),
                                            textAlign: TextAlign.center,
                                          ),
                                        )
                                      : ListView.builder(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 20,
                                            vertical: 8,
                                          ),
                                          itemCount: _presentLogs.length,
                                          itemBuilder: (context, index) {
                                            final log = _presentLogs[index];
                                            // Data is already joined from the select('*, users(name, university_id)') query
                                            final user =
                                                log['users']
                                                    as Map<String, dynamic>?;
                                            final name =
                                                user?['name'] ??
                                                log['student_id'] ??
                                                'Unknown';
                                            final uId =
                                                user?['university_id'] ?? '';

                                            return Container(
                                              margin: const EdgeInsets.only(
                                                bottom: 12,
                                              ),
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 16,
                                                    vertical: 12,
                                                  ),
                                              decoration: BoxDecoration(
                                                color: AppTheme.success
                                                    .withOpacity(0.1),
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                                border: Border.all(
                                                  color: AppTheme.success
                                                      .withOpacity(0.3),
                                                ),
                                              ),
                                              child: Row(
                                                children: [
                                                  const Icon(
                                                    Icons.check_circle,
                                                    color: AppTheme.success,
                                                  ),
                                                  const SizedBox(width: 12),
                                                  Expanded(
                                                    child: Column(
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment
                                                              .start,
                                                      children: [
                                                        Text(
                                                          name,
                                                          style: TextStyle(
                                                            fontWeight:
                                                                FontWeight.bold,
                                                            color: textColor,
                                                          ),
                                                        ),
                                                        if (uId.isNotEmpty)
                                                          Text(
                                                            uId,
                                                            style: TextStyle(
                                                              fontSize: 12,
                                                              color:
                                                                  subTextColor,
                                                            ),
                                                          ),
                                                      ],
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            );
                                          },
                                        ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
      floatingActionButton: _qrPayload.isNotEmpty
          ? FloatingActionButton.extended(
              onPressed: _isFinishing ? null : _finishAttendance,
              backgroundColor: AppTheme.primary,
              icon: _isFinishing
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Icon(Icons.stop_circle_outlined, color: Colors.white),
              label: Text(
                _isFinishing ? 'Finishing...' : 'Finish Attendance',
                style: const TextStyle(color: Colors.white),
              ),
            )
          : null,
    );
  }
}
