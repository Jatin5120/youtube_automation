import 'package:frontend/controllers/controllers.dart';
import 'package:get/get.dart';

class ReachBinding implements Bindings {
  @override
  void dependencies() {
    Get.put(ReachController());
  }
}
