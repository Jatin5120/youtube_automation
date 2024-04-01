import 'dart:convert';

import 'package:frontend/models/models.dart';
import 'package:frontend/repositories/repositories.dart';
import 'package:frontend/utils/utils.dart';

class DashboardViewModel {
  const DashboardViewModel(this._repository);

  final DashboardRepository _repository;

  Future<List<VideoModel>> getVideosByChannelIdentifier(List<String> usernames, bool useId) async {
    try {
      var ids = base64.encode(usernames.join(',').codeUnits);
      final res = await _repository.getVideosByChannelIdentifier(ids, useId);
      return (jsonDecode(res.data) as List).map((e) => VideoModel.fromMap(e as Map<String, dynamic>)).toList();
    } catch (e, st) {
      AppLog.error(e, st);
      return [];
    }
  }

  Future<List<VideoModel>> getVideosByUrl(String link) async {
    try {
      final url = Uri.encodeComponent(link);
      final res = await _repository.getVideosByUrl(url);
      return (jsonDecode(res.data) as List).map((e) => VideoModel.fromMap(e as Map<String, dynamic>)).toList();
    } catch (e, st) {
      AppLog.error(e, st);
      return [];
    }
  }
}
