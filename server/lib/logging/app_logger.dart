import 'dart:convert';
import 'dart:math';
import 'dart:io';

import 'package:shelf/shelf.dart';

class AppLogger {
  AppLogger._();

  static const _service = 'habitduel-server';

  static void info(String event, {Map<String, Object?> fields = const {}}) {
    _write('INFO', event, fields);
  }

  static void warn(String event, {Map<String, Object?> fields = const {}}) {
    _write('WARN', event, fields);
  }

  static void error(String event, {Map<String, Object?> fields = const {}}) {
    _write('ERROR', event, fields);
  }

  static Middleware requestLogging() {
    return (innerHandler) {
      return (request) async {
        final requestId = _newRequestId();
        final startedAt = DateTime.now().toUtc();
        final watch = Stopwatch()..start();
        final enrichedRequest = request.change(context: {
          ...request.context,
          'requestId': requestId,
          'requestStartedAt': startedAt.toIso8601String(),
        });

        try {
          final response = await innerHandler(enrichedRequest);
          watch.stop();
          info(
            'http_request',
            fields: {
              'requestId': requestId,
              'method': request.method,
              'path': '/${request.url.path}',
              'query': request.url.query,
              'statusCode': response.statusCode,
              'durationMs': watch.elapsedMilliseconds,
              'userAgent': request.headers['user-agent'],
              'remoteAddress': request.headers['x-forwarded-for'],
            },
          );
          return response.change(headers: {
            ...response.headers,
            'x-request-id': requestId,
          });
        } catch (error, stackTrace) {
          watch.stop();
          AppLogger.error(
            'http_request_failed',
            fields: {
              'requestId': requestId,
              'method': request.method,
              'path': '/${request.url.path}',
              'durationMs': watch.elapsedMilliseconds,
              'error': error.toString(),
              'stackTrace': stackTrace.toString(),
            },
          );
          return Response.internalServerError(
            body: '{"error":"internal_server_error","request_id":"$requestId"}',
            headers: {
              'content-type': 'application/json',
              'x-request-id': requestId,
            },
          );
        }
      };
    };
  }

  static String requestIdFrom(Request request) {
    return request.context['requestId'] as String? ?? 'unknown';
  }

  static void _write(String level, String event, Map<String, Object?> fields) {
    final payload = <String, Object?>{
      'ts': DateTime.now().toUtc().toIso8601String(),
      'level': level,
      'service': _service,
      'event': event,
      ...fields,
    };
    stdout.writeln(jsonEncode(payload));
  }

  static String _newRequestId() {
    final millis = DateTime.now().microsecondsSinceEpoch.toRadixString(36);
    final random = (Random.secure().nextInt(1 << 32)).toRadixString(36);
    return '$millis-$random';
  }
}
