import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final supabase = Supabase.instance.client;

class PostDetailScreen extends StatefulWidget {
  final Map<String, dynamic> post;
  final bool isLiked;
  final VoidCallback? onLike;
  final VoidCallback? onShare;
  final bool autoFocusComment;

  const PostDetailScreen({
    super.key,
    required this.post,
    this.isLiked = false,
    this.onLike,
    this.onShare,
    this.autoFocusComment = false,
  });

  @override
  State<PostDetailScreen> createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends State<PostDetailScreen> {
  final TextEditingController _commentController = TextEditingController();
  final FocusNode _commentFocusNode = FocusNode();
  bool _isPosting = false;
  List<Map<String, dynamic>> _comments = [];
  bool _loadingComments = true;

  @override
  void initState() {
    super.initState();
    _fetchComments();
    if (widget.autoFocusComment) {
      // Delay focus to after build
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _commentFocusNode.requestFocus();
      });
    }
  }

  Future<void> _fetchComments() async {
    setState(() {
      _loadingComments = true;
    });
    try {
      final response = await supabase
          .from('comment_details')
          .select()
          .eq('postid', widget.post['id'])
          .order('created_at', ascending: true);
      setState(() {
        _comments = List<Map<String, dynamic>>.from(response);
        _loadingComments = false;
      });
    } catch (e) {
      setState(() {
        _loadingComments = false;
      });
    }
  }

  Future<void> _refreshPostData() async {
    try {
      final response = await supabase
          .from('posts')
          .select('comments_count')
          .eq('postid', widget.post['id'])
          .maybeSingle();
      if (response != null && mounted) {
        setState(() {
          widget.post['comments'] = response['comments_count'];
        });
      }
    } catch (e) {
      // Optionally handle error
    }
  }

  Future<void> _addComment() async {
    final comment = _commentController.text.trim();
    if (comment.isEmpty || _isPosting) return;
    setState(() {
      _isPosting = true;
    });
    try {
      final session = supabase.auth.currentSession;
      final userId = session?.user.id;
      if (userId == null) return;
      await supabase.from('comments').insert({
        'postid': widget.post['id'],
        'userid': userId,
        'content': comment,
        'created_at': DateTime.now().toIso8601String(),
      });
      _commentController.clear();
      await _fetchComments();
      await _refreshPostData();
    } catch (e) {
    } finally {
      setState(() {
        _isPosting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final String userInitials = (widget.post['author'] ?? 'U')
        .split(' ')
        .map((e) => e.isNotEmpty ? e[0] : '')
        .take(2)
        .join()
        .toUpperCase();
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
                          tag: 'avatar_${widget.post['id']}',
                          child: CircleAvatar(
                            radius: 28,
                            backgroundImage:
                                NetworkImage(widget.post['avatar'] ?? ''),
                            backgroundColor:
                                colorScheme.primary.withOpacity(0.08),
                            child: (widget.post['avatar'] == null ||
                                    widget.post['avatar'].isEmpty)
                                ? Text(
                                    (widget.post['author'] ?? 'U')
                                        .substring(0, 1),
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
                              widget.post['author'] ?? 'Unknown User',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: colorScheme.primary,
                              ),
                            ),
                            Text(
                              widget.post['timestamp'] ?? '',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: colorScheme.onSurface.withOpacity(0.7),
                              ),
                            ),
                          ],
                        ),
                        const Spacer(),
                        Chip(
                          label: Text(
                            widget.post['department'] ?? '',
                            style: theme.textTheme.labelLarge?.copyWith(
                              color: colorScheme.onPrimary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          backgroundColor: colorScheme.primary,
                          padding: EdgeInsets.zero,
                          materialTapTargetSize:
                              MaterialTapTargetSize.shrinkWrap,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Text(
                      widget.post['title'] ?? '',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      widget.post['content'] ?? '',
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 32),
                    Row(
                      children: [
                        IconButton(
                          icon: Icon(
                            widget.isLiked
                                ? Icons.thumb_up_alt
                                : Icons.thumb_up_alt_outlined,
                            color: widget.isLiked
                                ? colorScheme.primary
                                : colorScheme.primary.withOpacity(0.5),
                          ),
                          onPressed: widget.onLike,
                          visualDensity: VisualDensity.compact,
                        ),
                        Text(
                          '${widget.post['likes']}',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: colorScheme.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 18),
                        Material(
                          color: colorScheme.surfaceVariant,
                          borderRadius: BorderRadius.circular(24),
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Icon(Icons.mode_comment_rounded,
                                color: colorScheme.primary, size: 22),
                          ),
                        ),
                        Text(
                          '${widget.post['comments']}',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: colorScheme.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const Spacer(),
                        IconButton(
                          icon: const Icon(Icons.share_rounded),
                          onPressed: widget.onShare,
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
                    _loadingComments
                        ? const Center(child: CircularProgressIndicator())
                        : _comments.isEmpty
                            ? Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 32),
                                child: Text(
                                  'No comments yet. Be the first to comment!',
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color:
                                        colorScheme.onSurface.withOpacity(0.6),
                                  ),
                                ),
                              )
                            : ListView.separated(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: _comments.length,
                                separatorBuilder: (_, __) =>
                                    const SizedBox(height: 18),
                                itemBuilder: (context, idx) {
                                  final c = _comments[idx];
                                  final initials = (c['name'] ?? 'U')
                                      .split(' ')
                                      .map((e) => e.isNotEmpty ? e[0] : '')
                                      .take(2)
                                      .join()
                                      .toUpperCase();
                                  return Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      CircleAvatar(
                                        radius: 18,
                                        backgroundColor: colorScheme.primary
                                            .withOpacity(0.15),
                                        child: Text(
                                          initials,
                                          style: theme.textTheme.labelLarge
                                              ?.copyWith(
                                            color: colorScheme.primary,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              c['name'] ?? 'User',
                                              style: theme.textTheme.bodyMedium
                                                  ?.copyWith(
                                                fontWeight: FontWeight.bold,
                                                color: colorScheme.primary,
                                              ),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              c['content'] ?? '',
                                              style: theme.textTheme.bodyLarge,
                                            ),
                                            if (c['created_at'] != null)
                                              Padding(
                                                padding: const EdgeInsets.only(
                                                    top: 2.0),
                                                child: Text(
                                                  _getTimeAgo(DateTime.parse(
                                                      c['created_at'])),
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
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(18)),
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
                        focusNode: _commentFocusNode,
                        minLines: 1,
                        maxLines: 4,
                        style: theme.textTheme.bodyLarge,
                        decoration: InputDecoration(
                          hintText: 'Add a comment...',
                          hintStyle: theme.textTheme.bodyMedium,
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                        ),
                        onSubmitted: (_) => _addComment(),
                        enabled: !_isPosting,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Material(
                    color: colorScheme.primary,
                    borderRadius: BorderRadius.circular(24),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(24),
                      onTap: _isPosting ? null : _addComment,
                      child: Padding(
                        padding: const EdgeInsets.all(10.0),
                        child: _isPosting
                            ? SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                      colorScheme.onPrimary),
                                ),
                              )
                            : Icon(Icons.send,
                                color: colorScheme.onPrimary, size: 22),
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

  String _getTimeAgo(DateTime dateTime) {
    final now = DateTime.now().toUtc();
    final difference = now.difference(dateTime.toUtc());
    if (difference.inDays > 365) {
      return '${(difference.inDays / 365).floor()}y ago';
    } else if (difference.inDays > 30) {
      return '${(difference.inDays / 30).floor()}mo ago';
    } else if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'just now';
    }
  }
}
