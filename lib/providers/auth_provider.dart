import 'package:flutter/material.dart';
import '../models/user.dart';
import '../services/api_service.dart';

class AuthProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();
  User? _user;
  bool _isLoading = false;
  String? _error;

  User? get user => _user;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _user != null;

  Future<bool> register(
      String name, String email, String password, String currency) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response =
          await _apiService.register(name, email, password, currency);
      _user = User.fromJson(response['user']);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _apiService.login(email, password);
      _user = User.fromJson(response['user']);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    try {
      await _apiService.logout();
    } catch (e) {
      // Continue with logout even if API call fails
    }
    _user = null;
    notifyListeners();
  }

  Future<void> loadUser() async {
    try {
      final userData = await _apiService.getUser();
      _user = User.fromJson(userData);
      notifyListeners();
    } catch (e) {
      // If loading user fails, consider them not authenticated
      _user = null;
      notifyListeners();
    }
  }

  Future<bool> checkAuth() async {
    final token = await _apiService.getToken();
    if (token == null) {
      return false;
    }

    try {
      await loadUser();
      return _user != null;
    } catch (e) {
      return false;
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
