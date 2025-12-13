import 'package:flutter/material.dart';
import 'package:frontend/app.dart';
import 'package:frontend/main.dart';
import 'package:get/get.dart';

class SearchController extends GetxController {
  SearchController(this._viewModel);
  final SearchViewModel _viewModel;

  var fetchedResult = false;

  var channels = <ChannelModel>[];

  var tableController = ScrollController();

  var searchController = TextEditingController();

  var queries = <String>[];

  var channelIdMap = <String, List<String>>{};
  var tokenMap = <String, String>{};

  void triggerSearch() async {
    Utility.showLoader();

    for (var query in queries) {
      final wasAlreadySearched = queries.indexOf(query) == 0 && channels.isNotEmpty;
      final requestsToMake = wasAlreadySearched ? AppConstants.totalSearchRequests - 1 : AppConstants.totalSearchRequests;

      for (var i = 0; i < requestsToMake; i++) {
        var gotData = await _search(
          query: query,
        );
        if (gotData.channels.isEmpty || gotData.pageToken.isEmpty) {
          break;
        }
      }
    }

    Utility.closeLoader();

    fetchDetails();
  }

  Future<ChannelSearchResult> search() async {
    queries = searchController.text
        .trim()
        .split(',')
        .map((e) => e.trim())
        .where(
          (e) => e.isNotEmpty,
        )
        .toList();

    if (queries.isEmpty) {
      return (channels: <ChannelModel>[], pageToken: '');
    }

    channels.clear();
    channelIdMap.clear();
    tokenMap.clear();

    for (var query in queries) {
      channelIdMap[query] = [];
      tokenMap[query] = '';
    }

    Utility.showLoader();

    final result = await _search(
      query: queries.first,
    );

    Utility.closeLoader();

    return result;
  }

  Future<ChannelSearchResult> _search({
    required String query,
  }) async {
    if (query.trim().isEmpty) {
      return (channels: <ChannelModel>[], pageToken: '');
    }

    var res = await _viewModel.searchChannels(
      query: query.trim(),
      pageToken: tokenMap[query] ?? '',
      variant: kVariant,
    );

    channels.addAll(res.channels);

    channelIdMap[query]?.addAll(res.channels.map((e) => e.channelId).toList());
    tokenMap[query] = res.pageToken;

    fetchedResult = true;

    update([SearchView.updateId]);
    return res;
  }

  // Download and save CSV to your Device
  void downloadCSV() async {
    Utility.showLoader();
    Utility.downloadCSV(
      data: [
        [
          'Query',
          'Channel Id',
          'Channel Name',
          'Channel Link',
          'Channel Description',
        ],
        ...channels.map((e) => e.properties.toList()),
      ],
      filename: 'channels',
    );
  }

  void fetchDetails() async {
    Get.find<DbClient>().save(LocalKeys.queriesChannels, channelIdMap);
    RouteManagement.goToDashboard();
    if (Get.isRegistered<DashboardController>()) {
      Get.find<DashboardController>().fetchChannels();
    }
  }
}
