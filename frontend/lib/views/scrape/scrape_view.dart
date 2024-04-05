import 'package:davi/davi.dart';
import 'package:flutter/material.dart';
import 'package:frontend/controllers/controllers.dart';
import 'package:frontend/models/models.dart';
import 'package:frontend/res/res.dart';
import 'package:frontend/utils/utils.dart';
import 'package:frontend/widgets/widgets.dart';
import 'package:get/get.dart';

class ScrapeView extends StatelessWidget {
  const ScrapeView({super.key});

  static const String route = AppRoutes.scrape;

  static const String updateId = 'scrape-view';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scrape'),
        elevation: 0,
        centerTitle: true,
        backgroundColor: AppColors.backgroundDark,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: ElevatedButton(
              onPressed: () => Get.offNamed(AppRoutes.dashboard),
              child: const Text('Dashboard'),
            ),
          ),
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
        child: GetBuilder<ScrapeController>(
          id: updateId,
          builder: (controller) {
            return Center(
              child: Column(
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: InputField(
                          hint: ChannelBy.url.inputHint,
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
                      if (controller.channels.isNotEmpty) ...[
                        const SizedBox(width: 16),
                        ElevatedButton(
                          onPressed: controller.downloadCSV,
                          child: const Text('Download csv'),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (controller.channels.isEmpty) ...[
                    Text(
                      controller.fetchedResult ? 'No videos found for "${controller.searchController.text.trim()}"' : 'Search to see results',
                      textAlign: TextAlign.center,
                      style: context.textTheme.headlineSmall?.withTitleColor,
                    ),
                  ] else ...[
                    Text(
                      '${controller.channels.length} result(s)',
                      textAlign: TextAlign.center,
                      style: context.textTheme.bodyMedium?.withTitleColor,
                    ),
                    const SizedBox(height: 16),
                    Flexible(child: buildTable(context, controller.channels)),
                  ],
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget buildTable(BuildContext context, List<ScrapeModel> channels) {
    var tableModel = DaviModel<ScrapeModel>(
      rows: channels,
      // multiSortEnabled: true,
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
          name: 'Subscriber Count',
          stringValue: (row) => row.subscribers,
          cellAlignment: Alignment.centerRight,
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
      child: Davi<ScrapeModel>(
        tableModel,
        visibleRowsCount: channels.length,
        columnWidthBehavior: ColumnWidthBehavior.fit,
        // unpinnedHorizontalScrollController: Get.find<ScrapeController>().tableController,
      ),
    );
  }
}
