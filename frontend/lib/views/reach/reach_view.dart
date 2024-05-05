import 'package:flutter/material.dart';
import 'package:flutter_dropzone/flutter_dropzone.dart';
import 'package:frontend/controllers/controllers.dart';
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
                  child: ColoredBox(
                    color: Colors.red,
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
                ),
                const SizedBox(height: 24),
                Flexible(
                  child: ColoredBox(
                    color: Colors.yellow,
                    child: DropzoneView(
                      operation: DragOperation.copy,
                      cursor: CursorType.grab,
                      onCreated: (ctrl) => controller.dropzoneController = ctrl,
                      onLoaded: () => AppLog.info('Zone loaded'),
                      onError: (ev) => AppLog.info('Error: $ev'),
                      onHover: () => AppLog.info('Zone hovered'),
                      onDrop: (ev) => AppLog.info('Drop: $ev ${ev.runtimeType}'),
                      onDropMultiple: (ev) => AppLog.info('Drop multiple: $ev'),
                      onLeave: () => AppLog.info('Zone left'),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
