import 'package:frontend/res/res.dart';
import 'package:get/get.dart';

class RouteManagement {
  const RouteManagement._();

  static void goToDashboard([
    Map<String, String>? parameters,
  ]) =>
      Get.toNamed(
        AppRoutes.dashboard,
        parameters: parameters,
      );

  static void goToAnalysis() => Get.toNamed(AppRoutes.analysis);

  static void goToSearch() => Get.toNamed(AppRoutes.search);
}
