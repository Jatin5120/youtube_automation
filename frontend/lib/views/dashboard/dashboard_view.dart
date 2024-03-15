import 'package:flutter/material.dart';
import 'package:frontend/controllers/controllers.dart';
import 'package:frontend/res/res.dart';
import 'package:get/get.dart';

class DashboardView extends StatelessWidget {
  const DashboardView({super.key});

  static const String route = AppRoutes.dashboard;

  static const String updateId = 'dashboard-view';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ElevatedButton(
          onPressed: Get.find<DashboardController>().getVideos,
          child: const Text('Fetch'),
        ),
      ),
    );
  }
}
