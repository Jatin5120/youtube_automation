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

  @override
  void onInit() {
    super.onInit();
    _loadAPIKey();
  }

  void _loadAPIKey() async {
    await dotenv.load();
    var key = switch (kVariant) {
      Variant.development => 'API_KEY',
      Variant.variant1 => 'API_KEY_VARIANT1',
      Variant.variant2 => 'API_KEY_VARIANT2',
      Variant.variant3 => 'API_KEY_VARIANT3',
    };
    apiKey = kApiKey.isEmpty ? dotenv.get(key, fallback: '') : kApiKey;
    _model = GenerativeModel(
      model: 'gemini-pro',
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
      final prompt = AppPrompts.titlePrompt(title);
      return await _getAnalysis(prompt);
    } catch (e) {
      AppLog.error(e);
      return null;
    }
  }

  Future<String?> analyzeName({
    required String username,
    required String channelName,
    required String description,
  }) async {
    try {
      final prompt = AppPrompts.namePrompt(username, channelName, description);
      return await _getAnalysis(prompt);
    } catch (e) {
      AppLog.error(e);
      return 'Team $channelName';
    }
  }

  Future<String?> _getAnalysis(String prompt) async {
    try {
      final content = [Content.text(prompt)];
      final response = await _model.generateContent(content);
      return response.text;
    } catch (e) {
      AppLog.error(e);
      return null;
    }
  }
}
