import 'package:frontend/app.dart';
import 'package:get/get.dart';

class AuthBinding implements Bindings {
  @override
  void dependencies() {
    Get.lazyPut(
      () => AuthController(
        AuthViewModel(
          AuthRepository(
            Get.find<DbClient>(),
          ),
        ),
      ),
    );
  }
}
