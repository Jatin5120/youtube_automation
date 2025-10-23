import 'dart:convert';

import 'package:frontend/models/models.dart';
import 'package:frontend/repositories/repositories.dart';
import 'package:frontend/utils/utils.dart';

class DashboardViewModel {
  const DashboardViewModel(this._repository, this._channelStreamRepository);

  final DashboardRepository _repository;
  final ChannelStreamRepository _channelStreamRepository;

  Future<List<ChannelDetailsModel>> getVideosByChannelIdentifier({
    required List<String> usernames,
    required bool useId,
    required Variant variant,
  }) async {
    try {
      var ids = base64.encode(usernames.join(',').codeUnits);
      var payload = {
        'ids': ids,
        'useId': useId.toString(),
        'variant': variant.name,
      };

      final res = await _repository.getVideosByChannelIdentifier(
        payload,
      );

      if (res.hasError) {
        AppLog.error(res.data);
        return [];
      }

      if (res.statusCode == 204) {
        return [];
      }

      final videos =
          (jsonDecode(res.data) as List? ?? []).where((e) => e != null).map((e) => ChannelDetailsModel.fromMap(e as Map<String, dynamic>)).toList();

      return videos;
    } catch (e, st) {
      AppLog.error(e, st);
      AppLog.error(st);
      return [];
    }
  }

  void streamChannelDetails({
    required List<String> channels,
    required bool useId,
    required String variant,
    required Function(int current, int total, String message) onProgress,
    required Function(List<ChannelDetailsModel> batchData) onBatchResult,
    required Function() onComplete,
    required Function(String error) onError,
  }) =>
      _channelStreamRepository.streamChannelDetails(
        channels: channels,
        useId: useId,
        variant: variant,
        onProgress: onProgress,
        onBatchResult: onBatchResult,
        onComplete: onComplete,
        onError: onError,
      );
}
