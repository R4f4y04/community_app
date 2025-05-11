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
  String?
      _userDepartmentId; // Will be used for department-specific chat in the future
  String _userDepartmentName = "";
  bool _isAdmin = false; // Track if current user is an administrator

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

      _userId = user
          .id; // Get user profile data with department info and admin status
      final userData = await supabase
          .from('users')
          .select('name, departmentid, isadmin, department(*), profile(*)')
          .eq('userid', user.id)
          .single();

      setState(() {
        _userName = userData['name'] ?? 'User';
        _userDepartmentId = userData['departmentid'];
        _userDepartmentName = userData['department']?['name'] ?? '';
        _avatarUrl = userData['profile']['profilepicture'] ?? '';
        _isAdmin = userData['isadmin'] == true; // Set admin status

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
        .order('timestamp')
        .listen((List<Map<String, dynamic>> data) async {
          if (mounted) {
            // When new messages come in, we need to fetch the full message data with user info
            // because real-time updates don't include joined tables
            if (data.isNotEmpty) {
              try {
                // Get the latest message
                final latestMessage = data.last;

                // Fetch the complete message with user data
                final completeMessages = await supabase
                    .from('globalchat')
                    .select('*, users(*)')
                    .eq('messageid', latestMessage['messageid'])
                    .single();

                // Create a properly formatted message
                final formattedNewMessage = _formatMessages([completeMessages]);

                // Update messages list by adding the new message
                setState(() {
                  bool messageExists = false;

                  // Check if the message already exists in the list
                  for (int i = 0; i < _messages.length; i++) {
                    if (_messages[i]['messageid'] ==
                        formattedNewMessage[0]['messageid']) {
                      messageExists = true;
                      break;
                    }
                  }

                  // Only add if it's a new message
                  if (!messageExists) {
                    _messages.add(formattedNewMessage[0]);
                    _messages
                        .sort((a, b) => a['dateTime'].compareTo(b['dateTime']));
                  }

                  _isLoading = false;
                  _hasError = false;
                });

                // Scroll to bottom on new messages if already near bottom
                if (_isNearBottom()) {
                  Future.delayed(
                      const Duration(milliseconds: 100), _scrollToBottom);
                }
              } catch (e) {
                print('Error processing real-time message: $e');
              }
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
          .order('timestamp', ascending: true);

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
      final timestamp = DateTime.parse(msg['timestamp']);
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

      final bool isCurrentUser = msg['senderid'] == _userId;
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
        'dateTime': timestamp,
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
        // Show sending indicator
        final scaffoldMessenger = ScaffoldMessenger.of(context);
        final sendingSnackBar = SnackBar(
          content: const Row(
            children: [
              SizedBox(
                height: 16,
                width: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
              SizedBox(width: 12),
              Text('Sending message...'),
            ],
          ),
          backgroundColor: AppColors.purpleLight,
          duration: const Duration(seconds: 1),
        );

        scaffoldMessenger.showSnackBar(sendingSnackBar);

        // Create timestamp for consistency
        final now = DateTime.now();
        final timestamp = now.toIso8601String();

        // Send to global chat
        final response = await supabase.from('globalchat').insert({
          'senderid': _userId,
          'message': messageText,
          'timestamp': timestamp,
        }).select('messageid');

        // Optimistically add the message to the UI immediately
        if (mounted && response.isNotEmpty) {
          final messageId = response[0]['messageid'];
          final formattedTime = DateFormat('h:mm a').format(now);

          setState(() {
            _messages.add({
              'messageid': messageId,
              'sender': _userName,
              'initials': _getInitials(_userName),
              'message': messageText,
              'timestamp': formattedTime,
              'dateTime': now,
              'avatar': _avatarUrl.isNotEmpty ? _avatarUrl : null,
              'isMe': true,
            });

            // Sort messages by time
            _messages.sort((a, b) => a['dateTime'].compareTo(b['dateTime']));
          });

          // Scroll to bottom
          Future.delayed(const Duration(milliseconds: 100), _scrollToBottom);
        }
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
          const SizedBox(height: 24),
          // Show department ID info - uses the _userDepartmentId field
          if (_userDepartmentId != null)
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant.withOpacity(0.5),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Your Department ID: $_userDepartmentId',
                style: const TextStyle(
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                  color: AppColors.textSecondary,
                ),
              ),
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
                  !_isSameDay(_messages[index]['dateTime'],
                      _messages[index - 1]['dateTime']);

              return Column(
                children: [
                  if (showDateHeader)
                    _buildDateHeader(_messages[index]['dateTime']),
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
      child: GestureDetector(
        onLongPress: _isAdmin ? () => _showMessageOptions(message) : null,
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
                    crossAxisAlignment: isMe
                        ? CrossAxisAlignment.end
                        : CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (!isMe)
                            Flexible(
                              child: Text(
                                message['sender'],
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          if (_isAdmin)
                            Padding(
                              padding: const EdgeInsets.only(left: 4.0),
                              child: Icon(
                                Icons.more_horiz,
                                size: 14,
                                color: isMe
                                    ? Colors.white70
                                    : AppColors.textSecondary,
                              ),
                            ),
                        ],
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
                          color:
                              isMe ? Colors.white70 : AppColors.textSecondary,
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

  // Show admin options for messages
  void _showMessageOptions(Map<String, dynamic> message) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8.0),
              child: Text(
                'Message Options',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text('Delete Message'),
              onTap: () {
                Navigator.pop(context);
                _deleteMessage(message);
              },
            ),
            ListTile(
              leading: const Icon(Icons.copy, color: AppColors.purpleLight),
              title: const Text('Copy Message Text'),
              onTap: () {
                Clipboard.setData(ClipboardData(text: message['message']));
                Navigator.pop(context);
                showSuccessSnackBar(context, 'Message copied to clipboard');
              },
            ),
            ListTile(
              leading:
                  const Icon(Icons.info_outline, color: AppColors.purpleLight),
              title: const Text('Message Info'),
              onTap: () {
                Navigator.pop(context);
                _showMessageInfo(message);
              },
            ),
          ],
        ),
      ),
    );
  }

  // Delete a message
  Future<void> _deleteMessage(Map<String, dynamic> message) async {
    try {
      await supabase
          .from('globalchat')
          .delete()
          .eq('messageid', message['messageid']);

      showSuccessSnackBar(context, 'Message deleted');
      // Message will be removed automatically through the subscription
    } catch (e) {
      print('Error deleting message: $e');
      showErrorSnackBar(context, 'Failed to delete message');
    }
  }

  // Show message details
  void _showMessageInfo(Map<String, dynamic> message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Message Details'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildMessageInfoRow('Sender', message['sender']),
            _buildMessageInfoRow('Time', message['timestamp']),
            _buildMessageInfoRow('Message ID', message['messageid'].toString()),
          ],
        ),
        actions: [
          TextButton(
            child: const Text('Close'),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  // Helper for message info dialog
  Widget _buildMessageInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
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
        ],
      ),
    );
  }
}
