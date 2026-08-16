import 'package:supabase/supabase.dart';

void main() async {
  try {
    final client = SupabaseClient(
      'https://nqmzpjaiphcfrnnlxhxv.supabase.co',
      'sb_publishable_z2KxRFk5y0UQM0kNxsIJRQ_dVwFg2XN'
    );

    final res = await client.from('leave_applications').select();
    print('Total leave applications: ${res.length}');
    for (var r in res) {
      print(r);
    }
  } catch (e) {
    print('Error: $e');
  }
}
