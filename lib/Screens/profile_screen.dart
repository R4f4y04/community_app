import 'package:flutter/material.dart';
import 'package:dbms_proj/util/functions.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Get Supabase client instance
final supabase = Supabase.instance.client;

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _isLoading = true;
  bool _isEditing = false;
  final _formKey = GlobalKey<FormState>();

  // User data
  Map<String, dynamic>? _userData;
  Map<String, dynamic>? _profileData;
  Map<String, dynamic>? _departmentData;
  bool _isAdmin = false; // Flag to track admin status

  // Form controllers
  late TextEditingController _nameController;
  late TextEditingController _bioController;
  late TextEditingController _instituteController;
  late TextEditingController _roleController;
  late TextEditingController _degreeDetailsController;
  String? _profileImageUrl;

  @override
  void initState() {
    super.initState();
    // Initialize controllers
    _nameController = TextEditingController();
    _bioController = TextEditingController();
    _instituteController = TextEditingController();
    _roleController = TextEditingController();
    _degreeDetailsController = TextEditingController();

    // Fetch user profile data
    _fetchUserProfile();
  }

  @override
  void dispose() {
    // Dispose all controllers
    _nameController.dispose();
    _bioController.dispose();
    _instituteController.dispose();
    _roleController.dispose();
    _degreeDetailsController.dispose();
    super.dispose();
  }

  // Fetch user profile from Supabase
  Future<void> _fetchUserProfile() async {
    setState(() {
      _isLoading = true;
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

      setState(() {
        _userData = data;
        _profileData = data['profile']; // Lowercase to match database schema
        _departmentData =
            data['department']; // Lowercase to match database schema
        _isAdmin = _userData?['isadmin'] == true; // Set admin status

        // Set controller values with lowercase field names to match schema
        _nameController.text = _userData?['name'] ?? '';
        _bioController.text = _profileData?['bio'] ?? '';
        _instituteController.text = _profileData?['institute'] ?? '';
        _roleController.text = _profileData?['role'] ?? '';
        _degreeDetailsController.text = _profileData?['degreedetails'] ?? '';
        _profileImageUrl = _profileData?['profilepicture'];

        _isLoading = false;
      });
    } catch (e) {
      print('Error fetching profile: $e');
      showErrorSnackBar(context, 'Failed to load profile data');
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Update profile in Supabase
  Future<void> _updateProfile() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      try {
        setState(() {
          _isLoading = true;
        });

        final supabase = Supabase.instance.client;
        final userId = supabase.auth.currentUser!.id;

        // Update profile data with lowercase column names
        await supabase.from('profile').update({
          'bio': _bioController.text,
          'institute': _instituteController.text,
          'role': _roleController.text,
          'degreedetails': _degreeDetailsController.text,
        }).eq('userid', userId);

        // Update user's name
        await supabase.from('users').update({
          'name': _nameController.text,
        }).eq('userid',
            userId); // Changed from 'id' to 'userid' to match database schema

        setState(() {
          // Update local data to reflect changes
          if (_userData != null) {
            _userData!['name'] = _nameController.text;
          }

          if (_profileData != null) {
            _profileData!['bio'] = _bioController.text;
            _profileData!['institute'] = _instituteController.text;
            _profileData!['role'] = _roleController.text;
            _profileData!['degreedetails'] = _degreeDetailsController.text;
          }

          _isEditing = false;
          _isLoading = false;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Profile updated successfully')),
          );

          // Return to the previous screen with result
          Navigator.pop(
              context, true); // Return true to indicate profile was updated
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error updating profile: ${e.toString()}')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          if (!_isLoading && !_isEditing)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () {
                setState(() {
                  _isEditing = true;
                });
              },
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _isEditing
              ? _buildEditProfileForm()
              : _buildProfileView(),
      bottomNavigationBar: _isEditing
          ? Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        setState(() {
                          _isEditing = false;
                          // Reset controllers to original values with lowercase field names to match schema
                          _nameController.text = _userData?['name'] ?? '';
                          _bioController.text = _profileData?['bio'] ?? '';
                          _instituteController.text =
                              _profileData?['institute'] ?? '';
                          _roleController.text = _profileData?['role'] ?? '';
                          _degreeDetailsController.text =
                              _profileData?['degreedetails'] ?? '';
                        });
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey[700],
                      ),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _updateProfile,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.primary,
                      ),
                      child: const Text('Save Changes'),
                    ),
                  ),
                ],
              ),
            )
          : null,
    );
  }

  // Profile view mode
  Widget _buildProfileView() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    String initials = (_userData?['name'] ?? 'User')
        .split(' ')
        .map((e) => e.isNotEmpty ? e[0] : '')
        .join('')
        .toUpperCase();
    if (initials.length > 2) {
      initials = initials.substring(0, 2);
    }
    bool hasValidImageUrl = _profileImageUrl != null &&
        _profileImageUrl!.isNotEmpty &&
        Uri.parse(_profileImageUrl!).hasScheme &&
        (Uri.parse(_profileImageUrl!).scheme == 'http' ||
            Uri.parse(_profileImageUrl!).scheme == 'https');
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Profile header
          Center(
            child: Column(
              children: [
                // Profile image
                Hero(
                  tag: 'profileAvatar',
                  child: CircleAvatar(
                    radius: 60,
                    backgroundColor: colorScheme.primary,
                    backgroundImage: hasValidImageUrl
                        ? NetworkImage(_profileImageUrl!)
                        : null,
                    child: !hasValidImageUrl
                        ? Text(
                            initials,
                            style: theme.textTheme.titleLarge?.copyWith(
                              color: colorScheme.onPrimary,
                              fontWeight: FontWeight.bold,
                              fontSize: 36,
                            ),
                          )
                        : null,
                  ),
                ),
                const SizedBox(height: 16),
                // Name
                Text(
                  _userData?['name'] ?? 'User',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                // Department
                Text(
                  _departmentData?['name'] ?? 'Department',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
                const SizedBox(height: 8),
                // Email
                Text(
                  _userData?['email'] ?? 'email@example.com',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: colorScheme.onSurface.withOpacity(0.7),
                  ),
                ),
                const SizedBox(height: 16),
                // Admin Badge
                if (_isAdmin)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    decoration: BoxDecoration(
                      color: colorScheme.primary,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: colorScheme.primary.withOpacity(0.4),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.admin_panel_settings,
                          color: colorScheme.onPrimary,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Administrator',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onPrimary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          // Bio section
          if (_profileData?['bio'] != null && _profileData?['bio'].isNotEmpty)
            _buildProfileSection('About Me', _profileData?['bio'] ?? ''),
          // Institute section
          if (_profileData?['institute'] != null &&
              _profileData?['institute'].isNotEmpty)
            _buildProfileSection('Institute', _profileData?['institute'] ?? ''),
          // Role section
          if (_profileData?['role'] != null && _profileData?['role'].isNotEmpty)
            _buildProfileSection('Role', _profileData?['role'] ?? ''),
          // Degree details section
          if (_profileData?['degreedetails'] != null &&
              _profileData?['degreedetails'].isNotEmpty)
            _buildProfileSection(
                'Degree Details', _profileData?['degreedetails'] ?? ''),
        ],
      ),
    );
  }

  // Helper method to build a profile section
  Widget _buildProfileSection(String title, String content,
      {bool isHighlighted = false}) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: isHighlighted ? colorScheme.primary : colorScheme.primary,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          content,
          style: theme.textTheme.bodyLarge?.copyWith(
            color:
                title == 'Role' ? colorScheme.primary : colorScheme.onSurface,
            fontWeight: title == 'Role' ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  // Profile edit mode
  Widget _buildEditProfileForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Profile image section
            Center(
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 60,
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    backgroundImage: (_profileImageUrl != null &&
                            _profileImageUrl!.isNotEmpty &&
                            Uri.parse(_profileImageUrl!).hasScheme &&
                            (Uri.parse(_profileImageUrl!).scheme == 'http' ||
                                Uri.parse(_profileImageUrl!).scheme == 'https'))
                        ? NetworkImage(_profileImageUrl!)
                        : null,
                    child: Stack(
                      children: [
                        if (_profileImageUrl == null ||
                            _profileImageUrl!.isEmpty ||
                            !Uri.parse(_profileImageUrl!).hasScheme ||
                            (Uri.parse(_profileImageUrl!).scheme != 'http' &&
                                Uri.parse(_profileImageUrl!).scheme != 'https'))
                          Center(
                            child: Text(
                              (_userData?['name'] ?? 'User')
                                  .split(' ')
                                  .map((e) => e.isNotEmpty ? e[0] : '')
                                  .join('')
                                  .toUpperCase()
                                  .substring(0, 2),
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 36,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),

            // Name field
            TextFormField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: 'Name',
                border: const OutlineInputBorder(),
                prefixIcon: Icon(Icons.person,
                    color: Theme.of(context).colorScheme.primary),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter your name';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Bio field
            TextFormField(
              controller: _bioController,
              decoration: InputDecoration(
                labelText: 'Bio',
                border: const OutlineInputBorder(),
                prefixIcon: Icon(Icons.description,
                    color: Theme.of(context).colorScheme.primary),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 16),

            // Institute field
            TextFormField(
              controller: _instituteController,
              decoration: InputDecoration(
                labelText: 'Institute',
                border: const OutlineInputBorder(),
                prefixIcon: Icon(Icons.school,
                    color: Theme.of(context).colorScheme.primary),
              ),
            ),
            const SizedBox(height: 16),

            // Role field
            TextFormField(
              controller: _roleController,
              decoration: InputDecoration(
                labelText: 'Role',
                border: const OutlineInputBorder(),
                prefixIcon: Icon(Icons.work,
                    color: Theme.of(context).colorScheme.primary),
              ),
            ),
            const SizedBox(height: 16),

            // Degree details field
            TextFormField(
              controller: _degreeDetailsController,
              decoration: InputDecoration(
                labelText: 'Degree Details',
                border: const OutlineInputBorder(),
                prefixIcon: Icon(Icons.school,
                    color: Theme.of(context).colorScheme.primary),
              ),
              maxLines: 2,
            ),
          ],
        ),
      ),
    );
  }
}
