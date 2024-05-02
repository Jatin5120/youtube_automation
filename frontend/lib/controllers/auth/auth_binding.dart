import 'package:frontend/controllers/controllers.dart';
import 'package:frontend/repositories/repositories.dart';
import 'package:frontend/view_models/view_models.dart';
import 'package:get/get.dart';

class AuthBinding implements Bindings {
  @override
  void dependencies() {
    Get.lazyPut(
      () => AuthController(
        AuthViewModel(
          AuthRepository(),
        ),
      ),
    );
  }
}
