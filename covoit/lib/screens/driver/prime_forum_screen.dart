import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../app_theme.dart';
import '../../data/providers/forum_providers.dart';
import '../../data/providers/journey_providers.dart';

class PrimeForumScreen extends ConsumerStatefulWidget {
  const PrimeForumScreen({super.key});

  @override
  ConsumerState<PrimeForumScreen> createState() => _PrimeForumScreenState();
}

class _PrimeForumScreenState extends ConsumerState<PrimeForumScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  final _postCtrl = TextEditingController();
  DateTime? _lastPostTime;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 3, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    final discussionsAsync = ref.watch(forumPostsProvider('discussion'));
    final annoncesAsync = ref.watch(forumPostsProvider('announcement'));
    final bonsPlansAsync = ref.watch(forumPostsProvider('tip'));

    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.workspace_premium_rounded,
                color: AppColors.prime, size: 20),
            SizedBox(width: 8),
            Text('Forum Prime'),
          ],
        ),
        bottom: TabBar(
          controller: _tabCtrl,
          indicatorColor: AppColors.prime,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          tabs: const [
            Tab(text: 'Discussions'),
            Tab(text: 'Annonces'),
            Tab(text: 'Bons plans'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabCtrl,
        children: [
          _buildForumTab(discussionsAsync),
          _buildForumTab(annoncesAsync),
          _buildForumTab(bonsPlansAsync),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showNewPostSheet(context),
        backgroundColor: AppColors.prime,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text('Nouveau post',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
      ),
    );
  }

  Widget _buildForumTab(AsyncValue<Map<String, dynamic>> async) {
    return async.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Erreur: $e')),
      data: (response) {
        final posts = (response['data'] as List?) ?? [];
        if (posts.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.forum_rounded, size: 48, color: AppColors.gray100),
                SizedBox(height: 12),
                Text('Aucun post', style: TextStyle(color: AppColors.gray400, fontWeight: FontWeight.w600)),
              ],
            ),
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: posts.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, i) => _PostCard(
            post: posts[i] as Map<String, dynamic>,
            onLike: () => _toggleLike(posts[i]['id']?.toString() ?? ''),
          ),
        );
      },
    );
  }

  Future<void> _toggleLike(String postId) async {
    final userId = await ref.read(currentUserIdProvider.future);
    if (userId == null || postId.isEmpty) return;
    try {
      final repo = ref.read(forumRepositoryProvider);
      await repo.toggleLike(postId, userId);
      ref.invalidate(forumPostsProvider('discussion'));
      ref.invalidate(forumPostsProvider('announcement'));
      ref.invalidate(forumPostsProvider('tip'));
    } catch (_) {}
  }

  void _showNewPostSheet(BuildContext context) {
    String selectedCategory = 'discussion';
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 20, right: 20, top: 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Nouveau message',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
              const SizedBox(height: 14),
              DropdownButtonFormField<String>(
                value: selectedCategory,
                decoration: const InputDecoration(labelText: 'Catégorie'),
                items: const [
                  DropdownMenuItem(value: 'discussion', child: Text('Discussion')),
                  DropdownMenuItem(value: 'announcement', child: Text('Annonce')),
                  DropdownMenuItem(value: 'tip', child: Text('Bon plan')),
                ],
                onChanged: (v) => setSheetState(() => selectedCategory = v ?? 'discussion'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _postCtrl,
                maxLines: 4,
                decoration: const InputDecoration(
                  hintText: 'Partagez avec la communauté Prime...',
                ),
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    final content = _postCtrl.text.trim();
                    if (content.isEmpty) return;
                    if (content.length < 10) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Le message doit contenir au moins 10 caractères.')),
                      );
                      return;
                    }
                    if (content.length > 4000) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Message trop long (max. 4000 caractères).')),
                      );
                      return;
                    }
                    final now = DateTime.now();
                    if (_lastPostTime != null &&
                        now.difference(_lastPostTime!).inSeconds < 60) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Attendez 1 minute avant de publier à nouveau.')),
                      );
                      return;
                    }
                    final userId = await ref.read(currentUserIdProvider.future);
                    if (userId == null) return;
                    try {
                      final repo = ref.read(forumRepositoryProvider);
                      await repo.createPost(
                        authorId: userId,
                        authorName: 'Moi',
                        category: selectedCategory,
                        content: content,
                      );
                      _lastPostTime = now;
                      _postCtrl.clear();
                      if (context.mounted) Navigator.pop(context);
                      ref.invalidate(forumPostsProvider(selectedCategory));
                    } catch (_) {}
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.prime),
                  child: const Text('Publier'),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}

class _PostCard extends StatelessWidget {
  final Map<String, dynamic> post;
  final VoidCallback onLike;

  const _PostCard({required this.post, required this.onLike});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final author = post['author_name'] as String? ?? 'Anonyme';
    final avatar = post['author_avatar'] as String? ?? author.split(' ').map((e) => e.isNotEmpty ? e[0] : '').take(2).join();
    final content = post['content'] as String? ?? '';
    final isPlatform = post['is_platform'] as bool? ?? false;
    final likes = post['likes_count'] as int? ?? 0;
    final comments = post['comments_count'] as int? ?? 0;
    final createdAt = post['created_at'] as String? ?? '';

    String timeStr = '';
    if (createdAt.isNotEmpty) {
      try {
        final dt = DateTime.parse(createdAt);
        final diff = DateTime.now().difference(dt);
        if (diff.inMinutes < 60) {
          timeStr = 'Il y a ${diff.inMinutes} min';
        } else if (diff.inHours < 24) {
          timeStr = 'Il y a ${diff.inHours}h';
        } else {
          timeStr = 'Il y a ${diff.inDays}j';
        }
      } catch (_) {
        timeStr = createdAt;
      }
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: isPlatform
                      ? AppColors.green
                      : AppColors.primeBg,
                  child: Text(avatar,
                      style: TextStyle(
                          fontSize: avatar.length > 2 ? 8 : 10,
                          fontWeight: FontWeight.w800,
                          color: isPlatform
                              ? Colors.white
                              : AppColors.primeDark)),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(author,
                              style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: cs.onSurface)),
                          if (!isPlatform) ...[
                            const SizedBox(width: 5),
                            const Icon(Icons.workspace_premium_rounded,
                                size: 12, color: AppColors.prime),
                          ],
                        ],
                      ),
                      Text(timeStr,
                          style: TextStyle(
                              fontSize: 11, color: cs.onSurfaceVariant)),
                    ],
                  ),
                ),
                Icon(Icons.more_horiz_rounded,
                    color: cs.onSurfaceVariant, size: 20),
              ],
            ),
            const SizedBox(height: 10),
            Text(content,
                style: TextStyle(
                    fontSize: 14, color: cs.onSurface, height: 1.5)),
            const SizedBox(height: 12),
            Row(
              children: [
                GestureDetector(
                  onTap: onLike,
                  child: Row(
                    children: [
                      Icon(Icons.favorite_border_rounded,
                          size: 18, color: cs.onSurfaceVariant),
                      const SizedBox(width: 4),
                      Text('$likes',
                          style: TextStyle(
                              fontSize: 12, color: cs.onSurfaceVariant)),
                    ],
                  ),
                ),
                const SizedBox(width: 20),
                Row(
                  children: [
                    Icon(Icons.chat_bubble_outline_rounded,
                        size: 16, color: cs.onSurfaceVariant),
                    const SizedBox(width: 4),
                    Text('$comments',
                        style: TextStyle(
                            fontSize: 12, color: cs.onSurfaceVariant)),
                  ],
                ),
                const Spacer(),
                Icon(Icons.share_rounded,
                    size: 16, color: cs.onSurfaceVariant),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
