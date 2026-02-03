import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  // Update this to your Laravel backend URL
  static const String baseUrl =
      'http://10.0.2.2:8000/api'; // For Android emulator
  // static const String baseUrl = 'http://localhost:8000/api'; // For iOS simulator
  // static const String baseUrl = 'https://your-api-domain.com/api'; // For production

  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', token);
  }

  Future<void> removeToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
  }

  Map<String, String> _getHeaders({bool includeAuth = false}) {
    Map<String, String> headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    return headers;
  }

  Future<Map<String, String>> _getAuthHeaders() async {
    final token = await getToken();
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  // Auth APIs
  Future<Map<String, dynamic>> register(
      String name, String email, String password, String currency) async {
    final response = await http.post(
      Uri.parse('$baseUrl/register'),
      headers: _getHeaders(),
      body: jsonEncode({
        'name': name,
        'email': email,
        'password': password,
        'password_confirmation': password,
        'default_currency': currency,
      }),
    );

    if (response.statusCode == 201) {
      final data = jsonDecode(response.body);
      await saveToken(data['access_token']);
      return data;
    } else {
      throw Exception(
          jsonDecode(response.body)['message'] ?? 'Registration failed');
    }
  }

  Future<Map<String, dynamic>> login(String email, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/login'),
      headers: _getHeaders(),
      body: jsonEncode({
        'email': email,
        'password': password,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      await saveToken(data['access_token']);
      return data;
    } else {
      throw Exception(jsonDecode(response.body)['message'] ?? 'Login failed');
    }
  }

  Future<void> logout() async {
    final headers = await _getAuthHeaders();
    await http.post(
      Uri.parse('$baseUrl/logout'),
      headers: headers,
    );
    await removeToken();
  }

  Future<Map<String, dynamic>> getUser() async {
    final headers = await _getAuthHeaders();
    final response = await http.get(
      Uri.parse('$baseUrl/me'),
      headers: headers,
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to get user data');
    }
  }

  // Currency APIs
  Future<Map<String, dynamic>> getCurrencies() async {
    final response = await http.get(
      Uri.parse('$baseUrl/currencies'),
      headers: _getHeaders(),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to get currencies');
    }
  }

  Future<Map<String, dynamic>> updateDefaultCurrency(String currency) async {
    final headers = await _getAuthHeaders();
    final response = await http.put(
      Uri.parse('$baseUrl/currencies/default'),
      headers: headers,
      body: jsonEncode({'currency': currency}),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to update currency');
    }
  }

  // Expense APIs
  Future<Map<String, dynamic>> parseAndStoreExpense(String message) async {
    final headers = await _getAuthHeaders();
    final response = await http.post(
      Uri.parse('$baseUrl/expenses/parse'),
      headers: headers,
      body: jsonEncode({'message': message}),
    );

    if (response.statusCode == 201) {
      return jsonDecode(response.body);
    } else {
      final error = jsonDecode(response.body);
      throw Exception(error['message'] ?? 'Failed to parse expense');
    }
  }

  Future<Map<String, dynamic>> getExpenseSummary(String period) async {
    final headers = await _getAuthHeaders();
    final response = await http.get(
      Uri.parse('$baseUrl/expenses/summary?period=$period'),
      headers: headers,
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to get expense summary');
    }
  }

  Future<Map<String, dynamic>> getExpenses({int page = 1}) async {
    final headers = await _getAuthHeaders();
    final response = await http.get(
      Uri.parse('$baseUrl/expenses?page=$page'),
      headers: headers,
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to get expenses');
    }
  }

  Future<void> deleteExpense(int id) async {
    final headers = await _getAuthHeaders();
    final response = await http.delete(
      Uri.parse('$baseUrl/expenses/$id'),
      headers: headers,
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to delete expense');
    }
  }
}
