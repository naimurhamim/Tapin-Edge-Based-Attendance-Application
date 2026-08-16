class AppConstants {
  // Supabase
  static const String supabaseUrl = 'https://nqmzpjaiphcfrnnlxhxv.supabase.co';
  static const String supabaseAnonKey =
      'sb_publishable_z2KxRFk5y0UQM0kNxsIJRQ_dVwFg2XN';

  // App Info
  static const String appName = 'TapIn';
  static const String appTagline = 'Smart Attendance System';
  static const String appVersion = '1.0.0';

  // Roles
  static const String roleStudent = 'student';
  static const String roleAdmin = 'admin';
  static const String roleTeacher = 'teacher';

  // Department
  static const String department = 'IRE';
  static const String section = '2021-22';

  // Attendance
  static const double minAttendancePercent = 90.0;
  static const int attendanceMark = 30;

  // Entry/Exit window (minutes)
  static const int entryWindowMinutes = 15;
  static const int exitWindowMinutes = 15;
}
