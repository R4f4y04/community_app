import 'package:flutter/material.dart';
import 'package:dbms_proj/util/theme.dart';
import 'package:dbms_proj/util/functions.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ProjectsScreen extends StatefulWidget {
  const ProjectsScreen({super.key});

  @override
  State<ProjectsScreen> createState() => _ProjectsScreenState();
}

class _ProjectsScreenState extends State<ProjectsScreen> {
  String _selectedStatus = "All";
  final List<String> _statuses = ["All", "Ongoing", "Completed", "Planning"];

  // Supabase client
  final supabase = Supabase.instance.client;

  // Projects and loading state
  List<Map<String, dynamic>> _projects = [];
  bool _isLoading = true;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _loadProjects();
  }

  Future<void> _loadProjects() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });
    try {
      final response = await supabase
          .from('project')
          .select(
              '*, department:departmentid(name), owner:ownerid(name, profile:profilepicture)')
          .order('projectid', ascending: false);
      setState(() {
        _projects = List<Map<String, dynamic>>.from(response);
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _hasError = true;
      });
      debugPrint('Error loading projects: $e');
    }
  }

  List<Map<String, dynamic>> get filteredProjects {
    if (_selectedStatus == "All") {
      return _projects;
    } else {
      return _projects
          .where((project) =>
              (project['status'] ?? '').toString().toLowerCase() ==
              _selectedStatus.toLowerCase())
          .toList();
    }
  }

  // Fetch project updates for a given project
  Future<List<Map<String, dynamic>>> _fetchProjectUpdates(int projectId) async {
    try {
      final response = await supabase
          .from('project_updates')
          .select('*, user:userid(name, profile:profilepicture)')
          .eq('projectid', projectId)
          .order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Error fetching project updates: $e');
      return [];
    }
  }

  // Add a new project update
  Future<void> _addProjectUpdate(int projectId, String content) async {
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) return;
      await supabase.from('project_updates').insert({
        'projectid': projectId,
        'userid': userId,
        'content': content,
        'created_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      debugPrint('Error adding project update: $e');
    }
  }

  // Show project details dialog with updates feed
  void _showProjectDetails(Map<String, dynamic> project) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: SizedBox(
          width: 400,
          child: Padding(
            padding: const EdgeInsets.all(18.0),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(project['title'] ?? '',
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 20)),
                  const SizedBox(height: 8),
                  Text(project['description'] ?? '',
                      style: const TextStyle(fontSize: 14)),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Icon(Icons.school, size: 16),
                      const SizedBox(width: 4),
                      Text(project['department']?['name'] ?? '',
                          style: const TextStyle(fontSize: 12)),
                      const Spacer(),
                      const Icon(Icons.calendar_today, size: 16),
                      const SizedBox(width: 4),
                      Text(project['deadline'] ?? '',
                          style: const TextStyle(fontSize: 12)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text('Team Members:',
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 8,
                    children: [
                      for (final member in (project['members'] ?? []))
                        Chip(label: Text(member.toString())),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text('Project Updates',
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 8),
                  FutureBuilder<List<Map<String, dynamic>>>(
                    future: _fetchProjectUpdates(project['projectid']),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      final updates = snapshot.data ?? [];
                      if (updates.isEmpty) {
                        return const Padding(
                          padding: EdgeInsets.symmetric(vertical: 16),
                          child: Text('No updates yet.',
                              style: TextStyle(color: Colors.black54)),
                        );
                      }
                      return ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: updates.length,
                        separatorBuilder: (_, __) => const Divider(height: 16),
                        itemBuilder: (context, idx) {
                          final u = updates[idx];
                          return Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              CircleAvatar(
                                radius: 16,
                                backgroundImage: NetworkImage(u['user']
                                        ?['profile'] ??
                                    'https://i.pravatar.cc/150?img=1'),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(u['user']?['name'] ?? 'User',
                                        style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14)),
                                    Text(u['content'] ?? '',
                                        style: const TextStyle(fontSize: 14)),
                                    Text(
                                      u['created_at'] != null
                                          ? u['created_at'].toString()
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
                      );
                    },
                  ),
                  const SizedBox(height: 12),
                  _ProjectUpdateInput(
                    onSubmit: (content) async {
                      await _addProjectUpdate(project['projectid'], content);
                      Navigator.pop(context);
                      Future.delayed(const Duration(milliseconds: 200), () {
                        _showProjectDetails(project);
                      });
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
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
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _hasError
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.error_outline,
                            size: 80,
                            color: AppColors.textSecondary,
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'Failed to load projects',
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 8),
                          ElevatedButton.icon(
                            onPressed: _loadProjects,
                            icon: const Icon(Icons.refresh),
                            label: const Text('Retry'),
                          ),
                        ],
                      ),
                    )
                  : filteredProjects.isEmpty
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
                                  _showProjectDetails(project);
                                },
                                borderRadius: BorderRadius.circular(12),
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
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
                                            backgroundColor: _getStatusColor(
                                                project['status']),
                                            padding: EdgeInsets.zero,
                                            materialTapTargetSize:
                                                MaterialTapTargetSize
                                                    .shrinkWrap,
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
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
                                      Row(
                                        children: [
                                          const Icon(
                                            Icons.school,
                                            size: 16,
                                            color: AppColors.textSecondary,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            project['department']?['name'] ??
                                                '',
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
                                            project['deadline'] ?? '',
                                            style: const TextStyle(
                                              fontSize: 12,
                                              color: AppColors.textSecondary,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 16),
                                      LinearProgressIndicator(
                                        value: project['progress'] as double,
                                        backgroundColor:
                                            AppColors.surfaceVariant,
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                          _getStatusColor(project['status']),
                                        ),
                                        borderRadius: BorderRadius.circular(2),
                                      ),
                                      const SizedBox(height: 8),
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
                                      Row(
                                        children: [
                                          SizedBox(
                                            width: 88,
                                            height: 32,
                                            child: Stack(
                                              children: [
                                                for (int i = 0;
                                                    i <
                                                            (project['members']
                                                                    as List)
                                                                .length &&
                                                        i < 3;
                                                    i++)
                                                  Positioned(
                                                    left: i * 22.0,
                                                    child: CircleAvatar(
                                                      radius: 16,
                                                      backgroundColor:
                                                          Colors.primaries[i %
                                                              Colors.primaries
                                                                  .length],
                                                      child: Text(
                                                        (project['members'][i]
                                                                as String)
                                                            .substring(0, 1),
                                                        style: const TextStyle(
                                                          color: Colors.white,
                                                          fontSize: 12,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                if ((project['members'] as List)
                                                        .length >
                                                    3)
                                                  Positioned(
                                                    left: 3 * 22.0,
                                                    child: CircleAvatar(
                                                      radius: 16,
                                                      backgroundColor: AppColors
                                                          .surfaceVariant,
                                                      child: Text(
                                                        '+${(project['members'] as List).length - 3}',
                                                        style: const TextStyle(
                                                          color: AppColors
                                                              .textPrimary,
                                                          fontSize: 10,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                              ],
                                            ),
                                          ),
                                          const Spacer(),
                                          TextButton.icon(
                                            onPressed: () {
                                              _showProjectDetails(project);
                                            },
                                            icon: const Icon(
                                                Icons.arrow_forward,
                                                size: 16),
                                            label: const Text('Details'),
                                            style: TextButton.styleFrom(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 12,
                                                      vertical: 4),
                                              visualDensity:
                                                  VisualDensity.compact,
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

class _ProjectUpdateInput extends StatefulWidget {
  final Future<void> Function(String content) onSubmit;

  const _ProjectUpdateInput({required this.onSubmit, Key? key})
      : super(key: key);

  @override
  State<_ProjectUpdateInput> createState() => _ProjectUpdateInputState();
}

class _ProjectUpdateInputState extends State<_ProjectUpdateInput> {
  final TextEditingController _controller = TextEditingController();
  bool _isSubmitting = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Add Update:',
            style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 6),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _controller,
                decoration: const InputDecoration(
                  hintText: 'Write an update...',
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: _isSubmitting
                  ? null
                  : () async {
                      final content = _controller.text.trim();
                      if (content.isEmpty) return;
                      setState(() {
                        _isSubmitting = true;
                      });
                      await widget.onSubmit(content);
                      setState(() {
                        _isSubmitting = false;
                      });
                      _controller.clear();
                    },
              child: _isSubmitting
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Post'),
            ),
          ],
        ),
      ],
    );
  }
}
