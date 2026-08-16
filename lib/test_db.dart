import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/constants/supabase_constants.dart';
import 'package:flutter/widgets.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: SupabaseConstants.supabaseUrl,
    anonKey: SupabaseConstants.supabaseAnonKey,
  );

  final res = await Supabase.instance.client
      .from('leave_applications')
      .select('*, subjects(name), users(name)');
  print("Leave Applications:");
  for (var r in res) {
    print(r);
  }
}
