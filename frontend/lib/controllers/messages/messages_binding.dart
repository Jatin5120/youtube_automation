import 'package:frontend/controllers/controllers.dart';
import 'package:get/get.dart';

class MessagesBinding implements Bindings {
  @override
  void dependencies() {
    Get.put(MessagesController());
  }
}
