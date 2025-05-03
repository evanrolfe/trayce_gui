import 'dart:async';
import 'dart:io';

import 'package:accessing_security_scoped_resource/accessing_security_scoped_resource.dart';
import 'package:event_bus/event_bus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:trayce/app_scaffold.dart';
import 'package:trayce/common/database.dart';
import 'package:trayce/common/error_widget.dart';
import 'package:trayce/common/events.dart';
import 'package:trayce/common/style.dart';
import 'package:trayce/menu_bar.dart';
import 'package:trayce/network/repo/proto_def_repo.dart';
import 'package:trayce/status_bar.dart';
import 'package:window_manager/window_manager.dart';

import 'editor/widgets/editor.dart';
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

class _AppState extends State<App> with WindowListener {
  int _selectedIndex = 0;
  Key _rebuildKey = UniqueKey();
  String? _errorMessage;
  bool _showingError = false;
  late final StreamSubscription _displaySub;
  Timer? _resizeDebounceTimer;

  @override
  void initState() {
    super.initState();
    _initializeWindow();
    _setupErrorHandling();

    // Subscribe to verification events
    _displaySub = context.read<EventBus>().on<EventDisplayAlert>().listen((event) {
      setState(() {
        _showingError = true;
        _errorMessage = event.message;
      });
    });

    // Register window listener
    windowManager.addListener(this);
  }

  @override
  void dispose() {
    // Remove window listener
    windowManager.removeListener(this);
    _displaySub.cancel();
    _resizeDebounceTimer?.cancel();
    super.dispose();
  }

  @override
  void onWindowResize() async {
    if (Platform.isLinux || Platform.isMacOS || Platform.isWindows) {
      _resizeDebounceTimer?.cancel();
      _resizeDebounceTimer = Timer(const Duration(milliseconds: 500), () async {
        final size = await windowManager.getSize();
        AppCache.saveSize(size);
        print('onWindowResize: ${size.width}x${size.height}');
      });
    }
  }

  void _setupErrorHandling() {
    FlutterError.onError = (FlutterErrorDetails details) {
      FlutterError.presentError(details);
      if (!_showingError) {
        _showingError = true;
        _errorMessage = details.exception.toString();
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            setState(() {});
          }
        });
      }
    };
  }

  void _clearError() {
    if (_showingError) {
      setState(() {
        _showingError = false;
      });
    }
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
      builder: (context, child) {
        ErrorWidget.builder = (FlutterErrorDetails details) {
          return CustomErrorWidget(errorMessage: details.exception.toString(), onClose: _clearError);
        };
        return child!;
      },
      home: Builder(
        builder: (context) {
          Widget appContent = AppMenuBar(
            appVersion: widget.appVersion,
            onFileOpen: (path) => _changeDatabase(context, path),
            onFileSave: (path) => _changeDatabase(context, path, shouldCopy: true),
            child: Scaffold(
              body: LayoutBuilder(
                builder: (context, constraints) {
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
          );

          if (_showingError && _errorMessage != null) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (context) => CustomErrorWidget(errorMessage: _errorMessage!, onClose: _clearError),
              );
            });
          }

          return appContent;
        },
      ),
    );
  }
}
