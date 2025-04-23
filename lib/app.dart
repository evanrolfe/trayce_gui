import 'dart:io';

import 'package:accessing_security_scoped_resource/accessing_security_scoped_resource.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:trayce/app_scaffold.dart';
import 'package:trayce/common/database.dart';
import 'package:trayce/common/style.dart';
import 'package:trayce/menu_bar.dart';
import 'package:trayce/network/repo/proto_def_repo.dart';
import 'package:trayce/status_bar.dart';
import 'package:window_manager/window_manager.dart';

import 'editor/editor.dart';
import 'network/repo/flow_repo.dart';
import 'network/widgets/network.dart';

const Color backgroundColor = Color(0xFF1E1E1E);
const Color textColor = Color(0xFFD4D4D4);
const Color sidebarColor = Color(0xFF333333);
const String windowWidthKey = 'window_width';
const String windowHeightKey = 'window_height';
const double defaultWindowWidth = 1200.0;
const double defaultWindowHeight = 800.0;

class AppCache {
  static double? _cachedWidth;
  static double? _cachedHeight;

  static Future<void> preloadSize() async {
    if (_cachedWidth != null && _cachedHeight != null) return;
    final prefs = await SharedPreferences.getInstance();
    _cachedWidth = prefs.getDouble(windowWidthKey);
    _cachedHeight = prefs.getDouble(windowHeightKey);
  }

  static Size get size => Size(_cachedWidth ?? defaultWindowWidth, _cachedHeight ?? defaultWindowHeight);

  static Future<void> saveSize(Size size) async {
    _cachedWidth = size.width;
    _cachedHeight = size.height;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(windowWidthKey, size.width);
    await prefs.setDouble(windowHeightKey, size.height);
  }
}

class App extends StatefulWidget {
  final String appVersion;

  const App({super.key, required this.appVersion});

  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> {
  int _selectedIndex = 0; // Add this to track current page
  Key _rebuildKey = UniqueKey();

  @override
  void initState() {
    super.initState();
    _initializeWindow();
  }

  Future<void> _initializeWindow() async {
    await AppCache.preloadSize();
    if (Platform.isLinux || Platform.isMacOS || Platform.isWindows) {
      final size = AppCache.size;
      await windowManager.setSize(size);
    }
  }

  // Helper function to handle database operations
  Future<void> _changeDatabase(BuildContext context, String path, {bool shouldCopy = false}) async {
    try {
      final flowRepo = context.read<FlowRepo>();
      final protoDefRepo = context.read<ProtoDefRepo>();
      final oldDb = flowRepo.db;
      if (oldDb.path == path) {
        return;
      }

      if (shouldCopy) {
        await File(oldDb.path).copy(path);
      }

      await oldDb.close();

      if (Platform.isMacOS) {
        final access = AccessingSecurityScopedResource();
        final dirPath = File(path).parent.path;
        await access.startAccessingSecurityScopedResourceWithURL(dirPath);
      }

      final newDb = await connectDB(path);
      flowRepo.db = newDb;
      protoDefRepo.db = newDb;

      if (context.mounted) {
        setState(() {
          // Force a rebuild of the IndexedStack
          _rebuildKey = UniqueKey();
        });
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error ${shouldCopy ? 'saving' : 'opening'} database: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Trayce',
      debugShowCheckedModeBanner: false,
      theme: appTheme,
      home: Builder(
        builder:
            (context) => AppMenuBar(
              appVersion: widget.appVersion,
              onFileOpen: (path) => _changeDatabase(context, path),
              onFileSave: (path) => _changeDatabase(context, path, shouldCopy: true),
              child: Scaffold(
                body: LayoutBuilder(
                  builder: (context, constraints) {
                    if (Platform.isLinux || Platform.isMacOS || Platform.isWindows) {
                      AppCache.saveSize(Size(constraints.maxWidth, constraints.maxHeight));
                    }
                    return IndexedStack(
                      key: _rebuildKey,
                      index: _selectedIndex,
                      children: [
                        AppScaffold(
                          selectedIndex: 0,
                          onIndexChanged: (index) => setState(() => _selectedIndex = index),
                          child: const Network(),
                        ),
                        AppScaffold(
                          selectedIndex: 1,
                          onIndexChanged: (index) => setState(() => _selectedIndex = index),
                          child: const Editor(),
                        ),
                      ],
                    );
                  },
                ),
                bottomNavigationBar: const StatusBar(),
              ),
            ),
      ),
    );
  }
}
