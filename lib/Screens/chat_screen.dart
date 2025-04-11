import 'package:flutter/material.dart';
import 'package:dbms_proj/util/theme.dart';
import 'package:dbms_proj/util/functions.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  // Dummy chat messages for demonstration
  final List<Map<String, dynamic>> _messages = [
    {
      'sender': 'Alex Johnson',
      'message':
          'Hey everyone! Who\'s coming to the Flutter workshop tomorrow?',
      'timestamp': '10:15 AM',
      'avatar': 'https://i.pravatar.cc/150?img=1',
      'isMe': false,
    },
    {
      'sender': 'Samantha Lee',
      'message': 'I\'ll be there! Looking forward to it.',
      'timestamp': '10:17 AM',
      'avatar': 'https://i.pravatar.cc/150?img=5',
      'isMe': false,
    },
    {
      'sender': 'Me',
      'message': 'Count me in too. Should I bring my laptop?',
      'timestamp': '10:20 AM',
      'avatar': 'https://i.pravatar.cc/150?img=2',
      'isMe': true,
    },
    {
      'sender': 'Alex Johnson',
      'message':
          'Yes, please bring your laptop. We\'ll be doing hands-on exercises.',
      'timestamp': '10:22 AM',
      'avatar': 'https://i.pravatar.cc/150?img=1',
      'isMe': false,
    },
    {
      'sender': 'Michael Chen',
      'message': 'I\'ll join too. Is there any pre-work we should do?',
      'timestamp': '10:25 AM',
      'avatar': 'https://i.pravatar.cc/150?img=3',
      'isMe': false,
    },
    {
      'sender': 'Emily Rodriguez',
      'message':
          'By the way, has anyone seen the announcement about the digital art exhibition next week?',
      'timestamp': '10:30 AM',
      'avatar': 'https://i.pravatar.cc/150?img=10',
      'isMe': false,
    },
  ];

  void _sendMessage() {
    if (_messageController.text.trim().isNotEmpty) {
      setState(() {
        _messages.add({
          'sender': 'Me',
          'message': _messageController.text.trim(),
          'timestamp': '${DateTime.now().hour}:${DateTime.now().minute}',
          'avatar': 'https://i.pravatar.cc/150?img=2',
          'isMe': true,
        });
      });

      _messageController.clear();

      // Scroll to bottom after sending message
      Future.delayed(const Duration(milliseconds: 100), () {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Chat messages
        Expanded(
          child: ListView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.all(16),
            itemCount: _messages.length,
            itemBuilder: (context, index) {
              final message = _messages[index];
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
                        CircleAvatar(
                          radius: 20,
                          backgroundImage: NetworkImage(message['avatar']),
                        ),
                        const SizedBox(width: 12),
                      ],
                      Flexible(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: isMe
                                ? AppColors.purpleLight
                                : AppColors.surfaceVariant,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Column(
                            crossAxisAlignment: isMe
                                ? CrossAxisAlignment.end
                                : CrossAxisAlignment.start,
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
                                  color: isMe
                                      ? Colors.white
                                      : AppColors.textPrimary,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                message['timestamp'],
                                style: TextStyle(
                                  color: isMe
                                      ? Colors.white70
                                      : AppColors.textSecondary,
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
            },
          ),
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
                ),
              ),
              const SizedBox(width: 8),
              CircleAvatar(
                radius: 24,
                backgroundColor: AppColors.purpleLight,
                child: IconButton(
                  icon: const Icon(Icons.send, color: Colors.white, size: 20),
                  onPressed: _sendMessage,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
