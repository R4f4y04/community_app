import 'package:flutter/material.dart';
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
  int? _selectedDepartmentId;
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

  Future<void> _fetchDepartments() async {
    try {
      final response = await supabase
          .from('department')
          .select('departmentid, name')
          .order('name');
      setState(() {
        _departments = List<Map<String, dynamic>>.from(response);
      });
    } catch (e) {
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
      final authResponse = await supabase.auth.signUp(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim());

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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
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
                    Text(
                      'Create New User Account',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Enter the details to register a new user.',
                      style: theme.textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 32),
                    TextFormField(
                      controller: _nameController,
                      decoration: InputDecoration(
                        labelText: 'Full Name',
                        prefixIcon:
                            Icon(Icons.person, color: colorScheme.primary),
                        border: const OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter the user\'s name';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: InputDecoration(
                        labelText: 'Email Address',
                        prefixIcon:
                            Icon(Icons.email, color: colorScheme.primary),
                        border: const OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter an email address';
                        }
                        if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
                          return 'Please enter a valid email address';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      decoration: InputDecoration(
                        labelText: 'Password',
                        prefixIcon:
                            Icon(Icons.lock, color: colorScheme.primary),
                        border: const OutlineInputBorder(),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility
                                : Icons.visibility_off,
                            color: colorScheme.primary,
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
                    DropdownButtonFormField<int>(
                      decoration: InputDecoration(
                        labelText: 'Department',
                        prefixIcon:
                            Icon(Icons.business, color: colorScheme.primary),
                        border: const OutlineInputBorder(),
                      ),
                      value: _selectedDepartmentId,
                      items: _departments.map((department) {
                        return DropdownMenuItem<int>(
                          value: department['departmentid'],
                          child: Text(department['name'] ?? 'Unknown'),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedDepartmentId = value;
                        });
                      },
                      hint: const Text('Select Department'),
                      validator: (value) {
                        if (value == null) {
                          return 'Please select a department';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _roleController,
                      decoration: InputDecoration(
                        labelText: 'Role',
                        prefixIcon:
                            Icon(Icons.work, color: colorScheme.primary),
                        border: const OutlineInputBorder(),
                        hintText: 'e.g. Team Leader, Team Member',
                      ),
                    ),
                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _registerNewUser,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: colorScheme.primary,
                          foregroundColor: colorScheme.onPrimary,
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
