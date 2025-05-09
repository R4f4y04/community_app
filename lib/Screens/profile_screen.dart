import 'package:flutter/material.dart';
import 'package:dbms_proj/util/theme.dart';
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
          .from('Users')
          .select('*, Profile(*), Department(*)')
          .eq('UserID', user.id)
          .single();

      setState(() {
        _userData = data;
        _profileData = data['Profile'];
        _departmentData = data['Department'];

        // Set controller values
        _nameController.text = _userData?['Name'] ?? '';
        _bioController.text = _profileData?['Bio'] ?? '';
        _instituteController.text = _profileData?['Institute'] ?? '';
        _roleController.text = _profileData?['Role'] ?? '';
        _degreeDetailsController.text = _profileData?['DegreeDetails'] ?? '';
        _profileImageUrl = _profileData?['ProfilePicture'];

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
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Get current user ID
      final userId = supabase.auth.currentUser?.id;

      if (userId == null) {
        showErrorSnackBar(context, 'User not authenticated');
        return;
      }

      // Update Users table
      await supabase.from('Users').update({
        'Name': _nameController.text,
      }).eq('UserID', userId);

      // Update Profile table
      await supabase.from('Profile').update({
        'Bio': _bioController.text,
        'Institute': _instituteController.text,
        'Role': _roleController.text,
        'DegreeDetails': _degreeDetailsController.text,
      }).eq('UserID', userId);

      showSuccessSnackBar(context, 'Profile updated successfully');

      // Refresh profile data
      await _fetchUserProfile();

      setState(() {
        _isEditing = false;
      });
    } catch (e) {
      print('Error updating profile: $e');
      showErrorSnackBar(context, 'Failed to update profile');
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
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
                          // Reset controllers to original values
                          _nameController.text = _userData?['Name'] ?? '';
                          _bioController.text = _profileData?['Bio'] ?? '';
                          _instituteController.text =
                              _profileData?['Institute'] ?? '';
                          _roleController.text = _profileData?['Role'] ?? '';
                          _degreeDetailsController.text =
                              _profileData?['DegreeDetails'] ?? '';
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
                        backgroundColor: AppColors.primaryPurple,
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
    String initials = (_userData?['Name'] ?? 'User')
        .split(' ')
        .map((e) => e.isNotEmpty ? e[0] : '')
        .join('')
        .toUpperCase();

    if (initials.length > 2) {
      initials = initials.substring(0, 2);
    }

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
                    backgroundColor: AppColors.purpleLight,
                    backgroundImage: _profileImageUrl != null
                        ? NetworkImage(_profileImageUrl!)
                        : null,
                    child: _profileImageUrl == null
                        ? Text(
                            initials,
                            style: const TextStyle(
                              color: Colors.white,
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
                  _userData?['Name'] ?? 'User',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 8),
                // Department
                Text(
                  _departmentData?['Name'] ?? 'Department',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                ),
                const SizedBox(height: 8),
                // Email
                Text(
                  _userData?['Email'] ?? 'email@example.com',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),

          // Bio section
          if (_profileData?['Bio'] != null && _profileData?['Bio'].isNotEmpty)
            _buildProfileSection(
              'About Me',
              _profileData?['Bio'] ?? '',
            ),

          // Institute section
          if (_profileData?['Institute'] != null &&
              _profileData?['Institute'].isNotEmpty)
            _buildProfileSection(
              'Institute',
              _profileData?['Institute'] ?? '',
            ),

          // Role section
          if (_profileData?['Role'] != null && _profileData?['Role'].isNotEmpty)
            _buildProfileSection(
              'Role',
              _profileData?['Role'] ?? '',
            ),

          // Degree details section
          if (_profileData?['DegreeDetails'] != null &&
              _profileData?['DegreeDetails'].isNotEmpty)
            _buildProfileSection(
              'Degree Details',
              _profileData?['DegreeDetails'] ?? '',
            ),
        ],
      ),
    );
  }

  // Helper method to build a profile section
  Widget _buildProfileSection(String title, String content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.purpleLight,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          content,
          style: const TextStyle(
            fontSize: 16,
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
                    backgroundColor: AppColors.purpleLight,
                    backgroundImage: _profileImageUrl != null
                        ? NetworkImage(_profileImageUrl!)
                        : null,
                    child: Stack(
                      children: [
                        if (_profileImageUrl == null)
                          Center(
                            child: Text(
                              (_userData?['Name'] ?? 'User')
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
                        Positioned(
                          right: 0,
                          bottom: 0,
                          child: CircleAvatar(
                            radius: 20,
                            backgroundColor: AppColors.surface,
                            child: IconButton(
                              icon: const Icon(
                                Icons.camera_alt,
                                color: AppColors.purpleLight,
                              ),
                              onPressed: () {
                                // Image upload functionality will be implemented later
                                showInfoSnackBar(
                                    context, 'Image upload coming soon!');
                              },
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
              decoration: const InputDecoration(
                labelText: 'Name',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.person, color: AppColors.purpleLight),
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
              decoration: const InputDecoration(
                labelText: 'Bio',
                border: OutlineInputBorder(),
                prefixIcon:
                    Icon(Icons.description, color: AppColors.purpleLight),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 16),

            // Institute field
            TextFormField(
              controller: _instituteController,
              decoration: const InputDecoration(
                labelText: 'Institute',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.school, color: AppColors.purpleLight),
              ),
            ),
            const SizedBox(height: 16),

            // Role field
            TextFormField(
              controller: _roleController,
              decoration: const InputDecoration(
                labelText: 'Role',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.work, color: AppColors.purpleLight),
              ),
            ),
            const SizedBox(height: 16),

            // Degree details field
            TextFormField(
              controller: _degreeDetailsController,
              decoration: const InputDecoration(
                labelText: 'Degree Details',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.school, color: AppColors.purpleLight),
              ),
              maxLines: 2,
            ),
          ],
        ),
      ),
    );
  }
}
