import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
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
    apiKey = dotenv.get('API_KEY', fallback: '');
    _model = GenerativeModel(model: 'gemini-pro', apiKey: apiKey);
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
      return await _getAnalysis(title, prompt);
    } catch (e) {
      AppLog.error(e);
      return null;
    }
  }

  Future<String?> analyzeName(String name, String description) async {
    try {
      final prompt = AppPrompts.namePrompt(name, description);
      return await _getAnalysis(name, prompt);
    } catch (e) {
      AppLog.error(e);
      return null;
    }
  }

  Future<String?> _getAnalysis(String title, String prompt) async {
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
