import 'dart:convert';

import 'package:frontend/models/models.dart';
import 'package:frontend/repositories/repositories.dart';
import 'package:frontend/utils/utils.dart';

class CacheManager {
  static final Map<String, List<VideoModel>> _cache = {};
  static const Duration _cacheExpiry = Duration(minutes: 30);
  static final Map<String, DateTime> _cacheTimestamps = {};

  static List<VideoModel>? getCachedData(String key) {
    final timestamp = _cacheTimestamps[key];
    if (timestamp == null) return null;

    if (DateTime.now().difference(timestamp) > _cacheExpiry) {
      _cache.remove(key);
      _cacheTimestamps.remove(key);
      return null;
    }

    return _cache[key];
  }

  static void setCachedData(String key, List<VideoModel> data) {
    _cache[key] = data;
    _cacheTimestamps[key] = DateTime.now();
  }

  static void clearCache() {
    _cache.clear();
    _cacheTimestamps.clear();
  }
}

class DashboardViewModel {
  const DashboardViewModel(this._repository);

  final DashboardRepository _repository;

  Future<List<VideoModel>> getVideosByChannelIdentifier({
    required List<String> usernames,
    required bool useId,
    required Variant variant,
  }) async {
    try {
      // Create cache key
      final cacheKey = '${usernames.join(',')}_${useId}_${variant.name}';

      // Check cache first
      final cachedData = CacheManager.getCachedData(cacheKey);
      if (cachedData != null) {
        AppLog.info('Cache hit for key: $cacheKey');
        return cachedData;
      }

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
        CacheManager.setCachedData(cacheKey, []);
        return [];
      }

      final videos = (jsonDecode(res.data) as List? ?? []).where((e) => e != null).map((e) => VideoModel.fromMap(e as Map<String, dynamic>)).toList();

      // Cache the result
      CacheManager.setCachedData(cacheKey, videos);

      return videos;
    } catch (e, st) {
      AppLog.error(e, st);
      AppLog.error(st);
      return [];
    }
  }
}
