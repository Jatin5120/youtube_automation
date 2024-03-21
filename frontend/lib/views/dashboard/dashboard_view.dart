import 'package:davi/davi.dart';
import 'package:flutter/material.dart';
import 'package:frontend/controllers/controllers.dart';
import 'package:frontend/models/models.dart';
import 'package:frontend/res/res.dart';
import 'package:frontend/utils/utils.dart';
import 'package:frontend/widgets/widgets.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

class DashboardView extends StatelessWidget {
  const DashboardView({super.key});

  static const String route = AppRoutes.dashboard;

  static const String updateId = 'dashboard-view';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        elevation: 0,
        centerTitle: true,
        backgroundColor: AppColors.backgroundDark,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: ElevatedButton(
              onPressed: () => Get.offNamed(AppRoutes.search),
              child: const Text('Search'),
            ),
          ),
          Padding(
            padding: EdgeInsets.only(right: context.width * 0.05),
            child: ElevatedButton(
              onPressed: () => Get.offNamed(AppRoutes.analysis),
              child: const Text('Analyze'),
            ),
          ),
        ],
      ),
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
                  Row(
                    children: [
                      Flexible(
                        child: InputField(
                          hint: '${controller.channelBy.label} must be separated by comma or space',
                          controller: controller.searchController,
                          onFieldSubmitted: (_) => controller.getVideos(),
                        ),
                      ),
                      const SizedBox(width: 8),
                      FloatingActionButton(
                        onPressed: controller.getVideos,
                        elevation: 0,
                        child: const Icon(Icons.search),
                      ),
                      if (controller.videos.isNotEmpty) ...[
                        const SizedBox(width: 16),
                        ElevatedButton(
                          onPressed: controller.downloadCSV,
                          child: const Text('Download csv'),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: ChannelBy.values
                        .map((e) => Flexible(
                              child: RadioListTile(
                                value: e,
                                groupValue: controller.channelBy,
                                title: Text(
                                  e.label,
                                  style: context.textTheme.titleMedium?.withTitleColor,
                                ),
                                onChanged: controller.onChannelByChanged,
                              ),
                            ))
                        .toList(),
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
          name: 'Channel Name',
          stringValue: (row) => row.channelName,
        ),
        DaviColumn(
          name: 'UserName',
          stringValue: (row) => row.userName,
        ),
        DaviColumn(
          name: 'Analyzed Name',
          stringValue: (row) => row.analyzedName,
        ),
        DaviColumn(
          name: 'Channel Link',
          cellBuilder: (context, row) => TapHandler(
            onTap: () => Utility.launchURL(row.data.channelLink),
            child: AppText(
              row.data.channelLink,
              style: context.textTheme.bodyMedium?.withTitleColor.copyWith(
                decoration: TextDecoration.underline,
                decorationColor: AppColors.titleDark,
              ),
              isSelectable: false,
            ),
          ),
          grow: 2,
        ),
        DaviColumn(
          name: 'Channel Description',
          stringValue: (row) => row.description,
          grow: 2,
        ),
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
          name: 'Total Videos Last Month',
          intValue: (row) => row.totalVideosLastMonth,
          cellAlignment: Alignment.centerRight,
        ),
        DaviColumn(
          name: 'Latest Video Title',
          stringValue: (row) => row.latestVideoTitle,
          grow: 2,
        ),
        DaviColumn(
          name: 'Analyzed Title',
          stringValue: (row) => row.analyzedTitle,
          grow: 2,
        ),
        DaviColumn(
          name: 'Last Upload Date',
          stringValue: (row) => DateFormat('yyyy MMM dd, hh:mm:ss').format(row.lastUploadDate),
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
        columnWidthBehavior: ColumnWidthBehavior.scrollable,
        visibleRowsCount: videos.length,
        unpinnedHorizontalScrollController: Get.find<DashboardController>().tableController,
      ),
    );
  }
}
