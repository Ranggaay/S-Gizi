import 'package:flutter/foundation.dart';

import 'package:s_gizi/models/nutritionist_profile_model.dart';
import 'package:s_gizi/services/profile_service.dart';

class ProfileProvider extends ChangeNotifier {
  ProfileProvider({ProfileService? service})
    : _service = service ?? ProfileService();

  final ProfileService _service;
  bool isLoading = false;
  bool isSaving = false;
  String? errorMessage;
  NutritionistProfileModel? profile;

  Future<void> fetchProfile() async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();
    try {
      profile = await _service.getProfile();
    } catch (e) {
      errorMessage = e.toString().replaceFirst('Exception: ', '');
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateStatus(bool active) async {
    isSaving = true;
    notifyListeners();
    try {
      profile = await _service.updateStatus(active);
    } catch (e) {
      errorMessage = e.toString().replaceFirst('Exception: ', '');
    } finally {
      isSaving = false;
      notifyListeners();
    }
  }
}
