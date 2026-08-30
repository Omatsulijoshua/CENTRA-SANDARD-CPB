import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  static const String baseUrl = String.fromEnvironment('API_BASE_URL', defaultValue: 'http://10.0.2.2:3000/api');
  static String? _token;

  static void setToken(String token) {
    _token = token;
  }

  static Future<Map<String, dynamic>> register(String name, String email, String password, String phone) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/register'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'name': name,
        'email': email,
        'password': password,
        'phone': phone,
      }),
    );
    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> login(String email, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email,
        'password': password,
      }),
    );
    final data = jsonDecode(response.body);
    if (response.statusCode == 200 && data['token'] != null) {
      setToken(data['token']);
    }
    return data;
  }

  static Future<Map<String, dynamic>> childLogin(String username, String pin) async {
    final response = await http.post(
      Uri.parse('$baseUrl/child-auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'username': username,
        'pin': pin,
      }),
    );
    return {
      'statusCode': response.statusCode,
      'data': jsonDecode(response.body),
    };
  }

  static Future<Map<String, dynamic>> getProfile() async {
    final response = await http.get(
      Uri.parse('$baseUrl/user/profile'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $_token',
      },
    );
    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> resolveAccount(String accountNumber, String bankCode) async {
    final response = await http.post(
      Uri.parse('$baseUrl/banks/resolve'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'accountNumber': accountNumber,
        'bankCode': bankCode,
      }),
    );
    return {
      'statusCode': response.statusCode,
      'data': jsonDecode(response.body),
    };
  }

  static Future<Map<String, dynamic>> sendMoney(String receiverAccountNumber, double amount) async {
    final response = await http.post(
      Uri.parse('$baseUrl/transactions/send'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $_token',
      },
      body: jsonEncode({
        'receiverAccountNumber': receiverAccountNumber,
        'amount': amount,
      }),
    );
    return {
      'statusCode': response.statusCode,
      'data': jsonDecode(response.body),
    };
  }

  static Future<List<dynamic>> getTransactions() async {
    final response = await http.get(
      Uri.parse('$baseUrl/transactions'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $_token',
      },
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    return [];
  }
}
