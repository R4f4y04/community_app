import 'package:flutter/material.dart';
import 'package:dbms_proj/util/theme.dart';
import 'package:dbms_proj/util/functions.dart';

class ProjectsScreen extends StatefulWidget {
  const ProjectsScreen({super.key});

  @override
  State<ProjectsScreen> createState() => _ProjectsScreenState();
}

class _ProjectsScreenState extends State<ProjectsScreen> {
  String _selectedStatus = "All";
  final List<String> _statuses = ["All", "Ongoing", "Completed", "Planning"];

  // Dummy projects data
  final List<Map<String, dynamic>> _projects = [
    {
      'title': 'Community App Development',
      'description':
          'Building a mobile application to connect university students and facilitate collaboration.',
      'status': 'Ongoing',
      'members': ['Alex Johnson', 'Samantha Lee', 'Michael Chen'],
      'progress': 0.7,
      'department': 'Computer Science',
      'deadline': 'May 15, 2025',
    },
    {
      'title': 'Sustainable Campus Initiative',
      'description':
          'Implementing eco-friendly practices across campus facilities and operations.',
      'status': 'Planning',
      'members': ['Emily Rodriguez', 'David Kim', 'Sophia Martinez'],
      'progress': 0.2,
      'department': 'Environmental Science',
      'deadline': 'August 30, 2025',
    },
    {
      'title': 'IoT Weather Station',
      'description':
          'Building a network of IoT devices to monitor and predict campus weather patterns.',
      'status': 'Ongoing',
      'members': ['Michael Chen', 'James Wilson', 'Olivia Brown'],
      'progress': 0.4,
      'department': 'Electrical Engineering',
      'deadline': 'June 10, 2025',
    },
    {
      'title': 'Virtual Art Gallery',
      'description':
          'A completed project showcasing student artwork in an immersive virtual environment.',
      'status': 'Completed',
      'members': ['Emily Rodriguez', 'Daniel Taylor', 'Ava Garcia'],
      'progress': 1.0,
      'department': 'Arts',
      'deadline': 'March 20, 2025',
    },
  ];

  List<Map<String, dynamic>> get filteredProjects {
    if (_selectedStatus == "All") {
      return _projects;
    } else {
      return _projects
          .where((project) => project['status'] == _selectedStatus)
          .toList();
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Ongoing':
        return Colors.blue;
      case 'Completed':
        return Colors.green;
      case 'Planning':
        return Colors.orange;
      default:
        return AppColors.purpleLight;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Status filter
        Container(
          height: 50,
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: _statuses.length,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemBuilder: (context, index) {
              final isSelected = _statuses[index] == _selectedStatus;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Text(_statuses[index]),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() {
                      _selectedStatus = _statuses[index];
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

        // Projects list
        Expanded(
          child: filteredProjects.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.work_outline,
                        size: 80,
                        color: AppColors.textSecondary,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No $_selectedStatus projects yet',
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ElevatedButton.icon(
                        onPressed: () {
                          showInfoSnackBar(
                              context, 'Project creation coming soon!');
                        },
                        icon: const Icon(Icons.add),
                        label: const Text('Create Project'),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  itemCount: filteredProjects.length,
                  padding: const EdgeInsets.all(16),
                  itemBuilder: (context, index) {
                    final project = filteredProjects[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: InkWell(
                        onTap: () {
                          // Show project details
                          showInfoSnackBar(
                              context, 'Project details coming soon!');
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Title and status
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      project['title'],
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 18,
                                      ),
                                    ),
                                  ),
                                  Chip(
                                    label: Text(
                                      project['status'],
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    backgroundColor:
                                        _getStatusColor(project['status']),
                                    padding: EdgeInsets.zero,
                                    materialTapTargetSize:
                                        MaterialTapTargetSize.shrinkWrap,
                                  ),
                                ],
                              ),

                              const SizedBox(height: 8),

                              // Description
                              Text(
                                project['description'],
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: AppColors.textSecondary,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),

                              const SizedBox(height: 16),

                              // Department and deadline
                              Row(
                                children: [
                                  const Icon(
                                    Icons.school,
                                    size: 16,
                                    color: AppColors.textSecondary,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    project['department'],
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                  const Spacer(),
                                  const Icon(
                                    Icons.calendar_today,
                                    size: 16,
                                    color: AppColors.textSecondary,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    project['deadline'],
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 16),

                              // Progress bar
                              LinearProgressIndicator(
                                value: project['progress'] as double,
                                backgroundColor: AppColors.surfaceVariant,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  _getStatusColor(project['status']),
                                ),
                                borderRadius: BorderRadius.circular(2),
                              ),

                              const SizedBox(height: 8),

                              // Progress text
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Progress: ${(project['progress'] * 100).toInt()}%',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                  Text(
                                    '${project['members'].length} members',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 16),

                              // Team members
                              Row(
                                children: [
                                  for (int i = 0;
                                      i < 3 &&
                                          i <
                                              (project['members'] as List)
                                                  .length;
                                      i++)
                                    Padding(
                                      padding: EdgeInsets.only(
                                          left: i > 0 ? -8.0 : 0),
                                      child: CircleAvatar(
                                        radius: 16,
                                        backgroundColor: Colors.primaries[
                                            i % Colors.primaries.length],
                                        child: Text(
                                          (project['members'][i] as String)
                                              .substring(0, 1),
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ),
                                  if ((project['members'] as List).length >
                                      3) ...[
                                    Padding(
                                      padding:
                                          const EdgeInsets.only(left: -8.0),
                                      child: CircleAvatar(
                                        radius: 16,
                                        backgroundColor:
                                            AppColors.surfaceVariant,
                                        child: Text(
                                          '+${(project['members'] as List).length - 3}',
                                          style: const TextStyle(
                                            color: AppColors.textPrimary,
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                  const Spacer(),
                                  TextButton.icon(
                                    onPressed: () {
                                      showInfoSnackBar(context,
                                          'View project details coming soon!');
                                    },
                                    icon: const Icon(Icons.arrow_forward,
                                        size: 16),
                                    label: const Text('Details'),
                                    style: TextButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 12, vertical: 4),
                                      visualDensity: VisualDensity.compact,
                                    ),
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
      ],
    );
  }
}
