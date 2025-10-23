import 'package:frontend/controllers/controllers.dart';
import 'package:frontend/res/res.dart';
import 'package:frontend/views/views.dart';
import 'package:get/get.dart';

class AppPages {
  const AppPages._();

  static const String initial = AppRoutes.splash;

  static Transition transition = Transition.noTransition;

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
      transition: transition,
    ),
    GetPage<DashboardView>(
      name: DashboardView.route,
      page: DashboardView.new,
      bindings: [
        DashboardBinding(),
        AnalysisBinding(),
      ],
      transition: transition,
    ),
    GetPage<SearchView>(
      name: SearchView.route,
      page: SearchView.new,
      binding: SearchBinding(),
      transition: transition,
    ),
  ];
}
