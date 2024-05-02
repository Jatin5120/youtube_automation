import 'package:flutter/material.dart';
import 'package:frontend/controllers/controllers.dart';
import 'package:frontend/res/res.dart';
import 'package:frontend/widgets/widgets.dart';
import 'package:get/get.dart';

class SplashView extends StatelessWidget {
  const SplashView({super.key});

  static const String route = AppRoutes.splash;

  static const String updateId = 'splash-view';

  @override
  Widget build(BuildContext context) {
    return GetBuilder<SplashController>(
      builder: (_) {
        return const Scaffold(
          body: Center(
            child: AppLogo(),
          ),
        );
      },
    );
  }
}
