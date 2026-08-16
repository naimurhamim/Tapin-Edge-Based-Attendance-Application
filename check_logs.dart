import 'package:supabase/supabase.dart';

void main() async {
  final client = SupabaseClient(
    'https://nqmzpjaiphcfrnnlxhxv.supabase.co',
    'sb_publishable_z2KxRFk5y0UQM0kNxsIJRQ_dVwFg2XN'
  );

  final logs = await client.from('attendance_logs').select().limit(5);
  print('Logs: $logs');
}
