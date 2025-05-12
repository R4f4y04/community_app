import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:convert';

class ProjectDetailScreen extends StatefulWidget {
  final Map<String, dynamic> project;
  final String currentUserId;
  final List<Map<String, dynamic>> allDepartments;

  const ProjectDetailScreen({
    super.key,
    required this.project,
    required this.currentUserId,
    required this.allDepartments,
  });

  @override
  State<ProjectDetailScreen> createState() => _ProjectDetailScreenState();
}

class _ProjectDetailScreenState extends State<ProjectDetailScreen> {
  late Map<String, dynamic> project;
  late bool isOwner;
  late bool isMember;
  double? progress;
  bool updatingProgress = false;
  List<Map<String, dynamic>> updates = [];
  bool loadingUpdates = true;
  final TextEditingController _updateController = TextEditingController();
  final supabase = Supabase.instance.client;

  @override
  void initState() {
    super.initState();
    project = widget.project;
    isOwner = widget.currentUserId == (project['ownerid']?.toString() ?? '');
    final membersRaw = project['members'];
    List members;
    if (membersRaw == null) {
      members = [];
    } else if (membersRaw is String) {
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
    isMember = members.map((e) => e.toString()).contains(widget.currentUserId);
    progress = (project['progress'] ?? 0.0) as double;
    _fetchUpdates();
  }

  Future<void> _fetchUpdates() async {
    setState(() => loadingUpdates = true);
    try {
      final response = await supabase
          .from('project_updates')
          .select('*, user:userid(name, profile:profile(profilepicture))')
          .eq('projectid', project['projectid'])
          .order('created_at', ascending: false);
      setState(() {
        updates = List<Map<String, dynamic>>.from(response);
        loadingUpdates = false;
      });
    } catch (e) {
      setState(() => loadingUpdates = false);
    }
  }

  Future<void> _addUpdate() async {
    final content = _updateController.text.trim();
    if (content.isEmpty || !isMember) return;
    try {
      final userId = widget.currentUserId;
      await supabase.from('project_updates').insert({
        'projectid': project['projectid'],
        'userid': userId,
        'content': content,
        'created_at': DateTime.now().toIso8601String(),
      });
      _updateController.clear();
      await _fetchUpdates();
    } catch (e) {}
  }

  Future<void> _updateProgress(double newProgress) async {
    if (!isOwner) return;
    setState(() => updatingProgress = true);
    try {
      await supabase.from('project').update({'progress': newProgress}).eq(
          'projectid', project['projectid']);
      setState(() {
        progress = newProgress;
        project['progress'] = newProgress;
      });
    } catch (e) {
    } finally {
      setState(() => updatingProgress = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final members = project['member_infos'] as List? ?? [];
    return Scaffold(
      appBar: AppBar(
        backgroundColor: colorScheme.surface,
        elevation: 0,
        iconTheme: IconThemeData(color: colorScheme.onSurface),
        title: Text(
          'Project',
          style: theme.textTheme.titleLarge?.copyWith(
            color: colorScheme.onSurface,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            project['title'] ?? '',
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: colorScheme.primary,
                            ),
                          ),
                        ),
                        Chip(
                          label: Text(
                            project['status'] ?? '',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: colorScheme.onPrimary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          backgroundColor: colorScheme.primary,
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      project['description'] ?? '',
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: colorScheme.onSurface.withOpacity(0.8),
                      ),
                    ),
                    const SizedBox(height: 18),
                    Row(
                      children: [
                        Icon(Icons.school,
                            size: 18, color: colorScheme.primary),
                        const SizedBox(width: 6),
                        Text(
                          project['department']?['name'] ?? '',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onSurface.withOpacity(0.7),
                          ),
                        ),
                        const Spacer(),
                        Icon(Icons.calendar_today,
                            size: 16, color: colorScheme.primary),
                        const SizedBox(width: 4),
                        Text(
                          project['deadline'] ?? '',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurface.withOpacity(0.7),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    Row(
                      children: [
                        Text('Progress:', style: theme.textTheme.bodyMedium),
                        const SizedBox(width: 8),
                        Expanded(
                          child: LinearProgressIndicator(
                            value: progress ?? 0.0,
                            backgroundColor: colorScheme.surfaceVariant,
                            valueColor: AlwaysStoppedAnimation<Color>(
                                colorScheme.primary),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text('${((progress ?? 0.0) * 100).toInt()}%',
                            style: theme.textTheme.bodySmall),
                        if (isOwner)
                          IconButton(
                            icon: Icon(Icons.edit, color: colorScheme.primary),
                            onPressed: updatingProgress
                                ? null
                                : () {
                                    showModalBottomSheet(
                                      context: context,
                                      shape: const RoundedRectangleBorder(
                                        borderRadius: BorderRadius.vertical(
                                            top: Radius.circular(20)),
                                      ),
                                      builder: (context) {
                                        double tempProgress = progress ?? 0.0;
                                        return Padding(
                                          padding: const EdgeInsets.all(24.0),
                                          child: Column(
                                            mainAxisSize: MainAxisSize.min,
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text('Update Progress',
                                                  style: theme
                                                      .textTheme.titleMedium),
                                              Slider(
                                                value: tempProgress,
                                                min: 0.0,
                                                max: 1.0,
                                                divisions: 20,
                                                label:
                                                    '${(tempProgress * 100).toInt()}%',
                                                onChanged: (v) {
                                                  setState(() {
                                                    tempProgress = v;
                                                  });
                                                },
                                              ),
                                              Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.end,
                                                children: [
                                                  TextButton(
                                                    onPressed: () =>
                                                        Navigator.pop(context),
                                                    child: const Text('Cancel'),
                                                  ),
                                                  ElevatedButton(
                                                    onPressed: () async {
                                                      await _updateProgress(
                                                          tempProgress);
                                                      Navigator.pop(context);
                                                    },
                                                    child: const Text('Update'),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        );
                                      },
                                    );
                                  },
                          ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    Text('Team Members', style: theme.textTheme.titleMedium),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 48,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: members.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 10),
                        itemBuilder: (context, i) {
                          final m = members[i];
                          final profileUrl = m['profileUrl'] ?? '';
                          final name = m['name'] ?? 'User';
                          return Column(
                            children: [
                              CircleAvatar(
                                radius: 18,
                                backgroundColor:
                                    colorScheme.primary.withOpacity(0.15),
                                backgroundImage: profileUrl.isNotEmpty
                                    ? NetworkImage(profileUrl)
                                    : null,
                                child: profileUrl.isEmpty
                                    ? Text(
                                        _getInitials(name),
                                        style: theme.textTheme.labelLarge
                                            ?.copyWith(
                                          color: colorScheme.primary,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      )
                                    : null,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                name.split(' ').first,
                                style: theme.textTheme.labelSmall,
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text('Project Updates', style: theme.textTheme.titleMedium),
                    const SizedBox(height: 8),
                    loadingUpdates
                        ? const Center(child: CircularProgressIndicator())
                        : updates.isEmpty
                            ? Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 32),
                                child: Text(
                                  'No updates yet. Be the first to post!',
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color:
                                        colorScheme.onSurface.withOpacity(0.6),
                                  ),
                                ),
                              )
                            : ListView.separated(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: updates.length,
                                separatorBuilder: (_, __) =>
                                    const SizedBox(height: 18),
                                itemBuilder: (context, idx) {
                                  final u = updates[idx];
                                  final user = u['user'] ?? {};
                                  final profileUrl =
                                      user['profile']?['profilepicture'] ?? '';
                                  final name = user['name'] ?? 'User';
                                  return Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      CircleAvatar(
                                        radius: 16,
                                        backgroundColor: colorScheme.primary
                                            .withOpacity(0.15),
                                        backgroundImage: profileUrl.isNotEmpty
                                            ? NetworkImage(profileUrl)
                                            : null,
                                        child: profileUrl.isEmpty
                                            ? Text(
                                                _getInitials(name),
                                                style: theme
                                                    .textTheme.labelLarge
                                                    ?.copyWith(
                                                  color: colorScheme.primary,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              )
                                            : null,
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              name,
                                              style: theme.textTheme.bodyMedium
                                                  ?.copyWith(
                                                fontWeight: FontWeight.bold,
                                                color: colorScheme.primary,
                                              ),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              u['content'] ?? '',
                                              style: theme.textTheme.bodyLarge,
                                            ),
                                            if (u['created_at'] != null)
                                              Padding(
                                                padding: const EdgeInsets.only(
                                                    top: 2.0),
                                                child: Text(
                                                  u['created_at'].toString(),
                                                  style: theme
                                                      .textTheme.bodySmall
                                                      ?.copyWith(
                                                    color: colorScheme.onSurface
                                                        .withOpacity(0.5),
                                                    fontSize: 11,
                                                  ),
                                                ),
                                              ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  );
                                },
                              ),
                  ],
                ),
              ),
            ),
            // Persistent update input bar (only for members)
            if (isMember)
              Container(
                padding: EdgeInsets.only(
                  left: 12,
                  right: 8,
                  bottom: MediaQuery.of(context).viewInsets.bottom + 8,
                  top: 8,
                ),
                decoration: BoxDecoration(
                  color: colorScheme.surface,
                  boxShadow: [
                    BoxShadow(
                      color: colorScheme.shadow.withOpacity(0.08),
                      blurRadius: 12,
                      offset: const Offset(0, -2),
                    ),
                  ],
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(18)),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: colorScheme.primary.withOpacity(0.15),
                      child: Text(
                        _getInitials(project['owner']?['name'] ?? 'U'),
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: colorScheme.surfaceVariant,
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: TextField(
                          controller: _updateController,
                          minLines: 1,
                          maxLines: 4,
                          style: theme.textTheme.bodyLarge,
                          decoration: InputDecoration(
                            hintText: 'Add an update...',
                            hintStyle: theme.textTheme.bodyMedium,
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 12),
                          ),
                          onSubmitted: (_) => _addUpdate(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Material(
                      color: colorScheme.primary,
                      borderRadius: BorderRadius.circular(24),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(24),
                        onTap: _addUpdate,
                        child: const Padding(
                          padding: EdgeInsets.all(10.0),
                          child:
                              Icon(Icons.send, color: Colors.white, size: 22),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
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
}
