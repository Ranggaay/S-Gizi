import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:s_gizi/models/mobile_child_model.dart';

class SgiziAppState extends ChangeNotifier {
  SgiziAppState._();

  static final SgiziAppState instance = SgiziAppState._();

  String? authToken;
  String? role;
  int? activeChildId;
  bool showFamilyOverviewOnHome = true;
  List<MobileChildModel> children = const [];
  Map<String, dynamic>? profileData;
  Map<String, dynamic>? userData;

  bool get isAuthenticated => authToken != null && authToken!.isNotEmpty;
  MobileChildModel? get activeChild {
    final id = activeChildId;
    if (id == null || children.isEmpty) return null;
    for (final child in children) {
      if (child.id == id) return child;
    }
    return null;
  }

  void setToken(String token) {
    authToken = token;
    notifyListeners();
  }

  Future<void> restoreSession() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(_tokenKey);
    final storedRole = prefs.getString(_roleKey);
    final userJson = prefs.getString(_userKey);

    authToken = token;
    role = storedRole;
    if (userJson != null && userJson.isNotEmpty) {
      try {
        final decoded = jsonDecode(userJson);
        if (decoded is Map<String, dynamic>) {
          userData = decoded;
          profileData = decoded;
        }
      } catch (_) {
        userData = null;
        profileData = null;
      }
    }
    notifyListeners();
  }

  Future<void> saveSession({
    required String token,
    required String role,
    required Map<String, dynamic> user,
  }) async {
    authToken = token;
    this.role = role;
    userData = user;
    profileData = user;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
    await prefs.setString(_roleKey, role);
    await prefs.setString(_userKey, jsonEncode(user));
    notifyListeners();
  }

  void setChildren(List<MobileChildModel> value) {
    children = value;
    if (value.isEmpty) {
      activeChildId = null;
      showFamilyOverviewOnHome = true;
    } else if (value.length == 1) {
      activeChildId = value.first.id;
      showFamilyOverviewOnHome = false;
    } else if (value.every((child) => child.id != activeChildId)) {
      activeChildId = null;
      showFamilyOverviewOnHome = true;
    }
    notifyListeners();
  }

  void setProfileData(Map<String, dynamic> value) {
    profileData = value;
    userData = value;
    notifyListeners();
  }

  void setActiveChild(int id) {
    activeChildId = id;
    showFamilyOverviewOnHome = false;
    notifyListeners();
  }

  void showFamilyOverview() {
    showFamilyOverviewOnHome = true;
    notifyListeners();
  }

  void resetActiveChild() {
    activeChildId = null;
    showFamilyOverviewOnHome = true;
    notifyListeners();
  }

  void updateChildMeasurementSnapshot({
    required int childId,
    required String latestStatus,
    required String latestMeasurementAt,
  }) {
    children = [
      for (final child in children)
        if (child.id == childId)
          child.copyWith(
            latestStatus: latestStatus,
            latestMeasurementAt: latestMeasurementAt,
          )
        else
          child,
    ];
    notifyListeners();
  }

  Future<void> logout() async {
    authToken = null;
    role = null;
    activeChildId = null;
    showFamilyOverviewOnHome = true;
    children = const [];
    profileData = null;
    userData = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_roleKey);
    await prefs.remove(_userKey);
    notifyListeners();
  }
}

const _tokenKey = 'sgizi_auth_token';
const _roleKey = 'sgizi_user_role';
const _userKey = 'sgizi_user_data';
