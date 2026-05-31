import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/auth_response.dart';
import '../models/user.dart';
import '../models/user_profile.dart';
import '../models/welcome_message.dart';
import '../models/reminder.dart';
import '../models/doctor_visit.dart';
import '../models/vital_reading.dart';
import '../models/savings_summary.dart';
import '../models/savings_entry.dart';
import '../models/community.dart';
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
  Future<UserProfile> completeOnboarding(ProfileSavePayload payload) {
    return _saveProfile(payload, onboarding: true);
  }

  /// Update profile fields from the profile page.
  Future<UserProfile> updateProfile(ProfileSavePayload payload) {
    return _saveProfile(payload, onboarding: false);
  }

  /// Upload a profile photo from a local file path.
  Future<UserProfile> uploadProfilePhoto(String filePath) async {
    final token = await _storage.getToken();
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('$baseUrl/api/users/me/profile-photo'),
    );
    if (token != null) {
      request.headers['Authorization'] = 'Bearer $token';
    }
    request.files.add(await http.MultipartFile.fromPath('photo', filePath));

    final streamed = await request.send();
    final response = await http.Response.fromStream(streamed);

    if (response.statusCode == 200) {
      return UserProfile.fromJson(
        Map<String, dynamic>.from(jsonDecode(response.body) as Map),
      );
    }

    throw ApiException(
      statusCode: response.statusCode,
      message: _errorMessageFromBody(response, 'Failed to upload profile photo'),
    );
  }

  /// Remove the user's uploaded profile photo.
  Future<UserProfile> deleteProfilePhoto() async {
    final response = await _http.delete(
      Uri.parse('$baseUrl/api/users/me/profile-photo'),
      headers: await _getHeaders(),
    );

    if (response.statusCode == 200) {
      return UserProfile.fromJson(
        Map<String, dynamic>.from(jsonDecode(response.body) as Map),
      );
    }

    throw ApiException(
      statusCode: response.statusCode,
      message: _errorMessageFromBody(response, 'Failed to remove profile photo'),
    );
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

  /// Fetch this week's personalized welcome message (cached server-side per week).
  Future<WelcomeMessage> getWelcomeMessage() async {
    final response = await _http.get(
      Uri.parse('$baseUrl/api/users/me/welcome'),
      headers: await _getHeaders(),
    );

    if (response.statusCode == 200) {
      return WelcomeMessage.fromJson(
        Map<String, dynamic>.from(jsonDecode(response.body) as Map),
      );
    }

    throw ApiException(
      statusCode: response.statusCode,
      message: _errorMessageFromBody(response, 'Failed to load welcome message'),
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

  // ============ DOCTOR VISIT ENDPOINTS ============

  /// Get all visit records for the current user
  Future<List<DoctorVisit>> getDoctorVisits() async {
    final response = await _http.get(
      Uri.parse('$baseUrl/api/doctor-visits'),
      headers: await _getHeaders(),
    );

    if (response.statusCode == 200) {
      return _mapJsonList(response.body, DoctorVisit.fromJson);
    }
    throw ApiException(
      statusCode: response.statusCode,
      message: 'Failed to fetch visit records',
    );
  }

  /// Get a single visit record
  Future<DoctorVisit> getDoctorVisit(String id) async {
    final response = await _http.get(
      Uri.parse('$baseUrl/api/doctor-visits/$id'),
      headers: await _getHeaders(),
    );

    if (response.statusCode == 200) {
      return DoctorVisit.fromJson(jsonDecode(response.body));
    }
    throw ApiException(
      statusCode: response.statusCode,
      message: 'Failed to fetch visit record',
    );
  }

  /// Create a visit record
  Future<DoctorVisit> createDoctorVisit(DoctorVisitPayload payload) async {
    final response = await _http.post(
      Uri.parse('$baseUrl/api/doctor-visits'),
      headers: await _getHeaders(),
      body: jsonEncode(payload.toJson()),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return DoctorVisit.fromJson(jsonDecode(response.body));
    }
    throw ApiException(
      statusCode: response.statusCode,
      message: _errorMessageFromBody(response, 'Failed to create visit record'),
    );
  }

  /// Update a visit record
  Future<DoctorVisit> updateDoctorVisit({
    required String id,
    required DoctorVisitPayload payload,
  }) async {
    final response = await _http.put(
      Uri.parse('$baseUrl/api/doctor-visits/$id'),
      headers: await _getHeaders(),
      body: jsonEncode(payload.toJson()),
    );

    if (response.statusCode == 200) {
      return DoctorVisit.fromJson(jsonDecode(response.body));
    }
    throw ApiException(
      statusCode: response.statusCode,
      message: _errorMessageFromBody(response, 'Failed to update visit record'),
    );
  }

  /// Delete a visit record
  Future<void> deleteDoctorVisit(String id) async {
    final response = await _http.delete(
      Uri.parse('$baseUrl/api/doctor-visits/$id'),
      headers: await _getHeaders(),
    );

    if (response.statusCode != 200) {
      throw ApiException(
        statusCode: response.statusCode,
        message: 'Failed to delete visit record',
      );
    }
  }

  // ============ VITAL READINGS ENDPOINTS ============

  Future<List<VitalReading>> getVitalReadings({int limit = 30}) async {
    final response = await _http.get(
      Uri.parse('$baseUrl/api/vitals?limit=$limit'),
      headers: await _getHeaders(),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final list = data['readings'] as List<dynamic>? ?? [];
      return list
          .map((e) => VitalReading.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    throw ApiException(
      statusCode: response.statusCode,
      message: 'Failed to fetch vital readings',
    );
  }

  Future<VitalReading> createVitalReading(VitalReadingPayload payload) async {
    final response = await _http.post(
      Uri.parse('$baseUrl/api/vitals'),
      headers: await _getHeaders(),
      body: jsonEncode(payload.toJson()),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return VitalReading.fromJson(jsonDecode(response.body));
    }
    throw ApiException(
      statusCode: response.statusCode,
      message: _errorMessageFromBody(response, 'Failed to save vital reading'),
    );
  }

  Future<void> deleteVitalReading(String id) async {
    final response = await _http.delete(
      Uri.parse('$baseUrl/api/vitals/$id'),
      headers: await _getHeaders(),
    );

    if (response.statusCode != 200) {
      throw ApiException(
        statusCode: response.statusCode,
        message: 'Failed to delete vital reading',
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

  // ============ COMMUNITY ============

  Future<List<CommunityInterestGroup>> getCommunityInterests() async {
    final response = await _http.get(
      Uri.parse('$baseUrl/api/community/interests'),
      headers: await _getHeaders(),
    );
    if (response.statusCode != 200) {
      throw ApiException(
        statusCode: response.statusCode,
        message: _errorMessageFromBody(response, 'Failed to load interests'),
      );
    }
    final body = Map<String, dynamic>.from(jsonDecode(response.body) as Map);
    return (body['groups'] as List<dynamic>? ?? [])
        .map((e) => CommunityInterestGroup.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  Future<CommunityStatus> getCommunityStatus() async {
    final response = await _http.get(
      Uri.parse('$baseUrl/api/community/status'),
      headers: await _getHeaders(),
    );
    if (response.statusCode != 200) {
      throw ApiException(
        statusCode: response.statusCode,
        message: _errorMessageFromBody(response, 'Failed to load community status'),
      );
    }
    return CommunityStatus.fromJson(
      Map<String, dynamic>.from(jsonDecode(response.body) as Map),
    );
  }

  Future<List<CommunityCountryOption>> getCommunityCountries() async {
    final response = await _http.get(
      Uri.parse('$baseUrl/api/community/locations/countries'),
      headers: await _getHeaders(),
    );
    if (response.statusCode != 200) {
      throw ApiException(
        statusCode: response.statusCode,
        message: _errorMessageFromBody(response, 'Failed to load countries'),
      );
    }
    final body = Map<String, dynamic>.from(jsonDecode(response.body) as Map);
    return (body['countries'] as List<dynamic>? ?? [])
        .map((e) => CommunityCountryOption.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  Future<List<String>> getCommunityLocationSuggestions({
    required String countryCode,
    required String field,
    required String query,
    String? stateProvince,
  }) async {
    final uri = Uri.parse('$baseUrl/api/community/locations/suggestions').replace(
      queryParameters: {
        'country_code': countryCode,
        'field': field,
        'q': query,
        if (stateProvince != null && stateProvince.isNotEmpty)
          'state_province': stateProvince,
      },
    );
    final response = await _http.get(uri, headers: await _getHeaders());
    if (response.statusCode != 200) {
      throw ApiException(
        statusCode: response.statusCode,
        message: _errorMessageFromBody(response, 'Failed to load suggestions'),
      );
    }
    final body = Map<String, dynamic>.from(jsonDecode(response.body) as Map);
    return (body['suggestions'] as List<dynamic>? ?? [])
        .map((e) => e.toString())
        .toList();
  }

  Future<List<CommunityCatalogItem>> getCommunityEventTypes() async {
    final response = await _http.get(
      Uri.parse('$baseUrl/api/community/event-types'),
      headers: await _getHeaders(),
    );
    if (response.statusCode != 200) {
      throw ApiException(
        statusCode: response.statusCode,
        message: _errorMessageFromBody(response, 'Failed to load event types'),
      );
    }
    final body = Map<String, dynamic>.from(jsonDecode(response.body) as Map);
    return (body['event_types'] as List<dynamic>? ?? [])
        .map((e) => CommunityCatalogItem.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  Future<CommunityBadgeCatalog> getCommunityBadgeCatalog() async {
    final response = await _http.get(
      Uri.parse('$baseUrl/api/community/badge-types'),
      headers: await _getHeaders(),
    );
    if (response.statusCode != 200) {
      throw ApiException(
        statusCode: response.statusCode,
        message: _errorMessageFromBody(response, 'Failed to load badge types'),
      );
    }
    final body = Map<String, dynamic>.from(jsonDecode(response.body) as Map);
    final labels = <String, String>{};
    for (final raw in body['badge_types'] as List<dynamic>? ?? []) {
      final item = Map<String, dynamic>.from(raw as Map);
      labels[item['key'].toString()] = item['label']?.toString() ?? item['key'].toString();
    }
    return CommunityBadgeCatalog(labels);
  }

  Future<CommunityStatus> completeCommunityOnboarding({
    required String countryCode,
    required String stateProvince,
    required String city,
    required List<String> interests,
  }) async {
    final response = await _http.post(
      Uri.parse('$baseUrl/api/community/onboarding'),
      headers: await _getHeaders(),
      body: jsonEncode({
        'country_code': countryCode,
        'state_province': stateProvince,
        'city': city,
        'interests': interests,
      }),
    );
    if (response.statusCode != 200) {
      throw ApiException(
        statusCode: response.statusCode,
        message: _errorMessageFromBody(response, 'Failed to complete onboarding'),
      );
    }
    return CommunityStatus.fromJson(
      Map<String, dynamic>.from(jsonDecode(response.body) as Map),
    );
  }

  Future<CommunityFeedPage> getCommunityFeed({
    required CommunityFeedFilter filter,
    String? cursor,
    int limit = 20,
  }) async {
    final query = {
      'filter': filter.apiValue,
      'limit': '$limit',
      if (cursor != null) 'cursor': cursor,
    };
    final uri = Uri.parse('$baseUrl/api/community/feed')
        .replace(queryParameters: query);
    final response = await _http.get(uri, headers: await _getHeaders());
    if (response.statusCode != 200) {
      throw ApiException(
        statusCode: response.statusCode,
        message: _errorMessageFromBody(response, 'Failed to load feed'),
      );
    }
    final body = Map<String, dynamic>.from(jsonDecode(response.body) as Map);
    final posts = (body['posts'] as List<dynamic>? ?? [])
        .map((e) => CommunityPost.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
    return CommunityFeedPage(
      posts: posts,
      nextCursor: body['next_cursor']?.toString(),
    );
  }

  Future<CommunityPost> createCommunityPost(CreatePostPayload payload) async {
    final response = await _http.post(
      Uri.parse('$baseUrl/api/community/posts'),
      headers: await _getHeaders(),
      body: jsonEncode(payload.toJson()),
    );
    if (response.statusCode != 201) {
      throw ApiException(
        statusCode: response.statusCode,
        message: _errorMessageFromBody(response, 'Failed to create post'),
      );
    }
    return CommunityPost.fromJson(
      Map<String, dynamic>.from(jsonDecode(response.body) as Map),
    );
  }

  Future<CommunityPost> getCommunityPost(String id) async {
    final response = await _http.get(
      Uri.parse('$baseUrl/api/community/posts/$id'),
      headers: await _getHeaders(),
    );
    if (response.statusCode != 200) {
      throw ApiException(
        statusCode: response.statusCode,
        message: _errorMessageFromBody(response, 'Failed to load post'),
      );
    }
    return CommunityPost.fromJson(
      Map<String, dynamic>.from(jsonDecode(response.body) as Map),
    );
  }

  Future<List<CommunityReply>> getCommunityReplies(String postId) async {
    final response = await _http.get(
      Uri.parse('$baseUrl/api/community/posts/$postId/replies'),
      headers: await _getHeaders(),
    );
    if (response.statusCode != 200) {
      throw ApiException(
        statusCode: response.statusCode,
        message: _errorMessageFromBody(response, 'Failed to load replies'),
      );
    }
    final body = Map<String, dynamic>.from(jsonDecode(response.body) as Map);
    return (body['replies'] as List<dynamic>? ?? [])
        .map((e) => CommunityReply.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  Future<CommunityReply> createCommunityReply({
    required String postId,
    required String body,
    bool isAnonymous = false,
  }) async {
    final response = await _http.post(
      Uri.parse('$baseUrl/api/community/posts/$postId/replies'),
      headers: await _getHeaders(),
      body: jsonEncode({'body': body, 'is_anonymous': isAnonymous}),
    );
    if (response.statusCode != 201) {
      throw ApiException(
        statusCode: response.statusCode,
        message: _errorMessageFromBody(response, 'Failed to create reply'),
      );
    }
    return CommunityReply.fromJson(
      Map<String, dynamic>.from(jsonDecode(response.body) as Map),
    );
  }

  Future<({bool liked, int likeCount})> toggleCommunityPostLike(String postId) async {
    final response = await _http.post(
      Uri.parse('$baseUrl/api/community/posts/$postId/like'),
      headers: await _getHeaders(),
    );
    if (response.statusCode != 200) {
      throw ApiException(
        statusCode: response.statusCode,
        message: _errorMessageFromBody(response, 'Failed to update like'),
      );
    }
    final body = Map<String, dynamic>.from(jsonDecode(response.body) as Map);
    return (
      liked: body['liked'] as bool? ?? false,
      likeCount: body['like_count'] as int? ?? 0,
    );
  }

  Future<({bool liked, int likeCount})> toggleCommunityReplyLike(String replyId) async {
    final response = await _http.post(
      Uri.parse('$baseUrl/api/community/replies/$replyId/like'),
      headers: await _getHeaders(),
    );
    if (response.statusCode != 200) {
      throw ApiException(
        statusCode: response.statusCode,
        message: _errorMessageFromBody(response, 'Failed to update like'),
      );
    }
    final body = Map<String, dynamic>.from(jsonDecode(response.body) as Map);
    return (
      liked: body['liked'] as bool? ?? false,
      likeCount: body['like_count'] as int? ?? 0,
    );
  }

  Future<CommunityEvent?> getCommunityEvent(String postId) async {
    final response = await _http.get(
      Uri.parse('$baseUrl/api/community/posts/$postId/event'),
      headers: await _getHeaders(),
    );
    if (response.statusCode == 404) return null;
    if (response.statusCode != 200) {
      throw ApiException(
        statusCode: response.statusCode,
        message: _errorMessageFromBody(response, 'Failed to load event'),
      );
    }
    return CommunityEvent.fromJson(
      Map<String, dynamic>.from(jsonDecode(response.body) as Map),
    );
  }

  Future<({bool interested, int count})> toggleEventInterest(String eventId) async {
    final response = await _http.post(
      Uri.parse('$baseUrl/api/community/events/$eventId/interested'),
      headers: await _getHeaders(),
    );
    if (response.statusCode != 200) {
      throw ApiException(
        statusCode: response.statusCode,
        message: _errorMessageFromBody(response, 'Failed to update interest'),
      );
    }
    final body = Map<String, dynamic>.from(jsonDecode(response.body) as Map);
    return (
      interested: body['interested'] as bool? ?? false,
      count: body['interested_count'] as int? ?? 0,
    );
  }

  Future<void> reportCommunityPost(String postId, {required String reason, String? details}) async {
    await _reportCommunityTarget('posts/$postId/report', reason, details);
  }

  Future<void> reportCommunityReply(String replyId, {required String reason, String? details}) async {
    await _reportCommunityTarget('replies/$replyId/report', reason, details);
  }

  Future<void> hideCommunityPost(String postId) async {
    final response = await _http.post(
      Uri.parse('$baseUrl/api/community/posts/$postId/hide'),
      headers: await _getHeaders(),
    );
    if (response.statusCode != 200) {
      throw ApiException(
        statusCode: response.statusCode,
        message: _errorMessageFromBody(response, 'Failed to hide post'),
      );
    }
  }

  Future<void> blockCommunityUser(String userId) async {
    final response = await _http.post(
      Uri.parse('$baseUrl/api/community/users/$userId/block'),
      headers: await _getHeaders(),
    );
    if (response.statusCode != 200) {
      throw ApiException(
        statusCode: response.statusCode,
        message: _errorMessageFromBody(response, 'Failed to block user'),
      );
    }
  }

  Future<void> followCommunityUser(String userId) async {
    final response = await _http.post(
      Uri.parse('$baseUrl/api/community/users/$userId/follow'),
      headers: await _getHeaders(),
    );
    if (response.statusCode != 200) {
      throw ApiException(
        statusCode: response.statusCode,
        message: _errorMessageFromBody(response, 'Failed to follow user'),
      );
    }
  }

  Future<List<CommunityNotification>> getCommunityNotifications() async {
    final response = await _http.get(
      Uri.parse('$baseUrl/api/community/notifications'),
      headers: await _getHeaders(),
    );
    if (response.statusCode != 200) {
      throw ApiException(
        statusCode: response.statusCode,
        message: _errorMessageFromBody(response, 'Failed to load notifications'),
      );
    }
    final body = Map<String, dynamic>.from(jsonDecode(response.body) as Map);
    return (body['notifications'] as List<dynamic>? ?? [])
        .map((e) => CommunityNotification.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  Future<void> markCommunityNotificationRead(String id) async {
    final response = await _http.put(
      Uri.parse('$baseUrl/api/community/notifications/$id/read'),
      headers: await _getHeaders(),
    );
    if (response.statusCode != 200) {
      throw ApiException(
        statusCode: response.statusCode,
        message: _errorMessageFromBody(response, 'Failed to mark notification read'),
      );
    }
  }

  Future<void> _reportCommunityTarget(String path, String reason, String? details) async {
    final response = await _http.post(
      Uri.parse('$baseUrl/api/community/$path'),
      headers: await _getHeaders(),
      body: jsonEncode({
        'reason': reason,
        if (details != null) 'details': details,
      }),
    );
    if (response.statusCode != 201) {
      throw ApiException(
        statusCode: response.statusCode,
        message: _errorMessageFromBody(response, 'Failed to submit report'),
      );
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
