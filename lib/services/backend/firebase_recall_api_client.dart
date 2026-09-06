import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:intl/intl.dart';

import '../ai/note_parser.dart';
import 'recall_api_client.dart';

/// Wire format for `now` and `resolvedDatetime`: ISO-8601 local wall-clock
/// with no offset and no trailing `Z`.
///
/// This matters more than it looks. `DateTime.parse` returns a *local*
/// `DateTime` only when the string carries no zone designator, and
/// `SchedulingService` hands that straight to `tz.TZDateTime.from(..., tz.local)`.
/// A `Z` slipping in here would shift every reminder by the device's UTC
/// offset. The backend rejects the same shapes for the same reason.
final _localIso = DateFormat("yyyy-MM-dd'T'HH:mm:ss");

/// Talks to the Firebase Cloud Functions proxy that holds the Gemini key.
///
/// Per Claude.md, the app never reaches the LLM directly and never holds a key
/// — the callable does, via Cloud Secret Manager. This class is also the only
/// place `cloud_functions` types are allowed to appear: everything it throws is
/// a [NoteParseException], so the UI never imports Firebase.
class FirebaseRecallApiClient implements RecallApiClient {
  FirebaseRecallApiClient({FirebaseFunctions? functions})
      : _functions =
            functions ?? FirebaseFunctions.instanceFor(region: 'us-central1');

  final FirebaseFunctions _functions;

  @override
  Future<ParsedNote> parseNote(String rawText) async {
    final String timeZone;
    try {
      timeZone = (await FlutterTimezone.getLocalTimezone()).identifier;
    } catch (error) {
      throw NoteParseException('Could not read the device timezone: $error');
    }

    final Object? data;
    try {
      final result = await _functions.httpsCallable('parseNote').call<Object?>({
        'rawText': rawText,
        'now': _localIso.format(DateTime.now()),
        'timeZone': timeZone,
      });
      data = result.data;
    } on FirebaseFunctionsException catch (error) {
      throw NoteParseException(error.message ?? error.code);
    } catch (error) {
      throw NoteParseException('$error');
    }

    return _toParsedNote(data);
  }

  @override
  Future<List<NearbyPlace>> placesNearby({
    required double lat,
    required double lng,
    required String category,
  }) {
    throw UnimplementedError(
      'RecallApiClient.placesNearby is a Phase 4 feature (specific/category '
      'place triggers) — the backend has no /places/nearby endpoint yet.',
    );
  }

  /// Callables decode to `Map<Object?, Object?>` on Android and
  /// `Map<String, dynamic>` on iOS/web, so normalize before reading.
  ParsedNote _toParsedNote(Object? data) {
    if (data is! Map) {
      throw NoteParseException('Unexpected response shape: ${data.runtimeType}');
    }
    final json = Map<String, Object?>.fromEntries(
      data.entries.map((e) => MapEntry('${e.key}', e.value)),
    );

    final triggerType = json['triggerType'];
    final taskDescription = json['taskDescription'];
    final confidence = json['confidence'];
    if (triggerType is! String || taskDescription is! String) {
      throw const NoteParseException('Response was missing required fields.');
    }

    final resolvedRaw = json['resolvedDatetime'];
    DateTime? resolvedDatetime;
    if (resolvedRaw is String) {
      resolvedDatetime = DateTime.tryParse(resolvedRaw);
      if (resolvedDatetime == null) {
        throw NoteParseException('Unparseable datetime: $resolvedRaw');
      }
      if (resolvedDatetime.isUtc) {
        // The backend already rejects this, so reaching here means the two
        // sides have drifted — fail loudly rather than schedule the wrong hour.
        throw NoteParseException('Datetime must be local, got: $resolvedRaw');
      }
    }

    return ParsedNote(
      taskDescription: taskDescription,
      triggerType: triggerType,
      locationKind: json['locationKind'] as String?,
      locationValue: json['locationValue'] as String?,
      resolvedDatetime: resolvedDatetime,
      recurrenceRule: json['recurrenceRule'] as String?,
      confidence: confidence is num ? confidence.toDouble() : 0,
    );
  }
}
