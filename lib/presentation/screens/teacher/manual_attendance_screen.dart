import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:convert';
import '../../../core/theme/app_theme.dart';

class TeacherManualAttendanceScreen extends StatefulWidget {
  final List<String> subjectIds;
  const TeacherManualAttendanceScreen({super.key, required this.subjectIds});

  @override
  State<TeacherManualAttendanceScreen> createState() =>
      _TeacherManualAttendanceScreenState();
}

class _TeacherManualAttendanceScreenState
    extends State<TeacherManualAttendanceScreen> {
  bool _isLoading = true;
  bool _isSaving = false;
  List<Map<String, dynamic>> _subjects = [];
  String? _selectedSubjectId;
  List<Map<String, dynamic>> _students = [];

  // Map of studentId -> status (true for present, false for absent)
  Map<String, bool> _attendanceState = {};

  @override
  void initState() {
    super.initState();
    _loadSubjects();
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
        }
      });
      if (_selectedSubjectId != null) {
        await _loadStudentsForSubject(_selectedSubjectId!);
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadStudentsForSubject(String subjectId) async {
    setState(() => _isLoading = true);
    try {
      final subject = _subjects.firstWhere((s) => s['id'] == subjectId);
      final dept = subject['department'];
      final section = subject['section'];

      // Fetch students in this dept and section
      final res = await Supabase.instance.client
          .from('users')
          .select()
          .eq('role', 'student')
          .eq('department', dept)
          .eq('section', section)
          .order('university_id');

      final today = DateTime.now().toIso8601String().split('T')[0];

      // Fetch existing logs for today to see if attendance was already taken
      final logsRes = await Supabase.instance.client
          .from('attendance_logs')
          .select()
          .eq('subject_id', subjectId)
          .eq('date', today);

      final existingLogs = List<Map<String, dynamic>>.from(logsRes);

      final studentsList = List<Map<String, dynamic>>.from(res);
      final Map<String, bool> newState = {};

      for (final s in studentsList) {
        final existing = existingLogs
            .where((l) => l['student_id'] == s['id'])
            .toList();
        if (existing.isNotEmpty) {
          newState[s['id']] = existing.first['status'] == 'present';
        } else {
          // Default to present for manual attendance
          newState[s['id']] = true;
        }
      }

      setState(() {
        _students = studentsList;
        _attendanceState = newState;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveAttendance() async {
    if (_selectedSubjectId == null || _students.isEmpty) return;

    setState(() => _isSaving = true);
    try {
      final today = DateTime.now().toIso8601String().split('T')[0];
      final now = DateTime.now().toIso8601String();

      final teacherId = Supabase.instance.client.auth.currentUser!.id;

      final List<Map<String, dynamic>> records = [];
      for (final s in _students) {
        final isPresent = _attendanceState[s['id']] ?? false;
        records.add({
          'student_id': s['id'],
          'subject_id': _selectedSubjectId,
          'date': today,
          'status': isPresent ? 'present' : 'absent',
          'entry_time': now,
          'marked_by': teacherId,
        });
      }

      // Upsert the records (requires unique constraint on student_id, subject_id, date)
      // In Supabase, if we don't have a unique constraint, we might need to delete old ones first.
      await Supabase.instance.client
          .from('attendance_logs')
          .delete()
          .eq('subject_id', _selectedSubjectId!)
          .eq('date', today)
          .inFilter('student_id', _students.map((e) => e['id']).toList());

      await Supabase.instance.client.from('attendance_logs').insert(records);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Attendance saved successfully'),
            backgroundColor: AppTheme.success,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save attendance: $e'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
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
          'Manual Attendance',
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
                              _loadStudentsForSubject(val);
                            }
                          },
                        ),
                      ),
                    ),
                  ),
                Expanded(
                  child: _isLoading
                      ? const Center(
                          child: CircularProgressIndicator(
                            color: AppTheme.primary,
                          ),
                        )
                      : _students.isEmpty
                      ? Center(
                          child: Text(
                            'No students found for this course.',
                            style: TextStyle(color: subTextColor),
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 8,
                          ),
                          itemCount: _students.length,
                          itemBuilder: (context, index) {
                            final student = _students[index];
                            final isPresent =
                                _attendanceState[student['id']] ?? true;

                            return Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                              decoration: BoxDecoration(
                                color: cardColor,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: isPresent
                                      ? AppTheme.success.withOpacity(0.3)
                                      : AppTheme.error.withOpacity(0.3),
                                  width: 1.5,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          student['name'] ?? 'Unknown',
                                          style: TextStyle(
                                            color: textColor,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          student['university_id'] ?? '',
                                          style: TextStyle(
                                            color: subTextColor,
                                            fontSize: 13,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Row(
                                    children: [
                                      IconButton(
                                        onPressed: () {
                                          setState(
                                            () =>
                                                _attendanceState[student['id']] =
                                                    false,
                                          );
                                        },
                                        icon: Icon(
                                          Icons.close,
                                          color: !isPresent
                                              ? AppTheme.error
                                              : subTextColor.withOpacity(0.3),
                                        ),
                                        style: IconButton.styleFrom(
                                          backgroundColor: !isPresent
                                              ? AppTheme.error.withOpacity(0.1)
                                              : Colors.transparent,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      IconButton(
                                        onPressed: () {
                                          setState(
                                            () =>
                                                _attendanceState[student['id']] =
                                                    true,
                                          );
                                        },
                                        icon: Icon(
                                          Icons.check,
                                          color: isPresent
                                              ? AppTheme.success
                                              : subTextColor.withOpacity(0.3),
                                        ),
                                        style: IconButton.styleFrom(
                                          backgroundColor: isPresent
                                              ? AppTheme.success.withOpacity(
                                                  0.1,
                                                )
                                              : Colors.transparent,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                ),
                if (_students.isNotEmpty && !_isLoading)
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: cardColor,
                      border: Border(top: BorderSide(color: borderColor)),
                    ),
                    child: SafeArea(
                      child: ElevatedButton(
                        onPressed: _isSaving ? null : _saveAttendance,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primary,
                          foregroundColor: Colors.white,
                          minimumSize: const Size(double.infinity, 56),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: _isSaving
                            ? const CircularProgressIndicator(
                                color: Colors.white,
                              )
                            : const Text(
                                'Save Attendance',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ),
                  ),
              ],
            ),
    );
  }
}
