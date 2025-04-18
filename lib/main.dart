import 'package:flutter/material.dart';
import 'package:dbms_proj/util/theme.dart';
import 'package:dbms_proj/Screens/login.dart';
import 'package:dbms_proj/Screens/home.dart';

void main() {
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
      },
      initialRoute: '/login',
    );
  }
}
