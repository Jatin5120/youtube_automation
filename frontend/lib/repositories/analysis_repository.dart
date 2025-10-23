import 'package:frontend/data/data.dart';
import 'package:frontend/models/models.dart';
import 'package:frontend/utils/utils.dart';

class AnalysisRepository {
  AnalysisRepository(this._sseClient);

  final SSEClient _sseClient;

  Future<void> analyzeChannelsWithSSE({
    required List<ChannelAnalysisItem> channels,
    int? batchSize,
    Function(int current, int total, String message)? onProgress,
    Function(ChannelDetailsModel?)? onResult,
    Function(List<ChannelDetailsModel>)? onBatchResult,
    Function()? onComplete,
    Function(String error)? onError,
  }) async {
    await _sseClient.subscribe(
      Endpoints.analyzeStream,
      type: RequestType.post,
      body: {
        'channels': channels.map((e) => e.toJson()).toList(),
        if (batchSize != null) 'batchSize': batchSize,
      },
      onProgress: onProgress,
      onResult: onResult,
      onBatchResult: onBatchResult,
      onComplete: onComplete,
      onError: onError,
    );
  }
}
