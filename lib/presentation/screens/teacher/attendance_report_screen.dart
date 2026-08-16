import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:excel/excel.dart' as xl;
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import '../../../core/theme/app_theme.dart';

class AttendanceReportScreen extends StatefulWidget {
  final Map<String, dynamic>? userData; // teacher's own userData
  const AttendanceReportScreen({super.key, required this.userData});

  @override
  State<AttendanceReportScreen> createState() => _AttendanceReportScreenState();
}

class _AttendanceReportScreenState extends State<AttendanceReportScreen> {
  bool _isLoading = true;
  bool _isExporting = false;

  List<Map<String, dynamic>> _subjects = [];
  List<Map<String, dynamic>> _reportRows = [];

  String? _selectedSubjectId;
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime _endDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _loadSubjects();
  }

  // ─── Load teacher's assigned subjects ─────────────────────
  Future<void> _loadSubjects() async {
    setState(() => _isLoading = true);
    try {
      final labGroupRaw = widget.userData?['lab_group'] ?? '';
      List<String> subjectIds = [];
      try {
        if (labGroupRaw.toString().isNotEmpty) {
          final decoded = jsonDecode(labGroupRaw.toString());
          if (decoded is List) {
            subjectIds = List<String>.from(decoded.map((e) => e.toString()));
          }
        }
      } catch (_) {}

      if (subjectIds.isEmpty) {
        setState(() => _isLoading = false);
        return;
      }

      final res = await Supabase.instance.client
          .from('subjects')
          .select()
          .inFilter('id', subjectIds);

      setState(() {
        _subjects = List<Map<String, dynamic>>.from(res);
        if (_subjects.isNotEmpty) {
          _selectedSubjectId = _subjects.first['id'];
        }
        _isLoading = false;
      });

      if (_selectedSubjectId != null) await _generateReport();
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  // ─── Generate report data ──────────────────────────────────
  Future<void> _generateReport() async {
    if (_selectedSubjectId == null) return;
    setState(() => _isLoading = true);

    try {
      final subject = _subjects.firstWhere(
        (s) => s['id'] == _selectedSubjectId,
      );

      // Get all students in this dept/section
      final students = await Supabase.instance.client
          .from('users')
          .select('id, name, university_id')
          .eq('role', 'student')
          .eq('department', subject['department'])
          .eq('section', subject['section'])
          .order('university_id');

      // Get all attendance logs for this subject in date range
      final startStr = DateFormat('yyyy-MM-dd').format(_startDate);
      final endStr = DateFormat('yyyy-MM-dd').format(_endDate);

      final logs = await Supabase.instance.client
          .from('attendance_logs')
          .select('student_id, status, date')
          .eq('subject_id', _selectedSubjectId!)
          .gte('date', startStr)
          .lte('date', endStr);

      // Build per-student stats
      List<Map<String, dynamic>> rows = [];
      for (final student in students) {
        final studentLogs = logs
            .where((l) => l['student_id'] == student['id'])
            .toList();
        final total = studentLogs.length;
        final present = studentLogs
            .where((l) => l['status'] == 'present')
            .length;
        final absent = studentLogs.where((l) => l['status'] == 'absent').length;
        final pct = total > 0 ? (present / total * 100) : 0.0;

        rows.add({
          'name': student['name'] ?? '',
          'uid': student['university_id'] ?? '',
          'total': total,
          'present': present,
          'absent': absent,
          'percentage': pct,
        });
      }

      // Sort by percentage ascending (lowest first — needs attention)
      rows.sort(
        (a, b) =>
            (a['percentage'] as double).compareTo(b['percentage'] as double),
      );

      setState(() {
        _reportRows = rows;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppTheme.error),
        );
      }
    }
  }

  // ─── Export PDF ────────────────────────────────────────────
  Future<void> _exportPdf() async {
    if (_reportRows.isEmpty) return;
    setState(() => _isExporting = true);

    try {
      final subject = _subjects.firstWhere(
        (s) => s['id'] == _selectedSubjectId,
      );
      final pdf = pw.Document();

      final headerColor = PdfColor.fromHex('#6C63FF');
      final lowAttColor = PdfColor.fromHex('#EF4444');
      final okColor = PdfColor.fromHex('#22C55E');

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(32),
          build: (pw.Context context) {
            return [
              // Title
              pw.Text(
                'Attendance Report',
                style: pw.TextStyle(
                  fontSize: 24,
                  fontWeight: pw.FontWeight.bold,
                  color: headerColor,
                ),
              ),
              pw.SizedBox(height: 8),
              pw.Text(
                '${subject['name']} (${subject['code']})',
                style: pw.TextStyle(fontSize: 14, color: PdfColors.grey700),
              ),
              pw.Text(
                'Period: ${DateFormat('dd MMM yyyy').format(_startDate)} – ${DateFormat('dd MMM yyyy').format(_endDate)}',
                style: pw.TextStyle(fontSize: 12, color: PdfColors.grey600),
              ),
              pw.Text(
                'Generated: ${DateFormat('dd MMM yyyy, hh:mm a').format(DateTime.now())}',
                style: pw.TextStyle(fontSize: 10, color: PdfColors.grey500),
              ),
              pw.SizedBox(height: 20),

              // Summary
              pw.Row(
                children: [
                  _pdfSummaryBox(
                    'Total Students',
                    '${_reportRows.length}',
                    headerColor,
                  ),
                  pw.SizedBox(width: 12),
                  _pdfSummaryBox(
                    'Low Attendance (<75%)',
                    '${_reportRows.where((r) => (r['percentage'] as double) < 75).length}',
                    lowAttColor,
                  ),
                  pw.SizedBox(width: 12),
                  _pdfSummaryBox(
                    'Good Attendance (≥75%)',
                    '${_reportRows.where((r) => (r['percentage'] as double) >= 75).length}',
                    okColor,
                  ),
                ],
              ),
              pw.SizedBox(height: 20),

              // Table
              pw.Table(
                border: pw.TableBorder.all(color: PdfColors.grey300),
                columnWidths: {
                  0: const pw.FlexColumnWidth(3),
                  1: const pw.FlexColumnWidth(2),
                  2: const pw.FlexColumnWidth(1),
                  3: const pw.FlexColumnWidth(1),
                  4: const pw.FlexColumnWidth(1),
                  5: const pw.FlexColumnWidth(1.5),
                },
                children: [
                  // Header
                  pw.TableRow(
                    decoration: pw.BoxDecoration(color: headerColor),
                    children: [
                      _pdfCell('Name', isHeader: true),
                      _pdfCell('University ID', isHeader: true),
                      _pdfCell('Total', isHeader: true),
                      _pdfCell('Present', isHeader: true),
                      _pdfCell('Absent', isHeader: true),
                      _pdfCell('Percentage', isHeader: true),
                    ],
                  ),
                  // Rows
                  ..._reportRows.map((row) {
                    final pct = row['percentage'] as double;
                    final rowColor = pct < 75
                        ? PdfColor.fromHex('#FEF2F2')
                        : PdfColors.white;
                    return pw.TableRow(
                      decoration: pw.BoxDecoration(color: rowColor),
                      children: [
                        _pdfCell(row['name']),
                        _pdfCell(row['uid']),
                        _pdfCell('${row['total']}'),
                        _pdfCell('${row['present']}'),
                        _pdfCell('${row['absent']}'),
                        _pdfCell(
                          '${pct.toStringAsFixed(1)}%',
                          color: pct < 75 ? lowAttColor : okColor,
                          bold: true,
                        ),
                      ],
                    );
                  }),
                ],
              ),
            ];
          },
        ),
      );

      final Uint8List bytes = await pdf.save();
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/attendance_report_${subject['code']}.pdf');
      await file.writeAsBytes(bytes);

      await Share.shareXFiles([
        XFile(file.path),
      ], subject: 'Attendance Report – ${subject['name']}');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('PDF Error: $e'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  pw.Widget _pdfSummaryBox(String label, String value, PdfColor color) {
    return pw.Expanded(
      child: pw.Container(
        padding: const pw.EdgeInsets.all(10),
        decoration: pw.BoxDecoration(
          color: color,
          borderRadius: pw.BorderRadius.circular(8),
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              value,
              style: pw.TextStyle(
                fontSize: 20,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.white,
              ),
            ),
            pw.Text(
              label,
              style: const pw.TextStyle(fontSize: 10, color: PdfColors.white),
            ),
          ],
        ),
      ),
    );
  }

  pw.Widget _pdfCell(
    String text, {
    bool isHeader = false,
    PdfColor? color,
    bool bold = false,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: 11,
          fontWeight: isHeader || bold
              ? pw.FontWeight.bold
              : pw.FontWeight.normal,
          color: isHeader ? PdfColors.white : (color ?? PdfColors.black),
        ),
      ),
    );
  }

  // ─── Export Excel ──────────────────────────────────────────
  Future<void> _exportExcel() async {
    if (_reportRows.isEmpty) return;
    setState(() => _isExporting = true);

    try {
      final subject = _subjects.firstWhere(
        (s) => s['id'] == _selectedSubjectId,
      );

      final excel = xl.Excel.createExcel();
      final sheet = excel['Attendance Report'];

      // Header style
      final headerStyle = xl.CellStyle(
        bold: true,
        fontColorHex: xl.ExcelColor.fromHexString('#FFFFFF'),
        backgroundColorHex: xl.ExcelColor.fromHexString('#6C63FF'),
        horizontalAlign: xl.HorizontalAlign.Center,
      );

      // Title row
      sheet.merge(
        xl.CellIndex.indexByString('A1'),
        xl.CellIndex.indexByString('F1'),
      );
      final titleCell = sheet.cell(xl.CellIndex.indexByString('A1'));
      titleCell.value = xl.TextCellValue(
        'Attendance Report – ${subject['name']} (${subject['code']})',
      );
      titleCell.cellStyle = xl.CellStyle(bold: true, fontSize: 14);

      // Date row
      sheet.merge(
        xl.CellIndex.indexByString('A2'),
        xl.CellIndex.indexByString('F2'),
      );
      sheet.cell(xl.CellIndex.indexByString('A2')).value = xl.TextCellValue(
        'Period: ${DateFormat('dd MMM yyyy').format(_startDate)} – ${DateFormat('dd MMM yyyy').format(_endDate)}',
      );

      // Header row
      final headers = [
        'Student Name',
        'University ID',
        'Total Classes',
        'Present',
        'Absent',
        'Percentage',
      ];
      for (int i = 0; i < headers.length; i++) {
        final cell = sheet.cell(
          xl.CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 3),
        );
        cell.value = xl.TextCellValue(headers[i]);
        cell.cellStyle = headerStyle;
      }

      // Data rows
      for (int r = 0; r < _reportRows.length; r++) {
        final row = _reportRows[r];
        final pct = row['percentage'] as double;
        final rowIdx = r + 4;
        final isLow = pct < 75;

        final rowBg = isLow
            ? xl.ExcelColor.fromHexString('#FEE2E2')
            : xl.ExcelColor.fromHexString('#F0FDF4');

        void setCell(int col, xl.CellValue value) {
          final cell = sheet.cell(
            xl.CellIndex.indexByColumnRow(columnIndex: col, rowIndex: rowIdx),
          );
          cell.value = value;
          cell.cellStyle = xl.CellStyle(backgroundColorHex: rowBg);
        }

        setCell(0, xl.TextCellValue(row['name']));
        setCell(1, xl.TextCellValue(row['uid']));
        setCell(2, xl.IntCellValue(row['total']));
        setCell(3, xl.IntCellValue(row['present']));
        setCell(4, xl.IntCellValue(row['absent']));
        setCell(5, xl.TextCellValue('${pct.toStringAsFixed(1)}%'));
      }

      // Column widths
      sheet.setColumnWidth(0, 30);
      sheet.setColumnWidth(1, 20);
      sheet.setColumnWidth(2, 14);
      sheet.setColumnWidth(3, 12);
      sheet.setColumnWidth(4, 12);
      sheet.setColumnWidth(5, 14);

      // Remove default sheet
      excel.delete('Sheet1');

      final bytes = excel.encode()!;
      final dir = await getTemporaryDirectory();
      final file = File(
        '${dir.path}/attendance_report_${subject['code']}.xlsx',
      );
      await file.writeAsBytes(bytes);

      await Share.shareXFiles([
        XFile(file.path),
      ], subject: 'Attendance Report – ${subject['name']}');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Excel Error: $e'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  // ─── Date picker ───────────────────────────────────────────
  Future<void> _pickDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: DateTimeRange(start: _startDate, end: _endDate),
      builder: (context, child) {
        return Theme(
          data: Theme.of(
            context,
          ).copyWith(colorScheme: ColorScheme.light(primary: AppTheme.primary)),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
      });
      await _generateReport();
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
          'Attendance Report',
          style: TextStyle(
            color: textColor,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        actions: [
          if (_reportRows.isNotEmpty && !_isExporting) ...[
            IconButton(
              tooltip: 'Export Excel',
              icon: const Icon(
                Icons.table_chart_outlined,
                color: AppTheme.success,
              ),
              onPressed: _exportExcel,
            ),
            IconButton(
              tooltip: 'Export PDF',
              icon: const Icon(Icons.picture_as_pdf, color: AppTheme.error),
              onPressed: _exportPdf,
            ),
          ],
          if (_isExporting)
            const Padding(
              padding: EdgeInsets.all(16),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppTheme.primary,
                ),
              ),
            ),
        ],
      ),
      body: _subjects.isEmpty && !_isLoading
          ? Center(
              child: Text(
                'No subjects assigned.',
                style: TextStyle(color: subTextColor),
              ),
            )
          : Column(
              children: [
                // ── Filters ──────────────────────────────────
                Container(
                  margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: borderColor),
                  ),
                  child: Column(
                    children: [
                      // Subject dropdown
                      DropdownButtonHideUnderline(
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
                          onChanged: (val) async {
                            if (val != null) {
                              setState(() => _selectedSubjectId = val);
                              await _generateReport();
                            }
                          },
                        ),
                      ),
                      const Divider(),
                      // Date range
                      GestureDetector(
                        onTap: _pickDateRange,
                        child: Row(
                          children: [
                            const Icon(
                              Icons.date_range,
                              color: AppTheme.primary,
                              size: 20,
                            ),
                            const SizedBox(width: 10),
                            Text(
                              '${DateFormat('dd MMM yyyy').format(_startDate)}  →  ${DateFormat('dd MMM yyyy').format(_endDate)}',
                              style: TextStyle(
                                color: textColor,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const Spacer(),
                            Icon(
                              Icons.edit_calendar_outlined,
                              color: subTextColor,
                              size: 18,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // ── Summary bar ───────────────────────────────
                if (_reportRows.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                    child: Row(
                      children: [
                        _summaryChip(
                          '${_reportRows.length}',
                          'Total',
                          AppTheme.primary,
                          textColor,
                        ),
                        const SizedBox(width: 8),
                        _summaryChip(
                          '${_reportRows.where((r) => (r['percentage'] as double) >= 75).length}',
                          '≥ 75%',
                          AppTheme.success,
                          textColor,
                        ),
                        const SizedBox(width: 8),
                        _summaryChip(
                          '${_reportRows.where((r) => (r['percentage'] as double) < 75).length}',
                          '< 75%',
                          AppTheme.error,
                          textColor,
                        ),
                      ],
                    ),
                  ),

                // ── Student list ──────────────────────────────
                Expanded(
                  child: _isLoading
                      ? const Center(
                          child: CircularProgressIndicator(
                            color: AppTheme.primary,
                          ),
                        )
                      : _reportRows.isEmpty
                      ? Center(
                          child: Text(
                            'No data for selected period.',
                            style: TextStyle(color: subTextColor),
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                          itemCount: _reportRows.length,
                          itemBuilder: (context, index) {
                            final row = _reportRows[index];
                            final pct = row['percentage'] as double;
                            final isLow = pct < 75;

                            return Container(
                              margin: const EdgeInsets.only(bottom: 10),
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: isLow
                                    ? AppTheme.error.withValues(alpha: 0.07)
                                    : cardColor,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: isLow
                                      ? AppTheme.error.withValues(alpha: 0.3)
                                      : borderColor,
                                ),
                              ),
                              child: Row(
                                children: [
                                  // Avatar
                                  Container(
                                    width: 44,
                                    height: 44,
                                    decoration: BoxDecoration(
                                      color: isLow
                                          ? AppTheme.error.withValues(
                                              alpha: 0.15,
                                            )
                                          : AppTheme.primary.withValues(
                                              alpha: 0.12,
                                            ),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Center(
                                      child: Text(
                                        (row['name'] as String).isNotEmpty
                                            ? (row['name'] as String)[0]
                                                  .toUpperCase()
                                            : 'S',
                                        style: TextStyle(
                                          color: isLow
                                              ? AppTheme.error
                                              : AppTheme.primary,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 18,
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
                                          row['name'],
                                          style: TextStyle(
                                            color: textColor,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 15,
                                          ),
                                        ),
                                        Text(
                                          row['uid'],
                                          style: TextStyle(
                                            color: subTextColor,
                                            fontSize: 12,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          '${row['present']} present / ${row['absent']} absent / ${row['total']} total',
                                          style: TextStyle(
                                            color: subTextColor,
                                            fontSize: 11,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  // Percentage badge
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: isLow
                                          ? AppTheme.error
                                          : AppTheme.success,
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
                            );
                          },
                        ),
                ),

                // ── Export buttons ────────────────────────────
                if (_reportRows.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                    child: Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _isExporting ? null : _exportExcel,
                            icon: const Icon(
                              Icons.table_chart_outlined,
                              size: 20,
                            ),
                            label: const Text('Export Excel'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.success,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _isExporting ? null : _exportPdf,
                            icon: const Icon(Icons.picture_as_pdf, size: 20),
                            label: const Text('Export PDF'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.error,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
    );
  }

  Widget _summaryChip(
    String value,
    String label,
    Color color,
    Color textColor,
  ) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            Text(label, style: TextStyle(color: textColor, fontSize: 11)),
          ],
        ),
      ),
    );
  }
}
