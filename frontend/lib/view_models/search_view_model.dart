import 'dart:convert';

import 'package:frontend/models/models.dart';
import 'package:frontend/repositories/repositories.dart';
import 'package:frontend/utils/utils.dart';

class SearchViewModel {
  const SearchViewModel(this._repository);

  final SearchRepository _repository;

  Future<ChannelSearchResult> searchChannels({
    required String query,
    required String pageToken,
    required Variant variant,
  }) async {
    try {
      final res = await _repository.searchChannels(
        query: query,
        pageToken: pageToken,
        variant: variant.name,
      );
      var data = jsonDecode(res.data) as Map<String, dynamic>;
      var token = data['nextPageToken'] as String? ?? '';
      var channels = (data['data'] as List? ?? [])
          .map(
            (e) => ChannelModel.fromMap(e as Map<String, dynamic>).copyWith(query: query),
          )
          .toList();
      return (channels: channels, pageToken: token);
    } catch (e, st) {
      AppLog.error(e, st);
      return (channels: <ChannelModel>[], pageToken: '');
    }
  }
}
