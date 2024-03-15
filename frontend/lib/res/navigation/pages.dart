import 'package:frontend/controllers/controllers.dart';
import 'package:frontend/res/res.dart';
import 'package:frontend/views/views.dart';
import 'package:get/get.dart';

class AppPages {
  const AppPages._();

  static const String initial = AppRoutes.dashboard;

  static GetPage get dashboard => GetPage<DashboardView>(
        name: DashboardView.route,
        page: DashboardView.new,
        binding: DashboardBinding(),
      );

  static List<GetPage> pages = [
    dashboard,
  ];
}
