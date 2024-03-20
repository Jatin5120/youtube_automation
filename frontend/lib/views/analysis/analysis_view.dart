import 'package:flutter/material.dart';
import 'package:frontend/controllers/controllers.dart';
import 'package:frontend/res/res.dart';
import 'package:frontend/utils/utils.dart';
import 'package:frontend/views/dashboard/dashboard.dart';
import 'package:frontend/widgets/widgets.dart';
import 'package:get/get.dart';

class AnalysisView extends StatelessWidget {
  const AnalysisView({super.key});

  static const String route = AppRoutes.analysis;

  static const String updateId = 'analysis-view';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Analyze Title'),
        elevation: 0,
        backgroundColor: AppColors.backgroundDark,
        actions: [
          Padding(
            padding: EdgeInsets.only(right: context.width * 0.05),
            child: ElevatedButton(
              onPressed: () => Get.offNamed(DashboardView.route),
              child: const Text('Dashboard'),
            ),
          ),
        ],
      ),
      body: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: context.width * 0.05,
          vertical: 24,
        ),
        child: GetBuilder<AnalysisController>(
          id: updateId,
          builder: (controller) {
            return Column(
              children: [
                Row(
                  children: [
                    Flexible(
                      child: InputField(
                        hint: 'Enter video title',
                        controller: controller.titleController,
                        onFieldSubmitted: controller.getAnalysis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Obx(
                      () => FloatingActionButton(
                        onPressed: controller.isAnalizing ? () {} : () => controller.getAnalysis(controller.titleController.text),
                        elevation: 0,
                        child: controller.isAnalizing
                            ? const CircularProgressIndicator(
                                color: Colors.white,
                              )
                            : const Icon(Icons.query_stats_rounded),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Obx(() {
                  var label = '';
                  if (controller.isAnalizing) {
                    label = 'Analyzing...';
                  } else if (controller.analysis == null) {
                    label = 'Error while creating analysis';
                  } else if (controller.analysis!.trim().isEmpty) {
                    label = 'Enter video title to analyze';
                  } else {
                    label = controller.analysis!;
                  }
                  return AppText(
                    label,
                    style: context.textTheme.titleLarge?.withTitleColor,
                  );
                }),
              ],
            );
          },
        ),
      ),
    );
  }
}
