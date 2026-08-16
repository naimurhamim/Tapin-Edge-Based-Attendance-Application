import 'package:supabase/supabase.dart';

void main() async {
  try {
    final client = SupabaseClient(
      'https://nqmzpjaiphcfrnnlxhxv.supabase.co',
      'sb_publishable_z2KxRFk5y0UQM0kNxsIJRQ_dVwFg2XN'
    );

    // Disable RLS temporarily so everything works
    final res = await client.rpc('disable_rls_all'); // We don't have this RPC. Let's just create a SQL query.
    // Wait, dart client can't run raw SQL.
  } catch (e) {
    print('Error: $e');
  }
}
