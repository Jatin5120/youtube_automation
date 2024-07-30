import 'package:frontend/controllers/controllers.dart';
import 'package:get/get.dart';

class JobsBinding implements Bindings {
  @override
  void dependencies() {
    Get.put(JobsController());
  }
}
