import 'package:flutter/material.dart';
import 'package:dbms_proj/util/theme.dart';
import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import 'package:dbms_proj/util/functions.dart';
import 'package:dbms_proj/Screens/feed_screen.dart';
import 'package:dbms_proj/Screens/chat_screen.dart';
import 'package:dbms_proj/Screens/projects_screen.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  int _selectedIndex = 0;

  // List of section titles for app bar
  final List<String> _sectionTitles = [
    "Community Feed",
    "Group Chat",
    "Projects",
  ];

  // List of screens for each tab
  final List<Widget> _screens = [
    const FeedScreen(),
    const ChatScreen(),
    const ProjectsScreen(),
  ];

  void _showProfileMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircleAvatar(
                radius: 40,
                backgroundColor: AppColors.purpleLight,
                child: Text(
                  'AJ',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 24,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Alex Johnson',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Computer Science',
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 24),
              ListTile(
                leading: const Icon(Icons.person, color: AppColors.purpleLight),
                title: const Text('View Profile'),
                onTap: () {
                  Navigator.pop(context);
                  // Navigate to profile page (to be implemented)
                  showInfoSnackBar(context, 'Profile page coming soon!');
                },
              ),
              ListTile(
                leading:
                    const Icon(Icons.settings, color: AppColors.purpleLight),
                title: const Text('Settings'),
                onTap: () {
                  Navigator.pop(context);
                  // Navigate to settings page (to be implemented)
                  showInfoSnackBar(context, 'Settings page coming soon!');
                },
              ),
              ListTile(
                leading: const Icon(Icons.logout, color: AppColors.purpleLight),
                title: const Text('Logout'),
                onTap: () {
                  Navigator.pop(context);
                  showSuccessSnackBar(context, 'Logged out successfully');
                  // Navigate to login page using named route after a short delay
                  Future.delayed(const Duration(seconds: 1), () {
                    Navigator.pushReplacementNamed(context, '/login');
                  });
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(_sectionTitles[_selectedIndex]),
        automaticallyImplyLeading: false, // Remove back button
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              // Search functionality
              showInfoSnackBar(context, 'Search feature coming soon!');
            },
          ),
          GestureDetector(
            onTap: _showProfileMenu,
            child: Padding(
              padding: const EdgeInsets.only(right: 16.0),
              child: Hero(
                tag: 'profileAvatar',
                child: CircleAvatar(
                  radius: 18,
                  backgroundColor: AppColors.purpleLight,
                  child: const Text(
                    'AJ',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: _screens[_selectedIndex],
      floatingActionButton: _selectedIndex == 0
          ? FloatingActionButton(
              onPressed: () {
                // Create a new post
                showInfoSnackBar(context, 'New post creation coming soon!');
              },
              backgroundColor: AppColors.primaryPurple,
              child: const Icon(Icons.add),
            )
          : null,
      bottomNavigationBar: CurvedNavigationBar(
        backgroundColor: AppColors.background,
        color: AppColors.surface,
        buttonBackgroundColor: AppColors.primaryPurple,
        height: 60,
        animationDuration: const Duration(milliseconds: 300),
        index: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        items: const [
          Icon(Icons.home, color: Colors.white),
          Icon(Icons.chat_bubble, color: Colors.white),
          Icon(Icons.work, color: Colors.white),
        ],
      ),
    );
  }
}
