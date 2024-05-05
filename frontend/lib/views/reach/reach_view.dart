import 'package:flutter/material.dart';
import 'package:flutter_dropzone/flutter_dropzone.dart';
import 'package:frontend/controllers/controllers.dart';
import 'package:frontend/models/models.dart';
import 'package:frontend/res/res.dart';
import 'package:frontend/utils/utils.dart';
import 'package:frontend/widgets/widgets.dart';
import 'package:get/get.dart';

class ReachView extends StatelessWidget {
  const ReachView({super.key});

  static const String route = AppRoutes.reach;

  static const String updateId = 'dashboard-view';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const AppHeader(
        label: 'Reach Messages',
        button1: (label: 'Dashboard', onTap: RouteManagement.goToDashboard),
        button2: (label: 'Search', onTap: RouteManagement.goToSearch),
        button3: (label: 'Analyze', onTap: RouteManagement.goToAnalysis),
        hasBottom: false,
      ),
      body: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: context.width * 0.05,
          vertical: 24,
        ),
        child: GetBuilder<ReachController>(
          builder: (controller) {
            return Column(
              children: [
                Flexible(
                  child: Row(
                    children: [
                      Flexible(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Email content',
                              style: context.textTheme.titleLarge?.withTitleColor,
                            ),
                            const SizedBox(height: 8),
                            const InputField(
                              minLines: 8,
                              maxLines: 10,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Flexible(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Dm content',
                              style: context.textTheme.titleLarge?.withTitleColor,
                            ),
                            const SizedBox(height: 8),
                            const InputField(
                              minLines: 8,
                              maxLines: 10,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Flexible(
                  child: Stack(
                    children: [
                      DropzoneView(
                        operation: DragOperation.copy,
                        cursor: CursorType.pointer,
                        mime: AppConstants.csvMimes,
                        onCreated: (ctrl) => controller.dropzoneController = ctrl,
                        onLoaded: () => AppLog.info('Zone loaded'),
                        onError: (ev) => AppLog.info('Error: $ev'),
                        onHover: () => AppLog.info('Zone hovered'),
                        onDrop: (ev) => AppLog.info('Drop: $ev ${ev.runtimeType}'),
                        onDropMultiple: controller.uploadFiles,
                        onLeave: () => AppLog.info('Zone left'),
                        onDropInvalid: (ev) {
                          Utility.showInfoDialog(ResponseModel.message('File type not support'));
                        },
                      ),
                      Positioned.fill(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.white),
                          ),
                          child: Obx(
                            () => controller.selectedFiles.isEmpty
                                ? Center(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.center,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(
                                          Icons.note_add_rounded,
                                          color: AppColors.titleDark,
                                          size: 40,
                                        ),
                                        const SizedBox(height: 10),
                                        Text(
                                          'Drag a file to upload',
                                          style: context.textTheme.labelLarge?.withTitleColor,
                                        ),
                                      ],
                                    ),
                                  )
                                : Wrap(
                                    alignment: WrapAlignment.center,
                                    crossAxisAlignment: WrapCrossAlignment.center,
                                    runAlignment: WrapAlignment.center,
                                    runSpacing: 16,
                                    spacing: 16,
                                    children: controller.selectedFiles
                                        .map(
                                          (e) => DecoratedBox(
                                            decoration: BoxDecoration(
                                              borderRadius: BorderRadius.circular(8),
                                              color: AppColors.cardDark,
                                            ),
                                            child: Padding(
                                              padding: const EdgeInsets.all(8.0),
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.center,
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  const Icon(
                                                    Icons.description_rounded,
                                                    color: AppColors.titleDark,
                                                  ),
                                                  const SizedBox(height: 10),
                                                  Text(
                                                    e.name,
                                                    style: context.textTheme.labelMedium?.withTitleColor,
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        )
                                        .toList(),
                                  ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                AppButton(
                  label: 'Generate Content',
                  onTap: () {},
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
