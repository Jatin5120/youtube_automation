// ignore: avoid_web_libraries_in_flutter, deprecated_member_use
import 'dart:html';

import 'package:flutter/material.dart';
import 'package:flutter_dropzone/flutter_dropzone.dart';
import 'package:frontend/app.dart';
import 'package:get/get.dart';

class UploadView extends StatelessWidget {
  const UploadView({super.key});

  static const String route = AppRoutes.upload;
  static const String updateId = 'upload-view';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const AppHeader(
        label: 'Upload CSV',
        buttons: [
          (label: 'Dashboard', onTap: RouteManagement.goToDashboard),
          (label: 'Search', onTap: RouteManagement.goToSearch),
        ],
      ),
      body: GetBuilder<UploadController>(
        id: updateId,
        initState: (_) {
          Utility.setWebTitle('Upload CSV - YouTube Automation');
        },
        builder: (controller) {
          if (controller.selectedFiles.isNotEmpty) {
            return const _Body();
          }
          return Stack(
            alignment: Alignment.center,
            children: [
              DropzoneView(
                operation: DragOperation.copy,
                cursor: CursorType.auto,
                mime: AppConstants.csvMimes,
                onCreated: (ctrl) => controller.dropzoneController = ctrl,
                onError: (ev) {
                  Utility.showInfoDialog(
                    ResponseModel.error('Error while uploading file(s) $ev'),
                  );
                },
                onDropFiles: controller.uploadFiles,
                onDropInvalid: (ev) {
                  Utility.showInfoDialog(
                    ResponseModel.error('File type not supported. Please upload a CSV file.'),
                  );
                },
                onHover: () {
                  controller.isDropping = true;
                },
                onLeave: () {
                  controller.isDropping = false;
                },
                onLoaded: () {
                  controller.isDropping = false;
                },
              ),
              AnimatedEntryWidget(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: 800,
                    minWidth: context.width * 0.3,
                    maxHeight: 300,
                    minHeight: 250,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: TapHandler(
                      onTap: controller.openFilePicker,
                      showArrowCursor: true,
                      child: Obx(
                        () => DecoratedBox(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: controller.isDropping ? AppColors.primary : AppColors.cardDark,
                              width: 2,
                            ),
                          ),
                          child: Center(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                DecoratedBox(
                                  decoration: BoxDecoration(
                                    color: controller.isDropping ? AppColors.primary : AppColors.primary.withValues(alpha: 0.2),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.all(16.0),
                                    child: Icon(
                                      Icons.file_upload_outlined,
                                      size: 32,
                                      color: controller.isDropping ? Colors.white : AppColors.primary,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                AppText(
                                  'Upload CSV file',
                                  style: context.textTheme.titleMedium?.withTitleColor,
                                ),
                                const SizedBox(height: 4),
                                AppText(
                                  'Drag and drop or click to select a CSV file',
                                  style: context.textTheme.bodyMedium?.withBodyColor,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _Body extends StatelessWidget {
  const _Body();

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
        padding: EdgeInsets.symmetric(
          horizontal: context.width * 0.02,
          vertical: 12,
        ),
        child: GetBuilder<UploadController>(
          id: UploadView.updateId,
          builder: (controller) => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                spacing: 12,
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        spacing: 12,
                        children: controller.selectedFiles
                            .map(
                              (e) => DecoratedBox(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(8),
                                  color: AppColors.cardDark,
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Flexible(
                                        child: AppText(
                                          (e is DropzoneFileInterface ? e.name : (e as File).name).substring(
                                            0,
                                            (e is DropzoneFileInterface ? e.name : (e as File).name).length.clamp(0, 30),
                                          ),
                                          style: context.textTheme.labelMedium?.withTitleColor,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      TapHandler(
                                        showArrowCursor: true,
                                        onTap: () => controller.removeFile(e),
                                        child: const DecoratedBox(
                                          decoration: BoxDecoration(
                                            color: Colors.red,
                                            shape: BoxShape.circle,
                                          ),
                                          child: Padding(
                                            padding: EdgeInsets.all(2.0),
                                            child: Icon(
                                              Icons.close_rounded,
                                              size: 16,
                                            ),
                                          ),
                                        ),
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
                  AppButton.small(
                    label: 'Clear Files',
                    color: AppColors.backgroundDark,
                    borderColor: AppColors.cardDark,
                    onTap: controller.clearFiles,
                  ),
                  AppButton.small(
                    label: 'Add file',
                    icon: Icons.add_rounded,
                    color: AppColors.cardDark,
                    onTap: controller.openFilePicker,
                  ),
                ],
              ),
              const SizedBox(height: 24),
              SizedBox(
                height: context.height * 0.7,
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.max,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      AppText(
                        '${controller.validChannelIdsCount} valid channel IDs detected',
                        style: context.textTheme.titleLarge?.withTitleColor,
                      ),
                      const SizedBox(height: 24),
                      if (controller.validChannelIdsCount > 0)
                        AppButton.small(
                          label: 'Process Channels',
                          onTap: controller.fetchDetails,
                        )
                      else
                        AppText(
                          'No valid channel IDs found. Please check your CSV file format.',
                          style: context.textTheme.bodyMedium?.withBodyColor,
                          textAlign: TextAlign.center,
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      );
}
