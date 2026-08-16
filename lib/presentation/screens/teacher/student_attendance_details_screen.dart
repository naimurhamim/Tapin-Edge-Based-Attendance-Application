import 'dart:math';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/theme/app_theme.dart';

class StudentAttendanceDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> student;
  const StudentAttendanceDetailsScreen({super.key, required this.student});

  @override
  State<StudentAttendanceDetailsScreen> createState() =>
      _StudentAttendanceDetailsScreenState();
}

class _StudentAttendanceDetailsScreenState
    extends State<StudentAttendanceDetailsScreen>
    with SingleTickerProviderStateMixin {
  bool _isLoading = true;
  List<Map<String, dynamic>> _subjectStats = [];
  late AnimationController _animController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _animation = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOutCubic,
    );
    _loadData();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      final studentId = widget.student['id'];
      final dept = widget.student['department'];
      final section = widget.student['section'];

      final subjects = await Supabase.instance.client
          .from('subjects')
          .select()
          .eq('department', dept)
          .eq('section', section);

      final logs = await Supabase.instance.client
          .from('attendance_logs')
          .select()
          .eq('student_id', studentId);

      List<Map<String, dynamic>> stats = [];
      for (final subject in subjects) {
        final subjectLogs = logs
            .where((l) => l['subject_id'] == subject['id'])
            .toList();
        final total = subjectLogs.length;
        final present = subjectLogs
            .where((l) => l['status'] == 'present')
            .length;
        final absent = subjectLogs.where((l) => l['status'] == 'absent').length;
        final percentage = total > 0 ? (present / total * 100) : 0.0;

        stats.add({
          'subject': subject,
          'total': total,
          'present': present,
          'absent': absent,
          'percentage': percentage,
        });
      }

      // Sort: lowest attendance first
      stats.sort(
        (a, b) =>
            (a['percentage'] as double).compareTo(b['percentage'] as double),
      );

      setState(() {
        _subjectStats = stats;
        _isLoading = false;
      });

      _animController.forward();
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  // ─── Computed overall stats ────────────────────────────────
  int get _totalPresent =>
      _subjectStats.fold(0, (sum, s) => sum + (s['present'] as int));
  int get _totalAbsent =>
      _subjectStats.fold(0, (sum, s) => sum + (s['absent'] as int));
  int get _totalClasses =>
      _subjectStats.fold(0, (sum, s) => sum + (s['total'] as int));
  double get _overallPct =>
      _totalClasses > 0 ? _totalPresent / _totalClasses * 100 : 0.0;

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

    final studentName = widget.student['name'] ?? 'Student';
    final universityId = widget.student['university_id'] ?? '';

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        elevation: 0,
        iconTheme: IconThemeData(color: textColor),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Analytics',
              style: TextStyle(
                color: textColor,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            Text(
              universityId,
              style: TextStyle(color: subTextColor, fontSize: 12),
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: AppTheme.primary),
              )
            : _subjectStats.isEmpty
            ? Center(
                child: Text(
                  'No attendance records found.',
                  style: TextStyle(color: subTextColor),
                ),
              )
            : AnimatedBuilder(
                animation: _animation,
                builder: (context, _) {
                  return ListView(
                    padding: const EdgeInsets.all(20),
                    children: [
                      // ── Student Header ──────────────────
                      _buildStudentHeader(studentName, textColor, subTextColor),
                      const SizedBox(height: 20),

                      // ── Pie Chart + Overall Stats ───────
                      _buildOverallCard(
                        cardColor,
                        borderColor,
                        textColor,
                        subTextColor,
                      ),
                      const SizedBox(height: 20),

                      // ── Subject bar charts ───────────────
                      Text(
                        'Per Subject Breakdown',
                        style: TextStyle(
                          color: textColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 12),

                      ..._subjectStats.map(
                        (stat) => _buildSubjectCard(
                          stat,
                          cardColor,
                          borderColor,
                          textColor,
                          subTextColor,
                        ),
                      ),
                    ],
                  );
                },
              ),
      ),
    );
  }

  // ─── Student header card ───────────────────────────────────
  Widget _buildStudentHeader(String name, Color textColor, Color subTextColor) {
    return Row(
      children: [
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppTheme.primary, AppTheme.accent],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Center(
            child: Text(
              name.isNotEmpty ? name[0].toUpperCase() : 'S',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 26,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                style: TextStyle(
                  color: textColor,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                widget.student['university_id'] ?? '',
                style: TextStyle(color: AppTheme.primary, fontSize: 13),
              ),
              Text(
                '${widget.student['department']} · ${widget.student['section']}',
                style: TextStyle(color: subTextColor, fontSize: 12),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ─── Overall pie chart card ────────────────────────────────
  Widget _buildOverallCard(
    Color cardColor,
    Color borderColor,
    Color textColor,
    Color subTextColor,
  ) {
    final pct = _overallPct;
    final color = pct >= 90
        ? AppTheme.success
        : pct >= 75
        ? AppTheme.warning
        : AppTheme.error;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        children: [
          Text(
            'Overall Attendance',
            style: TextStyle(
              color: textColor,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              // Pie chart
              SizedBox(
                width: 140,
                height: 140,
                child: CustomPaint(
                  painter: _PieChartPainter(
                    presentPct: pct / 100,
                    animValue: _animation.value,
                    presentColor: color,
                    absentColor: color.withValues(alpha: 0.15),
                  ),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${pct.toStringAsFixed(1)}%',
                          style: TextStyle(
                            color: color,
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Text(
                          'Overall',
                          style: TextStyle(color: subTextColor, fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 24),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _legendItem(
                      'Present',
                      _totalPresent,
                      AppTheme.success,
                      textColor,
                      subTextColor,
                    ),
                    const SizedBox(height: 12),
                    _legendItem(
                      'Absent',
                      _totalAbsent,
                      AppTheme.error,
                      textColor,
                      subTextColor,
                    ),
                    const SizedBox(height: 12),
                    _legendItem(
                      'Total Classes',
                      _totalClasses,
                      AppTheme.primary,
                      textColor,
                      subTextColor,
                    ),
                    const SizedBox(height: 16),
                    // Status badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        pct >= 75 ? '✓ Good Standing' : '⚠ At Risk',
                        style: TextStyle(
                          color: color,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _legendItem(
    String label,
    int value,
    Color color,
    Color textColor,
    Color subTextColor,
  ) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: TextStyle(color: subTextColor, fontSize: 12),
          ),
        ),
        Text(
          '$value',
          style: TextStyle(
            color: textColor,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  // ─── Per-subject card with animated bar ───────────────────
  Widget _buildSubjectCard(
    Map<String, dynamic> stat,
    Color cardColor,
    Color borderColor,
    Color textColor,
    Color subTextColor,
  ) {
    final subject = stat['subject'];
    final pct = stat['percentage'] as double;
    final isLow = pct < 75;
    final color = pct >= 90
        ? AppTheme.success
        : pct >= 75
        ? AppTheme.warning
        : AppTheme.error;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isLow ? AppTheme.error.withValues(alpha: 0.04) : cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isLow ? AppTheme.error.withValues(alpha: 0.35) : borderColor,
          width: isLow ? 1.5 : 1.0,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          subject['code'],
                          style: const TextStyle(
                            color: AppTheme.primary,
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                          ),
                        ),
                        if (isLow) ...[
                          const SizedBox(width: 6),
                          const Icon(
                            Icons.warning_amber_rounded,
                            color: AppTheme.error,
                            size: 14,
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subject['name'],
                      style: TextStyle(
                        color: textColor,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${pct.toStringAsFixed(1)}%',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Animated progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: (pct / 100) * _animation.value,
              backgroundColor: color.withValues(alpha: 0.12),
              valueColor: AlwaysStoppedAnimation<Color>(color),
              minHeight: 8,
            ),
          ),
          const SizedBox(height: 10),
          // Mini stats row
          Row(
            children: [
              _miniStat(
                '✓ Present',
                stat['present'],
                AppTheme.success,
                subTextColor,
              ),
              const SizedBox(width: 12),
              _miniStat(
                '✗ Absent',
                stat['absent'],
                AppTheme.error,
                subTextColor,
              ),
              const SizedBox(width: 12),
              _miniStat('Total', stat['total'], AppTheme.primary, subTextColor),
            ],
          ),
        ],
      ),
    );
  }

  Widget _miniStat(String label, int value, Color color, Color subTextColor) {
    return Row(
      children: [
        Text(
          '$value',
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
        const SizedBox(width: 4),
        Text(label, style: TextStyle(color: subTextColor, fontSize: 11)),
      ],
    );
  }
}

// ─── Custom Pie Chart Painter ──────────────────────────────────
class _PieChartPainter extends CustomPainter {
  final double presentPct;
  final double animValue;
  final Color presentColor;
  final Color absentColor;

  _PieChartPainter({
    required this.presentPct,
    required this.animValue,
    required this.presentColor,
    required this.absentColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final radius = min(cx, cy) - 8;
    const strokeW = 18.0;

    final rect = Rect.fromCircle(center: Offset(cx, cy), radius: radius);

    // Background (absent) arc — full circle
    final bgPaint = Paint()
      ..color = absentColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeW
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(Offset(cx, cy), radius, bgPaint);

    // Foreground (present) arc — animated
    final fgPaint = Paint()
      ..color = presentColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeW
      ..strokeCap = StrokeCap.round;

    final sweepAngle = 2 * pi * presentPct * animValue;
    canvas.drawArc(rect, -pi / 2, sweepAngle, false, fgPaint);
  }

  @override
  bool shouldRepaint(_PieChartPainter old) =>
      old.animValue != animValue || old.presentPct != presentPct;
}
