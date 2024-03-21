import 'dart:convert';

import 'package:frontend/models/models.dart';
import 'package:frontend/repositories/repositories.dart';
import 'package:frontend/utils/utils.dart';

class SearchViewModel {
  const SearchViewModel(this._repository);

  final SearchRepository _repository;

  Future<List<ChannelModel>> searchChannels(String query) async {
    try {
      final res = await _repository.searchChannels(query);
      return (jsonDecode(res.data) as List).map((e) => ChannelModel.fromMap(e as Map<String, dynamic>)).toList();
    } catch (e, st) {
      AppLog.error(e, st);
      return [];
    }
  }
}
