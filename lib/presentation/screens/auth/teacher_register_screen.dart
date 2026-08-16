import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tapin_attendance/core/theme/app_theme.dart';
import 'package:tapin_attendance/core/constants/app_constants.dart';
import 'package:tapin_attendance/presentation/screens/auth/login_screen.dart';

class TeacherRegisterScreen extends StatefulWidget {
  final bool isDarkMode;
  final Function(bool) onThemeToggle;

  const TeacherRegisterScreen({
    super.key,
    required this.isDarkMode,
    required this.onThemeToggle,
  });

  @override
  State<TeacherRegisterScreen> createState() => _TeacherRegisterScreenState();
}

class _TeacherRegisterScreenState extends State<TeacherRegisterScreen> {
  final _nameController = TextEditingController();
  final _idController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _phoneController = TextEditingController();

  bool _isLoading = false;
  bool _obscurePassword = true;
  String? _errorMessage;

  List<Map<String, dynamic>> _departments = [];
  String? _selectedDepartmentName;
  String? _selectedDesignation;
  bool _isLoadingDeps = true;

  final List<String> _designations = [
    'Professor',
    'Associate Professor',
    'Assistant Professor',
    'Lecturer',
    'Guest Lecturer',
  ];

  @override
  void initState() {
    super.initState();
    _loadDepartments();
  }

  Future<void> _loadDepartments() async {
    try {
      final res = await Supabase.instance.client
          .from('departments')
          .select('name')
          .order('name');
      if (mounted) {
        setState(() {
          _departments = List<Map<String, dynamic>>.from(res);
          _isLoadingDeps = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingDeps = false);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _idController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    final name = _nameController.text.trim();
    final idInput = _idController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final phone = _phoneController.text.trim();

    if (name.isEmpty ||
        idInput.isEmpty ||
        email.isEmpty ||
        password.isEmpty ||
        _selectedDepartmentName == null ||
        _selectedDesignation == null) {
      setState(
        () => _errorMessage = 'Please fill all required fields and selections',
      );
      return;
    }

    if (password.length < 6) {
      setState(() => _errorMessage = 'Password must be at least 6 characters');
      return;
    }

    final fullTeacherId = 'T-$idInput';

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await Supabase.instance.client.auth.signUp(
        email: email,
        password: password,
      );

      if (response.user == null) {
        setState(() => _errorMessage = 'Registration failed. Try again.');
        return;
      }

      await Supabase.instance.client.from('users').insert({
        'id': response.user!.id,
        'name': name,
        'university_id': fullTeacherId,
        'email': email,
        'role': AppConstants.roleTeacher,
        'department': _selectedDepartmentName,
        'section': _selectedDesignation, // Using section for designation
        'phone_number': phone.isEmpty ? null : phone,
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Teacher registration successful! Please sign in.'),
          backgroundColor: AppTheme.success,
        ),
      );

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => LoginScreen(
            isDarkMode: widget.isDarkMode,
            onThemeToggle: widget.onThemeToggle,
          ),
        ),
      );
    } on AuthException catch (e) {
      setState(() => _errorMessage = e.message);
    } catch (e) {
      setState(() => _errorMessage = 'Something went wrong. Try again.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Widget _fieldLabel(String label, Color color) {
    return Text(
      label,
      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: color),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppTheme.darkBg : AppTheme.lightBg;
    final cardColor = isDark ? AppTheme.darkCard : AppTheme.lightSurface;
    final textColor = isDark ? AppTheme.darkText : AppTheme.lightText;
    final subTextColor = isDark
        ? AppTheme.darkTextSecondary
        : AppTheme.lightTextSecondary;
    final borderColor = isDark ? AppTheme.darkBorder : AppTheme.lightBorder;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: textColor, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Teacher Registration',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: textColor,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Join TapIn as a faculty member',
                style: TextStyle(fontSize: 14, color: subTextColor),
              ),

              const SizedBox(height: 32),

              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: borderColor),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _fieldLabel('Full Name *', textColor),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _nameController,
                      style: TextStyle(color: textColor),
                      decoration: InputDecoration(
                        hintText: 'Your full name',
                        hintStyle: TextStyle(color: subTextColor),
                        prefixIcon: Icon(
                          Icons.person_outlined,
                          color: subTextColor,
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    _fieldLabel('Teacher ID *', textColor),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _idController,
                      style: TextStyle(color: textColor),
                      decoration: InputDecoration(
                        prefixText: 'T-',
                        prefixStyle: TextStyle(
                          color: textColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                        hintText: '100234',
                        hintStyle: TextStyle(color: subTextColor),
                        prefixIcon: Icon(
                          Icons.badge_outlined,
                          color: subTextColor,
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    _fieldLabel('Department *', textColor),
                    const SizedBox(height: 8),
                    _isLoadingDeps
                        ? const Center(
                            child: CircularProgressIndicator(
                              color: AppTheme.primary,
                            ),
                          )
                        : DropdownButtonFormField<String>(
                            value: _selectedDepartmentName,
                            dropdownColor: cardColor,
                            style: TextStyle(color: textColor),
                            decoration: InputDecoration(
                              hintText: 'Select Department',
                              hintStyle: TextStyle(color: subTextColor),
                              prefixIcon: Icon(
                                Icons.business_outlined,
                                color: subTextColor,
                              ),
                            ),
                            items: _departments.map((d) {
                              return DropdownMenuItem<String>(
                                value: d['name'],
                                child: Text(d['name']),
                              );
                            }).toList(),
                            onChanged: (val) {
                              setState(() {
                                _selectedDepartmentName = val;
                              });
                            },
                          ),

                    const SizedBox(height: 20),

                    _fieldLabel('Designation *', textColor),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: _selectedDesignation,
                      dropdownColor: cardColor,
                      style: TextStyle(color: textColor),
                      decoration: InputDecoration(
                        hintText: 'Select Designation',
                        hintStyle: TextStyle(color: subTextColor),
                        prefixIcon: Icon(
                          Icons.work_outline,
                          color: subTextColor,
                        ),
                      ),
                      items: _designations.map((d) {
                        return DropdownMenuItem<String>(
                          value: d,
                          child: Text(d),
                        );
                      }).toList(),
                      onChanged: (val) {
                        setState(() {
                          _selectedDesignation = val;
                        });
                      },
                    ),

                    const SizedBox(height: 20),

                    _fieldLabel('Email Address *', textColor),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      style: TextStyle(color: textColor),
                      decoration: InputDecoration(
                        hintText: 'teacher@university.edu',
                        hintStyle: TextStyle(color: subTextColor),
                        prefixIcon: Icon(
                          Icons.email_outlined,
                          color: subTextColor,
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    _fieldLabel('Phone Number', textColor),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      style: TextStyle(color: textColor),
                      decoration: InputDecoration(
                        hintText: 'Optional',
                        hintStyle: TextStyle(color: subTextColor),
                        prefixIcon: Icon(
                          Icons.phone_outlined,
                          color: subTextColor,
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    _fieldLabel('Password *', textColor),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      style: TextStyle(color: textColor),
                      decoration: InputDecoration(
                        hintText: '••••••••',
                        hintStyle: TextStyle(color: subTextColor),
                        prefixIcon: Icon(
                          Icons.lock_outline,
                          color: subTextColor,
                        ),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_off
                                : Icons.visibility,
                            color: subTextColor,
                          ),
                          onPressed: () {
                            setState(() {
                              _obscurePassword = !_obscurePassword;
                            });
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              if (_errorMessage != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.error.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.error_outline,
                        color: AppTheme.error,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: const TextStyle(
                            color: AppTheme.error,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ],

              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _register,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          'Create Teacher Account',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
