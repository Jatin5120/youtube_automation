import 'dart:convert';

import 'package:frontend/data/data.dart';
import 'package:frontend/models/models.dart';
import 'package:frontend/utils/utils.dart';

class ChannelStreamRepository {
  ChannelStreamRepository(this._sseClient);

  final SSEClient _sseClient;

  void streamChannelDetails({
    required List<String> channels,
    required bool useId,
    required String variant,
    required Function(int current, int total, String message) onProgress,
    required Function(List<ChannelDetailsModel> batchData) onBatchResult,
    required Function() onComplete,
    required Function(String error) onError,
  }) async {
    // Chunk channels to avoid HTTP client payload size limits
    const int maxChannelsPerRequest = 200;
    final List<List<String>> chunks = [];

    for (int i = 0; i < channels.length; i += maxChannelsPerRequest) {
      final end = (i + maxChannelsPerRequest < channels.length) ? i + maxChannelsPerRequest : channels.length;
      chunks.add(channels.sublist(i, end));
    }

    // Aggregate results across chunks
    final List<ChannelDetailsModel> allVideos = <ChannelDetailsModel>[];

    // Process each chunk sequentially
    for (int chunkIndex = 0; chunkIndex < chunks.length; chunkIndex++) {
      final chunk = chunks[chunkIndex];
      final ids = chunk.join(',');
      final encodedIds = base64Encode(utf8.encode(ids));

      await _sseClient.subscribe(
        Endpoints.videosStream,
        type: RequestType.post,
        body: {
          'ids': encodedIds,
          'useId': useId,
          'variant': variant,
        },
        onProgress: (current, total, message) {
          final globalCurrent = (chunkIndex * maxChannelsPerRequest) + current;
          final globalTotal = channels.length;
          onProgress(globalCurrent, globalTotal, message);
        },
        onBatchResult: (batch) {
          if (batch.isNotEmpty) {
            allVideos.addAll(batch);
            onBatchResult(batch);
          }
        },
        onComplete: () {
          // Only call onComplete for the last chunk
          if (chunkIndex == chunks.length - 1) {
            onComplete();
          }
        },
        onError: (err) {
          AppLog.error('[Repo] error: $err');
          onError(err);
        },
      );
    }
  }
}
