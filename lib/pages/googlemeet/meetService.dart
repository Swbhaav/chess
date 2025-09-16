import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/calendar/v3.dart' as calendar;
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher_string.dart';

// Helper that adapts GoogleSignIn auth headers into an http client
class GoogleAuthClient extends http.BaseClient {
  final Map<String, String> _headers;
  final http.Client _inner = http.Client();
  GoogleAuthClient(this._headers);
  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    request.headers.addAll(_headers);
    return _inner.send(request);
  }
}

Future<String?> createGoogleMeetAndGetLink(
  BuildContext context, {
  String? title,
  DateTime? startTime,
  int durationMinutes = 30,
}) async {
  try {
    final googleSignIn = GoogleSignIn(
      scopes: [calendar.CalendarApi.calendarScope],
    );

    final account = await googleSignIn.signIn();
    if (account == null) return null;

    final authHeaders = await account.authHeaders;
    final client = GoogleAuthClient(authHeaders);
    final calendarApi = calendar.CalendarApi(client);

    final now = startTime ?? DateTime.now().toUtc();
    final event = calendar.Event(
      summary: title ?? 'Meeting from MyApp',
      start: calendar.EventDateTime(dateTime: now, timeZone: 'UTC'),
      end: calendar.EventDateTime(
        dateTime: now.add(Duration(minutes: durationMinutes)),
        timeZone: 'UTC',
      ),
      conferenceData: calendar.ConferenceData(
        createRequest: calendar.CreateConferenceRequest(
          requestId: DateTime.now().millisecondsSinceEpoch.toString(),
          conferenceSolutionKey: calendar.ConferenceSolutionKey(
            type: 'hangoutsMeet',
          ),
        ),
      ),
    );

    final created = await calendarApi.events.insert(
      event,
      'primary',
      conferenceDataVersion: 1,
    );

    final meetLink =
        created.hangoutLink ??
        created.conferenceData?.entryPoints
            ?.firstWhere(
              (e) => e.entryPointType == 'video',
              orElse: () => created.conferenceData!.entryPoints!.first,
            )
            .uri;

    return meetLink;
  } catch (e, st) {
    debugPrint('Error creating meet: $e\n$st');
    rethrow;
  }
}

Future<void> joinMeet(String url) async {
  if (url.isNotEmpty) {
    // opens the meeting in browser or Google Meet app
    await launchUrlString(url, mode: LaunchMode.externalApplication);
  }
}
