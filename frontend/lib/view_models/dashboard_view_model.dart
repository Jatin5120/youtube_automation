import 'dart:convert';

import 'package:frontend/models/models.dart';
import 'package:frontend/repositories/repositories.dart';
import 'package:frontend/utils/utils.dart';

class DashboardViewModel {
  const DashboardViewModel(this._repository);

  final DashboardRepository _repository;

  Future<List<VideoModel>> getVideosByChannelIdentifier({
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
      if (res.statusCode == 204) {
        return [];
      }
      return (jsonDecode(res.data) as List? ?? []).where((e) => e != null).map((e) => VideoModel.fromMap(e as Map<String, dynamic>)).toList();
    } catch (e, st) {
      AppLog.error(e, st);
      AppLog.error(st);
      return [];
    }
  }
}
