import 'package:flutter/material.dart';
import '/backend/backend.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'flutter_flow/flutter_flow_util.dart';

class FFAppState extends ChangeNotifier {
  static FFAppState _instance = FFAppState._internal();

  // Store for persisted state
  SharedPreferences? _prefs;

  factory FFAppState() {
    return _instance;
  }

  FFAppState._internal();

  static void reset() {
    _instance = FFAppState._internal();
  }

  Future initializePersistedState() async {
    _prefs = await SharedPreferences.getInstance();
  }

  void update(VoidCallback callback) {
    callback();
    notifyListeners();
  }

  // Get value from SharedPreferences
  dynamic getValue(String key) {
    if (_prefs == null) return null;

    if (_prefs!.containsKey(key)) {
      return _prefs!.get(key);
    }
    return null;
  }

  // Save value to SharedPreferences
  Future<void> setValue(String key, dynamic value) async {
    if (_prefs == null) return;

    if (value is String) {
      await _prefs!.setString(key, value);
    } else if (value is int) {
      await _prefs!.setInt(key, value);
    } else if (value is double) {
      await _prefs!.setDouble(key, value);
    } else if (value is bool) {
      await _prefs!.setBool(key, value);
    } else if (value is List<String>) {
      await _prefs!.setStringList(key, value);
    }
    notifyListeners();
  }

  // User properties
  String? _currentUserUid;
  String? _currentUserDisplayName;

  // Current user UID getter and setter
  String? get currentUserUid => _currentUserUid;
  set currentUserUid(String? value) {
    _currentUserUid = value;
    if (_prefs != null && value != null) {
      _prefs!.setString('ff_currentUserUid', value);
    }
    notifyListeners();
  }

  // Current user display name getter and setter
  String? get currentUserDisplayName => _currentUserDisplayName;
  set currentUserDisplayName(String? value) {
    _currentUserDisplayName = value;
    if (_prefs != null && value != null) {
      _prefs!.setString('ff_currentUserDisplayName', value);
    }
    notifyListeners();
  }
}
