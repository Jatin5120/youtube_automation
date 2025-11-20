import 'package:davi/davi.dart';
import 'package:flutter/material.dart' hide SearchController;
import 'package:frontend/controllers/controllers.dart';
import 'package:frontend/models/models.dart';
import 'package:frontend/res/res.dart';
import 'package:frontend/utils/utils.dart';
import 'package:frontend/widgets/widgets.dart';
import 'package:get/get.dart';

class SearchView extends StatelessWidget {
  const SearchView({super.key});

  static const String route = AppRoutes.search;

  static const String updateId = 'search-view';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const AppHeader(
        label: 'Search',
        buttons: [
          (label: 'Dashboard', onTap: RouteManagement.goToDashboard),
        ],
      ),
      body: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: context.width * 0.05,
          vertical: 24,
        ),
        child: GetBuilder<SearchController>(
          id: updateId,
          builder: (controller) {
            return Center(
              child: Column(
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: InputField(
                          hint: 'Enter your query to search channels',
                          controller: controller.searchController,
                          onFieldSubmitted: (_) => controller.search(),
                        ),
                      ),
                      const SizedBox(width: 16),
                      SizedBox(
                        width: 80,
                        child: AppButton(
                          onTap: controller.search,
                          label: 'Search',
                        ),
                      ),
                      if (controller.channels.isNotEmpty) ...[
                        const SizedBox(width: 16),
                        AppButton.small(
                          onTap: controller.downloadCSV,
                          label: 'Download csv',
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 16),
                  Flexible(
                    child: SingleChildScrollView(
                      child: Column(
                        children: [
                          if (controller.channels.isEmpty) ...[
                            SizedBox(
                              height: context.height * 0.8,
                              child: Center(
                                child: Text(
                                  controller.fetchedResult
                                      ? 'No videos found for "${controller.searchController.text.trim()}"'
                                      : 'Search to see results',
                                  textAlign: TextAlign.center,
                                  style: context.textTheme.headlineSmall?.withTitleColor,
                                ),
                              ),
                            ),
                          ] else ...[
                            Text(
                              '10 sample results out of ${controller.channels.length} result(s)',
                              textAlign: TextAlign.center,
                              style: context.textTheme.bodyMedium?.withTitleColor,
                            ),
                            const SizedBox(height: 16),
                            _ChannelTable(channels: controller.channels),
                            const SizedBox(height: 16),
                            AppButton.small(
                              onTap: controller.triggerInLoop,
                              label: 'Fetch Details',
                            ),
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
}

class _ChannelTable extends StatelessWidget {
  const _ChannelTable({required this.channels});
  final List<ChannelModel> channels;

  @override
  Widget build(BuildContext context) {
    var tableModel = DaviModel<ChannelModel>(
      rows: channels.take(10).toList(),
      multiSortEnabled: true,
      columns: [
        DaviColumn(
          name: 'Channel Name',
          cellValue: (row) => row.data.channelName,
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
          name: 'Channel Id',
          cellValue: (row) => row.data.channelId,
        ),
        DaviColumn(
          name: 'Channel Description',
          cellValue: (row) => row.data.channelDescription,
          grow: 2,
        ),
      ],
    );
    return DaviTheme(
      data: AppTheme.daviTheme,
      child: Davi<ChannelModel>(
        tableModel,
        columnWidthBehavior: ColumnWidthBehavior.fit,
        visibleRowsCount: channels.take(10).length,
        unpinnedHorizontalScrollController: Get.find<SearchController>().tableController,
      ),
    );
  }
}
