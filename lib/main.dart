import 'package:flutter/material.dart';
import 'package:dbms_proj/util/theme.dart';
import 'package:dbms_proj/Screens/login.dart';
import 'package:dbms_proj/Screens/home.dart';
import 'package:dbms_proj/Screens/admin_dashboard.dart';
import 'package:dbms_proj/Screens/register_user_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

Future<void> main() async {
  await Supabase.initialize(
    url: 'https://qsqypgtgrbdqugjjbzvb.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InFzcXlwZ3RncmJkcXVnampienZiIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDYzNzk1NDksImV4cCI6MjA2MTk1NTU0OX0.RXhtwIaHMif_42idt8YM7hLX0pETfU_lksXPJkhuj3c',
  );
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Community App',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: const LoginScreen(),
      routes: {
        '/login': (context) => const LoginScreen(),
        '/home': (context) => const Home(),
        '/admin_dashboard': (context) => const AdminDashboardScreen(),
        '/register_user': (context) => const RegisterUserScreen(),
      },
      initialRoute: '/login',
    );
  }
}
