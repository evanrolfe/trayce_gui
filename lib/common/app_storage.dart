import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

const String windowWidthKey = 'window_width';
const String windowHeightKey = 'window_height';
const double defaultWindowWidth = 1200.0;
const double defaultWindowHeight = 800.0;

abstract class AppStorageI {
  Future<void> saveSize(Size size);
  Map<String, Map<String, dynamic>> getGlobalEnvMaps();
  Future<void> saveGlobalEnvVars(String envName, Map<String, String> vars);
  Future<void> deleteGlobalEnvVars();
  Future<void> renameGlobalEnv(String oldName, String newName);
  Future<void> saveSecretVars(String collectionPath, String envName, Map<String, String> vars);
  Future<Map<String, String>> getSecretVars(String collectionPath, String envName);
  Future<void> deleteSecretVars(String collectionPath, String envName);

  Future<String> getConfigValue(String key);
  Future<void> saveConfigValue(String key, String value);
}

class AppStorage implements AppStorageI {
  static double? _cachedWidth;
  static double? _cachedHeight;

  final SharedPreferences _prefs;

  AppStorage._(this._prefs);

  static Future<AppStorage> getInstance() async {
    final prefs = await SharedPreferences.getInstance();
    return AppStorage._(prefs);
  }

  static Future<void> preloadSize() async {
    if (_cachedWidth != null && _cachedHeight != null) return;
    final prefs = await SharedPreferences.getInstance();
    _cachedWidth = prefs.getDouble(windowWidthKey);
    _cachedHeight = prefs.getDouble(windowHeightKey);
  }

  static Size get size => Size(_cachedWidth ?? defaultWindowWidth, _cachedHeight ?? defaultWindowHeight);

  @override
  Future<void> saveSize(Size size) async {
    _cachedWidth = size.width;
    _cachedHeight = size.height;
    await _prefs.setDouble(windowWidthKey, size.width);
    await _prefs.setDouble(windowHeightKey, size.height);
  }

  @override
  Map<String, Map<String, dynamic>> getGlobalEnvMaps() {
    final keys = _prefs.getKeys();
    final envs = <String, Map<String, dynamic>>{};

    for (final key in keys) {
      if (key.startsWith('global_env_vars:')) {
        final envName = key.split(':')[1];
        final envVars = _prefs.getString(key);
        if (envVars == null) continue;

        envs[envName] = jsonDecode(envVars);
      }
    }
    return envs;
  }

  @override
  Future<void> renameGlobalEnv(String oldName, String newName) async {
    final oldKey = 'global_env_vars:$oldName';
    final newKey = 'global_env_vars:$newName';

    final value = _prefs.getString(oldKey);
    if (value == null) return;

    await _prefs.setString(newKey, value);
    await _prefs.remove(oldKey);
  }

  @override
  Future<void> saveGlobalEnvVars(String envName, Map<String, String> vars) async {
    final key = 'global_env_vars:$envName';
    await _prefs.setString(key, jsonEncode(vars));
  }

  @override
  Future<void> deleteGlobalEnvVars() async {
    final keys = _prefs.getKeys();
    for (final key in keys) {
      if (key.startsWith('global_env_vars:')) {
        await _prefs.remove(key);
      }
    }
  }

  @override
  Future<void> saveSecretVars(String collectionPath, String envName, Map<String, String> vars) async {
    final key = 'secret_vars:$collectionPath:$envName';
    await _prefs.setString(key, jsonEncode(vars));
  }

  @override
  Future<Map<String, String>> getSecretVars(String collectionPath, String envName) async {
    final key = 'secret_vars:$collectionPath:$envName';
    final jsonStr = _prefs.getString(key);
    if (jsonStr == null) return {};
    final Map<String, dynamic> decoded = jsonDecode(jsonStr);
    return decoded.map((key, value) => MapEntry(key, value.toString()));
  }

  @override
  Future<void> deleteSecretVars(String collectionPath, String envName) async {
    final key = 'secret_vars:$collectionPath:$envName';
    await _prefs.remove(key);
  }

  @override
  Future<String> getConfigValue(String key) async {
    key = 'config:$key';
    return _prefs.getString(key) ?? '';
  }

  @override
  Future<void> saveConfigValue(String key, String value) async {
    key = 'config:$key';
    await _prefs.setString(key, value);
  }
}
