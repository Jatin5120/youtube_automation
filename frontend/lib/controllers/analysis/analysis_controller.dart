import 'package:frontend/models/models.dart';
import 'package:frontend/utils/utils.dart';
import 'package:frontend/view_models/view_models.dart';
import 'package:get/get.dart';

class AnalysisController extends GetxController {
  AnalysisController(this._viewModel);

  final AnalysisViewModel _viewModel;

  // New channel-based batch analysis with SSE
  Future<void> analyzeChannelsBatch({
    required List<ChannelAnalysisItem> channels,
    int? batchSize,
    Function(ChannelDetailsModel?)? onResult,
    Function(List<ChannelDetailsModel>)? onBatchResult,
    Function(int current, int total, String message)? onProgress,
    Function()? onComplete,
    Function(String error)? onError,
  }) async {
    try {
      await _viewModel.analyzeChannelsWithSSE(
        channels: channels,
        batchSize: batchSize,
        onProgress: onProgress,
        onResult: onResult,
        onBatchResult: onBatchResult,
        onComplete: onComplete,
        onError: onError,
      );
    } catch (e) {
      AppLog.error('Channel batch analysis error: $e');
      onError?.call(e.toString());
    }
  }
}
