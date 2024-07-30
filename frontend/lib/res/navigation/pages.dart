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
      middlewares: [StrictAuthMiddleware()],
      transition: transition,
    ),
    GetPage<AnalysisView>(
      name: AnalysisView.route,
      page: AnalysisView.new,
      binding: AnalysisBinding(),
      middlewares: [StrictAuthMiddleware()],
      transition: transition,
    ),
    GetPage<SearchView>(
      name: SearchView.route,
      page: SearchView.new,
      binding: SearchBinding(),
      middlewares: [StrictAuthMiddleware()],
      transition: transition,
    ),
    GetPage<MessagesView>(
      name: MessagesView.route,
      page: MessagesView.new,
      binding: MessagesBinding(),
      middlewares: [StrictAuthMiddleware()],
      transition: transition,
    ),
    GetPage<JobsView>(
      name: JobsView.route,
      page: JobsView.new,
      binding: JobsBinding(),
      middlewares: [StrictAuthMiddleware()],
      transition: transition,
    ),
  ];
}
