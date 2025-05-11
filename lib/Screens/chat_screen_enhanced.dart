import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:dbms_proj/util/theme.dart';
import 'package:dbms_proj/util/functions.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'dart:async';

// Get Supabase client instance
final supabase = Supabase.instance.client;

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> with WidgetsBindingObserver {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _messageFocusNode = FocusNode();
  StreamSubscription? _chatSubscription;

  // Chat state
  List<Map<String, dynamic>> _messages = [];
  bool _isLoading = true;
  bool _hasError = false;
  bool _isDepartmentChat = false;
  String _chatMode = "Global Chat";

  // User data
  String? _userId;
  String _userName = "User";
  String _avatarUrl = "https://i.pravatar.cc/150?img=2";
  String? _userDepartmentId;
  String _userDepartmentName = "";

  @override
  void initState() {
    super.initState();
    _initUser();
    _loadGlobalChatMessages();
    _subscribeToGlobalChat();

    // Register observer for app lifecycle changes
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    _chatSubscription?.cancel();
    _messageController.dispose();
    _scrollController.dispose();
    _messageFocusNode.dispose();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  // Handle app lifecycle changes (background/foreground)
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // App came to foreground, reconnect subscription
      if (_chatSubscription == null) {
        _subscribeToGlobalChat();
      }
    } else if (state == AppLifecycleState.paused) {
      // App went to background, can optionally cancel subscription to save resources
    }
  }

  // Initialize user data
  Future<void> _initUser() async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) return;

      _userId = user.id;

      // Get user profile data with department info
      final userData = await supabase
          .from('users')
          .select('name, departmentid, department(*), profile(*)')
          .eq('userid', user.id)
          .single();

      setState(() {
        _userName = userData['name'] ?? 'User';
        _userDepartmentId = userData['departmentid'];
        _userDepartmentName = userData['department']?['name'] ?? '';
        _avatarUrl = userData['profile']['profilepicture'] ?? '';

        if (_avatarUrl.isEmpty) {
          _avatarUrl = 'https://i.pravatar.cc/150?img=2';
        }
      });
    } catch (e) {
      print('Error loading user data: $e');
      setState(() {
        _hasError = true;
      });
    }
  }

  // Subscribe to chat updates
  void _subscribeToGlobalChat() {
    _chatSubscription = supabase
        .from('globalchat')
        .stream(primaryKey: ['messageid'])
        .order('created_at')
        .listen((List<Map<String, dynamic>> data) {
          if (mounted) {
            setState(() {
              _messages = _formatMessages(data);
              _isLoading = false;
              _hasError = false;
            });

            // Scroll to bottom on new messages if already near bottom
            if (_isNearBottom()) {
              Future.delayed(
                  const Duration(milliseconds: 100), _scrollToBottom);
            }
          }
        }, onError: (error) {
          print('Error on chat subscription: $error');
          if (mounted) {
            setState(() {
              _hasError = true;
              _isLoading = false;
            });
          }
        });
  }

  // Check if the scroll is already near bottom
  bool _isNearBottom() {
    if (!_scrollController.hasClients) return true;

    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.offset;
    return maxScroll - currentScroll < 200;
  }

  // Load messages from global chat
  Future<void> _loadGlobalChatMessages() async {
    try {
      setState(() {
        _isLoading = true;
        _hasError = false;
      });

      final response = await supabase
          .from('globalchat')
          .select('*, users(*)')
          .order('created_at', ascending: true);

      if (mounted) {
        setState(() {
          _messages = _formatMessages(response);
          _isLoading = false;
        });

        // Scroll to bottom after loading messages
        Future.delayed(const Duration(milliseconds: 100), _scrollToBottom);
      }
    } catch (e) {
      print('Error loading messages: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasError = true;
        });
      }
    }
  }

  // Format messages from Supabase response
  List<Map<String, dynamic>> _formatMessages(
      List<Map<String, dynamic>> messages) {
    return messages.map((msg) {
      final user = msg['users'];
      final timestamp = DateTime.parse(msg['created_at']);
      final now = DateTime.now();
      final difference = now.difference(timestamp);

      String formattedTime;
      if (difference.inDays > 0) {
        // More than a day ago, show date and time
        formattedTime = DateFormat('MMM d, h:mm a').format(timestamp);
      } else {
        // Today, show only time
        formattedTime = DateFormat('h:mm a').format(timestamp);
      }

      final bool isCurrentUser = msg['user_id'] == _userId;
      final String senderName =
          isCurrentUser ? _userName : (user?['name'] ?? 'Unknown User');
      final String avatarUrl = isCurrentUser
          ? _avatarUrl
          : (user?['profile']?['profilepicture'] ?? '');

      final String initials = _getInitials(senderName);

      return {
        'messageid': msg['messageid'],
        'sender': senderName,
        'initials': initials,
        'message': msg['message'] ?? '',
        'timestamp': formattedTime,
        'created_at': timestamp,
        'avatar': avatarUrl.isNotEmpty ? avatarUrl : null,
        'isMe': isCurrentUser,
      };
    }).toList();
  }

  // Get initials from name
  String _getInitials(String name) {
    if (name.isEmpty) return 'U';

    List<String> nameParts = name.split(" ");
    if (nameParts.length > 1) {
      return nameParts[0][0].toUpperCase() + nameParts[1][0].toUpperCase();
    } else {
      return name[0].toUpperCase();
    }
  }

  // Send message
  Future<void> _sendMessage() async {
    if (_messageController.text.trim().isEmpty) return;

    final messageText = _messageController.text.trim();
    _messageController.clear();
    _messageFocusNode.requestFocus(); // Keep keyboard open

    try {
      if (_isDepartmentChat) {
        // Department chat is coming soon
        showInfoSnackBar(context, 'Department chat is coming soon');
      } else {
        // Send to global chat
        await supabase.from('globalchat').insert({
          'user_id': _userId,
          'message': messageText,
          'created_at': DateTime.now().toIso8601String(),
        });
      }
    } catch (e) {
      print('Error sending message: $e');
      showErrorSnackBar(context, 'Failed to send message');
    }
  }

  // Retry connecting when there's an error
  void _retryConnection() {
    _loadGlobalChatMessages();
    _subscribeToGlobalChat();
  }

  // Scroll to bottom
  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  // Toggle between global and department chat
  void _toggleChatMode() {
    setState(() {
      _isDepartmentChat = !_isDepartmentChat;
      _chatMode = _isDepartmentChat ? "Department Chat" : "Global Chat";

      if (_isDepartmentChat) {
        _messages = []; // Clear messages when switching to department chat
      } else {
        _loadGlobalChatMessages(); // Reload global chat messages
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Chat type selector
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.surfaceVariant,
            border: Border(
              bottom: BorderSide(color: AppColors.surfaceVariant, width: 1),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _chatMode,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              ElevatedButton.icon(
                onPressed: _toggleChatMode,
                icon: Icon(
                  _isDepartmentChat ? Icons.public : Icons.groups,
                  size: 18,
                ),
                label: Text(
                  _isDepartmentChat
                      ? 'Switch to Global'
                      : 'Switch to Department',
                  style: const TextStyle(fontSize: 12),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.purpleLight,
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
              ),
            ],
          ),
        ),

        // Chat messages
        Expanded(
          child: _isLoading
              ? const Center(
                  child: CircularProgressIndicator(
                    valueColor:
                        AlwaysStoppedAnimation<Color>(AppColors.purpleLight),
                  ),
                )
              : _hasError
                  ? _buildErrorView()
                  : _isDepartmentChat
                      ? _buildDepartmentChatPlaceholder()
                      : _buildGlobalChatMessages(),
        ),

        // Message Input
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.surface,
            border: Border(
              top: BorderSide(color: AppColors.surfaceVariant, width: 1),
            ),
          ),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.attach_file),
                color: AppColors.purpleLight,
                onPressed: () {
                  showInfoSnackBar(context, 'File attachment coming soon!');
                },
              ),
              Expanded(
                child: TextField(
                  controller: _messageController,
                  focusNode: _messageFocusNode,
                  style: const TextStyle(color: AppColors.textPrimary),
                  decoration: InputDecoration(
                    hintText: 'Type a message...',
                    hintStyle: TextStyle(color: AppColors.textSecondary),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: AppColors.surfaceVariant,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
                  ),
                  textCapitalization: TextCapitalization.sentences,
                  enabled:
                      !_isDepartmentChat, // Disable input in department chat
                  onSubmitted: (_) => _sendMessage(), // Send on enter
                  keyboardType: TextInputType.multiline,
                  maxLines: null, // Allow multiple lines
                  textInputAction:
                      TextInputAction.send, // Use send button on keyboard
                ),
              ),
              const SizedBox(width: 8),
              CircleAvatar(
                radius: 24,
                backgroundColor: _isDepartmentChat
                    ? AppColors.textSecondary
                        .withOpacity(0.5) // Dimmed when disabled
                    : AppColors.purpleLight,
                child: IconButton(
                  icon: const Icon(Icons.send, color: Colors.white, size: 20),
                  onPressed: _isDepartmentChat ? null : _sendMessage,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Error view with retry button
  Widget _buildErrorView() {
    return Center(
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
            'Something went wrong',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Could not load messages',
            style: TextStyle(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _retryConnection,
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.purpleLight,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  // Department chat "Coming soon" placeholder
  Widget _buildDepartmentChatPlaceholder() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.construction, size: 48, color: AppColors.purpleLight),
          const SizedBox(height: 16),
          const Text(
            'Department Chat Coming Soon!',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'We\'re working on implementing department-specific chats'
            '\nfor ${_userDepartmentName.isNotEmpty ? _userDepartmentName : 'your department'}.',
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  // Global chat messages view
  Widget _buildGlobalChatMessages() {
    return _messages.isEmpty
        ? Center(
            child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.chat_bubble_outline,
                  size: 48, color: AppColors.purpleLight.withOpacity(0.7)),
              const SizedBox(height: 16),
              const Text(
                'No messages yet',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Be the first to start the conversation!',
                style: TextStyle(color: AppColors.textSecondary),
              ),
            ],
          ))
        : ListView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.all(16),
            itemCount: _messages.length,
            itemBuilder: (context, index) {
              // Show date header if it's the first message or date changes from previous
              final bool showDateHeader = index == 0 ||
                  !_isSameDay(_messages[index]['created_at'],
                      _messages[index - 1]['created_at']);

              return Column(
                children: [
                  if (showDateHeader)
                    _buildDateHeader(_messages[index]['created_at']),
                  _buildMessageBubble(_messages[index]),
                ],
              );
            },
          );
  }

  // Date header for messages
  Widget _buildDateHeader(DateTime date) {
    final now = DateTime.now();
    final yesterday = now.subtract(const Duration(days: 1));

    String dateText;
    if (_isSameDay(date, now)) {
      dateText = 'Today';
    } else if (_isSameDay(date, yesterday)) {
      dateText = 'Yesterday';
    } else {
      dateText = DateFormat('MMMM d, y').format(date);
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.surfaceVariant.withOpacity(0.5),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Text(
            dateText,
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }

  // Check if two dates are on the same day
  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }

  // Build a message bubble
  Widget _buildMessageBubble(Map<String, dynamic> message) {
    final isMe = message['isMe'] as bool;

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!isMe) ...[
              _buildAvatar(message),
              const SizedBox(width: 12),
            ],
            Flexible(
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color:
                      isMe ? AppColors.purpleLight : AppColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 5,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment:
                      isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                  children: [
                    if (!isMe)
                      Text(
                        message['sender'],
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    const SizedBox(height: 4),
                    Text(
                      message['message'],
                      style: TextStyle(
                        color: isMe ? Colors.white : AppColors.textPrimary,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      message['timestamp'],
                      style: TextStyle(
                        color: isMe ? Colors.white70 : AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Build avatar for message bubble
  Widget _buildAvatar(Map<String, dynamic> message) {
    return CircleAvatar(
      radius: 20,
      backgroundColor: AppColors.purpleLight.withOpacity(0.7),
      backgroundImage:
          message['avatar'] != null ? NetworkImage(message['avatar']) : null,
      child: message['avatar'] == null
          ? Text(
              message['initials'],
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            )
          : null,
    );
  }
}
