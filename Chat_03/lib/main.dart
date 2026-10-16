import 'package:flutter/material.dart';

import 'core/app_controller.dart';
import 'core/server_host.dart';
import 'features/calls/call_screen.dart';
import 'screens/app_shell.dart';
import 'screens/auth_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(ServerHost(key: serverHostKey, builder: (controller) => MessagingApp(key: ValueKey(controller), controller: controller)));
}

class MessagingApp extends StatefulWidget {
  const MessagingApp({required this.controller, super.key});

  final AppController controller;

  @override
  State<MessagingApp> createState() => _MessagingAppState();
}

class _MessagingAppState extends State<MessagingApp> {
  @override
  void initState() {
    super.initState();
    widget.controller.initialize();
  }

  @override
  void dispose() {
    widget.controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'ForestTalk',
    debugShowCheckedModeBanner: false,
    theme: ThemeData(
      brightness: Brightness.dark,
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xff4ADE80),
        brightness: Brightness.dark,
        surface: const Color(0xff12251B),
      ),
      scaffoldBackgroundColor: const Color(0xff09150F),
      useMaterial3: true,
      appBarTheme: const AppBarTheme(backgroundColor: Color(0xff12251B), foregroundColor: Colors.white, centerTitle: false),
      navigationBarTheme: const NavigationBarThemeData(backgroundColor: Color(0xff12251B), indicatorColor: Color(0xff22593B)),
      navigationRailTheme: const NavigationRailThemeData(backgroundColor: Color(0xff12251B), indicatorColor: Color(0xff22593B)),
      filledButtonTheme: FilledButtonThemeData(style: FilledButton.styleFrom(
        backgroundColor: const Color(0xff4ADE80), foregroundColor: const Color(0xff09150F),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      )),
      inputDecorationTheme: const InputDecorationTheme(
        filled: true,
        fillColor: Color(0xff20392B),
        border: OutlineInputBorder(
          borderSide: BorderSide.none,
          borderRadius: BorderRadius.all(Radius.circular(12)),
        ),
      ),
    ),
    home: AnimatedBuilder(
      animation: widget.controller,
      builder: (context, _) {
        if (widget.controller.loading) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (!widget.controller.signedIn) {
          return AuthScreen(controller: widget.controller);
        }
        return CallCoordinator(
          app: widget.controller,
          child: AppShell(controller: widget.controller),
        );
      },
    ),
  );
}
