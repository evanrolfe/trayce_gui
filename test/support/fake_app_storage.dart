import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trayce/common/app_storage.dart';

// Fake AppStorage implementation for testing
class FakeAppStorage extends AppStorageI {
  static double? _cachedWidth;
  static double? _cachedHeight;
  final Map<String, String> _storage = {};

  FakeAppStorage._();

  static Future<FakeAppStorage> getInstance() async {
    return FakeAppStorage._();
  }

  static Future<void> preloadSize() async {
    // No-op for fake implementation
  }

  static Size get size => Size(_cachedWidth ?? defaultWindowWidth, _cachedHeight ?? defaultWindowHeight);

  @override
  Future<void> saveSize(Size size) async {
    _cachedWidth = size.width;
    _cachedHeight = size.height;
  }

  @override
  Map<String, Map<String, dynamic>> getGlobalEnvMaps() {
    final keys = _storage.keys;
    final envs = <String, Map<String, dynamic>>{};

    for (final key in keys) {
      if (key.startsWith('global_env_vars:')) {
        final envName = key.split(':')[1];
        final envVars = _storage[key];
        if (envVars == null) continue;
        envs[envName] = jsonDecode(envVars);
      }
    }
    return envs;
  }

  @override
  Future<void> saveGlobalEnvVars(String envName, Map<String, String> vars) async {
    final key = 'global_env_vars:$envName';
    _storage[key] = jsonEncode(vars);
  }

  @override
  Future<void> deleteGlobalEnvVars() async {
    final keys = _storage.keys;
    for (final key in keys) {
      if (key.startsWith('global_env_vars:')) {
        _storage.remove(key);
      }
    }
  }

  @override
  Future<void> deleteGlobalEnv(String envName) async {
    final key = 'global_env_vars:$envName';
    _storage.remove(key);
  }

  @override
  Future<void> renameGlobalEnv(String oldName, String newName) async {
    final oldKey = 'global_env_vars:$oldName';
    final newKey = 'global_env_vars:$newName';
    final value = _storage[oldKey];
    if (value == null) return;
    _storage[newKey] = value;
    _storage.remove(oldKey);
  }

  @override
  Future<void> saveSecretVars(String collectionPath, String envName, Map<String, String> vars) async {
    final key = 'secret_vars:$collectionPath:$envName';
    _storage[key] = jsonEncode(vars);
  }

  @override
  Future<Map<String, String>> getSecretVars(String collectionPath, String envName) async {
    final key = 'secret_vars:$collectionPath:$envName';
    final jsonStr = _storage[key];
    if (jsonStr == null) return {};
    final Map<String, dynamic> decoded = jsonDecode(jsonStr);
    return decoded.map((key, value) => MapEntry(key, value.toString()));
  }

  @override
  Future<void> deleteSecretVars(String collectionPath, String envName) async {
    final key = 'secret_vars:$collectionPath:$envName';
    _storage.remove(key);
  }

  @override
  Future<String> getConfigValue(String key) async {
    return _storage['config:$key'] ?? '';
  }

  @override
  Future<void> saveConfigValue(String key, String value) async {
    _storage['config:$key'] = value;
  }
}
