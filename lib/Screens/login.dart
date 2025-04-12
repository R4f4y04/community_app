import 'package:dbms_proj/Screens/home.dart';
import 'package:flutter/material.dart';
import 'package:dbms_proj/util/theme.dart';
import 'package:dbms_proj/util/functions.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // Test sign in function that prints request and response
  Future<void> _signIn() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      showErrorSnackBar(context, 'Please enter both email and password');
      return;
    }

    // Create request body
    final Map<String, String> requestBody = {
      'email': _emailController.text.trim(),
      'password': _passwordController.text.trim(),
    };

    // Print request data to terminal
    print('Sending login request with data:');
    print(jsonEncode(requestBody));

    try {
      // Send POST request to Node-RED server
      // Replace with your actual Node-RED endpoint
      final response = await http.post(
        Uri.parse(
            'http://192.168.100.189:1880/login'), // Use your actual IP/port
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(requestBody),
      );

      // Print response to terminal
      print('Response status code: ${response.statusCode}');
      print('Response body: ${response.body}');

      // Show result as snackbar for testing
      if (response.statusCode == 200) {
        showSuccessSnackBar(context, 'Request successful');
      } else {
        showErrorSnackBar(
            context, 'Request failed with status: ${response.statusCode}');
      }
    } catch (e) {
      // Print error to terminal
      print('Error making request: $e');
      showErrorSnackBar(context, 'Connection error: ${e.toString()}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 60),
                // Logo Space
                Container(
                  height: 120,
                  width: 120,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceVariant,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.purpleLight, width: 2),
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.group,
                      size: 70,
                      color: AppColors.purpleLight,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Community App',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Sign in to connect with your community',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                ),
                const SizedBox(height: 50),

                // Email TextField
                TextField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  style: const TextStyle(color: AppColors.textPrimary),
                  decoration: InputDecoration(
                    labelText: 'Email',
                    hintText: 'Enter your email',
                    prefixIcon:
                        const Icon(Icons.email, color: AppColors.purpleLight),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide:
                          const BorderSide(color: AppColors.surfaceVariant),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                          color: AppColors.purpleLight, width: 2),
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // Password TextField
                TextField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  style: const TextStyle(color: AppColors.textPrimary),
                  decoration: InputDecoration(
                    labelText: 'Password',
                    hintText: 'Enter your password',
                    prefixIcon:
                        const Icon(Icons.lock, color: AppColors.purpleLight),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_off
                            : Icons.visibility,
                        color: AppColors.purpleLight,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      },
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide:
                          const BorderSide(color: AppColors.surfaceVariant),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                          color: AppColors.purpleLight, width: 2),
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Forgot Password Button
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () {
                      // Let's use our info snackbar to show a message
                      showInfoSnackBar(context, 'Password reset coming soon!');
                    },
                    child: const Text(
                      'Forgot Password?',
                      style: TextStyle(
                        color: AppColors.purpleLight,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 30),

                // Login Button with loading state
                SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _signIn,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryPurple,
                      foregroundColor: Colors.white,
                      elevation: 5,
                      shadowColor: AppColors.purpleDark.withOpacity(0.5),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                    ),
                    child: _isLoading
                        ? const CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 3,
                          )
                        : const Text(
                            'SIGN IN',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.2,
                            ),
                          ),
                  ),
                ),

                const SizedBox(height: 40),

                // Don't have an account section
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'Don\'t have an account? ',
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                    GestureDetector(
                      onTap: () {
                        // Navigate to registration screen (to be implemented)
                        showInfoSnackBar(context, 'Sign up coming soon!');
                      },
                      child: const Text(
                        'Sign Up',
                        style: TextStyle(
                          color: AppColors.purpleLight,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
