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
      appBar: const AppHeader(
        label: 'Dashboard',
        button1: (label: 'Search', onTap: RouteManagement.goToSearch),
        button2: (label: 'Analyze', onTap: RouteManagement.goToAnalysis),
        button3: (label: 'Messages', onTap: RouteManagement.goToMessages),
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
                          hint: controller.channelBy.inputHint,
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
                  Flexible(
                    child: SingleChildScrollView(
                      child: Column(
                        children: [
                          if (controller.videos.isEmpty) ...[
                            Text(
                              controller.fetchedResult ? 'No videos found for ${controller.searchCount} Channels' : 'Search to see results',
                              textAlign: TextAlign.center,
                              style: context.textTheme.headlineSmall?.withTitleColor,
                            ),
                          ] else ...[
                            Text(
                              'Total ${controller.videos.length} video(s) found',
                              textAlign: TextAlign.center,
                              style: context.textTheme.bodyMedium?.withTitleColor,
                            ),
                            if (controller.parsedVideos.isEmpty) ...[
                              Text(
                                '0 relavant filtered results',
                                textAlign: TextAlign.center,
                                style: context.textTheme.bodyMedium?.withTitleColor,
                              ),
                            ] else ...[
                              Text(
                                '10 sample results out of ${controller.parsedVideos.length} filtered result(s)',
                                textAlign: TextAlign.center,
                                style: context.textTheme.bodyMedium?.withTitleColor,
                              ),
                              const SizedBox(height: 16),
                              buildTable(context, controller.parsedVideos),
                              const SizedBox(height: 16),
                              Obx(
                                () => controller.isAnalyzing
                                    ? Column(
                                        mainAxisSize: MainAxisSize.min,
                                        crossAxisAlignment: CrossAxisAlignment.center,
                                        children: [
                                          Text(
                                            'This is gonna take some time, so sit back and relax',
                                            style: context.textTheme.bodyLarge?.withTitleColor,
                                          ),
                                          const SizedBox(height: 16),
                                          LinearProgressIndicator(
                                            value: controller.analyzeProgress,
                                            color: Colors.deepOrange,
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            'Analyzed ${(controller.analyzeProgress * 100).toStringAsFixed(2)}%',
                                            style: context.textTheme.bodyLarge?.withTitleColor,
                                          ),
                                        ],
                                      )
                                    : AppButton.small(
                                        onTap: controller.analyzeData,
                                        label: 'Analysis Data & Download',
                                      ),
                              ),
                            ],
                          ],
                        ],
                      ),
                    ),
                  ),
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
      rows: videos.take(10).toList(),
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
          name: 'Total Videos Last 3 Months',
          intValue: (row) => row.totalVideosLastThreeMonths,
          cellAlignment: Alignment.centerRight,
        ),
        DaviColumn(
          name: 'Latest Video Title',
          stringValue: (row) => row.latestVideoTitle,
          grow: 2,
        ),
        DaviColumn(
          name: 'Last Upload Date',
          stringValue: (row) => DateFormat('yyyy MMM dd, hh:mm:ss').format(row.lastUploadDate),
        ),
        DaviColumn(
          name: 'Channel Country',
          stringValue: (row) => row.country,
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
        visibleRowsCount: videos.take(10).length,
        unpinnedHorizontalScrollController: Get.find<DashboardController>().tableController,
      ),
    );
  }
}
