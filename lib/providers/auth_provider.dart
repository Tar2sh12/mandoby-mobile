import 'package:flutter/foundation.dart';
import '../api/api_service.dart';
import '../models/models.dart';

class AuthProvider extends ChangeNotifier {
  UserModel? _user;
  bool _loading = true;

  UserModel? get user => _user;
  bool get loading => _loading;
  bool get isLoggedIn => _user != null;

  final _api = ApiService();

  Future<void> init() async {
    _loading = true;
    notifyListeners();
    try {
      final hasToken = await _api.hasToken();
      if (hasToken) {
        _user = await _api.getProfile();
      }
    } catch (_) {
      _user = null;
    }
    _loading = false;
    notifyListeners();
  }

  Future<void> login(String email, String password) async {
    await _api.login(email, password);
    _user = await _api.getProfile();
    notifyListeners();
  }

  Future<void> logout() async {
    await _api.logout();
    _user = null;
    notifyListeners();
  }

  Future<void> refreshProfile() async {
    try {
      _user = await _api.getProfile();
      notifyListeners();
    } catch (_) {}
  }
}
