import 'package:s_gizi/app_state.dart';

class AuthService {
  Future<void> logout() => SgiziAppState.instance.logout();
}
