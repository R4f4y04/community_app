import 'package:dbms_proj/Screens/home.dart';
import 'package:flutter/material.dart';
import 'package:dbms_proj/util/functions.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Get Supabase client instance
final supabase = Supabase.instance.client;

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

  // Sign in with Supabase
  Future<void> _signIn() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      showErrorSnackBar(context, 'Please enter both email and password');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Get email and password from text controllers
      final email = _emailController.text.trim();
      final password = _passwordController.text.trim();

      // Log for debugging (remove in production)
      print('===== LOGIN ATTEMPT WITH SUPABASE =====');
      print('Email: "$email"');

      // Sign in with Supabase authentication
      final response = await supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );

      // Get user from response
      final user = response.user;
      final session = response.session;

      // Log authentication success
      print('===== SUPABASE RESPONSE =====');
      print('Auth successful: ${user != null}');

      if (user != null) {
        // Successful login
        showSuccessSnackBar(context, 'Login successful');

        // Navigate to home screen after short delay
        Navigator.pushReplacementNamed(context, '/home');
      } else {
        // This shouldn't typically happen (Supabase throws exceptions on auth failure)
        showErrorSnackBar(context, 'Authentication failed');
      }
    } on AuthException catch (error) {
      // Handle Supabase Auth exceptions
      print('Auth error: ${error.message}');
      showErrorSnackBar(context, error.message);
    } catch (e) {
      // Handle other errors
      print('Error: $e');
      showErrorSnackBar(context, 'An unexpected error occurred');
    } finally {
      // Reset loading state
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
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
                    color: Theme.of(context).colorScheme.surfaceVariant,
                    shape: BoxShape.circle,
                    border: Border.all(
                        color: Theme.of(context).colorScheme.primary, width: 2),
                  ),
                  child: Center(
                    child: Icon(
                      Icons.group,
                      size: 70,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Community App',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Sign in to connect with your community',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withOpacity(0.7),
                      ),
                ),
                const SizedBox(height: 50),

                // Email TextField
                TextField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  style: Theme.of(context).textTheme.bodyLarge,
                  decoration: InputDecoration(
                    labelText: 'Email',
                    hintText: 'Enter your email',
                    prefixIcon: Icon(Icons.email,
                        color: Theme.of(context).colorScheme.primary),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                          color: Theme.of(context).colorScheme.surfaceVariant),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                          color: Theme.of(context).colorScheme.primary,
                          width: 2),
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // Password TextField
                TextField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  style: Theme.of(context).textTheme.bodyLarge,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    hintText: 'Enter your password',
                    prefixIcon: Icon(Icons.lock,
                        color: Theme.of(context).colorScheme.primary),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_off
                            : Icons.visibility,
                        color: Theme.of(context).colorScheme.primary,
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
                      borderSide: BorderSide(
                          color: Theme.of(context).colorScheme.surfaceVariant),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                          color: Theme.of(context).colorScheme.primary,
                          width: 2),
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Forgot Password Button
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () {
                      // Using Supabase password reset
                      final email = _emailController.text.trim();
                      if (email.isEmpty) {
                        showErrorSnackBar(
                            context, 'Please enter your email first');
                      } else {
                        // Send password reset email
                        supabase.auth.resetPasswordForEmail(email);
                        showInfoSnackBar(context,
                            'Password reset instructions sent to your email');
                      }
                    },
                    child: Text(
                      'Forgot Password?',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.primary,
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
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Colors.white,
                      elevation: 5,
                      shadowColor: Theme.of(context)
                          .colorScheme
                          .primary
                          .withOpacity(0.5),
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
                    Text(
                      'Don\'t have an account? ',
                      style: TextStyle(
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withOpacity(0.7)),
                    ),
                    GestureDetector(
                      onTap: () {
                        // Show sign up info for now
                        // You can implement sign up with Supabase in the future
                        showInfoSnackBar(context, 'Sign up coming soon!');
                      },
                      child: Text(
                        'Sign Up',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.primary,
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
