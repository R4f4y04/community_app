import 'package:flutter/material.dart';
import 'package:dbms_proj/util/theme.dart';
import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import 'package:dbms_proj/util/functions.dart';
import 'package:dbms_proj/Screens/feed_screen.dart';
import 'package:dbms_proj/Screens/chat_screen.dart';
import 'package:dbms_proj/Screens/projects_screen.dart';
import 'package:dbms_proj/Screens/profile_screen.dart';
import 'package:dbms_proj/Screens/admin_dashboard.dart';
import 'package:dbms_proj/Screens/settings_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:provider/provider.dart';
import 'package:dbms_proj/util/theme_provider.dart';

// Get Supabase client instance
final supabase = Supabase.instance.client;

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  int _selectedIndex = 0;

  // User data
  Map<String, dynamic>? _userData;
  Map<String, dynamic>? _profileData;
  Map<String, dynamic>? _departmentData;
  String? _profileImageUrl;
  String _userInitials = '';
  String _userName = 'User';
  String _departmentName = '';
  bool _isAdmin = false; // Flag to track admin status

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

  @override
  void initState() {
    super.initState();
    _fetchUserProfile();
  }

  // Fetch user profile from Supabase
  Future<void> _fetchUserProfile() async {
    setState(() {
      // _isLoading = true;
    });

    try {
      // Get current authenticated user
      final user = supabase.auth.currentUser;
      if (user == null) {
        showErrorSnackBar(context, 'User not authenticated');
        Navigator.pushReplacementNamed(context, '/login');
        return;
      }

      // Fetch user data with profile and department info
      final data = await supabase
          .from('users')
          .select('*, profile(*), department(*)')
          .eq('userid', user.id)
          .single();

      // Make sure widget is still mounted before setting state
      if (!mounted) return;

      setState(() {
        _userData = data;
        _profileData = data['profile'];
        _departmentData = data['department'];
        _profileImageUrl = _profileData?['profilepicture'];
        _userName = _userData?['name'] ?? 'User';
        _departmentName = _departmentData?['name'] ?? '';
        _isAdmin = _userData?['isadmin'] == true; // Set admin status

        // Generate initials from name
        _userInitials = _getUserInitials(_userName);

        // _isLoading = false;
      });
    } catch (e) {
      print('Error fetching profile: $e');
      if (mounted) {
        setState(() {
          // _isLoading = false;
        });
      }
    }
  }

  // Get user initials from name
  String _getUserInitials(String name) {
    String initials = name
        .split(' ')
        .map((e) => e.isNotEmpty ? e[0] : '')
        .join('')
        .toUpperCase();

    if (initials.length > 2) {
      initials = initials.substring(0, 2);
    }
    return initials;
  }

  // Check if profile image URL is valid
  bool _hasValidImageUrl() {
    return _profileImageUrl != null &&
        _profileImageUrl!.isNotEmpty &&
        Uri.parse(_profileImageUrl!).hasScheme &&
        (Uri.parse(_profileImageUrl!).scheme == 'http' ||
            Uri.parse(_profileImageUrl!).scheme == 'https');
  }

  // Get profile image URL with cache-busting parameter
  String? _getProfileImageWithCacheBusting() {
    if (!_hasValidImageUrl()) return null;

    // Add timestamp as a query parameter to prevent caching
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final separator = _profileImageUrl!.contains('?') ? '&' : '?';
    return '$_profileImageUrl${separator}t=$timestamp';
  }

  void _showProfileMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        final theme = Theme.of(context);
        final colorScheme = theme.colorScheme;
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircleAvatar(
                radius: 40,
                backgroundColor: colorScheme.primary.withOpacity(0.2),
                backgroundImage: _hasValidImageUrl()
                    ? NetworkImage(_getProfileImageWithCacheBusting()!)
                    : null,
                child: !_hasValidImageUrl()
                    ? Text(
                        _userInitials,
                        style: theme.textTheme.titleLarge?.copyWith(
                          color: colorScheme.onPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                      )
                    : null,
              ),
              const SizedBox(height: 16),
              Text(
                _userName,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _departmentName,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
              const SizedBox(height: 24),
              ListTile(
                leading: Icon(Icons.person, color: colorScheme.primary),
                title: const Text('View Profile'),
                onTap: () async {
                  Navigator.pop(context);
                  // Navigate to profile page
                  final profileUpdated = await Navigator.push<bool>(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const ProfileScreen()),
                  );

                  // Force refresh profile data when returning from profile screen if updates were made
                  if (mounted && (profileUpdated == true)) {
                    // Clear cached data explicitly
                    setState(() {
                      _profileImageUrl = null;
                      _userData = null;
                      _profileData = null;
                    });

                    // Fetch fresh data from the server
                    await _fetchUserProfile();
                  }
                },
              ),
              ListTile(
                leading: Icon(Icons.settings, color: colorScheme.primary),
                title: const Text('Settings'),
                onTap: () async {
                  Navigator.pop(context);
                  // Navigate to settings page with theme control
                  final themeProvider =
                      Provider.of<ThemeProvider>(context, listen: false);
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => SettingsScreen(
                        isDarkMode: themeProvider.isDarkMode,
                        onThemeChanged: (isDark) =>
                            themeProvider.toggleTheme(isDark),
                      ),
                    ),
                  );
                },
              ),
              // Admin Dashboard option (only for admins)
              if (_isAdmin)
                ListTile(
                  leading: Icon(Icons.admin_panel_settings,
                      color: colorScheme.primary),
                  title: const Text('Admin Dashboard'),
                  onTap: () {
                    Navigator.pop(context);
                    // Navigate to admin dashboard screen
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const AdminDashboardScreen()),
                    );
                  },
                ),
              ListTile(
                leading: Icon(Icons.logout, color: colorScheme.primary),
                title: const Text('Logout'),
                onTap: () async {
                  await Supabase.instance.client.auth.signOut();
                  Navigator.pop(context);
                  showSuccessSnackBar(context, 'Logged out successfully');
                  // Navigate to login page using named route after a short delay
                  Navigator.pushReplacementNamed(context, '/login');
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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(_sectionTitles[_selectedIndex],
            style: theme.appBarTheme.titleTextStyle),
        automaticallyImplyLeading: false, // Remove back button
        backgroundColor: theme.appBarTheme.backgroundColor,
        foregroundColor: theme.appBarTheme.foregroundColor,
        elevation: theme.appBarTheme.elevation,
        actions: [
          IconButton(
            icon: Icon(Icons.search, color: theme.iconTheme.color),
            onPressed: () {
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
                  backgroundColor: colorScheme.primary,
                  backgroundImage: _hasValidImageUrl()
                      ? NetworkImage(_getProfileImageWithCacheBusting()!)
                      : null,
                  child: !_hasValidImageUrl()
                      ? Text(
                          _userInitials,
                          style: theme.textTheme.labelLarge?.copyWith(
                              fontSize: 12, color: colorScheme.onPrimary),
                        )
                      : null,
                ),
              ),
            ),
          ),
        ],
      ),
      body: _screens[_selectedIndex],
      bottomNavigationBar: CurvedNavigationBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        color: theme.cardColor,
        buttonBackgroundColor: colorScheme.primary,
        height: 60,
        animationDuration: const Duration(milliseconds: 300),
        index: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        items: [
          Icon(Icons.home, color: colorScheme.onPrimary),
          Icon(Icons.chat_bubble, color: colorScheme.onPrimary),
          Icon(Icons.work, color: colorScheme.onPrimary),
        ],
      ),
    );
  }
}
