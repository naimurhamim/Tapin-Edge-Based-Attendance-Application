import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/theme/app_theme.dart';

class TeacherLeaveRequestsScreen extends StatefulWidget {
  final List<String> subjectIds;

  const TeacherLeaveRequestsScreen({super.key, required this.subjectIds});

  @override
  State<TeacherLeaveRequestsScreen> createState() =>
      _TeacherLeaveRequestsScreenState();
}

class _TeacherLeaveRequestsScreenState
    extends State<TeacherLeaveRequestsScreen> {
  List<Map<String, dynamic>> _leaves = [];
  bool _isLoading = true;
  String _filter = 'pending';

  @override
  void initState() {
    super.initState();
    _loadLeaves();
  }

  Future<void> _loadLeaves() async {
    if (widget.subjectIds.isEmpty) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    try {
      final leaves = await Supabase.instance.client
          .from('leave_applications')
          .select('*, users(name, university_id), subjects(name, code)')
          .inFilter('subject_id', widget.subjectIds)
          .eq('status', _filter)
          .order('created_at', ascending: false);

      if (mounted) {
        setState(() {
          _leaves = List<Map<String, dynamic>>.from(leaves);
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _updateLeave(String leaveId, String status, String? note) async {
    try {
      await Supabase.instance.client
          .from('leave_applications')
          .update({'status': status, 'admin_note': note})
          .eq('id', leaveId);
      _loadLeaves();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Leave $status'),
            backgroundColor: status == 'approved'
                ? AppTheme.success
                : AppTheme.error,
          ),
        );
      }
    } catch (e) {
      // handle error
    }
  }

  void _showActionDialog(Map<String, dynamic> leave, bool isDark) {
    String note = '';
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? AppTheme.darkCard : AppTheme.lightSurface,
        title: Text(
          'Leave Action',
          style: TextStyle(
            color: isDark ? AppTheme.darkText : AppTheme.lightText,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '${leave['users']?['name']} - ${leave['subjects']?['code']}',
              style: TextStyle(
                color: isDark
                    ? AppTheme.darkTextSecondary
                    : AppTheme.lightTextSecondary,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              onChanged: (val) => note = val,
              style: TextStyle(
                color: isDark ? AppTheme.darkText : AppTheme.lightText,
              ),
              decoration: InputDecoration(
                hintText: 'Note for student (optional)',
                hintStyle: TextStyle(
                  color: isDark
                      ? AppTheme.darkTextSecondary
                      : AppTheme.lightTextSecondary,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _updateLeave(leave['id'], 'rejected', note.isEmpty ? null : note);
            },
            child: const Text(
              'Reject',
              style: TextStyle(color: AppTheme.error),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              _updateLeave(leave['id'], 'approved', note.isEmpty ? null : note);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primary,
              foregroundColor: Colors.white,
            ),
            child: const Text('Approve'),
          ),
        ],
      ),
    );
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
        title: Text(
          'Leave Requests',
          style: TextStyle(color: textColor, fontWeight: FontWeight.bold),
        ),
        iconTheme: IconThemeData(color: textColor),
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Row(
                children: ['pending', 'approved', 'rejected'].map((f) {
                  final isSelected = _filter == f;
                  final color = f == 'approved'
                      ? AppTheme.success
                      : f == 'rejected'
                      ? AppTheme.error
                      : AppTheme.warning;
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _filter = f;
                        _isLoading = true;
                      });
                      _loadLeaves();
                    },
                    child: Container(
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected ? color.withOpacity(0.15) : cardColor,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isSelected ? color : borderColor,
                        ),
                      ),
                      child: Text(
                        f[0].toUpperCase() + f.substring(1),
                        style: TextStyle(
                          color: isSelected ? color : subTextColor,
                          fontSize: 13,
                          fontWeight: isSelected
                              ? FontWeight.w600
                              : FontWeight.w400,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(color: AppTheme.primary),
                    )
                  : _leaves.isEmpty
                  ? Center(
                      child: Text(
                        'No $_filter leaves',
                        style: TextStyle(color: subTextColor),
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadLeaves,
                      color: AppTheme.primary,
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 10,
                        ),
                        itemCount: _leaves.length,
                        itemBuilder: (context, index) {
                          final leave = _leaves[index];
                          final user = leave['users'];
                          final subject = leave['subjects'];
                          final status = leave['status'] ?? 'pending';
                          final statusColor = status == 'approved'
                              ? AppTheme.success
                              : status == 'rejected'
                              ? AppTheme.error
                              : AppTheme.warning;

                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: cardColor,
                              borderRadius: BorderRadius.circular(14),
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
                                            user?['name'] ?? '-',
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                              color: textColor,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            '${user?['university_id']} • ${subject?['code']}',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: subTextColor,
                                              fontWeight: FontWeight.w600,
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
                                        color: statusColor.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(8),
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
                                const SizedBox(height: 12),
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: isDark
                                        ? Colors.black.withOpacity(0.2)
                                        : Colors.grey.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  width: double.infinity,
                                  child: Text(
                                    leave['reason'] ?? '',
                                    style: TextStyle(
                                      color: textColor,
                                      fontSize: 13,
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.calendar_month,
                                          size: 14,
                                          color: subTextColor,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          leave['leave_date'] ?? '',
                                          style: TextStyle(
                                            color: subTextColor,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.category,
                                          size: 14,
                                          color: subTextColor,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          leave['leave_type'] ?? '',
                                          style: TextStyle(
                                            color: subTextColor,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                if (status == 'pending') ...[
                                  const SizedBox(height: 16),
                                  SizedBox(
                                    width: double.infinity,
                                    child: OutlinedButton(
                                      onPressed: () =>
                                          _showActionDialog(leave, isDark),
                                      style: OutlinedButton.styleFrom(
                                        side: const BorderSide(
                                          color: AppTheme.primary,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                        ),
                                      ),
                                      child: const Text(
                                        'Review Application',
                                        style: TextStyle(
                                          color: AppTheme.primary,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
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
