import 'package:flutter/material.dart';
import 'package:dbms_proj/util/theme.dart';
import 'package:dbms_proj/util/functions.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Get Supabase client instance
final supabase = Supabase.instance.client;

class RegisterUserScreen extends StatefulWidget {
  const RegisterUserScreen({super.key});

  @override
  State<RegisterUserScreen> createState() => _RegisterUserScreenState();
}

class _RegisterUserScreenState extends State<RegisterUserScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _obscurePassword = true;

  // Form controllers
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _roleController = TextEditingController();

  // Department selection
  String? _selectedDepartmentId;
  List<Map<String, dynamic>> _departments = [];

  @override
  void initState() {
    super.initState();
    _fetchDepartments();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _roleController.dispose();
    super.dispose();
  }

  // Fetch departments from Supabase
  Future<void> _fetchDepartments() async {
    try {
      final response = await supabase.from('department').select('*');
      setState(() {
        _departments = List<Map<String, dynamic>>.from(response);
      });
    } catch (e) {
      print('Error fetching departments: $e');
      showErrorSnackBar(context, 'Failed to load departments');
    }
  }

  // Register new user
  Future<void> _registerNewUser() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedDepartmentId == null) {
      showErrorSnackBar(context, 'Please select a department');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // 1. Create user in Supabase Auth
      final authResponse = await supabase.auth.admin.createUser(
        AdminUserAttributes(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
          emailConfirm: true,
        ),
      );

      final newUser = authResponse.user;
      if (newUser == null) {
        throw Exception('Failed to create user');
      }

      // 2. Add user to the users table
      await supabase.from('users').insert({
        'userid': newUser.id,
        'name': _nameController.text.trim(),
        'email': _emailController.text.trim(),
        'departmentid': _selectedDepartmentId,
        'isadmin': false, // New users won't be admins by default
      });

      // 3. Create profile record for the user
      await supabase.from('profile').insert({
        'userid': newUser.id,
        'role': _roleController.text.trim(),
        'bio': '',
        'institute': '',
        'degreedetails': '',
        'profilepicture': '',
      });

      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        showSuccessSnackBar(context, 'User registered successfully');
        Navigator.pop(context); // Return to previous screen
      }
    } on AuthException catch (error) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        showErrorSnackBar(context, 'Auth error: ${error.message}');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        showErrorSnackBar(context, 'Error: ${e.toString()}');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Register New User'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    const Text(
                      'Create New User Account',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: AppColors.purpleLight,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Enter the details to register a new user.',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Name Field
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Full Name',
                        prefixIcon:
                            Icon(Icons.person, color: AppColors.purpleLight),
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter the user\'s name';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Email Field
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        labelText: 'Email Address',
                        prefixIcon:
                            Icon(Icons.email, color: AppColors.purpleLight),
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter an email address';
                        }
                        // Basic email validation
                        if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
                          return 'Please enter a valid email address';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Password Field
                    TextFormField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      decoration: InputDecoration(
                        labelText: 'Password',
                        prefixIcon: const Icon(Icons.lock,
                            color: AppColors.purpleLight),
                        border: const OutlineInputBorder(),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility
                                : Icons.visibility_off,
                            color: AppColors.purpleLight,
                          ),
                          onPressed: () {
                            setState(() {
                              _obscurePassword = !_obscurePassword;
                            });
                          },
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a password';
                        }
                        if (value.length < 6) {
                          return 'Password must be at least 6 characters';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Department Dropdown
                    DropdownButtonFormField<String>(
                      decoration: const InputDecoration(
                        labelText: 'Department',
                        prefixIcon:
                            Icon(Icons.business, color: AppColors.purpleLight),
                        border: OutlineInputBorder(),
                      ),
                      value: _selectedDepartmentId,
                      items: _departments.map((department) {
                        return DropdownMenuItem<String>(
                          value: department['id'].toString(),
                          child: Text(department['name']),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedDepartmentId = value;
                        });
                      },
                      hint: const Text('Select Department'),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please select a department';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Role Field
                    TextFormField(
                      controller: _roleController,
                      decoration: const InputDecoration(
                          labelText: 'Role',
                          prefixIcon:
                              Icon(Icons.work, color: AppColors.purpleLight),
                          border: OutlineInputBorder(),
                          hintText: 'e.g., Student, Professor, Assistant'),
                    ),
                    const SizedBox(height: 32),

                    // Register Button
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _registerNewUser,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryPurple,
                          foregroundColor: Colors.white,
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white),
                                  strokeWidth: 2.0,
                                ),
                              )
                            : const Text('Register User'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
