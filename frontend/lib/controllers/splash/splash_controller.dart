import 'package:frontend/app.dart';
import 'package:frontend/main.dart';
import 'package:get/get.dart';

class SplashController extends GetxController {
  var isLoggedIn = kVariant == Variant.development;
  @override
  void onReady() {
    super.onReady();
    _checkLoggedIn();
  }

  void _checkLoggedIn() {
    if (isLoggedIn) {
      Get.offAllNamed(AppRoutes.defaultRoute);
    } else {
      Get.offAllNamed(AppRoutes.auth);
    }
  }
}
