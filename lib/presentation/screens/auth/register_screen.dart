import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/constants/app_constants.dart';
import 'login_screen.dart';

class RegisterScreen extends StatefulWidget {
  final bool isDarkMode;
  final Function(bool) onThemeToggle;

  const RegisterScreen({
    super.key,
    required this.isDarkMode,
    required this.onThemeToggle,
  });

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _nameController = TextEditingController();
  final _universityIdController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _phoneController = TextEditingController();

  bool _isLoading = false;
  bool _obscurePassword = true;
  String? _errorMessage;

  List<Map<String, dynamic>> _departments = [];
  List<Map<String, dynamic>> _sessions = [];
  String? _selectedDepartmentId;
  String? _selectedDepartmentName;
  String? _selectedSessionName;
  bool _isLoadingDeps = true;

  @override
  void initState() {
    super.initState();
    _loadDepartments();
  }

  Future<void> _loadDepartments() async {
    try {
      final res = await Supabase.instance.client
          .from('departments')
          .select('*, sessions(*)')
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

  void _onDepartmentChanged(String? deptId) {
    setState(() {
      _selectedDepartmentId = deptId;
      _selectedSessionName = null;
      if (deptId != null) {
        final dept = _departments.firstWhere((d) => d['id'] == deptId);
        _selectedDepartmentName = dept['name'];
        _sessions = List<Map<String, dynamic>>.from(dept['sessions'] ?? []);
      } else {
        _selectedDepartmentName = null;
        _sessions = [];
      }
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _universityIdController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  String _getLabGroup(String universityId) {
    if (universityId.length < 3) return 'G1';
    final lastThree =
        int.tryParse(universityId.substring(universityId.length - 3)) ?? 0;
    return lastThree <= 25 ? 'G1' : 'G2';
  }

  Future<void> _register() async {
    final name = _nameController.text.trim();
    final universityId = _universityIdController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final phone = _phoneController.text.trim();

    if (name.isEmpty ||
        universityId.isEmpty ||
        email.isEmpty ||
        password.isEmpty ||
        _selectedDepartmentName == null ||
        _selectedSessionName == null) {
      setState(
        () => _errorMessage = 'Please fill all required fields and selections',
      );
      return;
    }

    if (password.length < 6) {
      setState(() => _errorMessage = 'Password must be at least 6 characters');
      return;
    }

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
        'university_id': universityId,
        'email': email,
        'role': AppConstants.roleStudent,
        'department': _selectedDepartmentName,
        'section': _selectedSessionName,
        'lab_group': _getLabGroup(universityId),
        'phone_number': phone.isEmpty ? null : phone,
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Registration successful! Please sign in.'),
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
              // Title
              Text(
                'Create Account',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: textColor,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Join TapIn to track your attendance',
                style: TextStyle(fontSize: 14, color: subTextColor),
              ),

              const SizedBox(height: 32),

              // Form Card
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
                    // Full Name
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

                    // University ID
                    _fieldLabel('University ID *', textColor),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _universityIdController,
                      style: TextStyle(color: textColor),
                      decoration: InputDecoration(
                        hintText: 'e.g. 2101001',
                        hintStyle: TextStyle(color: subTextColor),
                        prefixIcon: Icon(
                          Icons.badge_outlined,
                          color: subTextColor,
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Email
                    _fieldLabel('Email *', textColor),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      style: TextStyle(color: textColor),
                      decoration: InputDecoration(
                        hintText: 'your@email.com',
                        hintStyle: TextStyle(color: subTextColor),
                        prefixIcon: Icon(
                          Icons.email_outlined,
                          color: subTextColor,
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Password
                    _fieldLabel('Password *', textColor),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      style: TextStyle(color: textColor),
                      decoration: InputDecoration(
                        hintText: 'Min. 6 characters',
                        hintStyle: TextStyle(color: subTextColor),
                        prefixIcon: Icon(
                          Icons.lock_outlined,
                          color: subTextColor,
                        ),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                            color: subTextColor,
                          ),
                          onPressed: () => setState(
                            () => _obscurePassword = !_obscurePassword,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Phone
                    _fieldLabel('Phone Number', textColor),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      style: TextStyle(color: textColor),
                      decoration: InputDecoration(
                        hintText: '01XXXXXXXXX',
                        hintStyle: TextStyle(color: subTextColor),
                        prefixIcon: Icon(
                          Icons.phone_outlined,
                          color: subTextColor,
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    if (_isLoadingDeps)
                      const Center(child: CircularProgressIndicator())
                    else ...[
                      _fieldLabel('Department *', textColor),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        value: _selectedDepartmentId,
                        dropdownColor: cardColor,
                        style: TextStyle(color: textColor),
                        decoration: InputDecoration(
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                          ),
                        ),
                        items: _departments
                            .map(
                              (d) => DropdownMenuItem<String>(
                                value: d['id'],
                                child: Text(d['name']),
                              ),
                            )
                            .toList(),
                        onChanged: _onDepartmentChanged,
                        hint: Text(
                          'Select Department',
                          style: TextStyle(color: subTextColor),
                        ),
                      ),

                      const SizedBox(height: 20),

                      _fieldLabel('Session *', textColor),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        value: _selectedSessionName,
                        dropdownColor: cardColor,
                        style: TextStyle(color: textColor),
                        decoration: InputDecoration(
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                          ),
                        ),
                        items: _sessions
                            .map(
                              (s) => DropdownMenuItem<String>(
                                value: s['name'],
                                child: Text(s['name']),
                              ),
                            )
                            .toList(),
                        onChanged: _selectedDepartmentId == null
                            ? null
                            : (val) {
                                setState(() => _selectedSessionName = val);
                              },
                        hint: Text(
                          'Select Session',
                          style: TextStyle(color: subTextColor),
                        ),
                        disabledHint: Text(
                          'Select Department first',
                          style: TextStyle(color: subTextColor),
                        ),
                      ),
                    ],

                    // Error message
                    if (_errorMessage != null) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppTheme.error.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: AppTheme.error.withOpacity(0.3),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.error_outline,
                              color: AppTheme.error,
                              size: 16,
                            ),
                            const SizedBox(width: 8),
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
                    ],

                    const SizedBox(height: 24),

                    // Register Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _register,
                        child: _isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text('Create Account'),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Login link
              Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Already have an account? ',
                      style: TextStyle(color: subTextColor, fontSize: 14),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: const Text(
                        'Sign In',
                        style: TextStyle(
                          color: AppTheme.primary,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _fieldLabel(String label, Color color) {
    return Text(
      label,
      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: color),
    );
  }
}
