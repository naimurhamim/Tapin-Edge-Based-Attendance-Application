import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import '../../../core/theme/app_theme.dart';
import '../auth/login_screen.dart';
import '../../../presentation/widgets/change_password_dialog.dart';
import 'teacher_leave_requests_screen.dart';
import 'manual_attendance_screen.dart';
import 'qr_attendance_screen.dart';
import 'student_attendance_details_screen.dart';
import 'attendance_report_screen.dart';

class TeacherHome extends StatefulWidget {
  final bool isDarkMode;
  final Function(bool) onThemeToggle;

  const TeacherHome({
    super.key,
    required this.isDarkMode,
    required this.onThemeToggle,
  });

  @override
  State<TeacherHome> createState() => _TeacherHomeState();
}

class _TeacherHomeState extends State<TeacherHome> {
  int _currentIndex = 0;
  Map<String, dynamic>? _userData;
  bool _isLoading = true;
  late RealtimeChannel _channel;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _setupRealtime();
  }

  void _setupRealtime() {
    final userId = Supabase.instance.client.auth.currentUser!.id;
    _channel = Supabase.instance.client
        .channel('public:users:teacher_$userId')
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'users',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'id',
            value: userId,
          ),
          callback: (payload) {
            _loadUserData();
          },
        )
        .subscribe();
  }

  @override
  void dispose() {
    Supabase.instance.client.removeChannel(_channel);
    super.dispose();
  }

  Future<void> _loadUserData() async {
    try {
      final userId = Supabase.instance.client.auth.currentUser!.id;
      final data = await Supabase.instance.client
          .from('users')
          .select()
          .eq('id', userId)
          .single();
      if (mounted) {
        setState(() {
          _userData = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppTheme.darkBg : AppTheme.lightBg;
    final navBg = isDark ? AppTheme.darkSurface : AppTheme.lightSurface;
    final borderColor = isDark ? AppTheme.darkBorder : AppTheme.lightBorder;

    if (_isLoading) {
      return Scaffold(
        backgroundColor: bg,
        body: const Center(
          child: CircularProgressIndicator(color: AppTheme.primary),
        ),
      );
    }

    final pages = [
      _DashboardTab(userData: _userData, isDarkMode: widget.isDarkMode),
      _StudentsTab(userData: _userData, isDarkMode: widget.isDarkMode),
      _CourseSelectionTab(userData: _userData, isDarkMode: widget.isDarkMode),
      _TeacherAttendanceTab(userData: _userData),
      _ProfileTab(
        userData: _userData,
        isDarkMode: widget.isDarkMode,
        onThemeToggle: widget.onThemeToggle,
      ),
    ];

    return Scaffold(
      backgroundColor: bg,
      body: pages[_currentIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: navBg,
          border: Border(top: BorderSide(color: borderColor)),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _navItem(
                  0,
                  Icons.dashboard_outlined,
                  Icons.dashboard,
                  'Dashboard',
                ),
                _navItem(1, Icons.people_outline, Icons.people, 'Students'),
                _navItem(
                  2,
                  Icons.library_add_outlined,
                  Icons.library_add,
                  'Courses',
                ),
                _navItem(
                  3,
                  Icons.fact_check_outlined,
                  Icons.fact_check,
                  'Attendance',
                ),
                _navItem(4, Icons.person_outline, Icons.person, 'Profile'),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _navItem(int index, IconData outline, IconData filled, String label) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isSelected = _currentIndex == index;
    final color = isSelected
        ? AppTheme.primary
        : (isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary);

    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _currentIndex = index),
        behavior: HitTestBehavior.opaque,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(isSelected ? filled : outline, color: color, size: 24),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontSize: 11,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------
// Dashboard Tab
// ---------------------------------------------------------
class _DashboardTab extends StatefulWidget {
  final Map<String, dynamic>? userData;
  final bool isDarkMode;

  const _DashboardTab({required this.userData, required this.isDarkMode});

  @override
  State<_DashboardTab> createState() => _DashboardTabState();
}

class _DashboardTabState extends State<_DashboardTab> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _todaySchedules = [];
  List<Map<String, dynamic>> _upcomingSchedules = [];
  int _pendingLeavesCount = 0;
  List<String> _selectedSubjectIds = [];

  @override
  void initState() {
    super.initState();
    _loadTodayClasses();
  }

  @override
  void didUpdateWidget(_DashboardTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.userData?['lab_group'] != oldWidget.userData?['lab_group']) {
      _loadTodayClasses();
    }
  }

  Future<void> _loadTodayClasses() async {
    setState(() => _isLoading = true);
    try {
      final labGroup = widget.userData?['lab_group'];
      List<String> selectedSubjectIds = [];
      if (labGroup != null && labGroup.toString().isNotEmpty) {
        try {
          selectedSubjectIds = List<String>.from(jsonDecode(labGroup));
        } catch (e) {
          selectedSubjectIds = [];
        }
      }

      if (selectedSubjectIds.isEmpty) {
        if (mounted) {
          setState(() {
            _todaySchedules = [];
            _upcomingSchedules = [];
            _pendingLeavesCount = 0;
            _selectedSubjectIds = [];
            _isLoading = false;
          });
        }
        return;
      }

      final res = await Supabase.instance.client
          .from('class_schedules')
          .select('*, subjects(*)')
          .inFilter('subject_id', selectedSubjectIds)
          .eq('is_active', true);

      final leavesRes = await Supabase.instance.client
          .from('leave_applications')
          .select('id')
          .inFilter('subject_id', selectedSubjectIds)
          .eq('status', 'pending');

      final currentDay = DateFormat('EEEE').format(DateTime.now());
      List<Map<String, dynamic>> today = [];
      List<Map<String, dynamic>> upcoming = [];

      for (var schedule in res) {
        if (schedule['day_name'] == currentDay) {
          today.add(schedule);
        } else {
          int daysLeft = _calculateDaysUntil(schedule['day_name'], currentDay);
          schedule['days_left'] = daysLeft;
          upcoming.add(schedule);
        }
      }

      today.sort((a, b) => a['start_time'].compareTo(b['start_time']));
      upcoming.sort(
        (a, b) => (a['days_left'] as int).compareTo(b['days_left'] as int),
      );

      if (mounted) {
        setState(() {
          _todaySchedules = today;
          _upcomingSchedules = upcoming;
          _pendingLeavesCount = leavesRes.length;
          _selectedSubjectIds = selectedSubjectIds;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  int _calculateDaysUntil(String targetDay, String currentDay) {
    const daysOfWeek = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];
    int currentIndex = daysOfWeek.indexOf(currentDay);
    int targetIndex = daysOfWeek.indexOf(targetDay);

    if (currentIndex == -1 || targetIndex == -1) return 0;

    int diff = targetIndex - currentIndex;
    if (diff <= 0) {
      diff += 7;
    }
    return diff;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? AppTheme.darkText : AppTheme.lightText;
    final subTextColor = isDark
        ? AppTheme.darkTextSecondary
        : AppTheme.lightTextSecondary;
    final cardColor = isDark ? AppTheme.darkCard : AppTheme.lightSurface;
    final borderColor = isDark ? AppTheme.darkBorder : AppTheme.lightBorder;

    final name = widget.userData?['name'] ?? 'Teacher';
    final currentDay = DateFormat('EEEE, MMM d').format(DateTime.now());

    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Welcome back,',
                  style: TextStyle(fontSize: 16, color: subTextColor),
                ),
                const SizedBox(height: 4),
                Text(
                  name,
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.calendar_today,
                        size: 16,
                        color: AppTheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        currentDay,
                        style: const TextStyle(
                          color: AppTheme.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            child: InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => TeacherLeaveRequestsScreen(
                      subjectIds: _selectedSubjectIds,
                    ),
                  ),
                ).then((_) => _loadTodayClasses());
              },
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _pendingLeavesCount > 0
                      ? AppTheme.warning.withOpacity(0.1)
                      : AppTheme.primary.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: _pendingLeavesCount > 0
                        ? AppTheme.warning.withOpacity(0.5)
                        : AppTheme.primary.withOpacity(0.2),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: _pendingLeavesCount > 0
                            ? AppTheme.warning.withOpacity(0.2)
                            : AppTheme.primary.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        _pendingLeavesCount > 0
                            ? Icons.assignment_late
                            : Icons.assignment,
                        color: _pendingLeavesCount > 0
                            ? AppTheme.warning
                            : AppTheme.primary,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Leave Requests',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: _pendingLeavesCount > 0
                                  ? AppTheme.warning
                                  : AppTheme.primary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _pendingLeavesCount > 0
                                ? 'You have $_pendingLeavesCount student leave requests pending review.'
                                : 'No pending leave requests.',
                            style: TextStyle(color: subTextColor, fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.chevron_right,
                      color: _pendingLeavesCount > 0
                          ? AppTheme.warning
                          : AppTheme.primary,
                    ),
                  ],
                ),
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              'Today\'s Classes',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
          ),
          const SizedBox(height: 16),

          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: AppTheme.primary),
                  )
                : _todaySchedules.isEmpty && _upcomingSchedules.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.event_available,
                          size: 64,
                          color: subTextColor.withOpacity(0.5),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No classes scheduled.',
                          style: TextStyle(color: subTextColor, fontSize: 16),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Make sure you have selected your courses\nin the Courses tab.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: subTextColor, fontSize: 13),
                        ),
                      ],
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: _loadTodayClasses,
                    color: AppTheme.primary,
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 8,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (_todaySchedules.isEmpty)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 24),
                              child: Text(
                                'No classes for today.',
                                style: TextStyle(
                                  color: subTextColor,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ),
                          ..._todaySchedules
                              .map(
                                (schedule) => _buildClassCard(
                                  schedule,
                                  cardColor,
                                  borderColor,
                                  textColor,
                                  subTextColor,
                                  isToday: true,
                                ),
                              )
                              .toList(),

                          if (_upcomingSchedules.isNotEmpty) ...[
                            const SizedBox(height: 16),
                            Text(
                              'Upcoming Classes',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: textColor,
                              ),
                            ),
                            const SizedBox(height: 16),
                            ..._upcomingSchedules
                                .map(
                                  (schedule) => _buildClassCard(
                                    schedule,
                                    cardColor,
                                    borderColor,
                                    textColor,
                                    subTextColor,
                                    isToday: false,
                                  ),
                                )
                                .toList(),
                          ],
                        ],
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildClassCard(
    Map<String, dynamic> schedule,
    Color cardColor,
    Color borderColor,
    Color textColor,
    Color subTextColor, {
    required bool isToday,
  }) {
    final subject = schedule['subjects'];
    final courseName = subject != null ? subject['name'] : 'Unknown Course';
    final courseCode = subject != null ? subject['code'] : '';

    final startTime = schedule['start_time'].toString().substring(0, 5);
    final endTime = schedule['end_time'].toString().substring(0, 5);
    final session = schedule['section'] ?? '';
    final dayName = schedule['day_name'] ?? '';
    final daysLeft = schedule['days_left'] as int?;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  courseCode,
                  style: const TextStyle(
                    color: AppTheme.primary,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
              const Spacer(),
              if (!isToday && daysLeft != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: daysLeft == 1
                        ? AppTheme.accent.withOpacity(0.1)
                        : subTextColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    daysLeft == 1 ? 'Tomorrow' : 'in $daysLeft days',
                    style: TextStyle(
                      color: daysLeft == 1 ? AppTheme.accent : subTextColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                )
              else
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.accent.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    session,
                    style: const TextStyle(
                      color: AppTheme.accent,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            courseName,
            style: TextStyle(
              color: textColor,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(Icons.schedule, size: 16, color: subTextColor),
              const SizedBox(width: 8),
              Text(
                isToday
                    ? '$startTime - $endTime'
                    : '$dayName, $startTime - $endTime',
                style: TextStyle(color: subTextColor, fontSize: 14),
              ),
              if (!isToday) ...[
                const Spacer(),
                Text(
                  session,
                  style: TextStyle(
                    color: subTextColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------
// Students Tab
// ---------------------------------------------------------
class _StudentsTab extends StatefulWidget {
  final Map<String, dynamic>? userData;
  final bool isDarkMode;

  const _StudentsTab({required this.userData, required this.isDarkMode});

  @override
  State<_StudentsTab> createState() => _StudentsTabState();
}

class _StudentsTabState extends State<_StudentsTab> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _sessions = [];
  String? _selectedSession;
  List<Map<String, dynamic>> _students = [];

  @override
  void initState() {
    super.initState();
    _loadSessions();
  }

  Future<void> _loadSessions() async {
    try {
      final dept = widget.userData?['department'];
      if (dept == null) return;

      final res = await Supabase.instance.client
          .from('departments')
          .select('id, sessions(*)')
          .eq('name', dept)
          .maybeSingle();

      if (res != null && res['sessions'] != null) {
        if (mounted) {
          setState(() {
            _sessions = List<Map<String, dynamic>>.from(res['sessions']);
            if (_sessions.isNotEmpty) {
              _selectedSession = _sessions.first['name'];
            }
            _isLoading = false;
          });
          _loadStudents();
        }
      } else {
        if (mounted) setState(() => _isLoading = false);
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _loadStudents() async {
    if (_selectedSession == null) return;
    setState(() => _isLoading = true);

    try {
      final dept = widget.userData?['department'];
      final sessionName = _selectedSession!;
      final res = await Supabase.instance.client
          .from('users')
          .select()
          .eq('role', 'student')
          .eq('department', dept)
          .eq('section', sessionName)
          .order('university_id');

      if (mounted) {
        setState(() {
          _students = List<Map<String, dynamic>>.from(res);
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? AppTheme.darkText : AppTheme.lightText;
    final subTextColor = isDark
        ? AppTheme.darkTextSecondary
        : AppTheme.lightTextSecondary;
    final cardColor = isDark ? AppTheme.darkCard : AppTheme.lightSurface;
    final borderColor = isDark ? AppTheme.darkBorder : AppTheme.lightBorder;

    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Students',
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: textColor,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'View students in your department',
                            style: TextStyle(fontSize: 14, color: subTextColor),
                          ),
                        ],
                      ),
                    ),
                    // Export Report Button
                    Container(
                      decoration: BoxDecoration(
                        color: AppTheme.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppTheme.primary.withValues(alpha: 0.3),
                        ),
                      ),
                      child: IconButton(
                        tooltip: 'Export Attendance Report',
                        icon: const Icon(
                          Icons.assessment_outlined,
                          color: AppTheme.primary,
                        ),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => AttendanceReportScreen(
                                userData: widget.userData,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Session Dropdown
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: borderColor),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _selectedSession,
                      isExpanded: true,
                      dropdownColor: cardColor,
                      icon: Icon(
                        Icons.keyboard_arrow_down,
                        color: subTextColor,
                      ),
                      items: _sessions.map((s) {
                        return DropdownMenuItem<String>(
                          value: s['name'],
                          child: Text(
                            'Session: ${s['name']}',
                            style: TextStyle(
                              color: textColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        );
                      }).toList(),
                      onChanged: (val) {
                        setState(() {
                          _selectedSession = val;
                        });
                        _loadStudents();
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),

          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: AppTheme.primary),
                  )
                : _students.isEmpty
                ? Center(
                    child: Text(
                      'No students found in this session.',
                      style: TextStyle(color: subTextColor),
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: _loadStudents,
                    color: AppTheme.primary,
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 8,
                      ),
                      itemCount: _students.length,
                      itemBuilder: (context, index) {
                        final student = _students[index];
                        final name = student['name'] ?? '';
                        final uid = student['university_id'] ?? '';
                        final labGroup = student['lab_group'] ?? '';

                        return GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => StudentAttendanceDetailsScreen(
                                  student: student,
                                ),
                              ),
                            );
                          },
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: cardColor,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: borderColor),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 48,
                                  height: 48,
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: [
                                        AppTheme.primary,
                                        AppTheme.accent,
                                      ],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Center(
                                    child: Text(
                                      name.isNotEmpty
                                          ? name[0].toUpperCase()
                                          : 'S',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 18,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        name,
                                        style: TextStyle(
                                          color: textColor,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '$uid • Lab $labGroup',
                                        style: TextStyle(
                                          color: subTextColor,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------
// Course Selection Tab
// ---------------------------------------------------------
class _CourseSelectionTab extends StatefulWidget {
  final Map<String, dynamic>? userData;
  final bool isDarkMode;

  const _CourseSelectionTab({required this.userData, required this.isDarkMode});

  @override
  State<_CourseSelectionTab> createState() => _CourseSelectionTabState();
}

class _CourseSelectionTabState extends State<_CourseSelectionTab> {
  bool _isLoading = true;
  bool _isSaving = false;
  List<Map<String, dynamic>> _subjects = [];
  Set<String> _selectedSubjectIds = {};

  @override
  void initState() {
    super.initState();
    _parseCurrentSelection();
    _loadSubjects();
  }

  void _parseCurrentSelection() {
    final labGroup = widget.userData?['lab_group'];
    if (labGroup != null && labGroup.toString().isNotEmpty) {
      try {
        final List<dynamic> ids = jsonDecode(labGroup);
        _selectedSubjectIds = ids.map((e) => e.toString()).toSet();
      } catch (e) {
        _selectedSubjectIds = {};
      }
    }
  }

  Future<void> _loadSubjects() async {
    try {
      final dept = widget.userData?['department'];
      if (dept == null) return;

      final res = await Supabase.instance.client
          .from('subjects')
          .select()
          .eq('department', dept)
          .order('name');

      if (mounted) {
        setState(() {
          _subjects = List<Map<String, dynamic>>.from(res);
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _saveSelection() async {
    setState(() => _isSaving = true);
    try {
      final userId = widget.userData?['id'];
      final selectionJson = jsonEncode(_selectedSubjectIds.toList());

      await Supabase.instance.client
          .from('users')
          .update({'lab_group': selectionJson})
          .eq('id', userId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Courses saved successfully!'),
            backgroundColor: AppTheme.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving: $e'),
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
    final textColor = isDark ? AppTheme.darkText : AppTheme.lightText;
    final subTextColor = isDark
        ? AppTheme.darkTextSecondary
        : AppTheme.lightTextSecondary;
    final cardColor = isDark ? AppTheme.darkCard : AppTheme.lightSurface;
    final borderColor = isDark ? AppTheme.darkBorder : AppTheme.lightBorder;

    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Course Selection',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Select the courses you teach',
                      style: TextStyle(fontSize: 14, color: subTextColor),
                    ),
                  ],
                ),
                ElevatedButton(
                  onPressed: _isLoading || _isSaving ? null : _saveSelection,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isSaving
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          'Save',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ],
            ),
          ),

          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: AppTheme.primary),
                  )
                : _subjects.isEmpty
                ? Center(
                    child: Text(
                      'No subjects found for your department.',
                      style: TextStyle(color: subTextColor),
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: _loadSubjects,
                    color: AppTheme.primary,
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 8,
                      ),
                      itemCount: _subjects.length,
                      itemBuilder: (context, index) {
                        final subject = _subjects[index];
                        final subjectId = subject['id'];

                        final courseName = subject['name'] ?? 'Unknown Course';
                        final courseCode = subject['code'] ?? '';

                        final isSelected = _selectedSubjectIds.contains(
                          subjectId,
                        );

                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              if (isSelected) {
                                _selectedSubjectIds.remove(subjectId);
                              } else {
                                _selectedSubjectIds.add(subjectId);
                              }
                            });
                          },
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppTheme.primary.withOpacity(0.05)
                                  : cardColor,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: isSelected
                                    ? AppTheme.primary.withOpacity(0.5)
                                    : borderColor,
                                width: isSelected ? 2 : 1,
                              ),
                            ),
                            child: Row(
                              children: [
                                Checkbox(
                                  value: isSelected,
                                  activeColor: AppTheme.primary,
                                  onChanged: (val) {
                                    setState(() {
                                      if (val == true) {
                                        _selectedSubjectIds.add(subjectId);
                                      } else {
                                        _selectedSubjectIds.remove(subjectId);
                                      }
                                    });
                                  },
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        courseName,
                                        style: TextStyle(
                                          color: textColor,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Row(
                                        children: [
                                          Icon(
                                            Icons.label_outline,
                                            size: 14,
                                            color: subTextColor,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            courseCode,
                                            style: TextStyle(
                                              color: subTextColor,
                                              fontSize: 13,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------
// Profile Tab
// ---------------------------------------------------------
class _ProfileTab extends StatelessWidget {
  final Map<String, dynamic>? userData;
  final bool isDarkMode; // This is stale, we'll use Theme.of(context) instead
  final Function(bool) onThemeToggle;

  const _ProfileTab({
    required this.userData,
    required this.isDarkMode,
    required this.onThemeToggle,
  });

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

    final name = userData?['name'] ?? 'Teacher';
    final uid = userData?['university_id'] ?? '-';
    final email = userData?['email'] ?? '-';
    final dept = userData?['department'] ?? '-';
    final designation = userData?['section'] ?? '-';

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const SizedBox(height: 20),
            Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppTheme.primary, AppTheme.accent],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(30),
              ),
              child: Center(
                child: Text(
                  name.isNotEmpty ? name[0].toUpperCase() : 'T',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 36,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              name,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: textColor,
              ),
            ),
            const SizedBox(height: 4),
            Text(uid, style: TextStyle(color: subTextColor, fontSize: 14)),

            const SizedBox(height: 32),

            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: borderColor),
              ),
              child: Column(
                children: [
                  _infoRow(
                    Icons.email_outlined,
                    'Email',
                    email,
                    textColor,
                    subTextColor,
                  ),
                  _divider(borderColor),
                  _infoRow(
                    Icons.business_outlined,
                    'Department',
                    dept,
                    textColor,
                    subTextColor,
                  ),
                  _divider(borderColor),
                  _infoRow(
                    Icons.work_outline,
                    'Designation',
                    designation,
                    textColor,
                    subTextColor,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            Container(
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: borderColor),
              ),
              child: Column(
                children: [
                  ListTile(
                    leading: Icon(
                      isDark ? Icons.light_mode : Icons.dark_mode,
                      color: textColor,
                    ),
                    title: Text(
                      isDark ? 'Light Mode' : 'Dark Mode',
                      style: TextStyle(
                        color: textColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    trailing: Icon(Icons.chevron_right, color: textColor),
                    onTap: () => onThemeToggle(!isDark),
                  ),
                  Divider(color: borderColor, height: 1),
                  ListTile(
                    leading: Icon(Icons.lock_outline, color: textColor),
                    title: Text(
                      'Change Password',
                      style: TextStyle(
                        color: textColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    trailing: Icon(Icons.chevron_right, color: textColor),
                    onTap: () {
                      showDialog(
                        context: context,
                        builder: (_) =>
                            ChangePasswordDialog(isDarkMode: isDark),
                      );
                    },
                  ),
                  Divider(color: borderColor, height: 1),
                  ListTile(
                    leading: const Icon(Icons.logout, color: AppTheme.error),
                    title: const Text(
                      'Sign Out',
                      style: TextStyle(
                        color: AppTheme.error,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    trailing: const Icon(
                      Icons.chevron_right,
                      color: AppTheme.error,
                    ),
                    onTap: () async {
                      await Supabase.instance.client.auth.signOut();
                      if (context.mounted) {
                        Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(
                            builder: (_) => LoginScreen(
                              isDarkMode: isDarkMode,
                              onThemeToggle: onThemeToggle,
                            ),
                          ),
                          (route) => false,
                        );
                      }
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(
    IconData icon,
    String label,
    String value,
    Color textColor,
    Color subColor,
  ) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppTheme.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: AppTheme.primary, size: 20),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(fontSize: 12, color: subColor)),
              const SizedBox(height: 4),
              Text(
                value,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: textColor,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _divider(Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Divider(color: color, height: 1),
    );
  }
}

// ---------------------------------------------------------
// Teacher Attendance Tab
// ---------------------------------------------------------
class _TeacherAttendanceTab extends StatefulWidget {
  final Map<String, dynamic>? userData;
  const _TeacherAttendanceTab({required this.userData});

  @override
  State<_TeacherAttendanceTab> createState() => _TeacherAttendanceTabState();
}

class _TeacherAttendanceTabState extends State<_TeacherAttendanceTab> {
  List<Map<String, dynamic>> _logs = [];
  bool _isLoading = true;
  DateTime _selectedDate = DateTime.now();
  List<String> _selectedSubjectIds = [];

  @override
  void initState() {
    super.initState();
    _extractSubjects();
    _loadData();
  }

  void _extractSubjects() {
    final labGroup = widget.userData?['lab_group'];
    if (labGroup != null && labGroup.toString().isNotEmpty) {
      try {
        _selectedSubjectIds = List<String>.from(jsonDecode(labGroup));
      } catch (e) {
        _selectedSubjectIds = [];
      }
    }
  }

  Future<void> _loadData() async {
    if (_selectedSubjectIds.isEmpty) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    try {
      final dateStr = _selectedDate.toIso8601String().split('T')[0];
      final logs = await Supabase.instance.client
          .from('attendance_logs')
          .select('*, users(name, university_id), subjects(name, code)')
          .inFilter('subject_id', _selectedSubjectIds)
          .eq('date', dateStr)
          .order('entry_time');

      setState(() {
        _logs = List<Map<String, dynamic>>.from(logs);
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2024),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
        _isLoading = true;
      });
      _loadData();
    }
  }

  Future<void> _updateStatus(String logId, String status) async {
    try {
      await Supabase.instance.client
          .from('attendance_logs')
          .update({'status': status})
          .eq('id', logId);
      _loadData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Status updated to $status'),
            backgroundColor: AppTheme.success,
          ),
        );
      }
    } catch (e) {
      // handle error
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

    if (_selectedSubjectIds.isEmpty) {
      return Center(
        child: Text(
          'No courses selected.\nPlease select courses in the Courses tab.',
          textAlign: TextAlign.center,
          style: TextStyle(color: subTextColor),
        ),
      );
    }

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Class Attendance',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: textColor,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 12),
                  GestureDetector(
                    onTap: _pickDate,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: cardColor,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: borderColor),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.calendar_today,
                            color: AppTheme.primary,
                            size: 18,
                          ),
                          const SizedBox(width: 10),
                          Text(
                            DateFormat('dd MMM yyyy').format(_selectedDate),
                            style: TextStyle(
                              color: textColor,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const Spacer(),
                          Icon(Icons.arrow_drop_down, color: subTextColor),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => TeacherManualAttendanceScreen(
                              subjectIds: _selectedSubjectIds,
                            ),
                          ),
                        ).then((_) => _loadData());
                      },
                      icon: const Icon(Icons.edit_document, size: 18),
                      label: const Text('Manual'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => TeacherQrAttendanceScreen(
                              subjectIds: _selectedSubjectIds,
                            ),
                          ),
                        ).then((_) => _loadData());
                      },
                      icon: const Icon(Icons.qr_code, size: 18),
                      label: const Text('QR Code'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.accent,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(color: AppTheme.primary),
                    )
                  : _logs.isEmpty
                  ? Center(
                      child: Text(
                        'No attendance for this date',
                        style: TextStyle(color: subTextColor),
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadData,
                      color: AppTheme.primary,
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        itemCount: _logs.length,
                        itemBuilder: (context, index) {
                          final log = _logs[index];
                          final user = log['users'];
                          final subject = log['subjects'];
                          final status = log['status'] ?? 'present';
                          final statusColor = status == 'present'
                              ? AppTheme.success
                              : status == 'condoned'
                              ? AppTheme.warning
                              : AppTheme.error;
                          final entryTime = log['entry_time'] != null
                              ? DateFormat('hh:mm a').format(
                                  DateTime.parse(log['entry_time']).toLocal(),
                                )
                              : '-';

                          return Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: cardColor,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: borderColor),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        user?['name'] ?? '-',
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: textColor,
                                        ),
                                      ),
                                      Text(
                                        '${user?['university_id']} • ${subject?['code']}',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: subTextColor,
                                        ),
                                      ),
                                      Text(
                                        'In: $entryTime',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: subTextColor,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                PopupMenuButton<String>(
                                  onSelected: (val) =>
                                      _updateStatus(log['id'], val),
                                  color: cardColor,
                                  itemBuilder: (_) => [
                                    const PopupMenuItem(
                                      value: 'present',
                                      child: Text('Present'),
                                    ),
                                    const PopupMenuItem(
                                      value: 'absent',
                                      child: Text('Absent'),
                                    ),
                                    const PopupMenuItem(
                                      value: 'condoned',
                                      child: Text('Condoned'),
                                    ),
                                  ],
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: statusColor.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          status.toUpperCase(),
                                          style: TextStyle(
                                            color: statusColor,
                                            fontSize: 11,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                        const SizedBox(width: 4),
                                        Icon(
                                          Icons.arrow_drop_down,
                                          size: 14,
                                          color: statusColor,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
