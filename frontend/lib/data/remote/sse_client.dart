import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:frontend/data/data.dart';
import 'package:frontend/models/models.dart';
import 'package:frontend/utils/utils.dart';
import 'package:http/http.dart';

class SSEClient {
  const SSEClient(this.client);

  final Client client;

  static const String _dataPrefix = 'data:';
  static const String _eventPrefix = 'event:';

  static const String _startedEvent = 'started';
  static const String _progressEvent = 'progress';
  static const String _resultEvent = 'result';
  static const String _batchEvent = 'batch';
  static const String _completeEvent = 'complete';
  static const String _errorEvent = 'error';

  Future<void> subscribe(
    String api, {
    String? baseUrl,
    RequestType type = RequestType.post,
    Map<String, dynamic>? body,
    Map<String, String>? headers,
    void Function(int current, int total, String message)? onProgress,
    void Function(ChannelDetailsModel? batchData)? onResult,
    void Function(List<ChannelDetailsModel> batchData)? onBatchResult,
    VoidCallback? onComplete,
    void Function(String error)? onError,
  }) async {
    body ??= {};

    var url = (baseUrl ?? Endpoints.baseUrl) + api;
    final uri = Uri.parse(url);

    AppLog.info('[SSE Request] - ${type.name.toUpperCase()} - $uri\n${jsonEncode(body)}');

    headers = {
      'Content-Type': 'application/json',
      'Accept': 'text/event-stream',
      'Cache-Control': 'no-cache',
      'Connection': 'keep-alive',
      ...?headers,
    };

    final request = Request(
      type == RequestType.get ? 'GET' : 'POST',
      uri,
    );

    request.headers.addAll(headers);
    try {
      request.bodyBytes = utf8.encode(jsonEncode(body));
    } catch (e) {
      AppLog.error('Failed to encode body: $e');
    }

    late StreamedResponse response;
    try {
      response = await client.send(request);
    } on SocketException catch (e) {
      AppLog.error('Socket exception: $e');
      onError?.call('No internet connection. Try again');
      return;
    } catch (e) {
      AppLog.error('SSE connection error: $e');
      AppLog.error('SSE connection error type: ${e.runtimeType}');
      onError?.call('Connection failed: ${e.runtimeType}: ${e.toString()}');
      return;
    }

    if (response.statusCode == 401) {
      AppLog.error('Unauthorized. Please check your authentication.');
      onError?.call('Unauthorized. Please check your authentication.');
      return;
    }

    if (response.statusCode != 200) {
      AppLog.error('SSE error: ${response.statusCode}');
      try {
        final errorBody = await response.stream.bytesToString();
        AppLog.error('SSE error body: $errorBody');
        onError?.call('Server error (${response.statusCode}): $errorBody');
      } catch (e) {
        onError?.call('Failed to connect. Status code: ${response.statusCode}');
      }
      return;
    }

    Completer<void> completer = Completer<void>();

    StreamSubscription<String>? subscription;
    String? lastEvent;

    subscription = response.stream
        .transform(
          utf8.decoder,
        )
        .transform(const LineSplitter())
        .listen(
          (dataLine) {
            try {
              if (dataLine.trim().isEmpty) return;

              // Parse event type and data
              // Standard SSE format handling
              if (dataLine.startsWith(_eventPrefix)) {
                lastEvent = dataLine.substring(_eventPrefix.length).trim();
                AppLog.info('[SSE] EVENT - $lastEvent');
                return;
              }

              if (!dataLine.startsWith(_dataPrefix)) {
                AppLog.error('[SSE] unknown event: $dataLine');
                return;
              }

              final payload = dataLine.substring(_dataPrefix.length).trim();

              if (payload.isEmpty) {
                return;
              }

              final data = jsonDecode(payload);

              switch (lastEvent) {
                case _startedEvent:
                  return;
                case _progressEvent:
                  final current = int.tryParse(data['current'].toString()) ?? 0;
                  final total = int.tryParse(data['total'].toString()) ?? 0;
                  final message = data['message'] as String? ?? '';
                  onProgress?.call(current, total, message);
                  return;
                case _resultEvent:
                  final videoData = data['data'] as Map<String, dynamic>?;
                  if (videoData == null) {
                    onResult?.call(null);
                    return;
                  }

                  final video = ChannelDetailsModel.fromMap(videoData);
                  onResult?.call(video);
                  return;
                case _batchEvent:
                  final batchData = (data['data'] as List? ?? []).cast<Map<String, dynamic>>();
                  final videos = batchData.map((e) => ChannelDetailsModel.fromMap(e)).toList();
                  onBatchResult?.call(videos);
                  return;
                case _completeEvent:
                  onComplete?.call();
                  subscription?.cancel();
                  completer.complete();
                  return;
                case _errorEvent:
                  final error = data['message'] as String? ?? data['error'] as String? ?? '';
                  onError?.call(error);
                  subscription?.cancel();
                  completer.completeError(error);
                  return;
                default:
                  return;
              }
            } catch (e, st) {
              AppLog.error('SSE parse error: $e', st);
              onError?.call('Failed to parse response: ${e.toString()}');
              // completer.completeError(e);
            }
          },
          onError: (error, stackTrace) {
            AppLog.error('SSE stream error: $error', stackTrace);
            onError?.call('Stream error: ${error.toString()}');
            completer.completeError(error);
          },
          cancelOnError: true,
          onDone: () {
            AppLog.info('[SSE] connection closed');
            subscription?.cancel();
            onComplete?.call();
            completer.complete();
          },
        );
    return completer.future;
  }
}
