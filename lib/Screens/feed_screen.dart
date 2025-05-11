import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:async';

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

  @override
  void initState() {
    super.initState();
    _initUser();
    _loadPosts();
    _subscribeToPosts();
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
        final DateTime createdAt = DateTime.parse(post['created_at']);
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
  } // Subscribe to real-time updates for posts

  void _subscribeToPosts() {
    // With Supabase Flutter v2.x:
    final channel = supabase.channel('schema-db-changes');

    channel
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'posts',
          callback: (payload) {
            _loadPosts(); // Reload all posts when a new one is added
          },
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'posts',
          callback: (payload) {
            _loadPosts(); // Reload all posts when one is updated
          },
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'comments',
          callback: (payload) {
            // When a comment is added, reload posts to update comment counts
            _loadPosts();
          },
        );

    // Subscribe to the channel
    channel.subscribe();

    // Create a stream that completes when onDispose is called
    final controller = StreamController<void>();
    controller.onCancel = () {
      channel.unsubscribe();
    };

    // Store a subscription to this stream for cleanup
    _postsSubscription = controller.stream.listen((_) {});
  }

  // Helper function to calculate time ago
  String _getTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

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

  // Like a post
  Future<void> _likePost(String postId) async {
    try {
      // Get current post data
      final post = await supabase
          .from('posts')
          .select('likes_count')
          .eq('postid', postId)
          .single();

      final currentLikes = post['likes_count'] as int? ?? 0;

      // Update post with incremented likes
      await supabase.from('posts').update({
        'likes_count': currentLikes + 1,
      }).eq('postid', postId);
    } catch (e) {
      debugPrint('Error liking post: $e');
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

  // Show comment dialog
  void _showCommentDialog(String postId) {
    final TextEditingController commentController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: SizedBox(
          width: 400,
          child: Padding(
            padding: const EdgeInsets.all(18.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Comments',
                    style:
                        TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                const SizedBox(height: 12),
                FutureBuilder<List<Map<String, dynamic>>>(
                  future: _fetchComments(postId),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    final comments = snapshot.data ?? [];
                    if (comments.isEmpty) {
                      return const Padding(
                        padding: EdgeInsets.symmetric(vertical: 16),
                        child: Text('No comments yet.',
                            style: TextStyle(color: Colors.black54)),
                      );
                    }
                    return SizedBox(
                      height: 200,
                      child: ListView.separated(
                        shrinkWrap: true,
                        itemCount: comments.length,
                        separatorBuilder: (_, __) => const Divider(height: 16),
                        itemBuilder: (context, idx) {
                          final c = comments[idx];
                          return Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              CircleAvatar(
                                radius: 16,
                                backgroundImage: NetworkImage(
                                    c['profilepicture'] ??
                                        'https://i.pravatar.cc/150?img=1'),
                                backgroundColor: Colors.purple[50],
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(c['name'] ?? 'User',
                                        style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14,
                                            color: Colors.purple)),
                                    Text(c['content'] ?? '',
                                        style: const TextStyle(fontSize: 14)),
                                    Text(
                                      c['created_at'] != null
                                          ? _getTimeAgo(
                                              DateTime.parse(c['created_at']))
                                          : '',
                                      style: const TextStyle(
                                          fontSize: 11, color: Colors.black45),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    );
                  },
                ),
                const SizedBox(height: 18),
                const Divider(),
                const SizedBox(height: 8),
                TextField(
                  controller: commentController,
                  decoration: const InputDecoration(
                    hintText: 'Write your comment...',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                    ElevatedButton(
                      onPressed: () async {
                        final comment = commentController.text.trim();
                        if (comment.isNotEmpty) {
                          await _addComment(postId, comment);
                          Navigator.pop(context);
                          // Reopen dialog to refresh comments
                          Future.delayed(const Duration(milliseconds: 200), () {
                            _showCommentDialog(postId);
                          });
                        }
                      },
                      child: const Text('Post Comment'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Show create post dialog
  void _showCreatePostDialog() {
    final TextEditingController titleController = TextEditingController();
    final TextEditingController contentController = TextEditingController();
    String selectedDept = _departments.contains(_userDepartment)
        ? _userDepartment
        : _departments.firstWhere((dept) => dept != "All",
            orElse: () => "Web Dev");

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create New Post'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: titleController,
                decoration: const InputDecoration(
                  labelText: 'Title',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: contentController,
                decoration: const InputDecoration(
                  labelText: 'Content',
                  border: OutlineInputBorder(),
                ),
                maxLines: 5,
              ),
              const SizedBox(height: 16),
              const Text('Department:'),
              DropdownButton<String>(
                value: selectedDept,
                isExpanded: true,
                items: _departments
                    .where((dept) => dept != "All")
                    .map((dept) => DropdownMenuItem<String>(
                          value: dept,
                          child: Text(dept),
                        ))
                    .toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      selectedDept = value;
                    });
                  }
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final title = titleController.text.trim();
              final content = contentController.text.trim();

              if (title.isNotEmpty && content.isNotEmpty) {
                Navigator.pop(context);

                // Get department ID from department name
                try {
                  final deptResponse = await supabase
                      .from('department')
                      .select('departmentid')
                      .eq('name', selectedDept)
                      .maybeSingle();

                  if (deptResponse == null) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                            content:
                                Text('Department "$selectedDept" not found.')),
                      );
                    }
                    return;
                  }

                  final departmentId = deptResponse['departmentid'] as int;
                  await _createNewPost(title, content, departmentId);
                  debugPrint('Post created for departmentId: $departmentId');
                } catch (e) {
                  debugPrint('Error getting department ID: $e');
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content:
                              Text('Error creating post. Please try again.')),
                    );
                  }
                }
              }
            },
            child: const Text('Post'),
          ),
        ],
      ),
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
                  selectedColor: Colors.purpleAccent,
                  backgroundColor: Colors.grey[200],
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.white : Colors.black54,
                    fontWeight:
                        isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                ),
              );
            },
          ),
        ),

        // Posts Feed
        Expanded(
          child: _isLoading
              ? const Center(
                  child: CircularProgressIndicator(),
                )
              : _hasError
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.error_outline,
                            size: 48,
                            color: Colors.red,
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'Error loading posts',
                            style: TextStyle(
                              fontSize: 16,
                            ),
                          ),
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
                              const Icon(
                                Icons.article_outlined,
                                size: 80,
                                color: Colors.black38,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No posts in $_selectedDepartment yet',
                                style: const TextStyle(
                                  color: Colors.black54,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 8),
                              ElevatedButton.icon(
                                onPressed: _showCreatePostDialog,
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
                              return Container(
                                margin: const EdgeInsets.only(bottom: 18),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(18),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.purple.withOpacity(0.08),
                                      blurRadius: 16,
                                      offset: const Offset(0, 8),
                                    ),
                                  ],
                                  border: Border.all(
                                    color:
                                        Colors.purpleAccent.withOpacity(0.18),
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
                                          CircleAvatar(
                                            radius: 22,
                                            backgroundImage:
                                                NetworkImage(post['avatar']),
                                            backgroundColor: Colors.purple[50],
                                          ),
                                          const SizedBox(width: 14),
                                          Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                post['author'],
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 16,
                                                  color: Colors.purple,
                                                ),
                                              ),
                                              Text(
                                                post['timestamp'],
                                                style: const TextStyle(
                                                  color: Colors.black45,
                                                  fontSize: 12,
                                                ),
                                              ),
                                            ],
                                          ),
                                          const Spacer(),
                                          Chip(
                                            label: Text(
                                              post['department'],
                                              style: const TextStyle(
                                                fontSize: 12,
                                                color: Colors.white,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                            backgroundColor:
                                                Colors.purpleAccent,
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
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 19,
                                          color: Colors.black87,
                                        ),
                                      ),
                                      const SizedBox(height: 7),
                                      Text(
                                        post['content'],
                                        style: const TextStyle(
                                          fontSize: 15,
                                          color: Colors.black87,
                                        ),
                                      ),
                                      const SizedBox(height: 18),
                                      // Interaction Buttons
                                      Row(
                                        children: [
                                          IconButton(
                                            icon: const Icon(
                                                Icons.thumb_up_alt_rounded),
                                            onPressed: () =>
                                                _likePost(post['id']),
                                            visualDensity:
                                                VisualDensity.compact,
                                            color: Colors.purpleAccent,
                                          ),
                                          Text(
                                            '${post['likes']}',
                                            style: const TextStyle(
                                              color: Colors.purple,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          const SizedBox(width: 18),
                                          IconButton(
                                            icon: const Icon(
                                                Icons.mode_comment_rounded),
                                            onPressed: () =>
                                                _showCommentDialog(post['id']),
                                            visualDensity:
                                                VisualDensity.compact,
                                            color: Colors.purpleAccent,
                                          ),
                                          Text(
                                            '${post['comments']}',
                                            style: const TextStyle(
                                              color: Colors.purple,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          const Spacer(),
                                          IconButton(
                                            icon:
                                                const Icon(Icons.share_rounded),
                                            onPressed: () {},
                                            visualDensity:
                                                VisualDensity.compact,
                                            color: Colors.purpleAccent,
                                          ),
                                        ],
                                      ),
                                    ],
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
            onPressed: _showCreatePostDialog,
            child: const Icon(Icons.add),
          ),
        ),
      ],
    );
  }
}
