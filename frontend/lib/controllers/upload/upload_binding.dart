import 'package:get/get.dart';

import '../controllers.dart';

class UploadBinding implements Bindings {
  @override
  void dependencies() {
    Get.put(UploadController());
  }
}
