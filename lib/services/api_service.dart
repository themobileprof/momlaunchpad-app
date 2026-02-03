import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/auth_response.dart';
import '../models/user.dart';
import '../models/reminder.dart';
import '../models/savings_summary.dart';
import '../models/savings_entry.dart';
import 'storage_service.dart';

/// HTTP service for REST API calls
/// Handles authentication, calendar, and other HTTP endpoints
class ApiService {
  final String baseUrl;
  final StorageService _storage;

  ApiService({
    required this.baseUrl,
    required StorageService storage,
  }) : _storage = storage;

  /// Get authorization header with JWT token
  Future<Map<String, String>> _getHeaders() async {
    final token = await _storage.getToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  // ============ AUTH ENDPOINTS ============

  /// Register new user
  Future<AuthResponse> register({
    required String email,
    required String password,
    required String name,
    required String language,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/auth/register'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email,
        'password': password,
        'name': name,
        'language': language,
      }),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      final authResponse = AuthResponse.fromJson(jsonDecode(response.body));
      await _storage.saveToken(authResponse.token);
      await _storage.saveUserId(authResponse.user.id);
      return authResponse;
    } else {
      throw ApiException(
        statusCode: response.statusCode,
        message: jsonDecode(response.body)['error'] ?? 'Registration failed',
      );
    }
  }

  /// Login user
  Future<AuthResponse> login({
    required String email,
    required String password,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email,
        'password': password,
      }),
    );

    if (response.statusCode == 200) {
      final authResponse = AuthResponse.fromJson(jsonDecode(response.body));
      await _storage.saveToken(authResponse.token);
      await _storage.saveUserId(authResponse.user.id);
      return authResponse;
    } else {
      throw ApiException(
        statusCode: response.statusCode,
        message: jsonDecode(response.body)['error'] ?? 'Login failed',
      );
    }
  }

  /// Google Sign-In
  Future<AuthResponse> googleSignIn({
    required String idToken,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/auth/google/token'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'id_token': idToken,
      }),
    );

    if (response.statusCode == 200) {
      final authResponse = AuthResponse.fromJson(jsonDecode(response.body));
      await _storage.saveToken(authResponse.token);
      await _storage.saveUserId(authResponse.user.id);
      return authResponse;
    } else {
      throw ApiException(
        statusCode: response.statusCode,
        message: jsonDecode(response.body)['error'] ?? 'Google sign-in failed',
      );
    }
  }

  /// Get current user info
  Future<User> getCurrentUser() async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/auth/me'),
      headers: await _getHeaders(),
    );

    if (response.statusCode == 200) {
      return User.fromJson(jsonDecode(response.body));
    } else if (response.statusCode == 401) {
      throw ApiException(
        statusCode: 401,
        message: 'Token expired or invalid',
      );
    } else {
      throw ApiException(
        statusCode: response.statusCode,
        message: 'Failed to get user info',
      );
    }
  }

  // ============ REMINDER ENDPOINTS ============

  /// Get all reminders for current user
  Future<List<Reminder>> getReminders() async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/reminders'),
      headers: await _getHeaders(),
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => Reminder.fromJson(json)).toList();
    } else {
      throw ApiException(
        statusCode: response.statusCode,
        message: 'Failed to fetch reminders',
      );
    }
  }

  /// Create new reminder
  Future<Reminder> createReminder({
    required String title,
    String? description,
    required DateTime scheduledTime,
    required String priority,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/reminders'),
      headers: await _getHeaders(),
      body: jsonEncode({
        'title': title,
        if (description != null) 'description': description,
        'reminder_time': scheduledTime.toUtc().toIso8601String(),
        'priority': priority,
      }),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return Reminder.fromJson(jsonDecode(response.body));
    } else {
      throw ApiException(
        statusCode: response.statusCode,
        message: 'Failed to create reminder',
      );
    }
  }

  /// Update existing reminder
  Future<void> updateReminder({
    required String id,
    String? title,
    String? description,
    DateTime? scheduledTime,
    String? priority,
    bool? isCompleted,
  }) async {
    final response = await http.put(
      Uri.parse('$baseUrl/api/reminders/$id'),
      headers: await _getHeaders(),
      body: jsonEncode({
        if (title != null) 'title': title,
        if (description != null) 'description': description,
        if (scheduledTime != null)
          'reminder_time': scheduledTime.toUtc().toIso8601String(),
        if (priority != null) 'priority': priority,
        if (isCompleted != null) 'is_completed': isCompleted,
      }),
    );

    if (response.statusCode != 200) {
      throw ApiException(
        statusCode: response.statusCode,
        message: 'Failed to update reminder',
      );
    }
  }

  /// Delete reminder
  Future<void> deleteReminder(String id) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/api/reminders/$id'),
      headers: await _getHeaders(),
    );

    if (response.statusCode != 200) {
      throw ApiException(
        statusCode: response.statusCode,
        message: 'Failed to delete reminder',
      );
    }
  }

  // ============ SAVINGS ENDPOINTS ============

  /// Get savings summary with EDD, goal, and progress
  Future<SavingsSummary> getSavingsSummary() async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/savings/summary'),
      headers: await _getHeaders(),
    );

    if (response.statusCode == 200) {
      try {
        return SavingsSummary.fromJson(jsonDecode(response.body));
      } catch (e) {
        print('DEBUG: FormatException in getSavingsSummary: $e');
        print('DEBUG: Response body: ${response.body}');
        rethrow;
      }
    } else {
      _checkForPremiumError(response);
      throw ApiException(
        statusCode: response.statusCode,
        message: 'Failed to fetch savings summary',
      );
    }
  }

  /// Get all savings entries for the current user
  Future<List<SavingsEntry>> getSavingsEntries() async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/savings/entries'),
      headers: await _getHeaders(),
    );

    if (response.statusCode == 200) {
      try {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => SavingsEntry.fromJson(json)).toList();
      } catch (e) {
        print('DEBUG: FormatException in getSavingsEntries: $e');
        print('DEBUG: Response body: ${response.body}');
        rethrow;
      }
    } else {
      _checkForPremiumError(response);
      throw ApiException(
        statusCode: response.statusCode,
        message: 'Failed to fetch savings entries',
      );
    }
  }

  // ... (keeping other savings methods as they were, or applying check if needed) ... 
  // Actually, createSavingsEntry, updateEDD, updateGoal might also trigger it. 
  // For brevity I'll just helper function.

  /// Create a new savings entry
  Future<SavingsEntry> createSavingsEntry({
    required double amount,
    required String description,
    DateTime? entryDate,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/savings/entries'),
      headers: await _getHeaders(),
      body: jsonEncode({
        'amount': amount,
        'description': description,
        if (entryDate != null) 'entry_date': entryDate.toUtc().toIso8601String(),
      }),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return SavingsEntry.fromJson(jsonDecode(response.body));
    } else {
      _checkForPremiumError(response);
      throw ApiException(
        statusCode: response.statusCode,
        message: 'Failed to create savings entry',
      );
    }
  }

  /// Update expected delivery date
  Future<void> updateExpectedDeliveryDate(DateTime? edd) async {
    final response = await http.put(
      Uri.parse('$baseUrl/api/savings/edd'),
      headers: await _getHeaders(),
      body: jsonEncode({
        'expected_delivery_date': edd?.toUtc().toIso8601String(),
      }),
    );

    if (response.statusCode != 200) {
      _checkForPremiumError(response);
      throw ApiException(
        statusCode: response.statusCode,
        message: 'Failed to update expected delivery date',
      );
    }
  }

  /// Update savings goal
  Future<void> updateSavingsGoal(double goal) async {
    final response = await http.put(
      Uri.parse('$baseUrl/api/savings/goal'),
      headers: await _getHeaders(),
      body: jsonEncode({
        'savings_goal': goal,
      }),
    );

    if (response.statusCode != 200) {
      _checkForPremiumError(response);
      throw ApiException(
        statusCode: response.statusCode,
        message: 'Failed to update savings goal',
      );
    }
  }

  /// Update savings currency
  Future<void> updateSavingsCurrency(String currency) async {
    final response = await http.put(
      Uri.parse('$baseUrl/api/savings/currency'),
      headers: await _getHeaders(),
      body: jsonEncode({
        'currency': currency,
      }),
    );

    if (response.statusCode != 200) {
      _checkForPremiumError(response);
      throw ApiException(
        statusCode: response.statusCode,
        message: 'Failed to update savings currency',
      );
    }
  }

  void _checkForPremiumError(http.Response response) {
    if (response.statusCode == 403) {
      try {
        final body = jsonDecode(response.body);
        if (body['error'] == 'feature not available') {
          throw PremiumFeatureException();
        }
      } catch (_) {
        // Ignore json parse error, fall through to generic error
      }
    }
  }
}

/// Exception specifically for premium feature restrictions
class PremiumFeatureException implements Exception {
  final String message = 'This feature requires a premium subscription';
  
  @override
  String toString() => message;
}

/// API Exception for error handling
class ApiException implements Exception {
  final int statusCode;
  final String message;

  ApiException({
    required this.statusCode,
    required this.message,
  });

  @override
  String toString() => 'ApiException($statusCode): $message';

  bool get isUnauthorized => statusCode == 401;
  bool get isRateLimited => statusCode == 429;
  bool get isForbidden => statusCode == 403;
  bool get isNotFound => statusCode == 404;
  bool get isServerError => statusCode >= 500;
}
