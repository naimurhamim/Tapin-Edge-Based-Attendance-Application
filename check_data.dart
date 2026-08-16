import 'package:supabase/supabase.dart';

void main() async {
  try {
    final client = SupabaseClient(
      'https://nqmzpjaiphcfrnnlxhxv.supabase.co',
      'sb_publishable_z2KxRFk5y0UQM0kNxsIJRQ_dVwFg2XN'
    );

    final users = await client.from('users').select('id, name, department, section, lab_group').inFilter('name', ['Naimur Rashid', 'Test student 1']);
    print('Users: $users');

    final schedules = await client.from('class_schedules').select('*, subjects(name)');
    print('Schedules: $schedules');
    
    // Check current time in postgres
    final res = await client.rpc('process_rfid_scan', params: {'p_rfid_uid': 'B0022E32'});
    print('RPC Result: $res');
    
  } catch (e) {
    print('Error: $e');
  }
}
