import 'package:frontend/controllers/controllers.dart';
import 'package:get/get.dart';

class ScrapeBinding implements Bindings {
  @override
  void dependencies() {
    Get.lazyPut(ScrapeController.new);
  }
}
