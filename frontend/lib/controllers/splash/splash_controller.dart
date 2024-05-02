import 'package:frontend/res/res.dart';
import 'package:get/get.dart';

class SplashController extends GetxController {
  var isLoggedIn = false;
  @override
  void onReady() {
    super.onReady();
    _checkLoggedIn();
  }

  void _checkLoggedIn() {
    if (isLoggedIn) {
      Get.offAllNamed(AppRoutes.dashboard);
    } else {
      Get.offAllNamed(AppRoutes.auth);
    }
  }
}
