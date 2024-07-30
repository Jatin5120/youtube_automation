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
    var key = kVariant.key;
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
      return await _getAnalysis(prompt, 'Title');
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
      final prompt = AppPrompts.namePrompt(username, channelName, description);
      return await _getAnalysis(prompt, 'Name');
    } catch (e) {
      AppLog.error('Name: $e');
      return 'Team $channelName';
    }
  }

  Future<String?> generateDm({
    required String title,
    required String username,
    required String description,
    required String template,
  }) async {
    try {
      final prompt = AppPrompts.dmPrompt(
        title: title,
        clientName: username,
        clientDescription: description,
        template: template,
      );
      return await _getAnalysis(prompt, 'DM');
    } catch (e) {
      AppLog.error('Name: $e');
      return '';
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
}
