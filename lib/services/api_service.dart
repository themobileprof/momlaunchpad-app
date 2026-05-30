import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/auth_response.dart';
import '../models/user.dart';
import '../models/user_profile.dart';
import '../models/reminder.dart';
import '../models/savings_summary.dart';
import '../models/savings_entry.dart';
import 'storage_service.dart';

/// HTTP service for REST API calls
/// Handles authentication, calendar, and other HTTP endpoints
class ApiService {
  final String baseUrl;
  final StorageService _storage;
  final http.Client _http;

  ApiService({
    required this.baseUrl,
    required StorageService storage,
    http.Client? httpClient,
  })  : _storage = storage,
        _http = httpClient ?? http.Client();

  /// Get authorization header with JWT token
  Future<Map<String, String>> _getHeaders() async {
    final token = await _storage.getToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  List<T> _mapJsonList<T>(String body, T Function(Map<String, dynamic> json) fromJson) {
    final list = jsonDecode(body) as List<dynamic>;
    return list
        .map((e) => fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  String _errorMessageFromBody(http.Response response, String fallback) {
    try {
      final decoded = jsonDecode(response.body);
      if (decoded is Map && decoded['error'] != null) {
        return decoded['error'].toString();
      }
    } catch (_) {}
    return fallback;
  }

  // ============ AUTH ENDPOINTS ============

  /// Register new user
  Future<AuthResponse> register({
    required String email,
    required String password,
    required String name,
    required String language,
  }) async {
    final response = await _http.post(
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
        message: _errorMessageFromBody(response, 'Registration failed'),
      );
    }
  }

  /// Login user
  Future<AuthResponse> login({
    required String email,
    required String password,
  }) async {
    final response = await _http.post(
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
        message: _errorMessageFromBody(response, 'Login failed'),
      );
    }
  }

  /// Google Sign-In
  Future<AuthResponse> googleSignIn({
    required String idToken,
  }) async {
    final response = await _http.post(
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
        message: _errorMessageFromBody(response, 'Google sign-in failed'),
      );
    }
  }

  /// Get current user info
  Future<User> getCurrentUser() async {
    final response = await _http.get(
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

  // ============ PROFILE / ONBOARDING ============

  /// Load profile and personalization facts for the current user.
  Future<UserProfile> getUserProfile() async {
    final response = await _http.get(
      Uri.parse('$baseUrl/api/users/me/profile'),
      headers: await _getHeaders(),
    );

    if (response.statusCode == 200) {
      return UserProfile.fromJson(
        Map<String, dynamic>.from(jsonDecode(response.body) as Map),
      );
    }

    throw ApiException(
      statusCode: response.statusCode,
      message: _errorMessageFromBody(response, 'Failed to load profile'),
    );
  }

  /// Save first-time onboarding answers.
  Future<UserProfile> completeOnboarding({
    required String name,
    required String language,
    required int pregnancyWeek,
    required bool isFirstPregnancy,
    String? primaryConcern,
    String? dietPreference,
  }) {
    return _saveProfile(
      ProfileSavePayload(
        name: name,
        language: language,
        pregnancyWeek: pregnancyWeek,
        isFirstPregnancy: isFirstPregnancy,
        primaryConcern: primaryConcern,
        dietPreference: dietPreference,
      ),
      onboarding: true,
    );
  }

  /// Update profile fields from the profile page.
  Future<UserProfile> updateProfile(ProfileSavePayload payload) {
    return _saveProfile(payload, onboarding: false);
  }

  Future<UserProfile> _saveProfile(
    ProfileSavePayload payload, {
    required bool onboarding,
  }) async {
    final path = onboarding
        ? '$baseUrl/api/users/me/onboarding'
        : '$baseUrl/api/users/me/profile';

    final response = await _http.put(
      Uri.parse(path),
      headers: await _getHeaders(),
      body: jsonEncode(payload.toJson()),
    );

    if (response.statusCode == 200) {
      return UserProfile.fromJson(
        Map<String, dynamic>.from(jsonDecode(response.body) as Map),
      );
    }

    throw ApiException(
      statusCode: response.statusCode,
      message: _errorMessageFromBody(
        response,
        onboarding
            ? 'Failed to complete onboarding'
            : 'Failed to update profile',
      ),
    );
  }

  // ============ REMINDER ENDPOINTS ============

  /// Get all reminders for current user
  Future<List<Reminder>> getReminders() async {
    final response = await _http.get(
      Uri.parse('$baseUrl/api/reminders'),
      headers: await _getHeaders(),
    );

    if (response.statusCode == 200) {
      return _mapJsonList(response.body, Reminder.fromJson);
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
    final response = await _http.post(
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
    final response = await _http.put(
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
    final response = await _http.delete(
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
    final response = await _http.get(
      Uri.parse('$baseUrl/api/savings/summary'),
      headers: await _getHeaders(),
    );

    if (response.statusCode == 200) {
      try {
        return SavingsSummary.fromJson(jsonDecode(response.body));
      } catch (e) {
        debugPrint('DEBUG: FormatException in getSavingsSummary: $e');
        debugPrint('DEBUG: Response body: ${response.body}');
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
    final response = await _http.get(
      Uri.parse('$baseUrl/api/savings/entries'),
      headers: await _getHeaders(),
    );

    if (response.statusCode == 200) {
      try {
        return _mapJsonList(response.body, SavingsEntry.fromJson);
      } catch (e) {
        debugPrint('DEBUG: FormatException in getSavingsEntries: $e');
        debugPrint('DEBUG: Response body: ${response.body}');
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

  /// Create a new savings entry
  Future<SavingsEntry> createSavingsEntry({
    required double amount,
    required String description,
    DateTime? entryDate,
  }) async {
    final response = await _http.post(
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
    final response = await _http.put(
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
    final response = await _http.put(
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
    final response = await _http.put(
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
