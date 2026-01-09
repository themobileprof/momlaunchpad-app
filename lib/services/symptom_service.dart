import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';
import '../models/symptom.dart';
import 'storage_service.dart';

/// Service for symptom tracking API calls
class SymptomService {
  final StorageService _storage;

  SymptomService({required StorageService storage}) : _storage = storage;

  /// Get symptom history with optional filters
  Future<List<Symptom>> getHistory({
    int limit = 50,
    String? type,
  }) async {
    final token = await _storage.getToken();
    if (token == null) {
      throw Exception('No authentication token found');
    }

    final queryParams = <String, String>{
      'limit': limit.toString(),
      if (type != null) 'type': type,
    };

    final uri = Uri.parse('${AppConfig.baseUrl}/api/symptoms/history')
        .replace(queryParameters: queryParams);

    final response = await http.get(
      uri,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final symptoms = (data['symptoms'] as List)
          .map((json) => Symptom.fromJson(json as Map<String, dynamic>))
          .toList();
      return symptoms;
    } else if (response.statusCode == 401) {
      throw Exception('Unauthorized - please login again');
    } else {
      throw Exception(
          'Failed to load symptom history: ${response.statusCode}');
    }
  }

  /// Get recent symptoms (last N symptoms)
  Future<List<Symptom>> getRecent({int limit = 10}) async {
    final token = await _storage.getToken();
    if (token == null) {
      throw Exception('No authentication token found');
    }

    final uri = Uri.parse('${AppConfig.baseUrl}/api/symptoms/recent')
        .replace(queryParameters: {'limit': limit.toString()});

    final response = await http.get(
      uri,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final symptoms = (data['symptoms'] as List)
          .map((json) => Symptom.fromJson(json as Map<String, dynamic>))
          .toList();
      return symptoms;
    } else if (response.statusCode == 401) {
      throw Exception('Unauthorized - please login again');
    } else {
      throw Exception('Failed to load recent symptoms: ${response.statusCode}');
    }
  }

  /// Get symptom statistics
  Future<SymptomStats> getStats() async {
    final token = await _storage.getToken();
    if (token == null) {
      throw Exception('No authentication token found');
    }

    final uri = Uri.parse('${AppConfig.baseUrl}/api/symptoms/stats');

    final response = await http.get(
      uri,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return SymptomStats.fromJson(data);
    } else if (response.statusCode == 401) {
      throw Exception('Unauthorized - please login again');
    } else {
      throw Exception('Failed to load symptom stats: ${response.statusCode}');
    }
  }

  /// Mark a symptom as resolved
  Future<void> resolveSymptom(String symptomId) async {
    final token = await _storage.getToken();
    if (token == null) {
      throw Exception('No authentication token found');
    }

    final uri =
        Uri.parse('${AppConfig.baseUrl}/api/symptoms/$symptomId/resolve');

    final response = await http.put(
      uri,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      return;
    } else if (response.statusCode == 401) {
      throw Exception('Unauthorized - please login again');
    } else if (response.statusCode == 404) {
      throw Exception('Symptom not found');
    } else {
      throw Exception('Failed to resolve symptom: ${response.statusCode}');
    }
  }
}
