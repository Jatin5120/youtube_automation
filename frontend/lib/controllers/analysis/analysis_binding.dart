import 'package:frontend/controllers/controllers.dart';
import 'package:get/get.dart';

class AnalysisBinding implements Bindings {
  @override
  void dependencies() {
    Get.put<AnalysisController>(
      AnalysisController(),
    );
  }
}
