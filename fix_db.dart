import 'package:supabase/supabase.dart';
import 'dart:convert';

void main() async {
  try {
    final client = SupabaseClient(
      'https://nqmzpjaiphcfrnnlxhxv.supabase.co',
      'sb_publishable_z2KxRFk5y0UQM0kNxsIJRQ_dVwFg2XN'
    );

    print('Fetching subjects...');
    final subjects = await client.from('subjects').select('id');
    List<String> allSubIds = subjects.map((s) => s['id'].toString()).toList();
    String labGroupJson = jsonEncode(allSubIds);
    
    print('Updating teachers with lab_group: $labGroupJson');
    
    await client.from('users').update({'lab_group': labGroupJson}).eq('role', 'teacher');
    await client.from('users').update({'lab_group': labGroupJson}).like('university_id', 'T-%');
    
    print('All teachers assigned to all subjects successfully!');
  } catch (e) {
    print('Error: $e');
  }
}
