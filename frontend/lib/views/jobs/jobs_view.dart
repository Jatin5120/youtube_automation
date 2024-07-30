import 'package:flutter/material.dart';
import 'package:frontend/controllers/controllers.dart';
import 'package:frontend/res/res.dart';
import 'package:frontend/widgets/widgets.dart';
import 'package:get/get.dart';

class JobsView extends StatelessWidget {
  const JobsView({super.key});

  static const String route = AppRoutes.jobs;
  static const String updateId = 'jobs-view';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const AppHeader(
        label: 'Jobs',
      ),
      body: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: context.width * 0.05,
          vertical: 24,
        ),
        child: GetBuilder<JobsController>(
          id: updateId,
          builder: (controller) {
            return const Center(
              child: Text('Jobs View'),
            );
          },
        ),
      ),
    );
  }
}
