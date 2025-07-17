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
  Future<void> saveSecretVars(String collectionPath, String envName, Map<String, String> vars);
  Future<Map<String, String>> getSecretVars(String collectionPath, String envName);
  Future<void> deleteSecretVars(String collectionPath, String envName);
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
}
