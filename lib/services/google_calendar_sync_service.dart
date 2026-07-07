import 'dart:convert';

import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;

import '../models/reminder.dart';

/// Syncs MomLaunchpad reminders to the user's primary Google Calendar.
class GoogleCalendarSyncService {
  GoogleCalendarSyncService(this._googleSignIn, {http.Client? httpClient})
      : _http = httpClient ?? http.Client();

  static const calendarEventsScope =
      'https://www.googleapis.com/auth/calendar.events';

  static const _eventsUrl =
      'https://www.googleapis.com/calendar/v3/calendars/primary/events';

  final GoogleSignIn _googleSignIn;
  final http.Client _http;

  /// Prompts for Google account + Calendar permission when needed.
  Future<bool> ensureAuthorized() async {
    var account = await _googleSignIn.signInSilently();
    account ??= await _googleSignIn.signIn();
    if (account == null) return false;
    return _googleSignIn.requestScopes([calendarEventsScope]);
  }

  Future<String> createEvent(Reminder reminder) async {
    final token = await _accessToken();
    final response = await _http.post(
      Uri.parse(_eventsUrl),
      headers: _headers(token),
      body: jsonEncode(_eventBody(reminder)),
    );
    _throwIfFailed(response, 'create calendar event');
    final body = Map<String, dynamic>.from(jsonDecode(response.body) as Map);
    final id = body['id']?.toString();
    if (id == null || id.isEmpty) {
      throw GoogleCalendarSyncException('Google Calendar returned no event id');
    }
    return id;
  }

  Future<void> updateEvent(Reminder reminder) async {
    final eventId = reminder.googleCalendarEventId;
    if (eventId == null || eventId.isEmpty) return;

    final token = await _accessToken();
    final response = await _http.patch(
      Uri.parse('$_eventsUrl/$eventId'),
      headers: _headers(token),
      body: jsonEncode(_eventBody(reminder)),
    );
    _throwIfFailed(response, 'update calendar event');
  }

  Future<void> deleteEvent(String eventId) async {
    if (eventId.isEmpty) return;

    final token = await _accessToken();
    final response = await _http.delete(
      Uri.parse('$_eventsUrl/$eventId'),
      headers: _headers(token),
    );
    if (response.statusCode != 204 && response.statusCode != 200) {
      _throwIfFailed(response, 'delete calendar event');
    }
  }

  Map<String, dynamic> _eventBody(Reminder reminder) {
    final start = reminder.scheduledTime.toLocal();
    final end = start.add(const Duration(hours: 1));

    return {
      'summary': reminder.title,
      if (reminder.description != null && reminder.description!.trim().isNotEmpty)
        'description': reminder.description!.trim(),
      'start': _dateTimeField(start),
      'end': _dateTimeField(end),
      'reminders': {
        'useDefault': true,
      },
      'extendedProperties': {
        'private': {
          'momlaunchpad_reminder_id': reminder.id,
        },
      },
      if (reminder.isCompleted) 'status': 'cancelled',
    };
  }

  Map<String, String> _dateTimeField(DateTime local) {
    return {
      'dateTime': local.toIso8601String(),
      'timeZone': local.timeZoneName,
    };
  }

  Map<String, String> _headers(String token) {
    return {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    };
  }

  Future<String> _accessToken() async {
    final account = await _googleSignIn.signInSilently();
    if (account == null) {
      throw GoogleCalendarSyncException('Google account not connected');
    }
    final auth = await account.authentication;
    final token = auth.accessToken;
    if (token == null || token.isEmpty) {
      throw GoogleCalendarSyncException('Could not obtain Google access token');
    }
    return token;
  }

  void _throwIfFailed(http.Response response, String action) {
    if (response.statusCode >= 200 && response.statusCode < 300) return;
    final body = response.body.trim();
    throw GoogleCalendarSyncException(
      body.isEmpty
          ? 'Failed to $action (HTTP ${response.statusCode})'
          : 'Failed to $action: $body',
    );
  }
}

class GoogleCalendarSyncException implements Exception {
  final String message;

  GoogleCalendarSyncException(this.message);

  @override
  String toString() => message;
}
