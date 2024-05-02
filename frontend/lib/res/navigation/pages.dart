import 'package:frontend/controllers/controllers.dart';
import 'package:frontend/res/res.dart';
import 'package:frontend/views/views.dart';
import 'package:get/get.dart';

class AppPages {
  const AppPages._();

  static const String initial = AppRoutes.splash;

  static GetPage get auth => GetPage<AuthView>(
        name: AuthView.route,
        page: AuthView.new,
        binding: AuthBinding(),
      );

  static List<GetPage> pages = [
    auth,
    GetPage<SplashView>(
      name: SplashView.route,
      page: SplashView.new,
      binding: SplashBinding(),
    ),
    GetPage<DashboardView>(
      name: DashboardView.route,
      page: DashboardView.new,
      bindings: [
        DashboardBinding(),
        AnalysisBinding(),
      ],
    ),
    GetPage<AnalysisView>(
      name: AnalysisView.route,
      page: AnalysisView.new,
      binding: AnalysisBinding(),
    ),
    GetPage<SearchView>(
      name: SearchView.route,
      page: SearchView.new,
      binding: SearchBinding(),
    ),
  ];
}
