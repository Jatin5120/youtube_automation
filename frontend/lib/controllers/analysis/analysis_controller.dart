import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
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

  Future<void> getAnalysis(String title) async {
    if (isAnalizing) {
      return;
    }
    isAnalizing = true;
    final prompt = '''Input: $title
Output: Analysis of the video topic or theme

Instructions:
1. Analyze the provided YouTube video title and generate a concise analysis of its primary topic or theme.
2. The analysis should focus on identifying the main subject matter or message conveyed by the video title.
3. Consider the keywords, phrases, or tone used in the title to infer the content of the video.
4. The output should not exceed 5-7 words.

Example:
Input: "If You Don't Get LOTS of Comments on Your Videos, Watch This ASAP"
Output: "Getting comments"''';
    final content = [Content.text(prompt)];
    final response = await _model.generateContent(content);
    isAnalizing = false;
    analysis = response.text;
  }
}
