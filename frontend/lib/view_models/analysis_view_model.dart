import 'package:frontend/models/models.dart';
import 'package:frontend/repositories/repositories.dart';
import 'package:frontend/utils/utils.dart';

class AnalysisViewModel {
  const AnalysisViewModel(this._repository);

  final AnalysisRepository _repository;

  Future<void> analyzeChannelsWithSSE({
    required List<ChannelAnalysisItem> channels,
    int? batchSize,
    Function(int current, int total, String message)? onProgress,
    Function(ChannelDetailsModel?)? onResult,
    Function(List<ChannelDetailsModel>)? onBatchResult,
    Function()? onComplete,
    Function(String error)? onError,
  }) async {
    try {
      await _repository.analyzeChannelsWithSSE(
        channels: channels,
        batchSize: batchSize,
        onProgress: onProgress,
        onResult: onResult,
        onBatchResult: onBatchResult,
        onComplete: onComplete,
        onError: onError,
      );
    } catch (e, st) {
      AppLog.error('Channel analysis error: $e', st);
      onError?.call('Analysis failed: ${e.toString()}');
    }
  }
}
