import 'package:flutter/material.dart';
import '../models/expense.dart';
import '../services/api_service.dart';

class ExpenseProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();

  List<Expense> _expenses = [];
  Map<String, dynamic>? _summary;
  bool _isLoading = false;
  String? _error;
  String _currentPeriod = 'current_month';

  List<Expense> get expenses => _expenses;
  Map<String, dynamic>? get summary => _summary;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String get currentPeriod => _currentPeriod;

  Future<void> loadExpenseSummary(String period) async {
    _isLoading = true;
    _error = null;
    _currentPeriod = period;
    notifyListeners();

    try {
      final data = await _apiService.getExpenseSummary(period);
      _summary = data;
      _expenses =
          (data['expenses'] as List).map((e) => Expense.fromJson(e)).toList();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadExpenses() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final data = await _apiService.getExpenses();
      _expenses =
          (data['data'] as List).map((e) => Expense.fromJson(e)).toList();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> parseAndStoreExpense(String message) async {
    try {
      await _apiService.parseAndStoreExpense(message);
      // Reload expenses after adding new one
      await loadExpenseSummary(_currentPeriod);
      return true;
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteExpense(int id) async {
    try {
      await _apiService.deleteExpense(id);
      _expenses.removeWhere((e) => e.id == id);
      // Reload summary to update totals
      await loadExpenseSummary(_currentPeriod);
      return true;
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
