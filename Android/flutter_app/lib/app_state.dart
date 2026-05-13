import 'package:flutter/foundation.dart';

import 'models/mobile_child_model.dart';

class SgiziAppState extends ChangeNotifier {
  SgiziAppState._();

  static final SgiziAppState instance = SgiziAppState._();

  String? authToken;
  int? activeChildId;
  List<MobileChildModel> children = const [];
  Map<String, dynamic>? profileData;

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

  void setChildren(List<MobileChildModel> value) {
    children = value;
    activeChildId ??= value.isNotEmpty ? value.first.id : null;
    if (value.every((child) => child.id != activeChildId)) {
      activeChildId = value.isNotEmpty ? value.first.id : null;
    }
    notifyListeners();
  }

  void setProfileData(Map<String, dynamic> value) {
    profileData = value;
    notifyListeners();
  }

  void setActiveChild(int id) {
    activeChildId = id;
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

  void logout() {
    authToken = null;
    activeChildId = null;
    children = const [];
    profileData = null;
    notifyListeners();
  }
}
