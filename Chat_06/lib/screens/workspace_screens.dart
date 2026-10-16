import 'package:flutter/material.dart';

import '../core/app_controller.dart';
import '../core/server_host.dart';
import 'pairing_screen.dart';

import 'package:file_picker/file_picker.dart';

import '../features/stories/story_screen.dart';
import '../features/profile/profile_screen.dart';
import '../features/profile/profile_avatar.dart';

class WorkspaceScreen extends StatefulWidget {
  const WorkspaceScreen({
    required this.controller,
    required this.section,
    super.key,
  });

  final AppController controller;
  final String section;

  @override
  State<WorkspaceScreen> createState() => _WorkspaceScreenState();
}

class _WorkspaceScreenState extends State<WorkspaceScreen> {
  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _items = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant WorkspaceScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.section != widget.section) _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final endpoint = switch (widget.section) {
        'calls' => 'calls',
        'statuses' => 'statuses',
        'communities' => 'communities',
        _ => '',
      };
      if (endpoint.isNotEmpty) {
        final result = await widget.controller.api.get(endpoint);
        final key = switch (widget.section) {
          'calls' => 'calls',
          'statuses' => 'statuses',
          _ => 'communities',
        };
        _items = (result[key] as List<dynamic>)
            .map((item) => Map<String, dynamic>.from(item as Map))
            .toList();
      }
    } catch (exception) {
      _error = exception.toString();
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = switch (widget.section) {
      'calls' => 'Calls',
      'statuses' => 'Status updates',
      'communities' => 'Communities',
      _ => 'Settings',
    };
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: _load,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      floatingActionButton: switch (widget.section) {
        'statuses' => FloatingActionButton.extended(
          onPressed: _addStatus,
          icon: const Icon(Icons.add),
          label: const Text('Add status'),
        ),
        'communities' => FloatingActionButton.extended(
          onPressed: _addCommunity,
          icon: const Icon(Icons.add),
          label: const Text('Create community'),
        ),
        _ => null,
      },
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(_error!),
                  const SizedBox(height: 10),
                  FilledButton(onPressed: _load, child: const Text('Retry')),
                ],
              ),
            )
          : switch (widget.section) {
              'settings' => _settings(),
              'calls' => _calls(),
              'statuses' => _statuses(),
              'communities' => _communities(),
              _ => const SizedBox.shrink(),
            },
    );
  }

  Widget _settings() => ListView(
    padding: const EdgeInsets.all(16),
    children: [
      Card(
        child: ListTile(
          leading: ProfileAvatar(
            api: widget.controller.api,
            id: widget.controller.user?['avatar'] as String? ?? '',
            name: widget.controller.user?['name'] as String? ?? '',
          ),
          trailing: const Icon(Icons.edit),
          onTap: () =>
              Navigator.push<void>(
                context,
                MaterialPageRoute(
                  builder: (_) => ProfileScreen(app: widget.controller),
                ),
              ).then((_) {
                if (mounted) setState(() {});
              }),
          title: Text(widget.controller.user?['name'] as String? ?? ''),
          subtitle: Text('@${widget.controller.user?['username']}'),
        ),
      ),
      const Padding(
        padding: EdgeInsets.symmetric(vertical: 12),
        child: Text(
          'Linked devices',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
      ),
      FutureBuilder<Map<String, dynamic>>(
        future: widget.controller.api.get('sessions'),
        builder: (context, snapshot) {
          if (snapshot.hasError)
            return ListTile(title: Text('${snapshot.error}'));
          if (!snapshot.hasData) return const LinearProgressIndicator();
          final devices = snapshot.data!['devices'] as List<dynamic>;
          return Column(
            children: devices.map((entry) {
              final device = Map<String, dynamic>.from(entry as Map);
              final current = device['current'] == true;
              return Card(
                child: ListTile(
                  leading: Icon(
                    device['platform'] == 'web'
                        ? Icons.language
                        : Icons.phone_android,
                  ),
                  title: Text(device['device_name'] as String? ?? 'Device'),
                  subtitle: Text(
                    '${device['platform']} · ${current ? 'This device' : 'Linked device'}',
                  ),
                  trailing: current
                      ? const Icon(Icons.check_circle, color: Color(0xff67E8F9))
                      : IconButton(
                          tooltip: 'Revoke this session',
                          icon: const Icon(Icons.link_off),
                          onPressed: () async {
                            await widget.controller.api.delete(
                              'sessions/${device['id']}',
                            );
                            if (mounted) setState(() {});
                          },
                        ),
                ),
              );
            }).toList(),
          );
        },
      ),
      OutlinedButton.icon(
        onPressed: () =>
            Navigator.push<void>(
              context,
              MaterialPageRoute(
                builder: (_) => PairingScreen(
                  controller: widget.controller,
                  mode: PairingMode.scan,
                ),
              ),
            ).then((_) {
              if (mounted) setState(() {});
            }),
        icon: const Icon(Icons.qr_code_scanner),
        label: const Text('Link a device by QR'),
      ),
      OutlinedButton.icon(
        onPressed: () async {
          await widget.controller.api.delete('sessions');
          if (mounted) setState(() {});
        },
        icon: const Icon(Icons.phonelink_erase),
        label: const Text('Sign out other devices'),
      ),
      ListTile(leading: const Icon(Icons.dns_outlined), title: const Text('Server settings'),
        subtitle: Text(widget.controller.api.baseUrl.origin), onTap: () => configureServer(context)),
      const Divider(height: 32),
      const ListTile(
        leading: Icon(Icons.lock_outline),
        title: Text('Security notes'),
        subtitle: Text(
          'This app does not provide end-to-end encryption or phone-number OTP. '
          'Messages are stored by the server. QR linking is only for accounts in this independent project.',
        ),
      ),
      FilledButton.tonal(
        onPressed: () async {
          await widget.controller.logout();
        },
        child: const Text('Sign out'),
      ),
    ],
  );

  Widget _calls() {
    if (_items.isEmpty) return const Center(child: Text('No recent calls.'));
    return ListView.builder(
      itemCount: _items.length,
      itemBuilder: (context, index) {
        final call = _items[index];
        return ListTile(
          leading: Icon(
            call['video'] == 1 ? Icons.videocam_outlined : Icons.call_outlined,
          ),
          title: Text(
            (call['caller'] == widget.controller.user?['id']
                        ? call['callee_name']
                        : call['caller_name'])
                    as String? ??
                'Call',
          ),
          subtitle: Text(
            '${call['state']} · ${call['video'] == 1 ? 'Video' : 'Voice'}',
          ),
        );
      },
    );
  }

  Widget _statuses() {
    if (_items.isEmpty) return const Center(child: Text('No active statuses.'));
    return ListView.builder(
      itemCount: _items.length,
      itemBuilder: (context, index) {
        final status = _items[index];
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
          child: ListTile(
            leading: ProfileAvatar(
              api: widget.controller.api,
              id: status['avatar'] as String? ?? '',
              name: status['name'] as String? ?? '',
            ),
            title: Text(status['name'] as String? ?? 'Status'),
            subtitle: Text(status['body'] as String? ?? ''),
            trailing: status['user_id'] == widget.controller.user?['id']
                ? Text('${status['views'] ?? 0} views')
                : Icon(
                    status['kind'] == 'video'
                        ? Icons.videocam
                        : status['kind'] == 'image'
                        ? Icons.image
                        : Icons.text_fields,
                  ),
            onTap: () => _viewStatus(status),
          ),
        );
      },
    );
  }

  Future<void> _viewStatus(Map<String, dynamic> story) async {
    await Navigator.push<void>(
      context,
      MaterialPageRoute(
        builder: (_) => StoryScreen(app: widget.controller, story: story),
      ),
    );
    if (mounted) await _load();
  }

  Widget _communities() {
    if (_items.isEmpty)
      return const Center(
        child: Text('Create a community for groups you administer.'),
      );
    return ListView.builder(
      itemCount: _items.length,
      itemBuilder: (context, index) {
        final community = _items[index];
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
          child: ListTile(
            leading: const CircleAvatar(child: Icon(Icons.groups_outlined)),
            title: Text(community['name'] as String? ?? 'Community'),
            subtitle: Text(community['description'] as String? ?? ''),
          ),
        );
      },
    );
  }

  Future<void> _addStatus() async {
    final mode = await showModalBottomSheet<String>(
      context: context,
      builder: (_) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.text_fields),
              title: const Text('Text story'),
              onTap: () => Navigator.pop(context, 'text'),
            ),
            ListTile(
              leading: const Icon(Icons.image),
              title: const Text('Image story'),
              onTap: () => Navigator.pop(context, 'image'),
            ),
            ListTile(
              leading: const Icon(Icons.video_library),
              title: const Text('Video story'),
              onTap: () => Navigator.pop(context, 'video'),
            ),
          ],
        ),
      ),
    );
    if (mode == null || !mounted) return;
    PlatformFile? file;
    if (mode != 'text') {
      final result = await FilePicker.platform.pickFiles(
        type: mode == 'image' ? FileType.image : FileType.video,
        withData: true,
      );
      if (result == null || !mounted) return;
      file = result.files.single;
      if (file.bytes == null || file.size > 20 * 1024 * 1024) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Choose a file smaller than 20 MB')),
        );
        return;
      }
    }
    final text = TextEditingController();
    final submit = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(
          mode == 'text' ? 'Share a text story' : 'Caption (optional)',
        ),
        content: TextField(controller: text, maxLength: 700, autofocus: true),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Share'),
          ),
        ],
      ),
    );
    final caption = text.text.trim();
    text.dispose();
    if (submit != true || !mounted) return;
    setState(() => _loading = true);
    try {
      String? mediaId;
      if (file != null) {
        final uploaded = await widget.controller.api.upload(
          'media/status',
          file.name,
          file.bytes!,
        );
        mediaId = uploaded['id'] as String;
      }
      await widget.controller.api.post('statuses', {
        'body': caption,
        if (mediaId != null) 'media_id': mediaId,
      });
      if (mounted) await _load();
    } catch (e) {
      if (mounted)
        setState(() {
          _error = '$e';
          _loading = false;
        });
    }
  }

  Future<void> _addCommunity() async {
    final name = TextEditingController();
    final submit = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create a community'),
        content: TextField(
          controller: name,
          maxLength: 80,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Name'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Create'),
          ),
        ],
      ),
    );
    if (submit == true && name.text.trim().isNotEmpty) {
      try {
        await widget.controller.api.post('communities', {
          'name': name.text.trim(),
        });
        await _load();
      } catch (exception) {
        if (mounted)
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text('$exception')));
      }
    }
    name.dispose();
  }
}
