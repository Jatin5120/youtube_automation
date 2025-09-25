import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:frontend/main.dart';
import 'package:frontend/res/res.dart';
import 'package:frontend/utils/utils.dart';
import 'package:get/get.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

class AnalysisController extends GetxController {
  var apiKey = '';
  late GenerativeModel _model;

  var titleController = TextEditingController();

  final Rx<String?> _analysis = ''.obs;
  String? get analysis => _analysis.value;
  set analysis(String? value) => _analysis.value = value;

  final RxBool _isAnalizing = false.obs;
  bool get isAnalizing => _isAnalizing.value;
  set isAnalizing(bool value) => _isAnalizing.value = value;

  // Cache for analysis results to avoid duplicate API calls
  final Map<String, String> _titleCache = {};
  final Map<String, String> _nameCache = {};

  @override
  void onInit() {
    super.onInit();
    _loadAPIKey();
  }

  void _loadAPIKey() async {
    await dotenv.load();
    var key = kVariant.key;
    apiKey = kApiKey.isEmpty ? dotenv.get(key, fallback: '') : kApiKey;
    _model = GenerativeModel(
      model: 'gemini-2.5-flash-lite',
      apiKey: apiKey,
    );
  }

  Future<void> analyzeSearchTitle(String title) async {
    try {
      if (isAnalizing) {
        return;
      }
      isAnalizing = true;
      analysis = await analyzeTitle(title);
      isAnalizing = false;
    } catch (e) {
      AppLog.error(e);
    }
  }

  Future<String?> analyzeTitle(String title) async {
    try {
      // Check cache first
      final cacheKey = title.trim().toLowerCase();
      if (_titleCache.containsKey(cacheKey)) {
        return _titleCache[cacheKey];
      }

      final prompt = AppPrompts.titlePrompt(title);
      final result = await _getAnalysis(prompt, 'Title');

      // Cache the result
      if (result != null && result.isNotEmpty) {
        _titleCache[cacheKey] = result;
      }

      return result;
    } catch (e) {
      AppLog.error('Title: $e');
      return null;
    }
  }

  Future<String?> analyzeName({
    required String username,
    required String channelName,
    required String description,
  }) async {
    try {
      // Check cache first
      final cacheKey = '${username}_${channelName}_$description'.trim().toLowerCase();
      if (_nameCache.containsKey(cacheKey)) {
        return _nameCache[cacheKey];
      }

      final prompt = AppPrompts.namePrompt(username, channelName, description);
      final result = await _getAnalysis(prompt, 'Name');

      // Cache the result
      final finalResult = result ?? 'Team $channelName';
      _nameCache[cacheKey] = finalResult;

      return finalResult;
    } catch (e) {
      AppLog.error('Name: $e');
      return 'Team $channelName';
    }
  }

  Future<String?> _getAnalysis(String prompt, String type) async {
    try {
      final content = [Content.text(prompt)];
      final response = await _model.generateContent(content);
      return response.text;
    } catch (e) {
      AppLog.error('Analyzing $type: $e');
      return null;
    }
  }

  // Clear cache when needed (e.g., when starting a new analysis session)
  void clearCache() {
    _titleCache.clear();
    _nameCache.clear();
  }

  // Get cache statistics for debugging
  Map<String, int> getCacheStats() {
    return {
      'titleCache': _titleCache.length,
      'nameCache': _nameCache.length,
    };
  }
}
