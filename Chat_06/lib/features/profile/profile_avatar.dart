import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../core/api_client.dart';

class ProfileAvatar extends StatefulWidget {
  const ProfileAvatar({
    required this.api,
    required this.id,
    required this.name,
    this.radius = 22,
    super.key,
  });
  final ApiClient api;
  final String id, name;
  final double radius;
  @override
  State<ProfileAvatar> createState() => _ProfileAvatarState();
}

class _ProfileAvatarState extends State<ProfileAvatar> {
  Future<List<int>>? _bytes;
  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant ProfileAvatar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.id != widget.id) _load();
  }

  void _load() {
    _bytes = widget.id.isEmpty
        ? null
        : widget.api.downloadBytes('media/${widget.id}');
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<List<int>>(
    future: _bytes,
    builder: (_, snapshot) => CircleAvatar(
      radius: widget.radius,
      backgroundImage: snapshot.hasData
          ? MemoryImage(Uint8List.fromList(snapshot.data!))
          : null,
      child: snapshot.hasData
          ? null
          : Text(
              widget.name.trim().isEmpty
                  ? '?'
                  : widget.name.trim()[0].toUpperCase(),
            ),
    ),
  );
}
