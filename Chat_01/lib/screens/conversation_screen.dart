import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../core/app_controller.dart';

import 'dart:async';

import '../features/media/media_preview.dart';
import '../features/media/voice_note_recorder.dart';
import '../features/calls/call_screen.dart';
import '../features/profile/profile_avatar.dart';
import '../features/chat_lock/password_dialog.dart';

class ConversationScreen extends StatefulWidget {
  const ConversationScreen({required this.controller, this.onBack, super.key});
  final AppController controller;
  final VoidCallback? onBack;
  @override
  State<ConversationScreen> createState() => _ConversationScreenState();
}

class _ConversationScreenState extends State<ConversationScreen> {
  final _composer = TextEditingController();
  final _scroll = ScrollController();
  bool _uploading = false;
  final _voice = VoiceNoteRecorder();
  bool _recording = false;
  Timer? _recordTimer;
  int _recordSeconds = 0;
  int? _recordChatId;
  int? _replyId;
  String? _replyText;
  @override
  void dispose() {
    _recordTimer?.cancel();
    unawaited(_voice.dispose());
    _composer.dispose();
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;
    final chat = controller.activeChat;
    if (chat == null) return const SizedBox.shrink();
    return Column(
      children: [
        Material(
          color: const Color(0xff29213D),
          child: SafeArea(
            bottom: false,
            child: SizedBox(
              height: 64,
              child: Row(
                children: [
                  if (widget.onBack != null)
                    IconButton(
                      tooltip: 'Back to chats',
                      onPressed: widget.onBack,
                      icon: const Icon(Icons.arrow_back),
                    ),
                  const SizedBox(width: 8),
                  ProfileAvatar(
                    api: controller.api,
                    id: _peerAvatar(controller, chat),
                    name: chat['title'] as String? ?? 'Chat',
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          chat['title'] as String? ?? 'Conversation',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        Text(
                          chat['kind'] == 'group'
                              ? '${(chat['members'] as List<dynamic>? ?? []).length} members'
                              : 'Direct conversation',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.white60,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (chat['kind'] == 'direct')
                    IconButton(
                      tooltip: 'Start voice call',
                      icon: const Icon(Icons.call_outlined),
                      onPressed: () => _startCall(false),
                    ),
                  if (chat['kind'] == 'direct')
                    IconButton(
                      tooltip: 'Start video call',
                      icon: const Icon(Icons.videocam_outlined),
                      onPressed: () => _startCall(true),
                    ),
                  PopupMenuButton<String>(
                    tooltip: 'Chat actions',
                    onSelected: (value) => _chatAction(controller, chat, value),
                    itemBuilder: (context) => const [
                      PopupMenuItem(
                        value: 'info',
                        child: Text('Chat information'),
                      ),
                      PopupMenuItem(
                        value: 'favourite',
                        child: Text('Toggle favourite'),
                      ),
                      PopupMenuItem(
                        value: 'archive',
                        child: Text('Archive / unarchive'),
                      ),
                      PopupMenuItem(
                        value: 'mute',
                        child: Text('Mute / unmute'),
                      ),
                      PopupMenuItem(
                        value: 'media',
                        child: Text('Toggle media visibility'),
                      ),
                      PopupMenuItem(
                        value: 'settings',
                        child: Text('Privacy settings'),
                      ),
                      PopupMenuItem(
                        value: 'lock',
                        child: Text('Lock this chat'),
                      ),
                      PopupMenuItem(
                        value: 'remove_lock',
                        child: Text('Remove chat lock'),
                      ),
                      PopupMenuItem(
                        value: 'relock',
                        child: Text('Close and relock'),
                      ),
                      PopupMenuItem(
                        value: 'clear',
                        child: Text('Clear chat for me'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
        if (controller.error != null)
          MaterialBanner(
            content: Text(controller.error!),
            actions: [
              TextButton(
                onPressed: () => controller.openChat(chat['id'] as int),
                child: const Text('Retry'),
              ),
            ],
          ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: () => controller.openChat(chat['id'] as int),
            child: ListView.builder(
              controller: _scroll,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 18),
              itemCount: controller.messages.length,
              itemBuilder: (context, index) =>
                  _messageBubble(controller, controller.messages[index]),
            ),
          ),
        ),
        SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_recording)
                ListTile(
                  title: Text('Recording $_recordSeconds s / 120 s'),
                  leading: const Icon(Icons.mic, color: Colors.redAccent),
                  trailing: IconButton(
                    tooltip: 'Discard recording',
                    icon: const Icon(Icons.delete_outline),
                    onPressed: _cancelVoice,
                  ),
                ),
              if (_replyId != null)
                ListTile(
                  dense: true,
                  title: const Text('Replying to message'),
                  subtitle: Text(
                    _replyText ?? '',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: IconButton(
                    tooltip: 'Cancel reply',
                    icon: const Icon(Icons.close),
                    onPressed: () => setState(() {
                      _replyId = null;
                      _replyText = null;
                    }),
                  ),
                ),
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 8, 8, 10),
                child: Row(
                  children: [
                    IconButton(
                      tooltip: 'Attach a file',
                      onPressed: _uploading || _recording
                          ? null
                          : () => _pickFile(controller),
                      icon: _uploading
                          ? const SizedBox.square(
                              dimension: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.attach_file),
                    ),
                    Expanded(
                      child: TextField(
                        controller: _composer,
                        minLines: 1,
                        maxLines: 5,
                        maxLength: 10000,
                        buildCounter: (
                          _, {
                          required currentLength,
                          required isFocused,
                          maxLength,
                        }) => null,
                        decoration: const InputDecoration(
                          hintText: 'Type a message',
                          isDense: true,
                        ),
                        onSubmitted: (_) => _send(controller),
                      ),
                    ),
                    IconButton(
                      tooltip: _recording
                          ? 'Stop and send voice note'
                          : 'Record voice note',
                      onPressed: _uploading
                          ? null
                          : () => _toggleVoice(controller),
                      icon: Icon(_recording ? Icons.stop_circle : Icons.mic),
                      color: _recording ? Colors.redAccent : null,
                    ),
                    const SizedBox(width: 8),
                    IconButton.filled(
                      tooltip: 'Send message',
                      onPressed: () => _send(controller),
                      icon: const Icon(Icons.send),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _messageBubble(
    AppController controller,
    Map<String, dynamic> message,
  ) {
    final own = message['sender'] == controller.user?['id'];
    final text = message['body'] as String? ?? '';
    final fileName = message['file_name'] as String?;
    final reply = message['reply'] as String?;
    return Align(
      alignment: own ? Alignment.centerRight : Alignment.centerLeft,
      child: GestureDetector(
        onLongPress: () => _messageMenu(controller, message, own),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 620),
          margin: const EdgeInsets.symmetric(vertical: 4),
          padding: const EdgeInsets.fromLTRB(12, 8, 8, 6),
          decoration: BoxDecoration(
            color: own ? const Color(0xff4C3574) : const Color(0xff29213D),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!own)
                Text(
                  message['sender_name'] as String? ?? 'Member',
                  style: const TextStyle(
                    color: Color(0xffC4B5FD),
                    fontSize: 12,
                  ),
                ),
              if (reply != null)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(7),
                  margin: const EdgeInsets.only(bottom: 5),
                  decoration: const BoxDecoration(
                    border: Border(
                      left: BorderSide(color: Color(0xffC4B5FD), width: 3),
                    ),
                    color: Color(0x33000000),
                  ),
                  child: Text(
                    reply,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              if (text.isNotEmpty) SelectableText(text),
              if (message['file_id'] != null &&
                  (message['deleted'] as int? ?? 0) == 0)
                MediaPreview(
                  key: ValueKey(message['file_id']),
                  api: controller.api,
                  path: 'files/${message['file_id']}',
                  kind: message['kind'] as String? ?? 'document',
                  mime:
                      message['mime'] as String? ?? 'application/octet-stream',
                  name: fileName ?? 'Attachment',
                ),
              if (fileName != null && message['kind'] == 'document')
                Row(
                  children: [
                    const Icon(Icons.insert_drive_file_outlined, size: 18),
                    const SizedBox(width: 6),
                    Flexible(child: Text(fileName)),
                  ],
                ),
              if (message['starred'] == true)
                const Icon(Icons.star, size: 14, color: Colors.amber),
              if ((message['reactions'] as List? ?? []).isNotEmpty)
                Wrap(
                  spacing: 4,
                  children: (message['reactions'] as List)
                      .map<Widget>(
                        (reaction) => Text(reaction['emoji'] as String? ?? ''),
                      )
                      .toList(),
                ),
              const SizedBox(height: 3),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if ((message['edited'] as int? ?? 0) == 1)
                    const Text(
                      'edited · ',
                      style: TextStyle(fontSize: 10, color: Colors.white60),
                    ),
                  Text(
                    _time(message['created']),
                    style: const TextStyle(fontSize: 10, color: Colors.white60),
                  ),
                  if (own) ...[
                    const SizedBox(width: 4),
                    Icon(
                      (message['read_by'] as List<dynamic>? ?? []).isEmpty
                          ? Icons.done
                          : Icons.done_all,
                      size: 14,
                      color:
                          (message['read_by'] as List<dynamic>? ?? []).isEmpty
                          ? Colors.white54
                          : const Color(0xffC4B5FD),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _send(AppController controller) async {
    final text = _composer.text;
    if (text.trim().isEmpty) return;
    _composer.clear();
    try {
      await controller.sendMessage(text, replyId: _replyId);
      _replyId = null;
      _replyText = null;
      if (_scroll.hasClients) {
        await _scroll.animateTo(
          _scroll.position.maxScrollExtent + 120,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    } catch (exception) {
      if (mounted)
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('$exception')));
    }
  }

  Future<void> _pickFile(AppController controller) async {
    final type = await showModalBottomSheet<FileType>(
      context: context,
      builder: (_) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.image),
              title: const Text('Photos'),
              onTap: () => Navigator.pop(context, FileType.image),
            ),
            ListTile(
              leading: const Icon(Icons.video_library),
              title: const Text('Videos'),
              onTap: () => Navigator.pop(context, FileType.video),
            ),
            ListTile(
              leading: const Icon(Icons.attach_file),
              title: const Text('Document / audio'),
              onTap: () => Navigator.pop(context, FileType.any),
            ),
          ],
        ),
      ),
    );
    if (type == null || !mounted) return;
    final result = await FilePicker.platform.pickFiles(
      type: type,
      withData: true,
    );
    if (result == null || result.files.single.bytes == null) return;
    if (!mounted) return;
    if (result.files.single.size > 20 * 1024 * 1024) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Choose a file smaller than 20 MB')),
      );
      return;
    }
    setState(() => _uploading = true);
    try {
      final file = result.files.single;
      await controller.sendAttachment(file.name, file.bytes!);
    } catch (exception) {
      if (mounted)
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('$exception')));
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  Future<void> _chatAction(
    AppController controller,
    Map<String, dynamic> chat,
    String action,
  ) async {
    final id = chat['id'] as int;
    try {
      switch (action) {
        case 'favourite':
        case 'archive':
        case 'mute':
        case 'media':
          final key = {
            'favourite': 'favourite',
            'archive': 'archived',
            'mute': 'muted',
            'media': 'media_visible',
          }[action]!;
          final preferences =
              chat['preferences'] as Map<String, dynamic>? ?? chat;
          final active =
              (preferences[key] as int? ?? (key == 'media_visible' ? 1 : 0)) ==
              1;
          await controller.updatePreference(id, key, !active);
          break;
        case 'clear':
          final confirm = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Clear this chat?'),
              content: const Text(
                'Messages will be hidden for your account only.',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('Clear'),
                ),
              ],
            ),
          );
          if (confirm == true) {
            await controller.api.post('chats/$id/clear');
            await controller.openChat(id);
          }
          break;
        case 'lock':
          await _lockChat(controller, id);
          break;
        case 'remove_lock':
          await _lockChat(controller, id, remove: true);
          break;
        case 'relock':
          await controller.api.post('chats/$id/relock');
          controller.closeChat();
          await controller.refreshChats();
          break;
        case 'settings':
          await _settingsDialog(controller, chat);
          break;
        case 'info':
          await _infoDialog(chat);
          break;
      }
    } catch (exception) {
      if (mounted)
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('$exception')));
    }
  }

  Future<void> _settingsDialog(
    AppController controller,
    Map<String, dynamic> chat,
  ) async {
    final id = chat['id'] as int;
    var disappear = chat['disappear'] as int? ?? 0;
    var advanced = (chat['advanced_privacy'] as int?) == 1;
    var adminOnly = (chat['admin_only'] as int?) == 1;
    final members = chat['members'] as List<dynamic>? ?? const [];
    final canAdmin =
        chat['kind'] == 'group' &&
        members.any(
          (member) =>
              member['id'] == controller.user?['id'] &&
              member['role'] == 'admin',
        );
    final canEditSettings = chat['kind'] != 'group' || canAdmin;
    var saving = false;
    String? settingsError;
    await showDialog<void>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, update) => AlertDialog(
          title: const Text('Chat privacy settings'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<int>(
                value: disappear,
                decoration: const InputDecoration(
                  labelText: 'Disappearing messages',
                ),
                items: const [
                  DropdownMenuItem(value: 0, child: Text('Off')),
                  DropdownMenuItem(value: 86400, child: Text('24 hours')),
                  DropdownMenuItem(value: 604800, child: Text('7 days')),
                  DropdownMenuItem(value: 7776000, child: Text('90 days')),
                ],
                onChanged: canEditSettings
                    ? (value) => update(() => disappear = value ?? 0)
                    : null,
              ),
              if (canAdmin)
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  value: adminOnly,
                  title: const Text('Only admins can send messages'),
                  onChanged: (value) => update(() => adminOnly = value),
                ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                value: advanced,
                title: const Text('Advanced privacy'),
                onChanged: canEditSettings
                    ? (value) => update(() => advanced = value)
                    : null,
              ),
              const Text(
                'These controls are enforced by the server but cannot prevent screenshots or copying. Expiry is not end-to-end encryption.',
                style: TextStyle(color: Colors.white60, fontSize: 12),
              ),
              if (settingsError != null)
                Text(
                  settingsError!,
                  style: const TextStyle(color: Colors.redAccent),
                ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: saving ? null : () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: saving || !canEditSettings
                  ? null
                  : () async {
                      update(() {
                        saving = true;
                        settingsError = null;
                      });
                      try {
                        await controller.updateChatSettings(id, {
                          'disappear': disappear,
                          'advanced_privacy': advanced,
                          if (canAdmin) 'admin_only': adminOnly,
                        });
                        update(() => saving = false);
                        if (context.mounted) Navigator.pop(context);
                      } catch (exception) {
                        update(() {
                          settingsError = exception.toString();
                          saving = false;
                        });
                      }
                    },
              child: saving
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _lockChat(
    AppController controller,
    int id, {
    bool remove = false,
  }) async {
    final saved = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => ChatPasswordDialog(
        title: remove ? 'Remove chat lock' : 'Lock this chat',
        actionLabel: remove ? 'Remove lock' : 'Lock',
        submit: (password) async {
          await controller.api.post('chats/$id/lock', {
            'password': password,
            'locked': !remove,
          });
        },
      ),
    );
    if (saved == true) {
      controller.closeChat();
      await controller.refreshChats();
    }
  }

  Future<void> _infoDialog(Map<String, dynamic> chat) async {
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(chat['title'] as String? ?? 'Chat'),
        content: Text(
          chat['description'] as String? ??
              'Chat details and members are server-managed.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Future<void> _messageMenu(
    AppController controller,
    Map<String, dynamic> message,
    bool own,
  ) async {
    final action = await showModalBottomSheet<String>(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.reply),
              title: const Text('Reply'),
              onTap: () => Navigator.pop(context, 'reply'),
            ),
            ListTile(
              leading: const Icon(Icons.add_reaction_outlined),
              title: const Text('React 👍'),
              onTap: () => Navigator.pop(context, 'reaction'),
            ),
            ListTile(
              leading: const Icon(Icons.star_outline),
              title: const Text('Toggle star'),
              onTap: () => Navigator.pop(context, 'star'),
            ),
            if (own && (message['deleted'] as int? ?? 0) == 0)
              ListTile(
                leading: const Icon(Icons.edit_outlined),
                title: const Text('Edit'),
                onTap: () => Navigator.pop(context, 'edit'),
              ),
            if (own && (message['deleted'] as int? ?? 0) == 0)
              ListTile(
                leading: const Icon(Icons.delete_forever),
                title: const Text('Delete for everyone'),
                onTap: () => Navigator.pop(context, 'delete_everyone'),
              ),
            ListTile(
              leading: const Icon(Icons.delete_outline),
              title: const Text('Delete for me'),
              onTap: () => Navigator.pop(context, 'delete'),
            ),
          ],
        ),
      ),
    );
    if (action == null) return;
    final id = message['id'] as int;
    try {
      switch (action) {
        case 'reply':
          setState(() {
            _replyId = message['id'] as int;
            _replyText =
                message['body'] as String? ?? (message['file_name'] as String?);
          });
          break;
        case 'reaction':
          await controller.api.post('messages/$id/reaction', {'emoji': '👍'});
          await controller.openChat(controller.activeChat!['id'] as int);
          break;
        case 'star':
          await controller.api.post('messages/$id/star');
          await controller.openChat(controller.activeChat!['id'] as int);
          break;
        case 'edit':
          await _editMessage(controller, message);
          break;
        case 'delete_everyone':
          final confirmed = await showDialog<bool>(
            context: context,
            builder: (_) => AlertDialog(
              title: const Text('Delete for everyone?'),
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
          if (confirmed == true) {
            await controller.api.delete('messages/$id?scope=everyone');
            if (controller.activeChat != null)
              await controller.openChat(controller.activeChat!['id'] as int);
          }
          break;
        case 'delete':
          await controller.api.delete('messages/$id');
          await controller.openChat(controller.activeChat!['id'] as int);
          break;
      }
    } catch (exception) {
      if (mounted)
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('$exception')));
    }
  }

  Future<void> _editMessage(
    AppController controller,
    Map<String, dynamic> message,
  ) async {
    final text = TextEditingController(text: message['body'] as String? ?? '');
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit message'),
        content: TextField(controller: text, maxLength: 10000, autofocus: true),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              await controller.api.patch('messages/${message['id']}', {
                'body': text.text,
              });
              if (context.mounted) Navigator.pop(context);
              await controller.openChat(controller.activeChat!['id'] as int);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
    text.dispose();
  }

  Future<void> _startCall(bool video) async {
    try {
      await openOutgoingCall(context, widget.controller, video);
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('$e')));
    }
  }

  String _peerAvatar(AppController app, Map<String, dynamic> chat) {
    for (final member in chat['members'] as List? ?? []) {
      if (member['id'] != app.user?['id'])
        return member['avatar'] as String? ?? '';
    }
    return '';
  }

  Future<void> _cancelVoice() async {
    _recordTimer?.cancel();
    await _voice.cancel();
    if (mounted) setState(() => _recording = false);
  }

  Future<void> _toggleVoice(AppController app) async {
    if (_uploading) return;
    try {
      if (!_recording) {
        setState(() => _uploading = true);
        await _voice.start();
        if (!mounted) {
          await _voice.cancel();
          return;
        }
        _recordChatId = app.activeChat?['id'] as int?;
        setState(() {
          _recording = true;
          _recordSeconds = 0;
          _uploading = false;
        });
        _recordTimer = Timer.periodic(const Duration(seconds: 1), (_) {
          if (!mounted) return;
          setState(() => _recordSeconds++);
          if (_recordSeconds >= 120) {
            _recordTimer?.cancel();
            unawaited(_toggleVoice(app));
          }
        });
      } else {
        _recordTimer?.cancel();
        setState(() {
          _recording = false;
          _uploading = true;
        });
        final bytes = await _voice.stop();
        if (app.activeChat?['id'] != _recordChatId)
          throw StateError('Chat changed. Recording discarded.');
        await app.sendAttachment(
          'voice-${DateTime.now().millisecondsSinceEpoch}.wav',
          bytes,
        );
      }
    } catch (e) {
      _recordTimer?.cancel();
      await _voice.cancel();
      if (mounted) {
        setState(() => _recording = false);
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('$e')));
      }
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  String _time(dynamic value) {
    if (value is! num) return '';
    final date = DateTime.fromMillisecondsSinceEpoch((value * 1000).round());
    final local = date.toLocal();
    return '${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
  }
}
