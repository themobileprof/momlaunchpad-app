import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/conversation.dart';
import '../models/message.dart';
import 'api_service.dart';
import 'storage_service.dart';

class ConversationService {
  final String baseUrl;
  final StorageService _storage;

  ConversationService({
    required this.baseUrl,
    required StorageService storage,
  }) : _storage = storage;

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

  Future<List<Conversation>> getConversations({int limit = 20, int offset = 0}) async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/conversations?limit=$limit&offset=$offset'),
      headers: await _getHeaders(),
    );

    if (response.statusCode == 200) {
      return _mapJsonList(response.body, Conversation.fromJson);
    } else {
      throw ApiException(
        statusCode: response.statusCode,
        message: 'Failed to fetch conversations',
      );
    }
  }

  Future<Conversation> createConversation(String title) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/conversations'),
      headers: await _getHeaders(),
      body: jsonEncode({'title': title}),
    );

    if (response.statusCode == 201 || response.statusCode == 200) {
      return Conversation.fromJson(jsonDecode(response.body));
    } else {
      throw ApiException(
        statusCode: response.statusCode,
        message: 'Failed to create conversation',
      );
    }
  }

  Future<Conversation> getConversation(String id) async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/conversations/$id'),
      headers: await _getHeaders(),
    );

    if (response.statusCode == 200) {
      return Conversation.fromJson(jsonDecode(response.body));
    } else {
      throw ApiException(
        statusCode: response.statusCode,
        message: 'Failed to fetch conversation',
      );
    }
  }

  Future<void> updateConversation(String id, {String? title, bool? isStarred}) async {
    final response = await http.patch(
      Uri.parse('$baseUrl/api/conversations/$id'),
      headers: await _getHeaders(),
      body: jsonEncode({
        if (title != null) 'title': title,
        if (isStarred != null) 'is_starred': isStarred,
      }),
    );

    if (response.statusCode != 200) {
      throw ApiException(
        statusCode: response.statusCode,
        message: 'Failed to update conversation',
      );
    }
  }

  Future<void> deleteConversation(String id) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/api/conversations/$id'),
      headers: await _getHeaders(),
    );

    if (response.statusCode != 200) {
      throw ApiException(
        statusCode: response.statusCode,
        message: 'Failed to delete conversation',
      );
    }
  }

  Future<List<Message>> getMessages(String conversationId, {int limit = 50, int offset = 0}) async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/conversations/$conversationId/messages?limit=$limit&offset=$offset'),
      headers: await _getHeaders(),
    );

    if (response.statusCode == 200) {
      return _mapJsonList(response.body, Message.fromJson);
    } else {
      throw ApiException(
        statusCode: response.statusCode,
        message: 'Failed to fetch messages',
      );
    }
  }
}
