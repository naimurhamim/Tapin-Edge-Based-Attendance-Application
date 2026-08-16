import 'package:supabase/supabase.dart';

void main() async {
  try {
    final client = SupabaseClient(
      'https://nqmzpjaiphcfrnnlxhxv.supabase.co',
      'sb_publishable_z2KxRFk5y0UQM0kNxsIJRQ_dVwFg2XN'
    );

    final teachers = await client.from('users').select('name, lab_group').eq('role', 'teacher');
    print('Teachers: $teachers');
  } catch (e) {
    print('Error: $e');
  }
}
