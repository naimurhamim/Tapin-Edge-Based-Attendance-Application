import 'package:supabase/supabase.dart';
import 'package:intl/intl.dart';

void main() async {
  try {
    final client = SupabaseClient(
      'https://nqmzpjaiphcfrnnlxhxv.supabase.co',
      'sb_publishable_z2KxRFk5y0UQM0kNxsIJRQ_dVwFg2XN'
    );

    print('Fetching users...');
    final users = await client.from('users').select('id, university_id, department, section').inFilter('university_id', ['2101042', '2101006', '2101001']);
    
    String? idNaimur;
    String? idRedwan;
    String? idTest;
    String? dept;
    String? section;

    for (var u in users) {
      if (u['university_id'] == '2101042') {
        idNaimur = u['id'];
        dept = u['department'];
        section = u['section'];
      }
      if (u['university_id'] == '2101006') idRedwan = u['id'];
      if (u['university_id'] == '2101001') idTest = u['id'];
    }

    print('Fetching subject for dept $dept and section $section...');
    final subjects = await client.from('subjects').select('id').eq('department', dept!).eq('section', section!).limit(1);
    if (subjects.isEmpty) {
      print('No subjects found for that dept/section');
      return;
    }
    final subjectId = subjects.first['id'];

    print('Generating fake logs for subject $subjectId...');
    List<Map<String, dynamic>> logsToInsert = [];
    final today = DateTime.now();

    for (int i = 0; i < 10; i++) {
      final classDate = today.subtract(Duration(days: i + 1));
      final dateStr = DateFormat('yyyy-MM-dd').format(classDate);

      logsToInsert.add({
        'student_id': idNaimur,
        'subject_id': subjectId,
        'date': dateStr,
        'status': i < 9 ? 'present' : 'absent',
        'entry_time': classDate.toIso8601String(),
      });
      logsToInsert.add({
        'student_id': idRedwan,
        'subject_id': subjectId,
        'date': dateStr,
        'status': i < 7 ? 'present' : 'absent',
        'entry_time': classDate.toIso8601String(),
      });
      logsToInsert.add({
        'student_id': idTest,
        'subject_id': subjectId,
        'date': dateStr,
        'status': i < 3 ? 'present' : 'absent',
        'entry_time': classDate.toIso8601String(),
      });
    }

    await client.from('attendance_logs').insert(logsToInsert);
    print('Fake attendance added successfully!');

  } catch (e) {
    print('Error: $e');
  }
}
