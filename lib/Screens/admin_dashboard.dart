import 'package:flutter/material.dart';
import 'package:dbms_proj/util/theme.dart';
import 'package:dbms_proj/util/functions.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Get Supabase client instance
final supabase = Supabase.instance.client;

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen>
    with SingleTickerProviderStateMixin {
  bool _isLoading = true;
  List<Map<String, dynamic>> _users = [];
  List<Map<String, dynamic>> _messages = [];
  Map<String, dynamic> _stats = {
    'totalUsers': 0,
    'totalMessages': 0,
    'totalDepartments': 0,
    'totalAdmins': 0,
  };

  // Tab controller
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // Load all necessary data
  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Load users with their profiles and departments
      final usersResponse = await supabase
          .from('users')
          .select('*, profile(*), department(name)')
          .order('name');

      // Load recent messages
      final messagesResponse = await supabase
          .from('globalchat')
          .select('*, users(name, email)')
          .order('created_at', ascending: false)
          .limit(50); // Get statistics using count() method
      final totalUsers = await supabase.from('users').count();

      final totalMessages = await supabase.from('globalchat').count();

      final totalDepartments = await supabase.from('department').count();

      final totalAdmins =
          await supabase.from('users').select().eq('isadmin', true).count();

      if (mounted) {
        setState(() {
          _users = List<Map<String, dynamic>>.from(usersResponse);
          _messages = List<Map<String, dynamic>>.from(messagesResponse);
          _stats = {
            'totalUsers': totalUsers ?? 0,
            'totalMessages': totalMessages ?? 0,
            'totalDepartments': totalDepartments ?? 0,
            'totalAdmins': totalAdmins ?? 0,
          };
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading admin data: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        showErrorSnackBar(context, 'Failed to load admin data');
      }
    }
  }

  // Toggle user admin status
  Future<void> _toggleAdminStatus(String userId, bool currentStatus) async {
    try {
      await supabase
          .from('users')
          .update({'isadmin': !currentStatus}).eq('userid', userId);

      showSuccessSnackBar(context, 'User status updated');
      _loadData(); // Reload data to reflect changes
    } catch (e) {
      print('Error toggling admin status: $e');
      showErrorSnackBar(context, 'Failed to update user status');
    }
  }

  // Delete a message
  Future<void> _deleteMessage(String messageId) async {
    try {
      await supabase.from('globalchat').delete().eq('messageid', messageId);

      showSuccessSnackBar(context, 'Message deleted');
      _loadData(); // Reload data to reflect changes
    } catch (e) {
      print('Error deleting message: $e');
      showErrorSnackBar(context, 'Failed to delete message');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Overview'),
            Tab(text: 'Users'),
            Tab(text: 'Messages'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildOverviewTab(),
                _buildUsersTab(),
                _buildMessagesTab(),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _loadData,
        backgroundColor: AppColors.purpleLight,
        child: const Icon(Icons.refresh),
      ),
    );
  }

  // Overview tab with statistics and quick actions
  Widget _buildOverviewTab() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'System Overview',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),

          // Stats cards in a grid
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            childAspectRatio: 1.5,
            children: [
              _buildStatCard('Total Users', _stats['totalUsers'].toString(),
                  Icons.people, AppColors.purpleLight),
              _buildStatCard(
                  'Total Messages',
                  _stats['totalMessages'].toString(),
                  Icons.message,
                  Colors.green),
              _buildStatCard(
                  'Departments',
                  _stats['totalDepartments'].toString(),
                  Icons.business,
                  Colors.orange),
              _buildStatCard('Admin Users', _stats['totalAdmins'].toString(),
                  Icons.admin_panel_settings, Colors.blue),
            ],
          ),

          const SizedBox(height: 32),
          const Text(
            'Admin Actions',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),

          // Quick action buttons
          Column(
            children: [
              _buildActionButton(
                'Register New User',
                Icons.person_add,
                AppColors.purpleLight,
                () {
                  Navigator.pushNamed(context, '/register_user');
                },
              ),
              const SizedBox(height: 12),
              _buildActionButton(
                'Moderate Messages',
                Icons.message,
                Colors.green,
                () {
                  _tabController.animateTo(2); // Switch to Messages tab
                },
              ),
              const SizedBox(height: 12),
              _buildActionButton(
                'Manage User Access',
                Icons.security,
                Colors.blue,
                () {
                  _tabController.animateTo(1); // Switch to Users tab
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Stat card widget
  Widget _buildStatCard(
      String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            colors: [
              color.withOpacity(0.7),
              color.withOpacity(0.5),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 28),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Action button widget
  Widget _buildActionButton(
      String title, IconData icon, Color color, VoidCallback onTap) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
          decoration: BoxDecoration(
            border: Border.all(color: color.withOpacity(0.3)),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(icon, color: color),
              const SizedBox(width: 16),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Spacer(),
              Icon(
                Icons.arrow_forward_ios,
                color: AppColors.textSecondary,
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Users management tab
  Widget _buildUsersTab() {
    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: _users.length,
      itemBuilder: (context, index) {
        final user = _users[index];
        final bool isAdmin = user['isadmin'] == true;
        final String name = user['name'] ?? 'Unknown User';
        final String email = user['email'] ?? 'No email';
        final String role = user['profile']?['role'] ?? 'No role';
        final String department =
            user['department']?['name'] ?? 'No department';

        return Card(
          margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color: isAdmin
                  ? AppColors.purpleLight.withOpacity(0.5)
                  : Colors.transparent,
              width: isAdmin ? 1 : 0,
            ),
          ),
          child: ListTile(
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            leading: CircleAvatar(
              backgroundColor:
                  isAdmin ? AppColors.purpleLight : AppColors.surfaceVariant,
              child: Text(
                name.isNotEmpty ? name[0].toUpperCase() : '?',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
            title: Text(
              name,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(email),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Dept: $department',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        'Role: $role',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isAdmin)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.purpleLight,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'Admin',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                const SizedBox(width: 8),
                IconButton(
                  icon: Icon(
                    isAdmin ? Icons.person_remove : Icons.admin_panel_settings,
                    color: isAdmin ? Colors.red : Colors.green,
                  ),
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: Text(isAdmin ? 'Remove Admin' : 'Make Admin'),
                        content: Text(isAdmin
                            ? 'Remove admin privileges from ${user['name']}?'
                            : 'Grant admin privileges to ${user['name']}?'),
                        actions: [
                          TextButton(
                            child: const Text('Cancel'),
                            onPressed: () => Navigator.pop(context),
                          ),
                          TextButton(
                            child: Text(isAdmin ? 'Remove' : 'Grant'),
                            onPressed: () {
                              Navigator.pop(context);
                              _toggleAdminStatus(user['userid'], isAdmin);
                            },
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
            onTap: () {
              // View user details
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: Text(name),
                  content: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildUserDetailItem('Email', email),
                        _buildUserDetailItem('Department', department),
                        _buildUserDetailItem('Role', role),
                        _buildUserDetailItem('Admin', isAdmin ? 'Yes' : 'No'),
                        if (user['profile'] != null) ...[
                          _buildUserDetailItem(
                              'Bio', user['profile']['bio'] ?? 'Not provided'),
                          _buildUserDetailItem('Institute',
                              user['profile']['institute'] ?? 'Not provided'),
                        ],
                      ],
                    ),
                  ),
                  actions: [
                    TextButton(
                      child: const Text('Close'),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  // Helper method for user details dialog
  Widget _buildUserDetailItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
            ),
          ),
          const Divider(),
        ],
      ),
    );
  }

  // Messages moderation tab
  Widget _buildMessagesTab() {
    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: _messages.length,
      itemBuilder: (context, index) {
        final message = _messages[index];
        final DateTime timestamp = DateTime.parse(message['created_at']);
        final String formattedDate =
            '${timestamp.day}/${timestamp.month}/${timestamp.year} ${timestamp.hour}:${timestamp.minute.toString().padLeft(2, '0')}';
        final String senderName = message['users']?['name'] ?? 'Unknown User';
        final String messageText = message['message'] ?? '';

        return Card(
          margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: ListTile(
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            title: Row(
              children: [
                Text(
                  senderName,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  formattedDate,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Text(
                  messageText,
                  style: const TextStyle(
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Message ID: ${message['messageid']}',
                  style: TextStyle(
                    fontSize: 10,
                    color: AppColors.textSecondary.withOpacity(0.7),
                  ),
                ),
              ],
            ),
            trailing: IconButton(
              icon: const Icon(
                Icons.delete,
                color: Colors.red,
              ),
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Delete Message'),
                    content: const Text(
                        'Are you sure you want to delete this message? This action cannot be undone.'),
                    actions: [
                      TextButton(
                        child: const Text('Cancel'),
                        onPressed: () => Navigator.pop(context),
                      ),
                      TextButton(
                        child: const Text('Delete'),
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.red,
                        ),
                        onPressed: () {
                          Navigator.pop(context);
                          _deleteMessage(message['messageid'].toString());
                        },
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }
}
