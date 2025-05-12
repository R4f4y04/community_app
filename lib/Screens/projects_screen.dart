import 'package:flutter/material.dart';
import 'package:dbms_proj/util/functions.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:convert';
import 'project_detail_screen.dart';

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

  // State for project creation dialog
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descController = TextEditingController();
  String? _selectedProjectStatus;
  double _selectedProgress = 0.0;
  int? _selectedDepartmentId;
  List<Map<String, dynamic>> _departments = [];
  List<Map<String, dynamic>> _allUsers = [];
  List<String> _selectedMemberIds = [];
  String? _formError;

  @override
  void initState() {
    super.initState();
    _loadProjects();
    _subscribeToProjectsRealtime();
  }

  void _subscribeToProjectsRealtime() {
    final channel = supabase.channel('public:project');
    channel
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'project',
          callback: (payload) {
            _loadProjects();
          },
        )
        .subscribe();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _loadProjects() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });
    try {
      final response = await supabase
          .from('project')
          .select('*, department:departmentid(name), owner:ownerid(name)')
          .order('projectid', ascending: false);
      List<Map<String, dynamic>> projects =
          List<Map<String, dynamic>>.from(response);
      // Prefetch member info for avatars (first 3 members)
      for (final project in projects) {
        // Ensure members is always a List
        final membersRaw = project['members'];
        List memberIds;
        if (membersRaw == null) {
          memberIds = [];
        } else if (membersRaw is String) {
          try {
            memberIds = List.from(jsonDecode(membersRaw));
          } catch (_) {
            memberIds = [];
          }
        } else if (membersRaw is List) {
          memberIds = membersRaw;
        } else {
          memberIds = [];
        }
        memberIds = memberIds.take(3).toList();
        if (memberIds.isNotEmpty) {
          final membersResp = await supabase
              .from('users')
              .select('userid, name, profile:profile(profilepicture)')
              .inFilter('userid', memberIds);
          final infos = <Map<String, String>>[];
          for (final m in membersResp) {
            infos.add({
              'name': m['name'] ?? 'User',
              'profileUrl': m['profile']?['profilepicture'] ?? '',
            });
          }
          project['member_infos'] = infos;
        } else {
          project['member_infos'] = [];
        }
      }
      setState(() {
        _projects = projects;
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

  Future<void> _fetchDepartmentsAndUsers() async {
    try {
      final deptResp = await supabase
          .from('department')
          .select('departmentid, name')
          .order('name');
      final usersResp =
          await supabase.from('users').select('userid, name').order('name');
      setState(() {
        _departments = List<Map<String, dynamic>>.from(deptResp);
        _allUsers = List<Map<String, dynamic>>.from(usersResp);
      });
    } catch (e) {
      setState(() {
        _departments = [];
        _allUsers = [];
      });
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

  Future<List<Map<String, dynamic>>> _fetchProjectUpdates(int projectId) async {
    try {
      final response = await supabase
          .from('project_updates')
          .select('*, user:userid(name, profile:profile(profilepicture))')
          .eq('projectid', projectId)
          .order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Error fetching project updates: $e');
      return [];
    }
  }

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

  Future<List<Map<String, dynamic>>> _fetchProjectMembers(
      dynamic membersRaw) async {
    // Ensure membersRaw is a List<String> or List<int>
    List members;
    if (membersRaw == null) {
      members = [];
    } else if (membersRaw is String) {
      // Try to decode JSON string
      try {
        members = List.from(jsonDecode(membersRaw));
      } catch (_) {
        members = [];
      }
    } else if (membersRaw is List) {
      members = membersRaw;
    } else {
      members = [];
    }
    if (members.isEmpty) return [];
    try {
      debugPrint('Fetching members for: ' + members.toString());
      final response = await supabase
          .from('users')
          .select('userid, name, profile:profile(profilepicture)')
          .inFilter('userid', members);
      debugPrint('Fetched members: ' + response.toString());
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Error fetching project members: $e');
      return [];
    }
  }

  String _getInitials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length == 1) {
      return parts[0].substring(0, 1).toUpperCase();
    } else if (parts.length > 1) {
      return (parts[0].substring(0, 1) + parts[1].substring(0, 1))
          .toUpperCase();
    }
    return 'U';
  }

  Widget _buildUserAvatar(String? name, String? profileUrl,
      {double radius = 12}) {
    if (profileUrl != null && profileUrl.isNotEmpty) {
      return CircleAvatar(
        radius: radius,
        backgroundImage: NetworkImage(profileUrl),
        backgroundColor: Colors.grey[200],
      );
    }
    String initials = '';
    if (name != null && name.isNotEmpty) {
      final parts = name.trim().split(' ');
      if (parts.length == 1) {
        initials = parts[0].substring(0, 1).toUpperCase();
      } else {
        initials = parts[0].substring(0, 1).toUpperCase() +
            parts[1].substring(0, 1).toUpperCase();
      }
    } else {
      initials = '?';
    }
    return CircleAvatar(
      radius: radius,
      backgroundColor: Theme.of(context).colorScheme.primary,
      child: Text(
        initials,
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: radius,
        ),
      ),
    );
  }

  void _showCreateProjectModalSheet() async {
    await _fetchDepartmentsAndUsers();
    _titleController.clear();
    _descController.clear();
    _selectedProjectStatus = null;
    _selectedProgress = 0.0;
    _selectedDepartmentId = null;
    _selectedMemberIds = [];
    _formError = null;
    bool isSubmitting = false;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

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
            builder: (context, setStateModal) => SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Create Project',
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
                  TextFormField(
                    controller: _titleController,
                    decoration: InputDecoration(
                      labelText: 'Project Title',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      filled: true,
                      fillColor: colorScheme.surfaceVariant,
                    ),
                    style: theme.textTheme.bodyLarge,
                    textInputAction: TextInputAction.next,
                    maxLength: 80,
                    validator: (v) => v == null || v.trim().isEmpty ? 'Title required' : null,
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _descController,
                    decoration: InputDecoration(
                      labelText: 'Description',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      filled: true,
                      fillColor: colorScheme.surfaceVariant,
                    ),
                    style: theme.textTheme.bodyLarge,
                    minLines: 3,
                    maxLines: 6,
                    maxLength: 500,
                    validator: (v) => v == null || v.trim().isEmpty ? 'Description required' : null,
                  ),
                  const SizedBox(height: 14),
                  DropdownButtonFormField<int>(
                    decoration: InputDecoration(
                      labelText: 'Department',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      filled: true,
                      fillColor: colorScheme.surfaceVariant,
                    ),
                    value: _selectedDepartmentId,
                    items: _departments
                        .map((d) => DropdownMenuItem<int>(
                              value: d['departmentid'],
                              child: Text(d['name'] ?? 'Unknown'),
                            ))
                        .toList(),
                    onChanged: (v) => setStateModal(() => _selectedDepartmentId = v),
                    validator: (v) => v == null ? 'Select department' : null,
                  ),
                  const SizedBox(height: 14),
                  DropdownButtonFormField<String>(
                    decoration: InputDecoration(
                      labelText: 'Status',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      filled: true,
                      fillColor: colorScheme.surfaceVariant,
                    ),
                    value: _selectedProjectStatus,
                    items: _statuses
                        .where((s) => s != 'All')
                        .map((s) => DropdownMenuItem<String>(
                              value: s,
                              child: Text(s),
                            ))
                        .toList(),
                    onChanged: (v) => setStateModal(() => _selectedProjectStatus = v),
                    validator: (v) => v == null ? 'Select status' : null,
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      const Text('Progress:'),
                      Expanded(
                        child: Slider(
                          value: _selectedProgress,
                          min: 0.0,
                          max: 1.0,
                          divisions: 20,
                          label: '${(_selectedProgress * 100).toInt()}%',
                          onChanged: (v) => setStateModal(() => _selectedProgress = v),
                        ),
                      ),
                      Text('${(_selectedProgress * 100).toInt()}%'),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Text('Team Members', style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: _allUsers.map((u) {
                      final isSelected = _selectedMemberIds.contains(u['userid']);
                      final name = u['name'] ?? 'User';
                      return FilterChip(
                        label: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            CircleAvatar(
                              radius: 10,
                              backgroundColor: colorScheme.primary.withOpacity(0.15),
                              child: Text(
                                name.isNotEmpty ? name[0].toUpperCase() : '?',
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: colorScheme.primary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(name),
                          ],
                        ),
                        selected: isSelected,
                        onSelected: (selected) {
                          setStateModal(() {
                            if (selected) {
                              _selectedMemberIds.add(u['userid']);
                            } else {
                              _selectedMemberIds.remove(u['userid']);
                            }
                          });
                        },
                      );
                    }).toList(),
                  ),
                  if (_formError != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(_formError!, style: const TextStyle(color: Colors.red)),
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
                      onPressed: isSubmitting
                          ? null
                          : () async {
                              if (_titleController.text.trim().isEmpty ||
                                  _descController.text.trim().isEmpty) {
                                setStateModal(() => _formError = 'Title and description required');
                                return;
                              }
                              if (_selectedDepartmentId == null) {
                                setStateModal(() => _formError = 'Select a department');
                                return;
                              }
                              if (_selectedProjectStatus == null) {
                                setStateModal(() => _formError = 'Select a status');
                                return;
                              }
                              if (_selectedMemberIds.isEmpty) {
                                setStateModal(() => _formError = 'Select at least one member');
                                return;
                              }
                              setStateModal(() {
                                isSubmitting = true;
                                _formError = null;
                              });
                              final ownerId = supabase.auth.currentUser?.id;
                              try {
                                await supabase.from('project').insert({
                                  'title': _titleController.text.trim(),
                                  'description': _descController.text.trim(),
                                  'departmentid': _selectedDepartmentId,
                                  'status': _selectedProjectStatus,
                                  'progress': _selectedProgress,
                                  'members': _selectedMemberIds,
                                  'ownerid': ownerId,
                                });
                                Navigator.pop(context);
                                _loadProjects();
                                showSuccessSnackBar(context, 'Project created');
                              } catch (e) {
                                setStateModal(() {
                                  _formError = 'Error creating project: \\n${e.toString()}';
                                  isSubmitting = false;
                                });
                              }
                            },
                      child: isSubmitting
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Text('Create', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Color _getStatusColor(String status) {
    final colorScheme = Theme.of(context).colorScheme;
    switch (status) {
      case 'Ongoing':
        return colorScheme.primary;
      case 'Completed':
        return colorScheme.secondary;
      case 'Planning':
        return colorScheme.tertiary;
      default:
        return colorScheme.surfaceVariant;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Column(
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
                    selectedColor: colorScheme.primary,
                    backgroundColor: colorScheme.surfaceVariant,
                    labelStyle: TextStyle(
                      color: isSelected
                          ? colorScheme.onPrimary
                          : colorScheme.onSurface.withOpacity(0.7),
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
                            Icon(
                              Icons.error_outline,
                              size: 80,
                              color: colorScheme.error,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Failed to load projects',
                              style: theme.textTheme.bodyLarge?.copyWith(
                                color: colorScheme.onSurface.withOpacity(0.7),
                              ),
                            ),
                            const SizedBox(height: 8),
                            ElevatedButton.icon(
                              onPressed: _loadProjects,
                              icon: const Icon(Icons.refresh),
                              label: const Text('Retry'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: colorScheme.primary,
                                foregroundColor: colorScheme.onPrimary,
                              ),
                            ),
                          ],
                        ),
                      )
                    : filteredProjects.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.work_outline,
                                  size: 80,
                                  color: colorScheme.onSurface.withOpacity(0.5),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'No $_selectedStatus projects yet',
                                  style: theme.textTheme.bodyLarge?.copyWith(
                                    color:
                                        colorScheme.onSurface.withOpacity(0.7),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                ElevatedButton.icon(
                                  onPressed: _showCreateProjectModalSheet,
                                  icon: const Icon(Icons.add),
                                  label: const Text('Create Project'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: colorScheme.primary,
                                    foregroundColor: colorScheme.onPrimary,
                                  ),
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
                                  onTap: () async {
                                    final userId = Supabase.instance.client.auth
                                            .currentUser?.id ??
                                        '';
                                    await Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            ProjectDetailScreen(
                                          project: project,
                                          currentUserId: userId,
                                          allDepartments: _departments,
                                        ),
                                      ),
                                    );
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
                                                project['title'] ?? '',
                                                style: theme
                                                    .textTheme.titleMedium
                                                    ?.copyWith(
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                            Chip(
                                              label: Text(
                                                project['status'] ?? '',
                                                style: theme
                                                    .textTheme.labelSmall
                                                    ?.copyWith(
                                                  color: colorScheme.onPrimary,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              backgroundColor: _getStatusColor(
                                                  project['status'] ?? ''),
                                              padding: EdgeInsets.zero,
                                              materialTapTargetSize:
                                                  MaterialTapTargetSize
                                                      .shrinkWrap,
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          project['description'] ?? '',
                                          style: theme.textTheme.bodyMedium
                                              ?.copyWith(
                                            color: colorScheme.onSurface
                                                .withOpacity(0.7),
                                          ),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 16),
                                        Row(
                                          children: [
                                            Icon(
                                              Icons.school,
                                              size: 16,
                                              color: colorScheme.primary,
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              project['department']?['name'] ??
                                                  '',
                                              style: theme.textTheme.bodySmall
                                                  ?.copyWith(
                                                color: colorScheme.onSurface
                                                    .withOpacity(0.7),
                                              ),
                                            ),
                                            const Spacer(),
                                            Icon(
                                              Icons.calendar_today,
                                              size: 16,
                                              color: colorScheme.primary,
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              project['deadline'] ?? '',
                                              style: theme.textTheme.bodySmall
                                                  ?.copyWith(
                                                color: colorScheme.onSurface
                                                    .withOpacity(0.7),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 16),
                                        LinearProgressIndicator(
                                          value: (project['progress'] ?? 0.0)
                                              as double,
                                          backgroundColor:
                                              colorScheme.surfaceVariant,
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
                                            _getStatusColor(
                                                project['status'] ?? ''),
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              'Progress: ${((project['progress'] ?? 0.0) * 100).toInt()}%',
                                              style: theme.textTheme.bodySmall
                                                  ?.copyWith(
                                                color: colorScheme.onSurface
                                                    .withOpacity(0.7),
                                              ),
                                            ),
                                            Text(
                                              '${(project['members'] as List?)?.length ?? 0} members',
                                              style: theme.textTheme.bodySmall
                                                  ?.copyWith(
                                                color: colorScheme.onSurface
                                                    .withOpacity(0.7),
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
                                                              (project['member_infos']
                                                                      as List)
                                                                  .length &&
                                                          i < 3;
                                                      i++)
                                                    Positioned(
                                                      left: i * 22.0,
                                                      child: _buildUserAvatar(
                                                        project['member_infos']
                                                            [i]['name'],
                                                        project['member_infos']
                                                            [i]['profileUrl'],
                                                        radius: 16,
                                                      ),
                                                    ),
                                                  if ((project['members']
                                                                  as List?)
                                                              ?.length !=
                                                          null &&
                                                      (project['members']
                                                                  as List)
                                                              .length >
                                                          3)
                                                    Positioned(
                                                      left: 3 * 22.0,
                                                      child: CircleAvatar(
                                                        radius: 16,
                                                        backgroundColor:
                                                            colorScheme
                                                                .surfaceVariant,
                                                        child: Text(
                                                          '+${(project['members'] as List).length - 3}',
                                                          style: theme.textTheme
                                                              .labelSmall
                                                              ?.copyWith(
                                                            color: colorScheme
                                                                .onSurface,
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
                                                final userId = Supabase
                                                        .instance
                                                        .client
                                                        .auth
                                                        .currentUser
                                                        ?.id ??
                                                    '';
                                                Navigator.push(
                                                  context,
                                                  MaterialPageRoute(
                                                    builder: (context) =>
                                                        ProjectDetailScreen(
                                                      project: project,
                                                      currentUserId: userId,
                                                      allDepartments:
                                                          _departments,
                                                    ),
                                                  ),
                                                );
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
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showCreateProjectModalSheet,
        backgroundColor: colorScheme.primary,
        child: const Icon(Icons.add),
        tooltip: 'Create Project',
      ),
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
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Add Update:',
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(fontWeight: FontWeight.bold)),
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
              style: ElevatedButton.styleFrom(
                backgroundColor: colorScheme.primary,
                foregroundColor: colorScheme.onPrimary,
              ),
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
