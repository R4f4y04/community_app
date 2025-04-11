import 'package:flutter/material.dart';
import 'package:dbms_proj/util/theme.dart';
import 'package:dbms_proj/util/functions.dart';

class FeedScreen extends StatefulWidget {
  const FeedScreen({super.key});

  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> {
  String _selectedDepartment = "All";
  final List<String> _departments = [
    "All",
    "Computer Science",
    "Electrical",
    "Mechanical",
    "Civil",
    "Business",
    "Arts"
  ];

  // Dummy post data for demonstration
  final List<Map<String, dynamic>> _posts = [
    {
      'author': 'Alex Johnson',
      'department': 'Computer Science',
      'title': 'Workshop on Flutter Development',
      'content':
          'Join us for an interactive workshop on building cross-platform apps with Flutter. We\'ll cover the basics and move on to advanced topics.',
      'likes': 42,
      'comments': 8,
      'timestamp': '2h ago',
      'avatar': 'https://i.pravatar.cc/150?img=1',
    },
    {
      'author': 'Samantha Lee',
      'department': 'Business',
      'title': 'Entrepreneurship Seminar',
      'content':
          'Learn how to turn your ideas into a successful business venture. Guest speakers from local startups will share their experiences.',
      'likes': 29,
      'comments': 12,
      'timestamp': '4h ago',
      'avatar': 'https://i.pravatar.cc/150?img=5',
    },
    {
      'author': 'Michael Chen',
      'department': 'Electrical',
      'title': 'IoT Project Showcase',
      'content':
          'Come see our department\'s latest Internet of Things projects. From smart home solutions to industrial automation.',
      'likes': 18,
      'comments': 3,
      'timestamp': '1d ago',
      'avatar': 'https://i.pravatar.cc/150?img=3',
    },
    {
      'author': 'Emily Rodriguez',
      'department': 'Arts',
      'title': 'Digital Art Exhibition',
      'content':
          'The Arts department is hosting a digital art exhibition featuring works from students and faculty. Opening reception is Friday at 6 PM.',
      'likes': 37,
      'comments': 15,
      'timestamp': '2d ago',
      'avatar': 'https://i.pravatar.cc/150?img=10',
    },
  ];

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
                  selectedColor: AppColors.purpleLight,
                  backgroundColor: AppColors.surfaceVariant,
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.white : AppColors.textSecondary,
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
          child: filteredPosts.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.article_outlined,
                        size: 80,
                        color: AppColors.textSecondary,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No posts in $_selectedDepartment yet',
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ElevatedButton.icon(
                        onPressed: () {
                          // Create a new post logic
                        },
                        icon: const Icon(Icons.add),
                        label: const Text('Create first post'),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  itemCount: filteredPosts.length,
                  padding: const EdgeInsets.all(8),
                  itemBuilder: (context, index) {
                    final post = filteredPosts[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Author Row
                            Row(
                              children: [
                                CircleAvatar(
                                  radius: 20,
                                  backgroundImage: NetworkImage(post['avatar']),
                                ),
                                const SizedBox(width: 12),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      post['author'],
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                    Text(
                                      post['timestamp'],
                                      style: TextStyle(
                                        color: AppColors.textSecondary,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                                const Spacer(),
                                Chip(
                                  label: Text(
                                    post['department'],
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                  backgroundColor: AppColors.surfaceVariant,
                                  padding: EdgeInsets.zero,
                                  materialTapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                ),
                              ],
                            ),

                            const SizedBox(height: 16),

                            // Post Content
                            Text(
                              post['title'],
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              post['content'],
                              style: const TextStyle(
                                fontSize: 14,
                              ),
                            ),

                            const SizedBox(height: 16),

                            // Interaction Buttons
                            Row(
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.thumb_up_outlined),
                                  onPressed: () {},
                                  visualDensity: VisualDensity.compact,
                                  color: AppColors.purpleLight,
                                ),
                                Text(
                                  '${post['likes']}',
                                  style: const TextStyle(
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                IconButton(
                                  icon: const Icon(Icons.comment_outlined),
                                  onPressed: () {},
                                  visualDensity: VisualDensity.compact,
                                  color: AppColors.purpleLight,
                                ),
                                Text(
                                  '${post['comments']}',
                                  style: const TextStyle(
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                                const Spacer(),
                                IconButton(
                                  icon: const Icon(Icons.share_outlined),
                                  onPressed: () {},
                                  visualDensity: VisualDensity.compact,
                                  color: AppColors.purpleLight,
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
      ],
    );
  }
}
