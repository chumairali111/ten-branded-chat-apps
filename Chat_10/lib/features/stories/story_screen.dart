import 'package:flutter/material.dart';

import '../../core/app_controller.dart';
import '../media/media_preview.dart';
import '../profile/profile_avatar.dart';

class StoryScreen extends StatefulWidget {
  const StoryScreen({required this.app, required this.story, super.key});
  final AppController app;
  final Map<String, dynamic> story;
  @override
  State<StoryScreen> createState() => _StoryScreenState();
}

class _StoryScreenState extends State<StoryScreen> {
  String? _error;
  @override
  void initState() {
    super.initState();
    _markViewed();
  }

  Future<void> _markViewed() async {
    try {
      await widget.app.api.post('statuses/${widget.story['id']}/view');
    } catch (e) {
      if (mounted) setState(() => _error = '$e');
    }
  }

  Future<void> _viewers() async {
    try {
      final result = await widget.app.api.get(
        'statuses/${widget.story['id']}/viewers',
      );
      if (!mounted) return;
      final viewers = result['viewers'] as List;
      await showModalBottomSheet<void>(
        context: context,
        builder: (_) => SafeArea(
          child: SizedBox(
            height: 380,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    '${viewers.length} viewers',
                    style: const TextStyle(fontSize: 20),
                  ),
                ),
                Expanded(
                  child: viewers.isEmpty
                      ? const Center(child: Text('No views yet'))
                      : ListView(
                          children: viewers.map((entry) {
                            final person = Map<String, dynamic>.from(
                              entry as Map,
                            );
                            final viewed = (person['viewed_at'] as num?) ?? 0;
                            return ListTile(
                              leading: ProfileAvatar(
                                api: widget.app.api,
                                id: person['avatar'] as String? ?? '',
                                name: person['name'] as String? ?? '',
                              ),
                              title: Text(person['name'] as String? ?? ''),
                              subtitle: Text(
                                viewed > 0
                                    ? DateTime.fromMillisecondsSinceEpoch(
                                        (viewed * 1000).round(),
                                      ).toLocal().toString().split('.').first
                                    : 'Viewed',
                              ),
                            );
                          }).toList(),
                        ),
                ),
              ],
            ),
          ),
        ),
      );
    } catch (e) {
      if (mounted) setState(() => _error = '$e');
    }
  }

  Future<void> _delete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete this story?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await widget.app.api.delete('statuses/${widget.story['id']}');
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) setState(() => _error = '$e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final story = widget.story;
    final own = story['user_id'] == widget.app.user?['id'];
    return Scaffold(
      appBar: AppBar(
        title: Text(story['name'] as String? ?? 'Story'),
        actions: [
          if (own)
            IconButton(
              tooltip: 'Delete story',
              onPressed: _delete,
              icon: const Icon(Icons.delete_outline),
            ),
        ],
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (story['media_id'] != null)
                MediaPreview(
                  api: widget.app.api,
                  path: 'media/${story['media_id']}',
                  kind: story['kind'] as String? ?? 'image',
                  mime: story['mime'] as String? ?? 'video/mp4',
                ),
              const SizedBox(height: 20),
              Text(
                story['body'] as String? ?? '',
                style: const TextStyle(fontSize: 24),
                textAlign: TextAlign.center,
              ),
              if (_error != null)
                Text(_error!, style: const TextStyle(color: Colors.redAccent)),
              if (own)
                TextButton.icon(
                  onPressed: _viewers,
                  icon: const Icon(Icons.visibility),
                  label: const Text('Viewers'),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
