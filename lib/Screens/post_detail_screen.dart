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
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Author Row
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
                  // Post Title
                  Text(
                    post['title'] ?? '',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Post Content
                  Text(
                    post['content'] ?? '',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: colorScheme.onSurface,
                    ),
                  ),
                  // TODO: Add image/attachment preview here in the future
                  const SizedBox(height: 32),
                  // Interaction Buttons
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
                  // Comments header (actual comments list will be below the comment bar)
                  Text(
                    'Comments',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.primary,
                    ),
                  ),
                  // TODO: Comments list will be implemented with the comment bar
                ],
              ),
            ),
          ),
          // TODO: Modern comment bar will be implemented in the next step
        ],
      ),
    );
  }
}
