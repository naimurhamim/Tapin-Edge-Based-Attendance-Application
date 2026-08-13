import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../auth/login_screen.dart';

class StudentHome extends StatefulWidget {
  final bool isDarkMode;
  final Function(bool) onThemeToggle;

  const StudentHome({
    super.key,
    required this.isDarkMode,
    required this.onThemeToggle,
  });

  @override
  State<StudentHome> createState() => _StudentHomeState();
}

class _StudentHomeState extends State<StudentHome> {
  int _currentIndex = 0;
  Map<String, dynamic>? _userData;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      final userId = Supabase.instance.client.auth.currentUser!.id;
      final data = await Supabase.instance.client
          .from('users')
          .select()
          .eq('id', userId)
          .single();
      setState(() {
        _userData = data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
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
      _AttendanceTab(userData: _userData, isDarkMode: widget.isDarkMode),
      _HistoryTab(userData: _userData, isDarkMode: widget.isDarkMode),
      _LeaveTab(userData: _userData, isDarkMode: widget.isDarkMode),
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
                _navItem(0, Icons.home_outlined, Icons.home, 'Home'),
                _navItem(1, Icons.bar_chart_outlined, Icons.bar_chart, 'Attendance'),
                _navItem(2, Icons.history_outlined, Icons.history, 'History'),
                _navItem(3, Icons.event_note_outlined, Icons.event_note, 'Leave'),
                _navItem(4, Icons.person_outlined, Icons.person, 'Profile'),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _navItem(int index, IconData icon, IconData activeIcon, String label) {
    final isActive = _currentIndex == index;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = isActive
        ? AppTheme.primary
        : (isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary);

    return GestureDetector(
      onTap: () => setState(() => _currentIndex = index),
      child: Container(
        color: Colors.transparent,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(isActive ? activeIcon : icon, color: color, size: 24),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 11,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── DASHBOARD TAB ───────────────────────────────────────────
class _DashboardTab extends StatefulWidget {
  final Map<String, dynamic>? userData;
  final bool isDarkMode;

  const _DashboardTab({required this.userData, required this.isDarkMode});

  @override
  State<_DashboardTab> createState() => _DashboardTabState();
}

class _DashboardTabState extends State<_DashboardTab> {
  List<Map<String, dynamic>> _todayClasses = [];
  Map<String, dynamic> _stats = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final userId = Supabase.instance.client.auth.currentUser!.id;
      final now = DateTime.now();
      final todayName = DateFormat('EEEE').format(now);
      final dept = widget.userData?['department'] ?? 'IRE';
      final section = widget.userData?['section'] ?? '2021-22';
      final labGroup = widget.userData?['lab_group'] ?? 'G1';

      // Today's classes
      final schedules = await Supabase.instance.client
          .from('class_schedules')
          .select('*, subjects(name, code)')
          .eq('department', dept)
          .eq('section', section)
          .eq('day_name', todayName)
          .eq('is_active', true)
          .or('lab_group.eq.all,lab_group.eq.$labGroup')
          .order('start_time');

      // Attendance stats
      final logs = await Supabase.instance.client
          .from('attendance_logs')
          .select()
          .eq('student_id', userId);

      final total = logs.length;
      final present = logs.where((l) => l['status'] == 'present').length;
      final absent = logs.where((l) => l['status'] == 'absent').length;
      final percentage = total > 0 ? (present / total * 100) : 0.0;

      setState(() {
        _todayClasses = List<Map<String, dynamic>>.from(schedules);
        _stats = {
          'total': total,
          'present': present,
          'absent': absent,
          'percentage': percentage,
        };
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppTheme.darkBg : AppTheme.lightBg;
    final textColor = isDark ? AppTheme.darkText : AppTheme.lightText;
    final subTextColor =
        isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary;
    final cardColor = isDark ? AppTheme.darkCard : AppTheme.lightSurface;
    final borderColor = isDark ? AppTheme.darkBorder : AppTheme.lightBorder;
    final name = widget.userData?['name'] ?? 'Student';
    final uid = widget.userData?['university_id'] ?? '';
    final labGroup = widget.userData?['lab_group'] ?? '';
    final percentage = (_stats['percentage'] ?? 0.0) as double;

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: AppTheme.primary))
            : RefreshIndicator(
                onRefresh: _loadData,
                color: AppTheme.primary,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Hello, ${name.split(' ')[0]} 👋',
                                  style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.w800,
                                    color: textColor,
                                    letterSpacing: -0.5,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '$uid • Lab $labGroup',
                                  style: TextStyle(
                                      fontSize: 13, color: subTextColor),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [AppTheme.primary, AppTheme.accent],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.fingerprint,
                                color: Colors.white, size: 24),
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),

                      // Attendance Summary Card
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [AppTheme.primary, AppTheme.accent],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Overall Attendance',
                                    style: TextStyle(
                                      color: Colors.white70,
                                      fontSize: 13,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    '${percentage.toStringAsFixed(1)}%',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 36,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: -1,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      _statChip('Present',
                                          '${_stats['present'] ?? 0}',
                                          Colors.white),
                                      const SizedBox(width: 8),
                                      _statChip('Absent',
                                          '${_stats['absent'] ?? 0}',
                                          Colors.white70),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(
                              width: 80,
                              height: 80,
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  CircularProgressIndicator(
                                    value: percentage / 100,
                                    strokeWidth: 8,
                                    backgroundColor:
                                        Colors.white.withOpacity(0.3),
                                    valueColor:
                                        const AlwaysStoppedAnimation<Color>(
                                            Colors.white),
                                  ),
                                  Text(
                                    percentage >= 90 ? '✓' : '!',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Today's Classes
                      Text(
                        "Today's Classes",
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: textColor,
                        ),
                      ),
                      const SizedBox(height: 12),

                      if (_todayClasses.isEmpty)
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: cardColor,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: borderColor),
                          ),
                          child: Center(
                            child: Column(
                              children: [
                                Icon(Icons.celebration_outlined,
                                    color: subTextColor, size: 32),
                                const SizedBox(height: 8),
                                Text(
                                  'No classes today!',
                                  style: TextStyle(
                                      color: subTextColor, fontSize: 14),
                                ),
                              ],
                            ),
                          ),
                        )
                      else
                        ...(_todayClasses.map((cls) {
                          final subject = cls['subjects'];
                          final start = cls['start_time']
                              .toString()
                              .substring(0, 5);
                          final end =
                              cls['end_time'].toString().substring(0, 5);
                          final isLab =
                              cls['lab_group'] != 'all';

                          return Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: cardColor,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: borderColor),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 4,
                                  height: 48,
                                  decoration: BoxDecoration(
                                    color: isLab
                                        ? AppTheme.accent
                                        : AppTheme.primary,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        subject?['code'] ?? '',
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w700,
                                          color: isLab
                                              ? AppTheme.accent
                                              : AppTheme.primary,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        subject?['name'] ?? '',
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: textColor,
                                          fontWeight: FontWeight.w500,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      '$start - $end',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: subTextColor,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: (isLab
                                                ? AppTheme.accent
                                                : AppTheme.primary)
                                            .withOpacity(0.1),
                                        borderRadius:
                                            BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        isLab ? 'Lab' : 'Theory',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: isLab
                                              ? AppTheme.accent
                                              : AppTheme.primary,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        })),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  Widget _statChip(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        '$label: $value',
        style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w500),
      ),
    );
  }
}

// ─── ATTENDANCE TAB ───────────────────────────────────────────
class _AttendanceTab extends StatefulWidget {
  final Map<String, dynamic>? userData;
  final bool isDarkMode;

  const _AttendanceTab({required this.userData, required this.isDarkMode});

  @override
  State<_AttendanceTab> createState() => _AttendanceTabState();
}

class _AttendanceTabState extends State<_AttendanceTab> {
  List<Map<String, dynamic>> _subjectStats = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final userId = Supabase.instance.client.auth.currentUser!.id;
      final dept = widget.userData?['department'] ?? 'IRE';
      final section = widget.userData?['section'] ?? '2021-22';

      // Get subjects for this dept/section
      final subjects = await Supabase.instance.client
          .from('subjects')
          .select()
          .eq('department', dept)
          .eq('section', section);

      // Get all attendance logs
      final logs = await Supabase.instance.client
          .from('attendance_logs')
          .select()
          .eq('student_id', userId);

      List<Map<String, dynamic>> stats = [];
      for (final subject in subjects) {
        final subjectLogs =
            logs.where((l) => l['subject_id'] == subject['id']).toList();
        final total = subjectLogs.length;
        final present =
            subjectLogs.where((l) => l['status'] == 'present').length;
        final absent =
            subjectLogs.where((l) => l['status'] == 'absent').length;
        final percentage =
            total > 0 ? (present / total * 100) : 0.0;

        stats.add({
          'subject': subject,
          'total': total,
          'present': present,
          'absent': absent,
          'percentage': percentage,
        });
      }

      setState(() {
        _subjectStats = stats;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppTheme.darkBg : AppTheme.lightBg;
    final textColor = isDark ? AppTheme.darkText : AppTheme.lightText;
    final subTextColor =
        isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary;
    final cardColor = isDark ? AppTheme.darkCard : AppTheme.lightSurface;
    final borderColor = isDark ? AppTheme.darkBorder : AppTheme.lightBorder;

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(20),
              child: Text(
                'Attendance',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: textColor,
                  letterSpacing: -0.5,
                ),
              ),
            ),
            Expanded(
              child: _isLoading
                  ? const Center(
                      child:
                          CircularProgressIndicator(color: AppTheme.primary))
                  : RefreshIndicator(
                      onRefresh: _loadData,
                      color: AppTheme.primary,
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        itemCount: _subjectStats.length,
                        itemBuilder: (context, index) {
                          final stat = _subjectStats[index];
                          final subject = stat['subject'];
                          final percentage =
                              (stat['percentage'] as double);
                          final color = percentage >= 90
                              ? AppTheme.success
                              : (percentage >= 75
                                  ? AppTheme.warning
                                  : AppTheme.error);

                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: cardColor,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: borderColor),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            subject['code'],
                                            style: TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w700,
                                              color: AppTheme.primary,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            subject['name'],
                                            style: TextStyle(
                                              fontSize: 13,
                                              color: textColor,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 12, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: color.withOpacity(0.1),
                                        borderRadius:
                                            BorderRadius.circular(10),
                                      ),
                                      child: Text(
                                        '${percentage.toStringAsFixed(1)}%',
                                        style: TextStyle(
                                          color: color,
                                          fontWeight: FontWeight.w700,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(4),
                                  child: LinearProgressIndicator(
                                    value: percentage / 100,
                                    backgroundColor:
                                        color.withOpacity(0.15),
                                    valueColor:
                                        AlwaysStoppedAnimation<Color>(color),
                                    minHeight: 6,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                Row(
                                  children: [
                                    _chip('Present', '${stat['present']}',
                                        AppTheme.success),
                                    const SizedBox(width: 8),
                                    _chip('Absent', '${stat['absent']}',
                                        AppTheme.error),
                                    const SizedBox(width: 8),
                                    _chip('Total', '${stat['total']}',
                                        subTextColor),
                                  ],
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

  Widget _chip(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        '$label: $value',
        style: TextStyle(
            color: color, fontSize: 12, fontWeight: FontWeight.w500),
      ),
    );
  }
}

// ─── HISTORY TAB ───────────────────────────────────────────
class _HistoryTab extends StatefulWidget {
  final Map<String, dynamic>? userData;
  final bool isDarkMode;

  const _HistoryTab({required this.userData, required this.isDarkMode});

  @override
  State<_HistoryTab> createState() => _HistoryTabState();
}

class _HistoryTabState extends State<_HistoryTab> {
  List<Map<String, dynamic>> _logs = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final userId = Supabase.instance.client.auth.currentUser!.id;
      final logs = await Supabase.instance.client
          .from('attendance_logs')
          .select('*, subjects(name, code)')
          .eq('student_id', userId)
          .order('date', ascending: false)
          .limit(50);

      setState(() {
        _logs = List<Map<String, dynamic>>.from(logs);
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppTheme.darkBg : AppTheme.lightBg;
    final textColor = isDark ? AppTheme.darkText : AppTheme.lightText;
    final subTextColor =
        isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary;
    final cardColor = isDark ? AppTheme.darkCard : AppTheme.lightSurface;
    final borderColor = isDark ? AppTheme.darkBorder : AppTheme.lightBorder;

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(20),
              child: Text(
                'History',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: textColor,
                  letterSpacing: -0.5,
                ),
              ),
            ),
            Expanded(
              child: _isLoading
                  ? const Center(
                      child:
                          CircularProgressIndicator(color: AppTheme.primary))
                  : _logs.isEmpty
                      ? Center(
                          child: Text('No attendance records yet',
                              style: TextStyle(color: subTextColor)))
                      : RefreshIndicator(
                          onRefresh: _loadData,
                          color: AppTheme.primary,
                          child: ListView.builder(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 20),
                            itemCount: _logs.length,
                            itemBuilder: (context, index) {
                              final log = _logs[index];
                              final subject = log['subjects'];
                              final status = log['status'] ?? 'present';
                              final date = log['date'] ?? '';
                              final entryTime = log['entry_time'] != null
                                  ? DateFormat('hh:mm a').format(
                                      DateTime.parse(log['entry_time'])
                                          .toLocal())
                                  : '-';
                              final exitTime = log['exit_time'] != null
                                  ? DateFormat('hh:mm a').format(
                                      DateTime.parse(log['exit_time'])
                                          .toLocal())
                                  : '-';

                              final statusColor = status == 'present'
                                  ? AppTheme.success
                                  : status == 'condoned'
                                      ? AppTheme.warning
                                      : AppTheme.error;

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
                                    Container(
                                      width: 40,
                                      height: 40,
                                      decoration: BoxDecoration(
                                        color:
                                            statusColor.withOpacity(0.1),
                                        borderRadius:
                                            BorderRadius.circular(10),
                                      ),
                                      child: Icon(
                                        status == 'present'
                                            ? Icons.check_circle_outline
                                            : status == 'condoned'
                                                ? Icons.info_outline
                                                : Icons.cancel_outlined,
                                        color: statusColor,
                                        size: 20,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            subject?['code'] ?? 'Unknown',
                                            style: TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w700,
                                              color: textColor,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            '$entryTime → $exitTime',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: subTextColor,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.end,
                                      children: [
                                        Text(
                                          date,
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: subTextColor,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 8, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: statusColor
                                                .withOpacity(0.1),
                                            borderRadius:
                                                BorderRadius.circular(6),
                                          ),
                                          child: Text(
                                            status.toUpperCase(),
                                            style: TextStyle(
                                              fontSize: 10,
                                              color: statusColor,
                                              fontWeight: FontWeight.w700,
                                            ),
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
            ),
          ],
        ),
      ),
    );
  }
}

// ─── LEAVE TAB ───────────────────────────────────────────
class _LeaveTab extends StatefulWidget {
  final Map<String, dynamic>? userData;
  final bool isDarkMode;

  const _LeaveTab({required this.userData, required this.isDarkMode});

  @override
  State<_LeaveTab> createState() => _LeaveTabState();
}

class _LeaveTabState extends State<_LeaveTab> {
  List<Map<String, dynamic>> _leaves = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadLeaves();
  }

  Future<void> _loadLeaves() async {
    try {
      final userId = Supabase.instance.client.auth.currentUser!.id;
      final leaves = await Supabase.instance.client
          .from('leave_applications')
          .select('*, subjects(name, code)')
          .eq('student_id', userId)
          .order('created_at', ascending: false);

      setState(() {
        _leaves = List<Map<String, dynamic>>.from(leaves);
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _applyLeave() async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final userId = Supabase.instance.client.auth.currentUser!.id;
    final dept = widget.userData?['department'] ?? 'IRE';
    final section = widget.userData?['section'] ?? '2021-22';

    // Get subjects
    final subjects = await Supabase.instance.client
        .from('subjects')
        .select()
        .eq('department', dept)
        .eq('section', section);

    if (!mounted) return;

    String? selectedSubjectId;
    DateTime selectedDate = DateTime.now();
    String reason = '';
    String leaveType = 'medical';

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? AppTheme.darkCard : AppTheme.lightSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 24,
                right: 24,
                top: 24,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Apply for Leave',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: isDark ? AppTheme.darkText : AppTheme.lightText,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Subject dropdown
                  DropdownButtonFormField<String>(
                    decoration: InputDecoration(
                      labelText: 'Subject',
                      filled: true,
                      fillColor:
                          isDark ? AppTheme.darkBg : AppTheme.lightBg,
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    dropdownColor:
                        isDark ? AppTheme.darkCard : AppTheme.lightSurface,
                    style: TextStyle(
                        color:
                            isDark ? AppTheme.darkText : AppTheme.lightText),
                    items: subjects.map<DropdownMenuItem<String>>((s) {
                      return DropdownMenuItem(
                        value: s['id'].toString(),
                        child: Text(s['code']),
                      );
                    }).toList(),
                    onChanged: (val) =>
                        setModalState(() => selectedSubjectId = val),
                  ),

                  const SizedBox(height: 16),

                  // Leave type
                  DropdownButtonFormField<String>(
                    value: leaveType,
                    decoration: InputDecoration(
                      labelText: 'Leave Type',
                      filled: true,
                      fillColor:
                          isDark ? AppTheme.darkBg : AppTheme.lightBg,
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    dropdownColor:
                        isDark ? AppTheme.darkCard : AppTheme.lightSurface,
                    style: TextStyle(
                        color:
                            isDark ? AppTheme.darkText : AppTheme.lightText),
                    items: const [
                      DropdownMenuItem(
                          value: 'medical', child: Text('Medical')),
                      DropdownMenuItem(
                          value: 'general', child: Text('General')),
                      DropdownMenuItem(
                          value: 'emergency', child: Text('Emergency')),
                    ],
                    onChanged: (val) =>
                        setModalState(() => leaveType = val!),
                  ),

                  const SizedBox(height: 16),

                  // Reason
                  TextField(
                    decoration: InputDecoration(
                      labelText: 'Reason',
                      filled: true,
                      fillColor:
                          isDark ? AppTheme.darkBg : AppTheme.lightBg,
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    style: TextStyle(
                        color:
                            isDark ? AppTheme.darkText : AppTheme.lightText),
                    maxLines: 3,
                    onChanged: (val) => reason = val,
                  ),

                  const SizedBox(height: 24),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () async {
                        if (selectedSubjectId == null || reason.isEmpty) {
                          return;
                        }
                        try {
                          await Supabase.instance.client
                              .from('leave_applications')
                              .insert({
                            'student_id': userId,
                            'subject_id': selectedSubjectId,
                            'leave_date': DateFormat('yyyy-MM-dd')
                                .format(selectedDate),
                            'reason': reason,
                            'leave_type': leaveType,
                            'status': 'pending',
                          });
                          if (!mounted) return;
                          Navigator.pop(context);
                          _loadLeaves();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Leave application submitted!'),
                              backgroundColor: AppTheme.success,
                            ),
                          );
                        } catch (e) {
                          // handle error
                        }
                      },
                      child: const Text('Submit Application'),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppTheme.darkBg : AppTheme.lightBg;
    final textColor = isDark ? AppTheme.darkText : AppTheme.lightText;
    final subTextColor =
        isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary;
    final cardColor = isDark ? AppTheme.darkCard : AppTheme.lightSurface;
    final borderColor = isDark ? AppTheme.darkBorder : AppTheme.lightBorder;

    return Scaffold(
      backgroundColor: bg,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _applyLeave,
        backgroundColor: AppTheme.primary,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Apply Leave',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(20),
              child: Text(
                'Leave Applications',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: textColor,
                  letterSpacing: -0.5,
                ),
              ),
            ),
            Expanded(
              child: _isLoading
                  ? const Center(
                      child:
                          CircularProgressIndicator(color: AppTheme.primary))
                  : _leaves.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.event_note_outlined,
                                  color: subTextColor, size: 48),
                              const SizedBox(height: 12),
                              Text('No leave applications yet',
                                  style: TextStyle(color: subTextColor)),
                            ],
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: _loadLeaves,
                          color: AppTheme.primary,
                          child: ListView.builder(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 20),
                            itemCount: _leaves.length,
                            itemBuilder: (context, index) {
                              final leave = _leaves[index];
                              final subject = leave['subjects'];
                              final status = leave['status'] ?? 'pending';
                              final statusColor = status == 'approved'
                                  ? AppTheme.success
                                  : status == 'rejected'
                                      ? AppTheme.error
                                      : AppTheme.warning;

                              return Container(
                                margin: const EdgeInsets.only(bottom: 10),
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: cardColor,
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(color: borderColor),
                                ),
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            subject?['code'] ?? 'Unknown',
                                            style: TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w700,
                                              color: textColor,
                                            ),
                                          ),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 10, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: statusColor
                                                .withOpacity(0.1),
                                            borderRadius:
                                                BorderRadius.circular(8),
                                          ),
                                          child: Text(
                                            status.toUpperCase(),
                                            style: TextStyle(
                                              color: statusColor,
                                              fontSize: 11,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      leave['reason'] ?? '',
                                      style: TextStyle(
                                          color: subTextColor, fontSize: 13),
                                    ),
                                    if (leave['admin_note'] != null) ...[
                                      const SizedBox(height: 6),
                                      Text(
                                        'Note: ${leave['admin_note']}',
                                        style: TextStyle(
                                          color: AppTheme.primary,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                    const SizedBox(height: 6),
                                    Text(
                                      'Date: ${leave['leave_date'] ?? ''}  •  Type: ${leave['leave_type'] ?? ''}',
                                      style: TextStyle(
                                          color: subTextColor, fontSize: 12),
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

// ─── PROFILE TAB ───────────────────────────────────────────
class _ProfileTab extends StatelessWidget {
  final Map<String, dynamic>? userData;
  final bool isDarkMode;
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
    final subTextColor =
        isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary;
    final cardColor = isDark ? AppTheme.darkCard : AppTheme.lightSurface;
    final borderColor = isDark ? AppTheme.darkBorder : AppTheme.lightBorder;

    final name = userData?['name'] ?? '-';
    final uid = userData?['university_id'] ?? '-';
    final email = userData?['email'] ?? '-';
    final dept = userData?['department'] ?? '-';
    final section = userData?['section'] ?? '-';
    final labGroup = userData?['lab_group'] ?? '-';
    final phone = userData?['phone_number'] ?? '-';

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              // Avatar
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppTheme.primary, AppTheme.accent],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Center(
                  child: Text(
                    name.isNotEmpty ? name[0].toUpperCase() : 'S',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                name,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: textColor,
                ),
              ),
              const SizedBox(height: 4),
              Text(uid,
                  style: TextStyle(color: subTextColor, fontSize: 14)),

              const SizedBox(height: 24),

              // Info Card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: borderColor),
                ),
                child: Column(
                  children: [
                    _infoRow(Icons.email_outlined, 'Email', email,
                        textColor, subTextColor),
                    _divider(borderColor),
                    _infoRow(Icons.school_outlined, 'Department', dept,
                        textColor, subTextColor),
                    _divider(borderColor),
                    _infoRow(Icons.group_outlined, 'Session', section,
                        textColor, subTextColor),
                    _divider(borderColor),
                    _infoRow(Icons.science_outlined, 'Lab Group', labGroup,
                        textColor, subTextColor),
                    _divider(borderColor),
                    _infoRow(Icons.phone_outlined, 'Phone', phone,
                        textColor, subTextColor),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Settings Card
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: borderColor),
                ),
                child: Column(
                  children: [
                    _settingRow(
                      icon: isDark ? Icons.light_mode : Icons.dark_mode,
                      label: isDark ? 'Light Mode' : 'Dark Mode',
                      textColor: textColor,
                      onTap: () => onThemeToggle(!isDark),
                    ),
                    Divider(color: borderColor, height: 1),
                    _settingRow(
                      icon: Icons.logout,
                      label: 'Sign Out',
                      textColor: AppTheme.error,
                      onTap: () async {
                        await Supabase.instance.client.auth.signOut();
                        if (!context.mounted) return;
                        Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(
                            builder: (_) => LoginScreen(
                              isDarkMode: isDark,
                              onThemeToggle: onThemeToggle,
                            ),
                          ),
                          (route) => false,
                        );
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value, Color textColor,
      Color subTextColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppTheme.primary),
          const SizedBox(width: 12),
          Text(label,
              style: TextStyle(color: subTextColor, fontSize: 13)),
          const Spacer(),
          Text(
            value,
            style: TextStyle(
                color: textColor,
                fontSize: 13,
                fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Widget _divider(Color color) => Divider(color: color, height: 1);

  Widget _settingRow({
    required IconData icon,
    required String label,
    required Color textColor,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: textColor, size: 20),
      title: Text(label,
          style: TextStyle(
              color: textColor,
              fontSize: 14,
              fontWeight: FontWeight.w500)),
      trailing: Icon(Icons.chevron_right, color: textColor, size: 20),
      onTap: onTap,
    );
  }
}