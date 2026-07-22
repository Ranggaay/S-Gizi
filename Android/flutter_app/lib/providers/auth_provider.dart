import 'package:flutter/foundation.dart';

import 'package:s_gizi/services/auth_service.dart';

class AuthProvider extends ChangeNotifier {
  AuthProvider({AuthService? service}) : _service = service ?? AuthService();

  final AuthService _service;
  bool isLoading = false;

  Future<void> logout() async {
    isLoading = true;
    notifyListeners();
    await _service.logout();
    isLoading = false;
    notifyListeners();
  }
}
