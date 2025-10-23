import 'package:frontend/controllers/controllers.dart';
import 'package:frontend/repositories/repositories.dart';
import 'package:frontend/view_models/view_models.dart';
import 'package:get/get.dart';

class AnalysisBinding implements Bindings {
  @override
  void dependencies() {
    Get.put<AnalysisController>(
      AnalysisController(
        AnalysisViewModel(
          AnalysisRepository(
            Get.find(),
          ),
        ),
      ),
    );
  }
}
