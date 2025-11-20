import 'dart:math';

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
        buttons: [
          (label: 'Search', onTap: RouteManagement.goToSearch),
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
                  const SizedBox(height: 16),
                  Flexible(
                    child: SingleChildScrollView(
                      child: Obx(() {
                        if (controller.isLoadingVideos) {
                          return _buildLoadingState(context, controller);
                        } else if (controller.isProcessingData) {
                          return _buildProcessingState(context, controller);
                        } else if (controller.channels.isEmpty) {
                          return _buildEmptyState(context, controller);
                        } else {
                          return _buildResultsState(context, controller);
                        }
                      }),
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

  Widget buildTable(BuildContext context, List<ChannelDetailsModel> channels) {
    var tableModel = DaviModel<ChannelDetailsModel>(
      rows: channels.take(10).toList(),
      multiSortEnabled: true,
      columns: [
        DaviColumn(
          name: 'Channel Name',
          cellValue: (row) => row.data.channelName,
        ),
        DaviColumn(
          name: 'UserName',
          cellValue: (row) => row.data.userName,
        ),
        DaviColumn(
          name: 'Channel Link',
          cellWidget: (row) => TapHandler(
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
          cellValue: (row) => row.data.channelDescription,
          grow: 2,
        ),
        DaviColumn(
          name: 'Subscriber Count',
          cellValue: (row) => row.data.subscriberCount,
          cellAlignment: Alignment.centerRight,
        ),
        DaviColumn(
          name: 'Total Videos',
          cellValue: (row) => row.data.totalVideos,
          cellAlignment: Alignment.centerRight,
        ),
        DaviColumn(
          name: 'Total Videos Last Month',
          cellValue: (row) => row.data.totalVideosLastMonth,
          cellAlignment: Alignment.centerRight,
        ),
        // DaviColumn(
        //   name: 'Total Videos Last 3 Months',
        //   cellValue: (row) => row.data.totalVideosLastThreeMonths,
        //   cellAlignment: Alignment.centerRight,
        // ),
        DaviColumn(
          name: 'Latest Video Title',
          cellValue: (row) => row.data.latestVideoTitle,
          grow: 2,
        ),
        DaviColumn(
          name: 'Last Upload Date',
          cellValue: (row) => DateFormat('yyyy MMM dd, hh:mm:ss').format(
            row.data.lastUploadDate ?? DateTime.now(),
          ),
        ),
        DaviColumn(
          name: 'Channel Country',
          cellValue: (row) => row.data.country,
          cellAlignment: Alignment.center,
        ),
      ],
    );
    return DaviTheme(
      data: AppTheme.daviTheme,
      child: Davi<ChannelDetailsModel>(
        tableModel,
        columnWidthBehavior: ColumnWidthBehavior.scrollable,
        visibleRowsCount: channels.take(10).length,
        unpinnedHorizontalScrollController: Get.find<DashboardController>().tableController,
      ),
    );
  }

  Widget _buildLoadingState(BuildContext context, DashboardController controller) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const SizedBox(height: 40),
        const AppLoader(),
        const SizedBox(height: 16),
        Text(
          controller.loadingMessage.isNotEmpty ? controller.loadingMessage : 'Loading channel data...',
          textAlign: TextAlign.center,
          style: context.textTheme.titleMedium?.withTitleColor,
        ),
        if (controller.retryCount > 0) ...[
          const SizedBox(height: 8),
          Text(
            'Retry attempt ${controller.retryCount}',
            textAlign: TextAlign.center,
            style: context.textTheme.bodySmall?.withTitleColor,
          ),
        ],
        const SizedBox(height: 40),
      ],
    );
  }

  Widget _buildProcessingState(BuildContext context, DashboardController controller) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const SizedBox(height: 40),
        const AppLoader(),
        const SizedBox(height: 16),
        Text(
          controller.loadingMessage.isNotEmpty ? controller.loadingMessage : 'Processing data...',
          textAlign: TextAlign.center,
          style: context.textTheme.titleMedium?.withTitleColor,
        ),
        const SizedBox(height: 8),
        Text(
          'Found ${controller.channels.length} channels, filtering results...',
          textAlign: TextAlign.center,
          style: context.textTheme.bodySmall?.withTitleColor,
        ),
        const SizedBox(height: 40),
      ],
    );
  }

  Widget _buildEmptyState(BuildContext context, DashboardController controller) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const SizedBox(height: 40),
        Icon(
          Icons.search,
          size: 64,
          color: AppColors.titleDark.withValues(alpha: 0.5),
        ),
        const SizedBox(height: 16),
        Text(
          controller.fetchedResult ? 'No videos found for ${controller.searchCount} channels' : 'Search to see results',
          textAlign: TextAlign.center,
          style: context.textTheme.headlineSmall?.withTitleColor,
        ),
        const SizedBox(height: 8),
        Text(
          controller.fetchedResult
              ? 'Try adjusting your search criteria or check if the channels exist'
              : 'Enter channel names or IDs separated by commas',
          textAlign: TextAlign.center,
          style: context.textTheme.bodyMedium?.withTitleColor,
        ),
        const SizedBox(height: 40),
      ],
    );
  }

  Widget _buildResultsState(BuildContext context, DashboardController controller) {
    return Column(
      children: [
        Text(
          'Total ${controller.channels.length} channel(s) found',
          textAlign: TextAlign.center,
          style: context.textTheme.bodyMedium?.withTitleColor,
        ),
        if (controller.parsedChannels.isEmpty) ...[
          Text(
            '0 relevant filtered results',
            textAlign: TextAlign.center,
            style: context.textTheme.bodyMedium?.withTitleColor,
          ),
        ] else ...[
          Text(
            '${min(10, controller.parsedChannels.length)} sample results out of ${controller.parsedChannels.length} filtered result(s)',
            textAlign: TextAlign.center,
            style: context.textTheme.bodyMedium?.withTitleColor,
          ),
          const SizedBox(height: 16),
          buildTable(context, controller.parsedChannels),
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
                    label: 'Analyze Data & Download',
                  ),
          ),
        ],
      ],
    );
  }
}
