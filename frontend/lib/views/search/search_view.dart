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
      appBar: AppBar(
        title: const Text('Search'),
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
                          hint: 'Enter your query to search',
                          controller: controller.searchController,
                          onFieldSubmitted: (_) => controller.search(),
                        ),
                      ),
                      const SizedBox(width: 8),
                      FloatingActionButton(
                        onPressed: controller.search,
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
                    ElevatedButton(
                      onPressed: controller.fetchDetails,
                      child: const Text('Fetch Details'),
                    ),
                    const SizedBox(height: 16),
                    Flexible(child: buildTable(context, controller.channels)),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => controller.search(true),
                      child: const Text('Load more'),
                    ),
                  ],
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget buildTable(BuildContext context, List<ChannelModel> channels) {
    var tableModel = DaviModel<ChannelModel>(
      rows: channels,
      multiSortEnabled: true,
      columns: [
        DaviColumn(
          name: 'Channel Name',
          stringValue: (row) => row.channelName,
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
          name: 'Channel Id',
          stringValue: (row) => row.channelId,
        ),
        DaviColumn(
          name: 'Title',
          stringValue: (row) => row.title,
        ),
        DaviColumn(
          name: 'Channel Description',
          stringValue: (row) => row.description,
          grow: 2,
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
      child: Davi<ChannelModel>(
        tableModel,
        columnWidthBehavior: ColumnWidthBehavior.fit,
        visibleRowsCount: channels.length,
        unpinnedHorizontalScrollController: Get.find<SearchController>().tableController,
      ),
    );
  }
}
