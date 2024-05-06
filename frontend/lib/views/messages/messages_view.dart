import 'package:flutter/material.dart';
import 'package:flutter_dropzone/flutter_dropzone.dart';
import 'package:frontend/controllers/controllers.dart';
import 'package:frontend/models/models.dart';
import 'package:frontend/res/res.dart';
import 'package:frontend/utils/utils.dart';
import 'package:frontend/views/views.dart';
import 'package:frontend/widgets/widgets.dart';
import 'package:get/get.dart';

class MessagesView extends StatelessWidget {
  const MessagesView({super.key});

  static const String route = AppRoutes.messages;

  static const String updateId = 'messages-view';
  static const String emailContentId = 'email-content-id';
  static const String dmContentId = 'dm-content-id';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const AppHeader(
        label: 'Messages',
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
        child: GetBuilder<MessagesController>(
          id: updateId,
          builder: (controller) {
            return Column(
              children: [
                Text(
                  'Tap on the chips to insert in the editing area or type the same text with double braces {{}} to insert. eg: {{text}}',
                  style: context.textTheme.titleMedium?.withBodyColor,
                ),
                const SizedBox(height: 16),
                Flexible(
                  child: Row(
                    children: [
                      Flexible(
                        child: GetBuilder<MessagesController>(
                          id: emailContentId,
                          builder: (_) {
                            return MessageContent(
                              controller: controller.emailTEC,
                              label: 'Email content',
                              onChanged: (_) => controller.onEmailContentChange(),
                            );
                          },
                        ),
                      ),
                      const SizedBox(width: 16),
                      Flexible(
                        child: GetBuilder<MessagesController>(
                          id: dmContentId,
                          builder: (_) {
                            return MessageContent(
                              controller: controller.dmTEC,
                              label: 'Dm content',
                              onChanged: (_) => controller.onDmContentChange(),
                            );
                          },
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
                        cursor: CursorType.Default,
                        mime: AppConstants.csvMimes,
                        onCreated: (ctrl) => controller.dropzoneController = ctrl,
                        onError: (ev) {
                          Utility.showInfoDialog(ResponseModel.message('Error while uploading file(s) $ev'));
                        },
                        onDropMultiple: controller.uploadFiles,
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
                                          (e) => Stack(
                                            clipBehavior: Clip.none,
                                            children: [
                                              DecoratedBox(
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
                                              Positioned(
                                                top: -8,
                                                right: -8,
                                                child: TapHandler(
                                                  showArrowCursor: true,
                                                  onTap: () => controller.removeFile(e),
                                                  child: const DecoratedBox(
                                                    decoration: BoxDecoration(
                                                      color: Colors.red,
                                                      shape: BoxShape.circle,
                                                    ),
                                                    child: Padding(
                                                      padding: EdgeInsets.all(2),
                                                      child: Icon(
                                                        Icons.close_rounded,
                                                        size: 16,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ],
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
                Row(
                  children: [
                    Flexible(
                      child: AppButton(
                        label: 'Clear Files',
                        color: AppColors.bodyLight,
                        onTap: controller.clearFiles,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Flexible(
                      child: AppButton(
                        label: 'Generate Content & Download',
                        onTap: controller.generateContent,
                      ),
                    ),
                  ],
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
