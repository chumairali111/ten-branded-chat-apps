import 'package:flutter/material.dart';

import '../core/app_controller.dart';
import 'conversation_screen.dart';
import 'workspace_screens.dart';
import '../features/profile/profile_avatar.dart';
import '../features/chat_lock/password_dialog.dart';

class AppShell extends StatefulWidget {
  const AppShell({required this.controller, super.key});
  final AppController controller;

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  final _search = TextEditingController();
  final _sections = const [
    'chats',
    'calls',
    'statuses',
    'communities',
    'settings',
  ];

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  // This method belongs to State, where context and mounted are available.
  Future<void> _openChat(
    AppController controller,
    Map<String, dynamic> chat,
  ) async {
    final id = chat['id'] as int;
    try {
      if (chat['locked'] == 1) {
        final unlocked = await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (_) => ChatPasswordDialog(
            title: 'Unlock chat',
            actionLabel: 'Unlock',
            submit: (password) async {
              await controller.api.post('chats/$id/unlock', {
                'password': password,
              });
            },
          ),
        );
        if (!mounted || unlocked != true) return;
      }
      if (!mounted) return;
      await controller.openChat(id);
      if (controller.error != null && mounted)
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(controller.error!)));
    } catch (exception) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('$exception')));
      }
    }
  }

  void _selectSection(AppController controller, int index) {
    setState(() {
      controller.activeSection = _sections[index];
      if (controller.activeSection != 'chats') controller.activeChat = null;
    });
    controller.notifyListeners();
  }

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 900;
        return Scaffold(
          body: wide
              ? _wideLayout(controller, constraints.maxWidth)
              : _narrowLayout(controller),
          bottomNavigationBar: wide
              ? null
              : NavigationBar(
                  selectedIndex: _sections.indexOf(controller.activeSection),
                  onDestinationSelected: (index) =>
                      _selectSection(controller, index),
                  destinations: const [
                    NavigationDestination(
                      icon: Icon(Icons.chat_bubble_outline),
                      label: 'Chats',
                    ),
                    NavigationDestination(
                      icon: Icon(Icons.call_outlined),
                      label: 'Calls',
                    ),
                    NavigationDestination(
                      icon: Icon(Icons.circle_outlined),
                      label: 'Status',
                    ),
                    NavigationDestination(
                      icon: Icon(Icons.groups_outlined),
                      label: 'Groups',
                    ),
                    NavigationDestination(
                      icon: Icon(Icons.settings_outlined),
                      label: 'Settings',
                    ),
                  ],
                ),
        );
      },
    );
  }

  Widget _wideLayout(AppController controller, double width) {
    return Row(
      children: [
        NavigationRail(
          selectedIndex: _sections.indexOf(controller.activeSection),
          labelType: NavigationRailLabelType.all,
          onDestinationSelected: (index) => _selectSection(controller, index),
          destinations: const [
            NavigationRailDestination(
              icon: Icon(Icons.chat_bubble_outline),
              label: Text('Chats'),
            ),
            NavigationRailDestination(
              icon: Icon(Icons.call_outlined),
              label: Text('Calls'),
            ),
            NavigationRailDestination(
              icon: Icon(Icons.circle_outlined),
              label: Text('Status'),
            ),
            NavigationRailDestination(
              icon: Icon(Icons.groups_outlined),
              label: Text('Groups'),
            ),
            NavigationRailDestination(
              icon: Icon(Icons.settings_outlined),
              label: Text('Settings'),
            ),
          ],
        ),
        const VerticalDivider(width: 1),
        if (controller.activeSection == 'chats') ...[
          SizedBox(
            width: width < 1160 ? 310 : 360,
            child: _chatList(controller),
          ),
          const VerticalDivider(width: 1),
          Expanded(
            child: controller.activeChat == null
                ? const _WelcomePane()
                : ConversationScreen(controller: controller),
          ),
        ] else
          Expanded(
            child: WorkspaceScreen(
              controller: controller,
              section: controller.activeSection,
            ),
          ),
      ],
    );
  }

  Widget _narrowLayout(AppController controller) {
    if (controller.activeSection != 'chats') {
      return WorkspaceScreen(
        controller: controller,
        section: controller.activeSection,
      );
    }
    if (controller.activeChat != null) {
      return ConversationScreen(
        controller: controller,
        onBack: () {
          controller.activeChat = null;
          controller.notifyListeners();
        },
      );
    }
    return _chatList(controller);
  }

  Widget _chatList(AppController controller) {
    final filtered = controller.chats.where((chat) {
      final title = (chat['title'] as String? ?? '').toLowerCase();
      final matches = title.contains(_search.text.toLowerCase());
      switch (controller.chatFilter) {
        case 'unread':
          return matches && (chat['unread'] as int? ?? 0) > 0;
        case 'favourite':
          return matches && (chat['favourite'] as int? ?? 0) == 1;
        case 'archived':
          return matches && (chat['archived'] as int? ?? 0) == 1;
        default:
          return matches && (chat['archived'] as int? ?? 0) == 0;
      }
    }).toList();
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 18, 12, 8),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'Chats',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
              ),
              IconButton(
                tooltip: 'Create a group',
                onPressed: () => _createGroup(controller),
                icon: const Icon(Icons.group_add_outlined),
              ),
              IconButton(
                tooltip: 'Start a chat',
                onPressed: () => _createDirect(controller),
                icon: const Icon(Icons.add_comment_outlined),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: TextField(
            controller: _search,
            onChanged: (_) => setState(() {}),
            decoration: const InputDecoration(
              hintText: 'Search or start a chat',
              prefixIcon: Icon(Icons.search),
              isDense: true,
            ),
          ),
        ),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            children: [
              for (final filter in ['all', 'unread', 'favourite', 'archived'])
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 3),
                  child: ChoiceChip(
                    label: Text(filter[0].toUpperCase() + filter.substring(1)),
                    selected: controller.chatFilter == filter,
                    onSelected: (_) {
                      controller.chatFilter = filter;
                      controller.notifyListeners();
                    },
                  ),
                ),
            ],
          ),
        ),
        if (controller.error != null)
          MaterialBanner(
            content: Text(controller.error!),
            actions: [
              TextButton(
                onPressed: () => controller.refreshChats(),
                child: const Text('Retry'),
              ),
            ],
          ),
        Expanded(
          child: filtered.isEmpty
              ? const Center(
                  child: Text('No chats here yet. Start a conversation.'),
                )
              : RefreshIndicator(
                  onRefresh: controller.refreshChats,
                  child: ListView.builder(
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final chat = filtered[index];
                      final unread = chat['unread'] as int? ?? 0;
                      final last = chat['last'];
                      final preview = chat['locked'] == 1
                          ? 'Locked chat'
                          : last is Map
                          ? last['body'] as String? ?? 'No messages yet'
                          : 'No messages yet';
                      return ListTile(
                        leading: ProfileAvatar(
                          api: controller.api,
                          id: chat['peer']?['avatar'] as String? ?? '',
                          name: chat['title'] as String? ?? 'Chat',
                        ),
                        title: Text(
                          chat['title'] as String? ?? 'Chat',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Text(
                          preview,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        trailing: unread > 0
                            ? CircleAvatar(
                                radius: 12,
                                backgroundColor: const Color(0xffFB7185),
                                child: Text(
                                  '$unread',
                                  style: const TextStyle(fontSize: 11),
                                ),
                              )
                            : null,
                        onTap: () => _openChat(controller, chat),
                      );
                    },
                  ),
                ),
        ),
      ],
    );
  }

  Future<void> _createDirect(AppController controller) async {
    final query = TextEditingController();
    List<Map<String, dynamic>> users = [];
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, update) => AlertDialog(
          title: const Text('Start a chat'),
          content: SizedBox(
            width: 360,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: query,
                  autofocus: true,
                  decoration: const InputDecoration(
                    labelText: 'Search registered users',
                  ),
                  onChanged: (value) async {
                    if (value.trim().length < 2) {
                      update(() => users = []);
                      return;
                    }
                    try {
                      final matches = await controller.searchUsers(
                        value.trim(),
                      );
                      if (dialogContext.mounted &&
                          query.text.trim() == value.trim()) {
                        update(() => users = matches);
                      }
                    } catch (exception) {
                      if (mounted && dialogContext.mounted) {
                        ScaffoldMessenger.of(
                          context,
                        ).showSnackBar(SnackBar(content: Text('$exception')));
                      }
                    }
                  },
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 300,
                  child: ListView(
                    children: users
                        .map(
                          (person) => ListTile(
                            title: Text(person['name'] as String? ?? ''),
                            subtitle: Text('@${person['username']}'),
                            onTap: () async {
                              try {
                                final result = await controller.createChat(
                                  members: [person['id'] as int],
                                );
                                if (!mounted) return;
                                if (dialogContext.mounted)
                                  Navigator.pop(dialogContext);
                                await controller.openChat(result['id'] as int);
                              } catch (exception) {
                                if (mounted)
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('$exception')),
                                  );
                              }
                            },
                          ),
                        )
                        .toList(),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Close'),
            ),
          ],
        ),
      ),
    );
    query.dispose();
  }

  Future<void> _createGroup(AppController controller) async {
    final title = TextEditingController();
    final search = TextEditingController();
    final selected = <int>{};
    List<Map<String, dynamic>> users = [];
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, update) => AlertDialog(
          title: const Text('Create a group'),
          content: SizedBox(
            width: 380,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: title,
                  decoration: const InputDecoration(labelText: 'Group name'),
                  onChanged: (_) => update(() {}),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: search,
                  decoration: const InputDecoration(labelText: 'Find members'),
                  onChanged: (value) async {
                    if (value.trim().length < 2) {
                      update(() => users = []);
                      return;
                    }
                    try {
                      final matches = await controller.searchUsers(
                        value.trim(),
                      );
                      if (dialogContext.mounted &&
                          search.text.trim() == value.trim())
                        update(() => users = matches);
                    } catch (exception) {
                      if (mounted && dialogContext.mounted)
                        ScaffoldMessenger.of(
                          context,
                        ).showSnackBar(SnackBar(content: Text('$exception')));
                    }
                  },
                ),
                SizedBox(
                  height: 260,
                  child: ListView(
                    children: users.map((person) {
                      final id = person['id'] as int;
                      return CheckboxListTile(
                        value: selected.contains(id),
                        title: Text(person['name'] as String? ?? ''),
                        onChanged: (value) => update(() {
                          if (value == true) {
                            selected.add(id);
                          } else {
                            selected.remove(id);
                          }
                        }),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: selected.isEmpty || title.text.trim().isEmpty
                  ? null
                  : () async {
                      try {
                        final result = await controller.createChat(
                          members: selected.toList(),
                          kind: 'group',
                          title: title.text.trim(),
                        );
                        if (!mounted) return;
                        if (dialogContext.mounted) Navigator.pop(dialogContext);
                        await controller.openChat(result['id'] as int);
                      } catch (exception) {
                        if (mounted)
                          ScaffoldMessenger.of(
                            context,
                          ).showSnackBar(SnackBar(content: Text('$exception')));
                      }
                    },
              child: const Text('Create'),
            ),
          ],
        ),
      ),
    );
    title.dispose();
    search.dispose();
  }
}

class _WelcomePane extends StatelessWidget {
  const _WelcomePane();
  @override
  Widget build(BuildContext context) => const Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.forum_outlined, size: 64, color: Colors.white38),
        SizedBox(height: 18),
        Text('RoseTalk - stay connected', style: TextStyle(fontSize: 22)),
        SizedBox(height: 8),
        Text(
          'Choose a chat or start a new conversation.',
          style: TextStyle(color: Colors.white60),
        ),
      ],
    ),
  );
}
