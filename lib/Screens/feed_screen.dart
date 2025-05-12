import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart'
    show PostgresChangeEvent;
import 'dart:async';
import 'post_detail_screen.dart';

// Get Supabase client instance
final supabase = Supabase.instance.client;

class FeedScreen extends StatefulWidget {
  const FeedScreen({super.key});

  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> {
  String _selectedDepartment = "All";
  final List<String> _departments = [
    "All",
    "Web Dev",
    "App Dev",
    "Backend",
    "Design",
    "Marketing",
    "Finance",
    "Fullstack",
    "AI",
    "Quality Assurance",
    "Executive Council",
    "Unassigned"
  ];

  // State variables
  bool _isLoading = true;
  bool _hasError = false;
  StreamSubscription? _postsSubscription;
  // User information
  String? _userId;
  String _userDepartment = "";
  String _avatarUrl = "https://i.pravatar.cc/150?img=1";

  // Add a Set to track liked posts for the current user
  Set<String> _likedPostIds = {};

  @override
  void initState() {
    super.initState();
    _initUser();
    _loadPosts();
    _subscribeToPosts();
    _fetchLikedPosts();
  }

  @override
  void dispose() {
    _postsSubscription?.cancel();
    super.dispose();
  }

  // Initialize user data from Supabase auth session
  Future<void> _initUser() async {
    try {
      final session = supabase.auth.currentSession;
      if (session != null) {
        final userId = session.user.id;
        setState(() {
          _userId = userId;
        }); // Get user details from profile table
        final userData = await supabase
            .from('profile')
            .select('bio, profilepicture')
            .eq('userid', userId)
            .single();

        // Get user's department from users table
        final userInfo = await supabase
            .from('users')
            .select('departmentid')
            .eq('userid', userId)
            .single();
        final deptId = userInfo['departmentid']
            as int?; // Changed from 'DepartmentID' to 'departmentid'

        if (deptId != null) {
          // Get department name
          final deptData = await supabase
              .from('department')
              .select('name')
              .eq('departmentid', deptId)
              .single();
          setState(() {
            _avatarUrl = userData['profilepicture'] ??
                _avatarUrl; // Changed from 'ProfilePicture' to 'profilepicture'
            _userDepartment = deptData['name'] ?? "";
          });
        }
      }
    } catch (e) {
      debugPrint('Error loading user data: $e');
    }
  }

  // Fetch liked posts for the current user
  Future<void> _fetchLikedPosts() async {
    if (_userId == null) return;
    try {
      final response =
          await supabase.from('likes').select('postid').eq('userid', _userId!);
      setState(() {
        _likedPostIds =
            Set<String>.from(response.map((e) => e['postid'].toString()));
      });
    } catch (e) {
      debugPrint('Error fetching liked posts: $e');
    }
  }

  // Load posts from Supabase
  Future<void> _loadPosts() async {
    try {
      setState(() {
        _isLoading = true;
        _hasError = false;
      });

      // Query the post_details view which already joins all necessary tables
      final response = await supabase
          .from('post_details')
          .select()
          .order('created_at', ascending: false);

      final List<Map<String, dynamic>> formattedPosts = [];

      for (final post in response) {
        // The view already flattened the data structure, so we can access fields directly
        final DateTime createdAt = DateTime.parse(post['created_at']).toUtc();
        final String timeAgo = _getTimeAgo(createdAt);

        formattedPosts.add({
          'id': post['postid'],
          'author':
              post['name'] ?? 'Unknown User', // This is user name from the view
          'department': post['department_name'] ??
              'General', // Department name from the view
          'title': post['title'] ?? 'Untitled Post',
          'content': post['content'] ?? '',
          'likes': post['likes_count'] ?? 0,
          'comments': post['comments_count'] ?? 0,
          'timestamp': timeAgo,
          'avatar': post['profilepicture'] ??
              'https://i.pravatar.cc/150?img=1', // Lowercase as per schema
          'raw_data': post,
        });
      }

      setState(() {
        _posts = formattedPosts;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _hasError = true;
      });
      debugPrint('Error loading posts: $e');
    }
  }

  // Subscribe to real-time updates for posts, comments, and likes
  void _subscribeToPosts() {
    final channel = supabase.channel('schema-db-changes');

    channel
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'posts',
          callback: (payload) {
            _loadPosts();
          },
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'posts',
          callback: (payload) {
            _loadPosts();
          },
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'comments',
          callback: (payload) {
            _loadPosts();
          },
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'likes',
          callback: (payload) {
            _loadPosts();
            _fetchLikedPosts();
          },
        );
    channel.subscribe();

    // Create a stream that completes when onDispose is called
    final controller = StreamController<void>();
    controller.onCancel = () {
      channel.unsubscribe();
    };
    _postsSubscription = controller.stream.listen((_) {});
  }

  // Helper function to calculate time ago
  String _getTimeAgo(DateTime dateTime) {
    final now = DateTime.now().toUtc();
    final difference = now.difference(dateTime.toUtc());

    if (difference.inDays > 365) {
      return '${(difference.inDays / 365).floor()}y ago';
    } else if (difference.inDays > 30) {
      return '${(difference.inDays / 30).floor()}mo ago';
    } else if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'just now';
    }
  }

  // Create a new post
  Future<void> _createNewPost(
      String title, String content, int departmentId) async {
    try {
      if (_userId == null) {
        // User not logged in
        return;
      }

      // Insert post into database
      await supabase.from('posts').insert({
        'userid': _userId,
        'title': title,
        'content': content,
        'departmentid': departmentId,
        'created_at': DateTime.now().toIso8601String(),
        'likes_count': 0,
        'comments_count': 0,
      });
      // Immediately reload posts for instant UI feedback
      await _loadPosts();

      // Reload posts (should happen automatically via subscription)
    } catch (e) {
      debugPrint('Error creating post: $e');
      // Show error snackbar
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error creating post: $e')),
        );
      }
    }
  }

  // Like/unlike a post
  Future<void> _toggleLikePost(String postId) async {
    if (_userId == null) return;
    try {
      final alreadyLiked = _likedPostIds.contains(postId);
      if (alreadyLiked) {
        // Remove like
        await supabase
            .from('likes')
            .delete()
            .match({'postid': postId, 'userid': _userId!});
        setState(() {
          _likedPostIds.remove(postId);
        });
      } else {
        // Add like
        await supabase
            .from('likes')
            .insert({'postid': postId, 'userid': _userId!});
        setState(() {
          _likedPostIds.add(postId);
        });
      }
      // Always reload posts to get updated like count
      await _loadPosts();
    } catch (e) {
      debugPrint('Error toggling like: $e');
    }
  }

  // Add comment to post
  Future<void> _addComment(String postId, String comment) async {
    try {
      if (_userId == null) {
        // User not logged in
        return;
      }

      // Insert comment
      await supabase.from('comments').insert({
        'postid': postId,
        'userid': _userId,
        'content': comment,
        'created_at': DateTime.now().toIso8601String(),
      });

      // Update comment count on post
      final post = await supabase
          .from('posts')
          .select('comments_count')
          .eq('postid', postId)
          .single();

      final currentComments = post['comments_count'] as int? ?? 0;

      await supabase.from('posts').update({
        'comments_count': currentComments + 1,
      }).eq('postid', postId);
    } catch (e) {
      debugPrint('Error adding comment: $e');
    }
  }

  // Fetch comments for a post
  Future<List<Map<String, dynamic>>> _fetchComments(String postId) async {
    try {
      final response = await supabase
          .from('comment_details')
          .select()
          .eq('postid', postId)
          .order('created_at', ascending: true);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Error fetching comments: $e');
      return [];
    }
  }

  // Show create post modal sheet
  void _showCreatePostModalSheet() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final TextEditingController titleController = TextEditingController();
    final TextEditingController contentController = TextEditingController();
    String selectedDept = _departments.contains(_userDepartment)
        ? _userDepartment
        : _departments.firstWhere((dept) => dept != "All", orElse: () => "Web Dev");
    bool isPosting = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 24,
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          child: StatefulBuilder(
            builder: (context, setStateModal) => Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 24,
                      backgroundColor: colorScheme.primary.withOpacity(0.15),
                      backgroundImage: _avatarUrl.isNotEmpty ? NetworkImage(_avatarUrl) : null,
                      child: _avatarUrl.isEmpty
                          ? Icon(Icons.person, color: colorScheme.primary, size: 28)
                          : null,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        'Create Post',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: colorScheme.primary,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.close, color: colorScheme.onSurface.withOpacity(0.7)),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                TextField(
                  controller: titleController,
                  decoration: InputDecoration(
                    labelText: 'Title',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    filled: true,
                    fillColor: colorScheme.surfaceVariant,
                  ),
                  style: theme.textTheme.bodyLarge,
                  textInputAction: TextInputAction.next,
                  maxLength: 80,
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: contentController,
                  decoration: InputDecoration(
                    labelText: 'Content',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    filled: true,
                    fillColor: colorScheme.surfaceVariant,
                  ),
                  style: theme.textTheme.bodyLarge,
                  minLines: 4,
                  maxLines: 8,
                  maxLength: 1000,
                ),
                const SizedBox(height: 14),
                DropdownButtonFormField<String>(
                  value: selectedDept,
                  decoration: InputDecoration(
                    labelText: 'Department',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    filled: true,
                    fillColor: colorScheme.surfaceVariant,
                  ),
                  items: _departments
                      .where((dept) => dept != "All")
                      .map((dept) => DropdownMenuItem<String>(
                            value: dept,
                            child: Text(dept),
                          ))
                      .toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setStateModal(() {
                        selectedDept = value;
                      });
                    }
                  },
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    IconButton(
                      icon: Icon(Icons.attach_file, color: colorScheme.primary),
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Attachments coming soon!')),
                        );
                      },
                    ),
                    const SizedBox(width: 8),
                    Text('Add attachment', style: theme.textTheme.bodyMedium?.copyWith(color: colorScheme.onSurface.withOpacity(0.6))),
                  ],
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colorScheme.primary,
                      foregroundColor: colorScheme.onPrimary,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: isPosting
                        ? null
                        : () async {
                            final title = titleController.text.trim();
                            final content = contentController.text.trim();
                            if (title.isEmpty || content.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Title and content required.')),
                              );
                              return;
                            }
                            setStateModal(() => isPosting = true);
                            try {
                              final deptResponse = await supabase
                                  .from('department')
                                  .select('departmentid')
                                  .eq('name', selectedDept)
                                  .maybeSingle();
                              if (deptResponse == null) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Department "$selectedDept" not found.')),
                                );
                                setStateModal(() => isPosting = false);
                                return;
                              }
                              final departmentId = deptResponse['departmentid'] as int;
                              await _createNewPost(title, content, departmentId);
                              Navigator.pop(context);
                            } catch (e) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Error creating post. Please try again.')),
                              );
                            } finally {
                              setStateModal(() => isPosting = false);
                            }
                          },
                    child: isPosting
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Text('Post', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // List of posts from Supabase
  List<Map<String, dynamic>> _posts = [];

  // Get filtered posts based on selected department
  List<Map<String, dynamic>> get filteredPosts {
    if (_selectedDepartment == "All") {
      return _posts;
    } else {
      return _posts
          .where((post) => post['department'] == _selectedDepartment)
          .toList();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Column(
      children: [
        // Department Filter
        Container(
          height: 50,
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: _departments.length,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemBuilder: (context, index) {
              final isSelected = _departments[index] == _selectedDepartment;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Text(_departments[index]),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() {
                      _selectedDepartment = _departments[index];
                    });
                  },
                  selectedColor: colorScheme.primary,
                  backgroundColor: colorScheme.surface,
                  labelStyle: TextStyle(
                    color: isSelected
                        ? colorScheme.onPrimary
                        : colorScheme.onSurface,
                    fontWeight:
                        isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  side: BorderSide(
                    color:
                        isSelected ? colorScheme.primary : theme.dividerColor,
                    width: 1.2,
                  ),
                ),
              );
            },
          ),
        ),
        // Posts Feed
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _hasError
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.error_outline,
                              size: 48, color: colorScheme.error),
                          const SizedBox(height: 16),
                          Text('Error loading posts',
                              style: theme.textTheme.bodyLarge),
                          const SizedBox(height: 8),
                          ElevatedButton(
                            onPressed: _loadPosts,
                            child: const Text('Try Again'),
                          ),
                        ],
                      ),
                    )
                  : filteredPosts.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.article_outlined,
                                  size: 80,
                                  color:
                                      colorScheme.onSurface.withOpacity(0.2)),
                              const SizedBox(height: 16),
                              Text('No posts in $_selectedDepartment yet',
                                  style: theme.textTheme.bodyMedium),
                              const SizedBox(height: 8),
                              ElevatedButton.icon(
                                onPressed: _showCreatePostModalSheet,
                                icon: const Icon(Icons.add),
                                label: const Text('Create first post'),
                              ),
                            ],
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: _loadPosts,
                          child: ListView.builder(
                            itemCount: filteredPosts.length,
                            padding: const EdgeInsets.all(8),
                            itemBuilder: (context, index) {
                              final post = filteredPosts[index];
                              return GestureDetector(
                                onTap: () async {
                                  // Navigate to PostDetailScreen with animation
                                  await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => PostDetailScreen(
                                        post: post,
                                        isLiked:
                                            _likedPostIds.contains(post['id']),
                                        onLike: () =>
                                            _toggleLikePost(post['id']),
                                        onShare: () {
                                          // TODO: Implement share functionality
                                        },
                                      ),
                                    ),
                                  );
                                  // Optionally reload posts after returning
                                  _loadPosts();
                                },
                                child: Container(
                                  margin: const EdgeInsets.only(bottom: 18),
                                  decoration: BoxDecoration(
                                    color: theme.cardColor,
                                    borderRadius: BorderRadius.circular(18),
                                    boxShadow: [
                                      BoxShadow(
                                        color: colorScheme.primary
                                            .withOpacity(0.08),
                                        blurRadius: 16,
                                        offset: const Offset(0, 8),
                                      ),
                                    ],
                                    border: Border.all(
                                      color:
                                          colorScheme.primary.withOpacity(0.18),
                                      width: 1.2,
                                    ),
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 18, vertical: 18),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        // Author Row
                                        Row(
                                          children: [
                                            Hero(
                                              tag: 'avatar_${post['id']}',
                                              child: CircleAvatar(
                                                radius: 22,
                                                backgroundImage: NetworkImage(
                                                    post['avatar']),
                                                backgroundColor: colorScheme
                                                    .primary
                                                    .withOpacity(0.08),
                                              ),
                                            ),
                                            const SizedBox(width: 14),
                                            Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  post['author'],
                                                  style: theme
                                                      .textTheme.titleMedium
                                                      ?.copyWith(
                                                    fontWeight: FontWeight.bold,
                                                    color: colorScheme.primary,
                                                  ),
                                                ),
                                                Text(
                                                  post['timestamp'],
                                                  style: theme
                                                      .textTheme.bodySmall
                                                      ?.copyWith(
                                                    color: colorScheme.onSurface
                                                        .withOpacity(0.7),
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const Spacer(),
                                            Chip(
                                              label: Text(
                                                post['department'],
                                                style: theme
                                                    .textTheme.labelLarge
                                                    ?.copyWith(
                                                  color: colorScheme.onPrimary,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                              backgroundColor:
                                                  colorScheme.primary,
                                              padding: EdgeInsets.zero,
                                              materialTapTargetSize:
                                                  MaterialTapTargetSize
                                                      .shrinkWrap,
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 18),
                                        // Post Content
                                        Text(
                                          post['title'],
                                          style: theme.textTheme.titleLarge
                                              ?.copyWith(
                                            fontWeight: FontWeight.bold,
                                            color: colorScheme.onSurface,
                                          ),
                                        ),
                                        const SizedBox(height: 7),
                                        Text(
                                          post['content'],
                                          maxLines: 6,
                                          overflow: TextOverflow.ellipsis,
                                          style: theme.textTheme.bodyLarge
                                              ?.copyWith(
                                            color: colorScheme.onSurface,
                                          ),
                                        ),
                                        const SizedBox(height: 18),
                                        // Interaction Buttons
                                        Row(
                                          children: [
                                            IconButton(
                                              icon: Icon(
                                                _likedPostIds
                                                        .contains(post['id'])
                                                    ? Icons.thumb_up_alt
                                                    : Icons
                                                        .thumb_up_alt_outlined,
                                                color: _likedPostIds
                                                        .contains(post['id'])
                                                    ? colorScheme.primary
                                                    : colorScheme.primary
                                                        .withOpacity(0.5),
                                              ),
                                              onPressed: () =>
                                                  _toggleLikePost(post['id']),
                                              visualDensity:
                                                  VisualDensity.compact,
                                            ),
                                            Text(
                                              '${post['likes']}',
                                              style: theme.textTheme.bodyMedium
                                                  ?.copyWith(
                                                color: colorScheme.primary,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                            const SizedBox(width: 18),
                                            IconButton(
                                              icon: const Icon(
                                                  Icons.mode_comment_rounded),
                                              onPressed: () async {
                                                await Navigator.push(
                                                  context,
                                                  MaterialPageRoute(
                                                    builder: (context) =>
                                                        PostDetailScreen(
                                                      post: post,
                                                      isLiked: _likedPostIds
                                                          .contains(post['id']),
                                                      onLike: () =>
                                                          _toggleLikePost(
                                                              post['id']),
                                                      onShare: () {
                                                        // TODO: Implement share functionality
                                                      },
                                                      autoFocusComment: true,
                                                    ),
                                                  ),
                                                );
                                                _loadPosts();
                                              },
                                              visualDensity:
                                                  VisualDensity.compact,
                                              color: colorScheme.primary,
                                            ),
                                            Text(
                                              '${post['comments']}',
                                              style: theme.textTheme.bodyMedium
                                                  ?.copyWith(
                                                color: colorScheme.primary,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                            const Spacer(),
                                            IconButton(
                                              icon: const Icon(
                                                  Icons.share_rounded),
                                              onPressed: () {},
                                              visualDensity:
                                                  VisualDensity.compact,
                                              color: colorScheme.primary,
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
        ),
        // Add Post Button
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: FloatingActionButton(
            onPressed: _showCreatePostModalSheet,
            child: const Icon(Icons.add),
          ),
        ),
      ],
    );
  }
}
