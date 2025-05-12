import 'package:flutter/material.dart';

class PostDetailScreen extends StatelessWidget {
  final Map<String, dynamic> post;
  final bool isLiked;
  final VoidCallback? onLike;
  final VoidCallback? onComment;
  final VoidCallback? onShare;

  const PostDetailScreen({
    super.key,
    required this.post,
    this.isLiked = false,
    this.onLike,
    this.onComment,
    this.onShare,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final String userInitials = (post['author'] ?? 'U').split(' ').map((e) => e.isNotEmpty ? e[0] : '').take(2).join().toUpperCase();
    final TextEditingController _commentController = TextEditingController();
    final List<Map<String, String>> comments = [];

    return Scaffold(
      appBar: AppBar(
        backgroundColor: colorScheme.surface,
        elevation: 0,
        iconTheme: IconThemeData(color: colorScheme.onSurface),
        title: Text(
          'Post',
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
                        Hero(
                          tag: 'avatar_${post['id']}',
                          child: CircleAvatar(
                            radius: 28,
                            backgroundImage: NetworkImage(post['avatar'] ?? ''),
                            backgroundColor:
                                colorScheme.primary.withOpacity(0.08),
                            child: (post['avatar'] == null ||
                                    post['avatar'].isEmpty)
                                ? Text(
                                    (post['author'] ?? 'U').substring(0, 1),
                                    style: theme.textTheme.titleLarge?.copyWith(
                                      color: colorScheme.primary,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  )
                                : null,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              post['author'] ?? 'Unknown User',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: colorScheme.primary,
                              ),
                            ),
                            Text(
                              post['timestamp'] ?? '',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: colorScheme.onSurface.withOpacity(0.7),
                              ),
                            ),
                          ],
                        ),
                        const Spacer(),
                        Chip(
                          label: Text(
                            post['department'] ?? '',
                            style: theme.textTheme.labelLarge?.copyWith(
                              color: colorScheme.onPrimary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          backgroundColor: colorScheme.primary,
                          padding: EdgeInsets.zero,
                          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Text(
                      post['title'] ?? '',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      post['content'] ?? '',
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 32),
                    Row(
                      children: [
                        IconButton(
                          icon: Icon(
                            isLiked
                                ? Icons.thumb_up_alt
                                : Icons.thumb_up_alt_outlined,
                            color: isLiked
                                ? colorScheme.primary
                                : colorScheme.primary.withOpacity(0.5),
                          ),
                          onPressed: onLike,
                          visualDensity: VisualDensity.compact,
                        ),
                        Text(
                          '${post['likes']}',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: colorScheme.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 18),
                        IconButton(
                          icon: const Icon(Icons.mode_comment_rounded),
                          onPressed: onComment,
                          visualDensity: VisualDensity.compact,
                          color: colorScheme.primary,
                        ),
                        Text(
                          '${post['comments']}',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: colorScheme.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const Spacer(),
                        IconButton(
                          icon: const Icon(Icons.share_rounded),
                          onPressed: onShare,
                          visualDensity: VisualDensity.compact,
                          color: colorScheme.primary,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Comments',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    comments.isEmpty
                        ? Padding(
                            padding: const EdgeInsets.symmetric(vertical: 32),
                            child: Text(
                              'No comments yet. Be the first to comment!',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: colorScheme.onSurface.withOpacity(0.6),
                              ),
                            ),
                          )
                        : ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: comments.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 18),
                            itemBuilder: (context, idx) {
                              final c = comments[idx];
                              final initials = (c['name'] ?? 'U').split(' ').map((e) => e.isNotEmpty ? e[0] : '').take(2).join().toUpperCase();
                              return Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  CircleAvatar(
                                    radius: 18,
                                    backgroundColor: colorScheme.primary.withOpacity(0.15),
                                    child: Text(
                                      initials,
                                      style: theme.textTheme.labelLarge?.copyWith(
                                        color: colorScheme.primary,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          c['name'] ?? 'User',
                                          style: theme.textTheme.bodyMedium?.copyWith(
                                            fontWeight: FontWeight.bold,
                                            color: colorScheme.primary,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          c['content'] ?? '',
                                          style: theme.textTheme.bodyLarge,
                                        ),
                                        if (c['time'] != null)
                                          Padding(
                                            padding: const EdgeInsets.only(top: 2.0),
                                            child: Text(
                                              c['time']!,
                                              style: theme.textTheme.bodySmall?.copyWith(
                                                color: colorScheme.onSurface.withOpacity(0.5),
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
                    const SizedBox(height: 80),
                  ],
                ),
              ),
            ),
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
                borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: colorScheme.primary.withOpacity(0.15),
                    child: Text(
                      userInitials,
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
                        controller: _commentController,
                        minLines: 1,
                        maxLines: 4,
                        style: theme.textTheme.bodyLarge,
                        decoration: InputDecoration(
                          hintText: 'Add a comment...',
                          hintStyle: theme.textTheme.bodyMedium,
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Material(
                    color: colorScheme.primary,
                    borderRadius: BorderRadius.circular(24),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(24),
                      onTap: () {
                        // TODO: Implement comment send logic
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(10.0),
                        child: Icon(Icons.send, color: colorScheme.onPrimary, size: 22),
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
}
