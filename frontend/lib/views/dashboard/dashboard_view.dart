import 'package:davi/davi.dart';
import 'package:flutter/material.dart';
import 'package:frontend/controllers/controllers.dart';
import 'package:frontend/models/models.dart';
import 'package:frontend/res/res.dart';
import 'package:frontend/utils/utils.dart';
import 'package:frontend/widgets/widgets.dart';
import 'package:get/get.dart';

class DashboardView extends StatelessWidget {
  const DashboardView({super.key});

  static const String route = AppRoutes.dashboard;

  static const String updateId = 'dashboard-view';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: context.width * 0.05,
          vertical: 24,
        ),
        child: GetBuilder<DashboardController>(
          id: updateId,
          builder: (controller) {
            return Center(
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Flexible(
                        child: InputField(
                          hint: 'usernames must be separated by comma or space',
                          controller: controller.searchController,
                          onFieldSubmitted: (_) => Get.find<DashboardController>().getVideos(),
                        ),
                      ),
                      const SizedBox(width: 8),
                      FloatingActionButton(
                        onPressed: Get.find<DashboardController>().getVideos,
                        elevation: 0,
                        child: const Icon(Icons.search),
                      ),
                      if (controller.videos.isNotEmpty) ...[
                        const SizedBox(width: 16),
                        ElevatedButton(
                          onPressed: Get.find<DashboardController>().downloadCSV,
                          child: const Text('Download csv'),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (controller.videos.isEmpty) ...[
                    Text(
                      controller.fetchedResult ? 'No videos found for "${controller.searchController.text.trim()}"' : 'Search to see results',
                      textAlign: TextAlign.center,
                      style: context.textTheme.headlineSmall?.withTitleColor,
                    ),
                  ] else ...[
                    Text(
                      '${controller.videos.length} result(s)',
                      textAlign: TextAlign.center,
                      style: context.textTheme.bodyMedium?.withTitleColor,
                    ),
                    const SizedBox(height: 16),
                    Flexible(child: buildTable(context, controller.videos)),
                  ],
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget buildTable(BuildContext context, List<VideoModel> videos) {
    var tableModel = DaviModel<VideoModel>(
      rows: videos,
      multiSortEnabled: true,
      columns: [
        DaviColumn(
          name: 'Subscriber Count',
          intValue: (row) => row.subscriberCount,
          cellAlignment: Alignment.centerRight,
        ),
        DaviColumn(
          name: 'Total Videos',
          intValue: (row) => row.totalVideos,
          cellAlignment: Alignment.centerRight,
        ),
        DaviColumn(
          name: 'Channel Name',
          stringValue: (row) => row.channelName,
        ),
        DaviColumn(
          name: 'Username',
          stringValue: (row) => row.userName,
        ),
        DaviColumn(
          name: 'Total Videos Last Month',
          intValue: (row) => row.totalVideosLastMonth,
          cellAlignment: Alignment.centerRight,
        ),
        DaviColumn(
          name: 'Latest Video Title',
          stringValue: (row) => row.latestVideoTitle,
          grow: 3,
        ),
        DaviColumn(
          name: 'Last Upload Date',
          objectValue: (row) => row.lastUploadDate,
        ),
        DaviColumn(
          name: 'Uploaded this Month?',
          objectValue: (row) => row.uploadedThisMonth,
          cellAlignment: Alignment.center,
        ),
      ],
    );
    return DaviTheme(
      data: DaviThemeData(
        header: const HeaderThemeData(
          color: AppColors.primary,
        ),
        headerCell: HeaderCellThemeData(
          alignment: Alignment.center,
          textStyle: context.textTheme.titleSmall?.withTitleColor,
        ),
        row: RowThemeData(
          color: (_) => AppColors.cardDark,
          hoverForeground: (_) => AppColors.primary.withOpacity(.2),
          fillHeight: true,
        ),
        cell: CellThemeData(
          textStyle: context.textTheme.bodyMedium?.withTitleColor,
        ),
      ),
      child: Davi<VideoModel>(
        tableModel,
        columnWidthBehavior: ColumnWidthBehavior.fit,
        visibleRowsCount: videos.length,
      ),
    );
  }
}
