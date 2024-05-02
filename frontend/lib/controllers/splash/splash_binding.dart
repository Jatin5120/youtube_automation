import 'package:frontend/controllers/controllers.dart';
import 'package:get/get.dart';

class SplashBinding implements Bindings {
  @override
  void dependencies() {
    Get.lazyPut(SplashController.new);
  }
}
