import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../auth/login_screen.dart';
import '../../../presentation/widgets/change_password_dialog.dart';
import 'geofence_settings_screen.dart';

class AdminHome extends StatefulWidget {
  final bool isDarkMode;
  final Function(bool) onThemeToggle;

  const AdminHome({
    super.key,
    required this.isDarkMode,
    required this.onThemeToggle,
  });

  @override
  State<AdminHome> createState() => _AdminHomeState();
}

class _AdminHomeState extends State<AdminHome> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppTheme.darkBg : AppTheme.lightBg;
    final navBg = isDark ? AppTheme.darkSurface : AppTheme.lightSurface;
    final borderColor = isDark ? AppTheme.darkBorder : AppTheme.lightBorder;

    final pages = [
      _AdminDashboardTab(isDarkMode: isDark),
      _AdminStudentsTab(isDarkMode: isDark),
      _AdminScheduleTab(isDarkMode: isDark),
      _AdminProfileTab(isDarkMode: isDark, onThemeToggle: widget.onThemeToggle),
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
                _navItem(1, Icons.people_outlined, Icons.people, 'Students'),
                _navItem(
                  2,
                  Icons.calendar_month_outlined,
                  Icons.calendar_month,
                  'Schedule',
                ),
                _navItem(3, Icons.person_outlined, Icons.person, 'Profile'),
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
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(isActive ? activeIcon : icon, color: color, size: 22),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 10,
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
class _AdminDashboardTab extends StatefulWidget {
  final bool isDarkMode;
  const _AdminDashboardTab({required this.isDarkMode});

  @override
  State<_AdminDashboardTab> createState() => _AdminDashboardTabState();
}

class _AdminDashboardTabState extends State<_AdminDashboardTab> {
  Map<String, dynamic> _stats = {};
  List<Map<String, dynamic>> _todayClasses = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final today = DateTime.now().toIso8601String().split('T')[0];
      final todayName = DateFormat('EEEE').format(DateTime.now());

      final students = await Supabase.instance.client
          .from('users')
          .select()
          .eq('role', 'student')
          .eq('department', 'IRE')
          .eq('section', '2021-22');

      final todayClasses = await Supabase.instance.client
          .from('class_schedules')
          .select('*, subjects(name, code)')
          .eq('department', 'IRE')
          .eq('section', '2021-22')
          .eq('day_name', todayName)
          .eq('is_active', true)
          .order('start_time');

      setState(() {
        _stats = {'totalStudents': students.length};
        _todayClasses = List<Map<String, dynamic>>.from(todayClasses);
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
    final subTextColor = isDark
        ? AppTheme.darkTextSecondary
        : AppTheme.lightTextSecondary;
    final cardColor = isDark ? AppTheme.darkCard : AppTheme.lightSurface;
    final borderColor = isDark ? AppTheme.darkBorder : AppTheme.lightBorder;
    final today = DateFormat('EEEE, dd MMM').format(DateTime.now());

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: AppTheme.primary),
              )
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
                                  'Admin Panel',
                                  style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.w800,
                                    color: textColor,
                                    letterSpacing: -0.5,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  today,
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: subTextColor,
                                  ),
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
                            child: const Icon(
                              Icons.admin_panel_settings,
                              color: Colors.white,
                              size: 24,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      // ── Geofence Settings Quick Link ──────
                      GestureDetector(
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const GeofenceSettingsScreen(),
                          ),
                        ),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: cardColor,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: borderColor),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: AppTheme.accent.withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(
                                  Icons.location_on_outlined,
                                  color: AppTheme.accent,
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Geofence Settings',
                                      style: TextStyle(
                                        color: textColor,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text(
                                      'Set campus location & attendance radius',
                                      style: TextStyle(
                                        color: subTextColor,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Icon(
                                Icons.arrow_forward_ios,
                                color: subTextColor,
                                size: 16,
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Stats Grid
                      Row(
                        children: [
                          Expanded(
                            child: _statCard(
                              'Total Students',
                              '${_stats['totalStudents'] ?? 0}',
                              Icons.people,
                              AppTheme.primary,
                              cardColor,
                              borderColor,
                              textColor,
                              subTextColor,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _statCard(
                              'Today Present',
                              '${_stats['todayPresent'] ?? 0}',
                              Icons.check_circle_outline,
                              AppTheme.success,
                              cardColor,
                              borderColor,
                              textColor,
                              subTextColor,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _statCard(
                              'Pending Leaves',
                              '${_stats['pendingLeaves'] ?? 0}',
                              Icons.pending_actions,
                              AppTheme.warning,
                              cardColor,
                              borderColor,
                              textColor,
                              subTextColor,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _statCard(
                              'Today Classes',
                              '${_todayClasses.length}',
                              Icons.class_outlined,
                              AppTheme.accent,
                              cardColor,
                              borderColor,
                              textColor,
                              subTextColor,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),

                      // Today's Schedule
                      Text(
                        "Today's Schedule",
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
                            child: Text(
                              'No classes today',
                              style: TextStyle(color: subTextColor),
                            ),
                          ),
                        )
                      else
                        ...(_todayClasses.map((cls) {
                          final subject = cls['subjects'];
                          final start = cls['start_time'].toString().substring(
                            0,
                            5,
                          );
                          final end = cls['end_time'].toString().substring(
                            0,
                            5,
                          );
                          final isLab = cls['lab_group'] != 'all';

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
                                  width: 4,
                                  height: 44,
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
                                      Text(
                                        subject?['name'] ?? '',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: subTextColor,
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
                                        horizontal: 8,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color:
                                            (isLab
                                                    ? AppTheme.accent
                                                    : AppTheme.primary)
                                                .withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        isLab
                                            ? 'Lab ${cls['lab_group']}'
                                            : 'Theory',
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
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  Widget _statCard(
    String label,
    String value,
    IconData icon,
    Color color,
    Color cardColor,
    Color borderColor,
    Color textColor,
    Color subTextColor,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: textColor,
            ),
          ),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(fontSize: 12, color: subTextColor)),
        ],
      ),
    );
  }
}

// ─── STUDENTS TAB ───────────────────────────────────────────
class _AdminStudentsTab extends StatefulWidget {
  final bool isDarkMode;
  const _AdminStudentsTab({required this.isDarkMode});

  @override
  State<_AdminStudentsTab> createState() => _AdminStudentsTabState();
}

class _AdminStudentsTabState extends State<_AdminStudentsTab> {
  List<Map<String, dynamic>> _students = [];
  List<Map<String, dynamic>> _filtered = [];
  bool _isLoading = true;
  final _searchController = TextEditingController();

  int _unassignedScansCount = 0;
  int _assignedStudentsCount = 0;

  List<Map<String, dynamic>> _departments = [];
  List<Map<String, dynamic>> _sessions = [];
  String? _selectedDepartmentId;
  String? _selectedDepartmentName;
  String? _selectedSessionName;

  @override
  void initState() {
    super.initState();
    _initData();
  }

  Future<void> _initData() async {
    try {
      final res = await Supabase.instance.client
          .from('departments')
          .select('*, sessions(*)')
          .order('name');
      if (mounted) {
        setState(() {
          _departments = List<Map<String, dynamic>>.from(res);
          if (_departments.isNotEmpty) {
            final firstDept = _departments.first;
            _selectedDepartmentId = firstDept['id'];
            _selectedDepartmentName = firstDept['name'];
            _sessions = List<Map<String, dynamic>>.from(
              firstDept['sessions'] ?? [],
            );
            if (_sessions.isNotEmpty) {
              _selectedSessionName = _sessions.first['name'];
            }
          }
        });
      }
      await _loadStudents();
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _onDepartmentChanged(String? deptId) {
    setState(() {
      _selectedDepartmentId = deptId;
      _selectedSessionName = null;
      if (deptId != null) {
        final dept = _departments.firstWhere((d) => d['id'] == deptId);
        _selectedDepartmentName = dept['name'];
        _sessions = List<Map<String, dynamic>>.from(dept['sessions'] ?? []);
        if (_sessions.isNotEmpty) {
          _selectedSessionName = _sessions.first['name'];
        }
      } else {
        _selectedDepartmentName = null;
        _sessions = [];
      }
      _isLoading = true;
    });
    _loadStudents();
  }

  Future<void> _loadStudents() async {
    if (_selectedDepartmentName == null || _selectedSessionName == null) {
      if (mounted) {
        setState(() {
          _students = [];
          _filtered = [];
          _isLoading = false;
        });
      }
      return;
    }

    try {
      final students = await Supabase.instance.client
          .from('users')
          .select()
          .eq('role', 'student')
          .eq('department', _selectedDepartmentName!)
          .eq('section', _selectedSessionName!)
          .order('university_id');

      final unassigned = await Supabase.instance.client
          .from('unassigned_rfid_scans')
          .select('id');

      int assignedCount = 0;
      for (var s in students) {
        if (s['rfid_uid'] != null && s['rfid_uid'].toString().isNotEmpty) {
          assignedCount++;
        }
      }

      if (mounted) {
        setState(() {
          _students = List<Map<String, dynamic>>.from(students);
          _filtered = _students;
          _assignedStudentsCount = assignedCount;
          _unassignedScansCount = unassigned.length;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _search(String query) {
    setState(() {
      _filtered = _students.where((s) {
        return s['name'].toString().toLowerCase().contains(
              query.toLowerCase(),
            ) ||
            s['university_id'].toString().contains(query);
      }).toList();
    });
  }

  void _showStudentDetails(Map<String, dynamic> student) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) =>
          _StudentDetailSheet(student: student, isDarkMode: widget.isDarkMode),
    ).then((_) => _loadStudents());
  }

  void _showAllUnassignedDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => _AllUnassignedScansDialog(isDarkMode: widget.isDarkMode),
    ).then((_) => _loadStudents());
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
                    'Students',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: textColor,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: _selectedDepartmentId,
                          dropdownColor: cardColor,
                          style: TextStyle(color: textColor, fontSize: 13),
                          decoration: InputDecoration(
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 10,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          items: _departments
                              .map(
                                (d) => DropdownMenuItem<String>(
                                  value: d['id'],
                                  child: Text(d['name']),
                                ),
                              )
                              .toList(),
                          onChanged: _onDepartmentChanged,
                          hint: Text(
                            'Dept',
                            style: TextStyle(color: subTextColor),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: _selectedSessionName,
                          dropdownColor: cardColor,
                          style: TextStyle(color: textColor, fontSize: 13),
                          decoration: InputDecoration(
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 10,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          items: _sessions
                              .map(
                                (s) => DropdownMenuItem<String>(
                                  value: s['name'],
                                  child: Text(s['name']),
                                ),
                              )
                              .toList(),
                          onChanged: _selectedDepartmentId == null
                              ? null
                              : (val) {
                                  setState(() {
                                    _selectedSessionName = val;
                                    _isLoading = true;
                                  });
                                  _loadStudents();
                                },
                          hint: Text(
                            'Session',
                            style: TextStyle(color: subTextColor),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _searchController,
                    onChanged: _search,
                    style: TextStyle(color: textColor),
                    decoration: InputDecoration(
                      hintText: 'Search by name or ID...',
                      hintStyle: TextStyle(color: subTextColor),
                      prefixIcon: Icon(Icons.search, color: subTextColor),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: Icon(Icons.clear, color: subTextColor),
                              onPressed: () {
                                _searchController.clear();
                                _search('');
                              },
                            )
                          : null,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppTheme.primary.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: AppTheme.primary.withOpacity(0.2),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Assigned RFIDs',
                                style: TextStyle(
                                  color: subTextColor,
                                  fontSize: 12,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '$_assignedStudentsCount / ${_students.length}',
                                style: const TextStyle(
                                  color: AppTheme.primary,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: InkWell(
                          onTap: () => _showAllUnassignedDialog(context),
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppTheme.warning.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: AppTheme.warning.withOpacity(0.3),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Unassigned Scans',
                                  style: TextStyle(
                                    color: subTextColor,
                                    fontSize: 12,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      '$_unassignedScansCount',
                                      style: const TextStyle(
                                        color: AppTheme.warning,
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const Icon(
                                      Icons.arrow_forward_ios,
                                      size: 14,
                                      color: AppTheme.warning,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(color: AppTheme.primary),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadStudents,
                      color: AppTheme.primary,
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        itemCount: _filtered.length,
                        itemBuilder: (context, index) {
                          final student = _filtered[index];
                          final name = student['name'] ?? '';
                          final uid = student['university_id'] ?? '';
                          final labGroup = student['lab_group'] ?? '';

                          return GestureDetector(
                            onTap: () => _showStudentDetails(student),
                            child: Container(
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
                                    width: 42,
                                    height: 42,
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
                                          fontWeight: FontWeight.w700,
                                          fontSize: 16,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          name,
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                            color: textColor,
                                          ),
                                        ),
                                        Text(
                                          uid,
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: subTextColor,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
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
                                      'Lab $labGroup',
                                      style: const TextStyle(
                                        color: AppTheme.primary,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                      ),
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
      ),
    );
  }
}

class _StudentDetailSheet extends StatefulWidget {
  final Map<String, dynamic> student;
  final bool isDarkMode;

  const _StudentDetailSheet({required this.student, required this.isDarkMode});

  @override
  State<_StudentDetailSheet> createState() => _StudentDetailSheetState();
}

class _StudentDetailSheetState extends State<_StudentDetailSheet> {
  Map<String, dynamic> _stats = {};
  late Map<String, dynamic> _studentData;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _studentData = Map.from(widget.student);
    _loadStats();
  }

  Future<void> _refreshStudent() async {
    final res = await Supabase.instance.client
        .from('users')
        .select()
        .eq('id', _studentData['id'])
        .single();
    if (mounted) {
      setState(() {
        _studentData = res;
      });
    }
  }

  Future<void> _editName() async {
    final controller = TextEditingController(text: _studentData['name']);
    final newName = await showDialog<String>(
      context: context,
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return AlertDialog(
          backgroundColor: isDark ? AppTheme.darkCard : AppTheme.lightSurface,
          title: Text(
            'Edit Student Name',
            style: TextStyle(
              color: isDark ? AppTheme.darkText : AppTheme.lightText,
            ),
          ),
          content: TextField(
            controller: controller,
            style: TextStyle(
              color: isDark ? AppTheme.darkText : AppTheme.lightText,
            ),
            decoration: InputDecoration(
              hintText: 'Student Name',
              hintStyle: TextStyle(
                color: isDark
                    ? AppTheme.darkTextSecondary
                    : AppTheme.lightTextSecondary,
              ),
              enabledBorder: OutlineInputBorder(
                borderSide: BorderSide(
                  color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder,
                ),
              ),
              focusedBorder: const OutlineInputBorder(
                borderSide: BorderSide(color: AppTheme.primary),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, controller.text.trim()),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
              ),
              child: const Text('Save', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );

    if (newName == null || newName.isEmpty || newName == _studentData['name'])
      return;

    setState(() => _isLoading = true);
    try {
      await Supabase.instance.client
          .from('users')
          .update({'name': newName})
          .eq('id', _studentData['id']);
      await _refreshStudent();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _loadStats() async {
    try {
      final logs = await Supabase.instance.client
          .from('attendance_logs')
          .select('*, subjects(name, code)')
          .eq('student_id', widget.student['id']);

      final total = logs.length;
      final present = logs.where((l) => l['status'] == 'present').length;
      final absent = logs.where((l) => l['status'] == 'absent').length;
      final condoned = logs.where((l) => l['status'] == 'condoned').length;
      final percentage = total > 0 ? ((present + condoned) / total * 100) : 0.0;

      setState(() {
        _stats = {
          'total': total,
          'present': present,
          'absent': absent,
          'condoned': condoned,
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
    final cardColor = isDark ? AppTheme.darkCard : AppTheme.lightSurface;
    final textColor = isDark ? AppTheme.darkText : AppTheme.lightText;
    final subTextColor = isDark
        ? AppTheme.darkTextSecondary
        : AppTheme.lightTextSecondary;
    final borderColor = isDark ? AppTheme.darkBorder : AppTheme.lightBorder;
    final name = _studentData['name'] ?? '';
    final uid = _studentData['university_id'] ?? '';
    final labGroup = _studentData['lab_group'] ?? '';
    final percentage = (_stats['percentage'] ?? 0.0) as double;
    final color = percentage >= 90
        ? AppTheme.success
        : (percentage >= 75 ? AppTheme.warning : AppTheme.error);

    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: subTextColor.withOpacity(0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppTheme.primary, AppTheme.accent],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Center(
                  child: Text(
                    name.isNotEmpty ? name[0].toUpperCase() : 'S',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 22,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            name,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: textColor,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.edit_outlined,
                            color: AppTheme.primary,
                            size: 20,
                          ),
                          onPressed: _isLoading ? null : _editName,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ],
                    ),
                    Text(
                      '$uid • Lab $labGroup',
                      style: TextStyle(fontSize: 13, color: subTextColor),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          if (_isLoading)
            const CircularProgressIndicator(color: AppTheme.primary)
          else ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: color.withOpacity(0.08),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: color.withOpacity(0.2)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _statItem(
                    'Attendance',
                    '${percentage.toStringAsFixed(1)}%',
                    color,
                  ),
                  _statItem(
                    'Present',
                    '${_stats['present']}',
                    AppTheme.success,
                  ),
                  _statItem('Absent', '${_stats['absent']}', AppTheme.error),
                  _statItem('Total', '${_stats['total']}', subTextColor),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: percentage >= 90
                    ? AppTheme.success.withOpacity(0.1)
                    : AppTheme.error.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: percentage >= 90
                      ? AppTheme.success.withOpacity(0.3)
                      : AppTheme.error.withOpacity(0.3),
                ),
              ),
              child: Text(
                percentage >= 90
                    ? '✓ Attendance mark secured (30/30)'
                    : '✗ Attendance mark not secured (0/30)',
                style: TextStyle(
                  color: percentage >= 90 ? AppTheme.success : AppTheme.error,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
          const SizedBox(height: 16),
          // RFID Assign
          _RfidAssignWidget(
            student: _studentData,
            isDarkMode: widget.isDarkMode,
            onUpdated: _refreshStudent,
          ),
        ],
      ),
    );
  }

  Widget _statItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(fontSize: 11, color: color)),
      ],
    );
  }
}

class _RfidAssignWidget extends StatelessWidget {
  final Map<String, dynamic> student;
  final bool isDarkMode;
  final VoidCallback onUpdated;

  const _RfidAssignWidget({
    required this.student,
    required this.isDarkMode,
    required this.onUpdated,
  });

  Future<void> _unassign(BuildContext context) async {
    try {
      await Supabase.instance.client
          .from('users')
          .update({'rfid_uid': null})
          .eq('id', student['id']);

      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('RFID Unassigned successfully!'),
          backgroundColor: AppTheme.success,
        ),
      );
      onUpdated();
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: AppTheme.error),
      );
    }
  }

  void _showAssignDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => _AssignRfidDialog(
        student: student,
        isDarkMode: isDarkMode,
        onAssigned: onUpdated,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final textColor = isDarkMode ? AppTheme.darkText : AppTheme.lightText;
    final subTextColor = isDarkMode
        ? AppTheme.darkTextSecondary
        : AppTheme.lightTextSecondary;
    final borderColor = isDarkMode ? AppTheme.darkBorder : AppTheme.lightBorder;
    final bg = isDarkMode ? AppTheme.darkBg : AppTheme.lightBg;

    final rfid = student['rfid_uid'] as String?;
    final hasRfid = rfid != null && rfid.isNotEmpty;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.credit_card, size: 20, color: subTextColor),
              const SizedBox(width: 8),
              Text(
                'RFID Card Status',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: textColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (hasRfid) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: AppTheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppTheme.primary.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.check_circle,
                    color: AppTheme.primary,
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Assigned ID: $rfid',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.primary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _unassign(context),
                icon: const Icon(Icons.remove_circle_outline),
                label: const Text('Unassign RFID'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.error,
                  side: const BorderSide(color: AppTheme.error),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ] else ...[
            Text(
              'No RFID card assigned to this student.',
              style: TextStyle(color: subTextColor, fontSize: 13),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _showAssignDialog(context),
                icon: const Icon(Icons.add_circle_outline),
                label: const Text('Assign RFID'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _AssignRfidDialog extends StatefulWidget {
  final Map<String, dynamic> student;
  final bool isDarkMode;
  final VoidCallback onAssigned;

  const _AssignRfidDialog({
    required this.student,
    required this.isDarkMode,
    required this.onAssigned,
  });

  @override
  State<_AssignRfidDialog> createState() => _AssignRfidDialogState();
}

class _AssignRfidDialogState extends State<_AssignRfidDialog> {
  final _manualController = TextEditingController();
  List<Map<String, dynamic>> _unassignedScans = [];
  bool _isLoading = true;
  bool _isSaving = false;
  late RealtimeChannel _channel;

  @override
  void initState() {
    super.initState();
    _loadUnassignedScans();
    _setupRealtime();
  }

  @override
  void dispose() {
    _manualController.dispose();
    Supabase.instance.client.removeChannel(_channel);
    super.dispose();
  }

  void _setupRealtime() {
    _channel = Supabase.instance.client
        .channel('public:unassigned_rfid_scans')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'unassigned_rfid_scans',
          callback: (payload) {
            _loadUnassignedScans();
          },
        )
        .subscribe();
  }

  Future<void> _loadUnassignedScans() async {
    try {
      final res = await Supabase.instance.client
          .from('unassigned_rfid_scans')
          .select()
          .order('scanned_at', ascending: false)
          .limit(10);
      if (mounted) {
        setState(() {
          _unassignedScans = List<Map<String, dynamic>>.from(res);
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _assign(String rfid) async {
    if (rfid.isEmpty) return;
    setState(() => _isSaving = true);

    try {
      // 1. Check if already assigned
      final existingUser = await Supabase.instance.client
          .from('users')
          .select('name, university_id')
          .eq('rfid_uid', rfid)
          .maybeSingle();

      if (existingUser != null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Error: RFID already assigned to ${existingUser['name']} (${existingUser['university_id']})',
            ),
            backgroundColor: AppTheme.error,
            duration: const Duration(seconds: 4),
          ),
        );
        setState(() => _isSaving = false);
        return;
      }

      // 2. Assign to current student
      await Supabase.instance.client
          .from('users')
          .update({'rfid_uid': rfid})
          .eq('id', widget.student['id']);

      // 3. Delete from unassigned
      await Supabase.instance.client
          .from('unassigned_rfid_scans')
          .delete()
          .eq('rfid_uid', rfid);

      if (!mounted) return;
      Navigator.pop(context); // Close dialog
      widget.onAssigned();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('RFID successfully assigned!'),
          backgroundColor: AppTheme.success,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: AppTheme.error),
      );
      setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bg = widget.isDarkMode ? AppTheme.darkCard : AppTheme.lightSurface;
    final textColor = widget.isDarkMode
        ? AppTheme.darkText
        : AppTheme.lightText;
    final subColor = widget.isDarkMode
        ? AppTheme.darkTextSecondary
        : AppTheme.lightTextSecondary;

    return Dialog(
      backgroundColor: bg,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Assign RFID',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Assign to ${widget.student['name']}',
              style: TextStyle(fontSize: 14, color: subColor),
            ),
            const SizedBox(height: 24),

            // Auto detected scans
            Row(
              children: [
                Icon(Icons.wifi_tethering, size: 18, color: AppTheme.primary),
                const SizedBox(width: 8),
                Text(
                  'Recent Scans (Auto-updates)',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: textColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (_isLoading)
              const Center(
                child: CircularProgressIndicator(color: AppTheme.primary),
              )
            else if (_unassignedScans.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.primary.withOpacity(0.1)),
                ),
                child: Text(
                  'No recent unassigned scans found. Tap a card on the scanner!',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: subColor, fontSize: 13),
                ),
              )
            else
              Container(
                constraints: const BoxConstraints(maxHeight: 180),
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: _unassignedScans.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final scan = _unassignedScans[index];
                    final rfid = scan['rfid_uid'];

                    // Format time
                    final time = DateTime.parse(scan['scanned_at']).toLocal();
                    final timeStr = DateFormat('hh:mm a').format(time);

                    return InkWell(
                      onTap: _isSaving ? null : () => _assign(rfid),
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: widget.isDarkMode
                              ? AppTheme.darkBg
                              : AppTheme.lightBg,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: widget.isDarkMode
                                ? AppTheme.darkBorder
                                : AppTheme.lightBorder,
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.credit_card,
                              size: 20,
                              color: AppTheme.primary,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    rfid,
                                    style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      color: textColor,
                                    ),
                                  ),
                                  Text(
                                    'Scanned at $timeStr',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: subColor,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(
                              Icons.chevron_right,
                              color: AppTheme.primary,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),

            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(child: Divider(color: subColor.withOpacity(0.3))),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Text(
                    'OR',
                    style: TextStyle(
                      color: subColor,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Expanded(child: Divider(color: subColor.withOpacity(0.3))),
              ],
            ),
            const SizedBox(height: 24),

            // Manual Entry
            Text(
              'Manual Entry',
              style: TextStyle(fontWeight: FontWeight.w600, color: textColor),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _manualController,
              style: TextStyle(color: textColor),
              textCapitalization: TextCapitalization.characters,
              decoration: InputDecoration(
                hintText: 'Enter RFID Manually...',
                hintStyle: TextStyle(color: subColor),
                filled: true,
                fillColor: widget.isDarkMode
                    ? AppTheme.darkBg
                    : AppTheme.lightBg,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Action Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: _isSaving ? null : () => Navigator.pop(context),
                  child: Text('Cancel', style: TextStyle(color: subColor)),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _isSaving
                      ? null
                      : () => _assign(
                          _manualController.text.trim().toUpperCase(),
                        ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: _isSaving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Assign'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─── SCHEDULE TAB ───────────────────────────────────────────
class _AdminScheduleTab extends StatefulWidget {
  final bool isDarkMode;
  const _AdminScheduleTab({required this.isDarkMode});

  @override
  State<_AdminScheduleTab> createState() => _AdminScheduleTabState();
}

class _AdminScheduleTabState extends State<_AdminScheduleTab> {
  List<Map<String, dynamic>> _schedules = [];
  bool _isLoading = true;
  String _selectedDay = DateFormat('EEEE').format(DateTime.now());

  final List<String> _days = [
    'Saturday',
    'Sunday',
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
  ];

  List<Map<String, dynamic>> _departments = [];
  List<Map<String, dynamic>> _sessions = [];
  String? _selectedDepartmentId;
  String? _selectedDepartmentName;
  String? _selectedSessionName;

  @override
  void initState() {
    super.initState();
    _initData();
  }

  Future<void> _initData() async {
    try {
      final res = await Supabase.instance.client
          .from('departments')
          .select('*, sessions(*)')
          .order('name');
      if (mounted) {
        setState(() {
          _departments = List<Map<String, dynamic>>.from(res);
          if (_departments.isNotEmpty) {
            final firstDept = _departments.first;
            _selectedDepartmentId = firstDept['id'];
            _selectedDepartmentName = firstDept['name'];
            _sessions = List<Map<String, dynamic>>.from(
              firstDept['sessions'] ?? [],
            );
            if (_sessions.isNotEmpty) {
              _selectedSessionName = _sessions.first['name'];
            }
          }
        });
      }
      await _loadSchedules();
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _onDepartmentChanged(String? deptId) {
    setState(() {
      _selectedDepartmentId = deptId;
      _selectedSessionName = null;
      if (deptId != null) {
        final dept = _departments.firstWhere((d) => d['id'] == deptId);
        _selectedDepartmentName = dept['name'];
        _sessions = List<Map<String, dynamic>>.from(dept['sessions'] ?? []);
        if (_sessions.isNotEmpty) {
          _selectedSessionName = _sessions.first['name'];
        }
      } else {
        _selectedDepartmentName = null;
        _sessions = [];
      }
      _isLoading = true;
    });
    _loadSchedules();
  }

  Future<void> _loadSchedules() async {
    if (_selectedDepartmentName == null || _selectedSessionName == null) {
      if (mounted) {
        setState(() {
          _schedules = [];
          _isLoading = false;
        });
      }
      return;
    }

    try {
      final schedules = await Supabase.instance.client
          .from('class_schedules')
          .select('*, subjects(name, code)')
          .eq('department', _selectedDepartmentName!)
          .eq('section', _selectedSessionName!)
          .eq('day_name', _selectedDay)
          .eq('is_active', true)
          .order('start_time');

      setState(() {
        _schedules = List<Map<String, dynamic>>.from(schedules);
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteSchedule(String id) async {
    try {
      await Supabase.instance.client
          .from('class_schedules')
          .delete()
          .eq('id', id);
      _loadSchedules();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: AppTheme.error),
      );
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
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (_) {
              if (_selectedDepartmentName == null ||
                  _selectedSessionName == null) {
                return const Center(
                  child: Text(
                    'Please select a department and session first',
                    style: TextStyle(color: Colors.white),
                  ),
                );
              }
              return _AddScheduleSheet(
                isDarkMode: widget.isDarkMode,
                selectedDay: _selectedDay,
                selectedDepartmentName: _selectedDepartmentName!,
                selectedSessionName: _selectedSessionName!,
              );
            },
          ).then((_) => _initData());
        },
        backgroundColor: AppTheme.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Class Schedule',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          color: textColor,
                          letterSpacing: -0.5,
                        ),
                      ),
                      IconButton(
                        onPressed: () {
                          showModalBottomSheet(
                            context: context,
                            isScrollControlled: true,
                            backgroundColor: Colors.transparent,
                            builder: (_) => _ManageDepartmentsSheet(
                              isDarkMode: widget.isDarkMode,
                            ),
                          ).then((_) => _initData());
                        },
                        icon: const Icon(Icons.settings),
                        color: AppTheme.primary,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: _selectedDepartmentId,
                          dropdownColor: cardColor,
                          style: TextStyle(color: textColor, fontSize: 13),
                          decoration: InputDecoration(
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 10,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          items: _departments
                              .map(
                                (d) => DropdownMenuItem<String>(
                                  value: d['id'],
                                  child: Text(d['name']),
                                ),
                              )
                              .toList(),
                          onChanged: _onDepartmentChanged,
                          hint: Text(
                            'Dept',
                            style: TextStyle(color: subTextColor),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: _selectedSessionName,
                          dropdownColor: cardColor,
                          style: TextStyle(color: textColor, fontSize: 13),
                          decoration: InputDecoration(
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 10,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          items: _sessions
                              .map(
                                (s) => DropdownMenuItem<String>(
                                  value: s['name'],
                                  child: Text(s['name']),
                                ),
                              )
                              .toList(),
                          onChanged: _selectedDepartmentId == null
                              ? null
                              : (val) {
                                  setState(() {
                                    _selectedSessionName = val;
                                    _isLoading = true;
                                  });
                                  _loadSchedules();
                                },
                          hint: Text(
                            'Session',
                            style: TextStyle(color: subTextColor),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 38,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: _days.length,
                      itemBuilder: (_, i) {
                        final day = _days[i];
                        final isSelected = _selectedDay == day;
                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedDay = day;
                              _isLoading = true;
                            });
                            _loadSchedules();
                          },
                          child: Container(
                            margin: const EdgeInsets.only(right: 8),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: isSelected ? AppTheme.primary : cardColor,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: isSelected
                                    ? AppTheme.primary
                                    : borderColor,
                              ),
                            ),
                            child: Text(
                              day.substring(0, 3),
                              style: TextStyle(
                                color: isSelected ? Colors.white : subTextColor,
                                fontSize: 13,
                                fontWeight: isSelected
                                    ? FontWeight.w600
                                    : FontWeight.w400,
                              ),
                            ),
                          ),
                        );
                      },
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
                  : _schedules.isEmpty
                  ? Center(
                      child: Text(
                        'No classes on $_selectedDay',
                        style: TextStyle(color: subTextColor),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      itemCount: _schedules.length,
                      itemBuilder: (context, index) {
                        final cls = _schedules[index];
                        final subject = cls['subjects'];
                        final start = cls['start_time'].toString().substring(
                          0,
                          5,
                        );
                        final end = cls['end_time'].toString().substring(0, 5);
                        final isLab = cls['lab_group'] != 'all';

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
                                height: 52,
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
                                  crossAxisAlignment: CrossAxisAlignment.start,
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
                                    Text(
                                      subject?['name'] ?? '',
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: textColor,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    Text(
                                      '$start - $end',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: subTextColor,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color:
                                      (isLab
                                              ? AppTheme.accent
                                              : AppTheme.primary)
                                          .withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  isLab ? 'Lab ${cls['lab_group']}' : 'Theory',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: isLab
                                        ? AppTheme.accent
                                        : AppTheme.primary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              IconButton(
                                icon: const Icon(
                                  Icons.delete_outline,
                                  color: AppTheme.error,
                                  size: 20,
                                ),
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                                onPressed: () {
                                  showDialog(
                                    context: context,
                                    builder: (ctx) => AlertDialog(
                                      backgroundColor: cardColor,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      title: Text(
                                        'Delete Schedule?',
                                        style: TextStyle(color: textColor),
                                      ),
                                      content: Text(
                                        'Are you sure you want to delete ${subject?['code']} from $_selectedDay?',
                                        style: TextStyle(color: subTextColor),
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed: () => Navigator.pop(ctx),
                                          child: const Text('Cancel'),
                                        ),
                                        TextButton(
                                          onPressed: () {
                                            Navigator.pop(ctx);
                                            _deleteSchedule(cls['id']);
                                          },
                                          child: const Text(
                                            'Delete',
                                            style: TextStyle(
                                              color: AppTheme.error,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                },
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
    );
  }
}

// ─── PROFILE TAB ───────────────────────────────────────────
class _AdminProfileTab extends StatelessWidget {
  final bool isDarkMode;
  final Function(bool) onThemeToggle;

  const _AdminProfileTab({
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

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              const SizedBox(height: 20),
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
                child: const Icon(
                  Icons.admin_panel_settings,
                  color: Colors.white,
                  size: 38,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Administrator',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: textColor,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'IRE Department • 2021-22',
                style: TextStyle(color: subTextColor, fontSize: 14),
              ),

              const SizedBox(height: 24),

              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: borderColor),
                ),
                child: Column(
                  children: [
                    ListTile(
                      leading: Icon(
                        isDark ? Icons.light_mode : Icons.dark_mode,
                        color: textColor,
                        size: 20,
                      ),
                      title: Text(
                        isDark ? 'Light Mode' : 'Dark Mode',
                        style: TextStyle(
                          color: textColor,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      trailing: Icon(
                        Icons.chevron_right,
                        color: textColor,
                        size: 20,
                      ),
                      onTap: () => onThemeToggle(!isDark),
                    ),
                    Divider(color: borderColor, height: 1),
                    ListTile(
                      leading: Icon(
                        Icons.lock_outline,
                        color: textColor,
                        size: 20,
                      ),
                      title: Text(
                        'Change Password',
                        style: TextStyle(
                          color: textColor,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      trailing: Icon(
                        Icons.chevron_right,
                        color: textColor,
                        size: 20,
                      ),
                      onTap: () {
                        showDialog(
                          context: context,
                          builder: (_) =>
                              ChangePasswordDialog(isDarkMode: isDarkMode),
                        );
                      },
                    ),
                    Divider(color: borderColor, height: 1),
                    ListTile(
                      leading: const Icon(
                        Icons.logout,
                        color: AppTheme.error,
                        size: 20,
                      ),
                      title: const Text(
                        'Sign Out',
                        style: TextStyle(
                          color: AppTheme.error,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      trailing: const Icon(
                        Icons.chevron_right,
                        color: AppTheme.error,
                        size: 20,
                      ),
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
            ],
          ),
        ),
      ),
    );
  }
}

class _AllUnassignedScansDialog extends StatefulWidget {
  final bool isDarkMode;
  const _AllUnassignedScansDialog({required this.isDarkMode});

  @override
  State<_AllUnassignedScansDialog> createState() =>
      _AllUnassignedScansDialogState();
}

class _AllUnassignedScansDialogState extends State<_AllUnassignedScansDialog> {
  List<Map<String, dynamic>> _unassignedScans = [];
  bool _isLoading = true;
  late RealtimeChannel _channel;

  @override
  void initState() {
    super.initState();
    _loadScans();
    _setupRealtime();
  }

  @override
  void dispose() {
    Supabase.instance.client.removeChannel(_channel);
    super.dispose();
  }

  void _setupRealtime() {
    _channel = Supabase.instance.client
        .channel('public:unassigned_rfid_scans_all')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'unassigned_rfid_scans',
          callback: (payload) {
            _loadScans();
          },
        )
        .subscribe();
  }

  Future<void> _loadScans() async {
    try {
      final res = await Supabase.instance.client
          .from('unassigned_rfid_scans')
          .select()
          .order('scanned_at', ascending: false);
      if (mounted) {
        setState(() {
          _unassignedScans = List<Map<String, dynamic>>.from(res);
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteScan(String rfid) async {
    try {
      await Supabase.instance.client
          .from('unassigned_rfid_scans')
          .delete()
          .eq('rfid_uid', rfid);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: AppTheme.error),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final bg = widget.isDarkMode ? AppTheme.darkCard : AppTheme.lightSurface;
    final textColor = widget.isDarkMode
        ? AppTheme.darkText
        : AppTheme.lightText;
    final subColor = widget.isDarkMode
        ? AppTheme.darkTextSecondary
        : AppTheme.lightTextSecondary;

    return Dialog(
      backgroundColor: bg,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Unassigned Scans',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: Icon(Icons.close, color: subColor),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'These RFIDs were scanned but are not assigned to any student.',
              style: TextStyle(fontSize: 13, color: subColor),
            ),
            const SizedBox(height: 24),

            if (_isLoading)
              const Center(
                child: CircularProgressIndicator(color: AppTheme.primary),
              )
            else if (_unassignedScans.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.primary.withOpacity(0.1)),
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.wifi_tethering_off,
                      size: 40,
                      color: AppTheme.primary.withOpacity(0.5),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'No unassigned scans found.',
                      style: TextStyle(color: subColor, fontSize: 14),
                    ),
                  ],
                ),
              )
            else
              Container(
                constraints: const BoxConstraints(maxHeight: 350),
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: _unassignedScans.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final scan = _unassignedScans[index];
                    final rfid = scan['rfid_uid'];

                    final time = DateTime.parse(scan['scanned_at']).toLocal();
                    final dateStr =
                        '${time.year}-${time.month.toString().padLeft(2, '0')}-${time.day.toString().padLeft(2, '0')} ${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';

                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: widget.isDarkMode
                            ? AppTheme.darkBg
                            : AppTheme.lightBg,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: widget.isDarkMode
                              ? AppTheme.darkBorder
                              : AppTheme.lightBorder,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppTheme.warning.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.credit_card,
                              size: 20,
                              color: AppTheme.warning,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  rfid,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    color: textColor,
                                  ),
                                ),
                                Text(
                                  dateStr,
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: subColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            onPressed: () => _deleteScan(rfid),
                            icon: const Icon(
                              Icons.delete_outline,
                              color: AppTheme.error,
                              size: 20,
                            ),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
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
    );
  }
}

class _AddScheduleSheet extends StatefulWidget {
  final bool isDarkMode;
  final String selectedDay;
  final String selectedDepartmentName;
  final String selectedSessionName;

  const _AddScheduleSheet({
    required this.isDarkMode,
    required this.selectedDay,
    required this.selectedDepartmentName,
    required this.selectedSessionName,
  });

  @override
  State<_AddScheduleSheet> createState() => _AddScheduleSheetState();
}

class _AddScheduleSheetState extends State<_AddScheduleSheet> {
  final _codeController = TextEditingController();
  final _nameController = TextEditingController();

  TimeOfDay? _startTime;
  TimeOfDay? _endTime;
  String _labGroup = 'all';
  bool _isLoading = false;

  Future<void> _selectTime(bool isStart) async {
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: widget.isDarkMode
                ? const ColorScheme.dark(primary: AppTheme.primary)
                : const ColorScheme.light(primary: AppTheme.primary),
          ),
          child: child!,
        );
      },
    );

    if (time != null && mounted) {
      setState(() {
        if (isStart) {
          _startTime = time;
        } else {
          _endTime = time;
        }
      });
    }
  }

  Future<void> _saveSchedule() async {
    if (_codeController.text.trim().isEmpty ||
        _nameController.text.trim().isEmpty ||
        _startTime == null ||
        _endTime == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please fill all fields')));
      return;
    }

    setState(() => _isLoading = true);

    try {
      final code = _codeController.text.trim();
      final name = _nameController.text.trim();

      // 1. Find or create subject
      String? subjectId;
      final existingSubjectRes = await Supabase.instance.client
          .from('subjects')
          .select('id')
          .eq('code', code)
          .maybeSingle();

      if (existingSubjectRes != null) {
        subjectId = existingSubjectRes['id'];
      } else {
        final insertRes = await Supabase.instance.client
            .from('subjects')
            .insert({
              'code': code,
              'name': name,
              'department': widget.selectedDepartmentName,
              'section': widget.selectedSessionName,
            })
            .select('id')
            .single();
        subjectId = insertRes['id'];
      }

      // 2. Insert schedule
      final startStr =
          '${_startTime!.hour.toString().padLeft(2, '0')}:${_startTime!.minute.toString().padLeft(2, '0')}:00';
      final endStr =
          '${_endTime!.hour.toString().padLeft(2, '0')}:${_endTime!.minute.toString().padLeft(2, '0')}:00';

      await Supabase.instance.client.from('class_schedules').insert({
        'subject_id': subjectId,
        'department': widget.selectedDepartmentName,
        'section': widget.selectedSessionName,
        'day_name': widget.selectedDay,
        'start_time': startStr,
        'end_time': endStr,
        'lab_group': _labGroup,
        'is_active': true,
      });

      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppTheme.error),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bg = widget.isDarkMode ? AppTheme.darkCard : AppTheme.lightSurface;
    final textColor = widget.isDarkMode
        ? AppTheme.darkText
        : AppTheme.lightText;
    final subColor = widget.isDarkMode
        ? AppTheme.darkTextSecondary
        : AppTheme.lightTextSecondary;

    return Container(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        top: 24,
        left: 24,
        right: 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Add Schedule',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: Icon(Icons.close, color: subColor),
              ),
            ],
          ),
          Text('Day: ${widget.selectedDay}', style: TextStyle(color: subColor)),
          const SizedBox(height: 24),

          TextField(
            controller: _codeController,
            style: TextStyle(color: textColor),
            decoration: InputDecoration(
              labelText: 'Subject Code (e.g. CSE-412)',
              labelStyle: TextStyle(color: subColor),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _nameController,
            style: TextStyle(color: textColor),
            decoration: InputDecoration(
              labelText: 'Subject Name (e.g. App Dev)',
              labelStyle: TextStyle(color: subColor),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          const SizedBox(height: 16),

          Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: () => _selectTime(true),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      border: Border.all(color: subColor.withOpacity(0.3)),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Text(
                        _startTime?.format(context) ?? 'Start Time',
                        style: TextStyle(
                          color: _startTime == null ? subColor : textColor,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: InkWell(
                  onTap: () => _selectTime(false),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      border: Border.all(color: subColor.withOpacity(0.3)),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Text(
                        _endTime?.format(context) ?? 'End Time',
                        style: TextStyle(
                          color: _endTime == null ? subColor : textColor,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          DropdownButtonFormField<String>(
            value: _labGroup,
            dropdownColor: bg,
            style: TextStyle(color: textColor),
            decoration: InputDecoration(
              labelText: 'Class Type / Lab Group',
              labelStyle: TextStyle(color: subColor),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            items: const [
              DropdownMenuItem(value: 'all', child: Text('Theory (All)')),
              DropdownMenuItem(value: 'A', child: Text('Lab - Group A')),
              DropdownMenuItem(value: 'B', child: Text('Lab - Group B')),
            ],
            onChanged: (val) {
              if (val != null) setState(() => _labGroup = val);
            },
          ),
          const SizedBox(height: 24),

          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _saveSchedule,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isLoading
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Text(
                      'Add to Schedule',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ManageDepartmentsSheet extends StatefulWidget {
  final bool isDarkMode;
  const _ManageDepartmentsSheet({required this.isDarkMode});

  @override
  State<_ManageDepartmentsSheet> createState() =>
      _ManageDepartmentsSheetState();
}

class _ManageDepartmentsSheetState extends State<_ManageDepartmentsSheet> {
  List<Map<String, dynamic>> _departments = [];
  bool _isLoading = true;

  final _deptNameController = TextEditingController();
  final _sessionNameController = TextEditingController();

  String? _expandedDeptId;

  @override
  void initState() {
    super.initState();
    _loadDepartments();
  }

  Future<void> _loadDepartments() async {
    try {
      final res = await Supabase.instance.client
          .from('departments')
          .select('*, sessions(*)')
          .order('name');
      if (mounted) {
        setState(() {
          _departments = List<Map<String, dynamic>>.from(res);
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _addDepartment() async {
    final name = _deptNameController.text.trim();
    if (name.isEmpty) return;

    setState(() => _isLoading = true);
    try {
      await Supabase.instance.client.from('departments').insert({
        'code': name, // Store name in code as well
        'name': name,
      });
      _deptNameController.clear();
      await _loadDepartments();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
      setState(() => _isLoading = false);
    }
  }

  Future<void> _addSession(String deptId) async {
    final name = _sessionNameController.text.trim();
    if (name.isEmpty) return;

    setState(() => _isLoading = true);
    try {
      await Supabase.instance.client.from('sessions').insert({
        'department_id': deptId,
        'name': name,
      });
      _sessionNameController.clear();
      await _loadDepartments();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
      setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteDepartment(String id) async {
    setState(() => _isLoading = true);
    try {
      await Supabase.instance.client.from('departments').delete().eq('id', id);
      await _loadDepartments();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
      setState(() => _isLoading = false);
    }
  }

  Future<void> _editDepartment(Map<String, dynamic> dept) async {
    final controller = TextEditingController(text: dept['name']);
    final newName = await showDialog<String>(
      context: context,
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return AlertDialog(
          backgroundColor: isDark ? AppTheme.darkCard : AppTheme.lightSurface,
          title: Text(
            'Edit Department',
            style: TextStyle(
              color: isDark ? AppTheme.darkText : AppTheme.lightText,
            ),
          ),
          content: TextField(
            controller: controller,
            style: TextStyle(
              color: isDark ? AppTheme.darkText : AppTheme.lightText,
            ),
            decoration: InputDecoration(
              hintText: 'Department Name',
              hintStyle: TextStyle(
                color: isDark
                    ? AppTheme.darkTextSecondary
                    : AppTheme.lightTextSecondary,
              ),
              enabledBorder: OutlineInputBorder(
                borderSide: BorderSide(
                  color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder,
                ),
              ),
              focusedBorder: const OutlineInputBorder(
                borderSide: BorderSide(color: AppTheme.primary),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, controller.text.trim()),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
              ),
              child: const Text('Save', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );

    if (newName == null || newName.isEmpty || newName == dept['name']) return;

    setState(() => _isLoading = true);
    try {
      final oldName = dept['name'];

      // Update department
      await Supabase.instance.client
          .from('departments')
          .update({'name': newName, 'code': newName})
          .eq('id', dept['id']);

      // Update related records
      await Supabase.instance.client
          .from('users')
          .update({'department': newName})
          .eq('department', oldName);
      await Supabase.instance.client
          .from('class_schedules')
          .update({'department': newName})
          .eq('department', oldName);

      await _loadDepartments();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
      setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteSession(String id) async {
    setState(() => _isLoading = true);
    try {
      await Supabase.instance.client.from('sessions').delete().eq('id', id);
      await _loadDepartments();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bg = widget.isDarkMode ? AppTheme.darkCard : AppTheme.lightSurface;
    final textColor = widget.isDarkMode
        ? AppTheme.darkText
        : AppTheme.lightText;
    final subColor = widget.isDarkMode
        ? AppTheme.darkTextSecondary
        : AppTheme.lightTextSecondary;

    return Container(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        top: 24,
        left: 24,
        right: 24,
      ),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.8,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Manage Departments',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: Icon(Icons.close, color: subColor),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _deptNameController,
                  style: TextStyle(color: textColor, fontSize: 14),
                  decoration: InputDecoration(
                    hintText: 'Department Name (e.g. IRE)',
                    hintStyle: TextStyle(color: subColor),
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 12,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: _isLoading ? null : _addDepartment,
                icon: const Icon(
                  Icons.add_circle,
                  color: AppTheme.primary,
                  size: 28,
                ),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_isLoading)
            const Center(
              child: CircularProgressIndicator(color: AppTheme.primary),
            )
          else if (_departments.isEmpty)
            Expanded(
              child: Center(
                child: Text(
                  'No departments found',
                  style: TextStyle(color: subColor),
                ),
              ),
            )
          else
            Expanded(
              child: ListView.builder(
                itemCount: _departments.length,
                itemBuilder: (context, index) {
                  final dept = _departments[index];
                  final isExpanded = _expandedDeptId == dept['id'];
                  final sessions = List<Map<String, dynamic>>.from(
                    dept['sessions'] ?? [],
                  );

                  return Card(
                    color: widget.isDarkMode
                        ? AppTheme.darkBg
                        : AppTheme.lightBg,
                    margin: const EdgeInsets.only(bottom: 8),
                    child: Column(
                      children: [
                        ListTile(
                          title: Text(
                            '${dept['name']}',
                            style: TextStyle(
                              color: textColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(
                                  Icons.edit_outlined,
                                  color: AppTheme.primary,
                                  size: 20,
                                ),
                                onPressed: () => _editDepartment(dept),
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.delete_outline,
                                  color: AppTheme.error,
                                  size: 20,
                                ),
                                onPressed: () => _deleteDepartment(dept['id']),
                              ),
                              Icon(
                                isExpanded
                                    ? Icons.expand_less
                                    : Icons.expand_more,
                                color: subColor,
                              ),
                            ],
                          ),
                          onTap: () {
                            setState(() {
                              _expandedDeptId = isExpanded ? null : dept['id'];
                            });
                          },
                        ),
                        if (isExpanded)
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            child: Column(
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: TextField(
                                        controller: _sessionNameController,
                                        style: TextStyle(
                                          color: textColor,
                                          fontSize: 13,
                                        ),
                                        decoration: InputDecoration(
                                          hintText:
                                              'New Session (e.g. 2021-22)',
                                          hintStyle: TextStyle(color: subColor),
                                          isDense: true,
                                          contentPadding:
                                              const EdgeInsets.symmetric(
                                                horizontal: 12,
                                                vertical: 10,
                                              ),
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    TextButton(
                                      onPressed: () => _addSession(dept['id']),
                                      child: const Text('Add Session'),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                if (sessions.isEmpty)
                                  Text(
                                    'No sessions added yet.',
                                    style: TextStyle(
                                      color: subColor,
                                      fontSize: 12,
                                    ),
                                  )
                                else
                                  ...sessions
                                      .map(
                                        (s) => ListTile(
                                          dense: true,
                                          title: Text(
                                            s['name'],
                                            style: TextStyle(color: textColor),
                                          ),
                                          trailing: IconButton(
                                            icon: const Icon(
                                              Icons.delete_outline,
                                              color: AppTheme.error,
                                              size: 18,
                                            ),
                                            onPressed: () =>
                                                _deleteSession(s['id']),
                                          ),
                                        ),
                                      )
                                      .toList(),
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
    );
  }
}
