import 'package:flutter/material.dart';
import 'package:frontend/controllers/controllers.dart';
import 'package:frontend/main.dart';
import 'package:frontend/models/models.dart';
import 'package:frontend/res/res.dart';
import 'package:frontend/utils/utils.dart';
import 'package:frontend/view_models/view_models.dart';
import 'package:frontend/views/views.dart';
import 'package:get/get.dart';

class SearchController extends GetxController {
  SearchController(this._viewModel);
  final SearchViewModel _viewModel;

  var fetchedResult = false;

  var channels = <ChannelModel>[];

  var pageToken = '';

  var tableController = ScrollController();

  var searchController = TextEditingController();

  void triggerInLoop() async {
    for (var i = 0; i < 7; i++) {
      var gotData = await search(true);
      if (!gotData) {
        break;
      }
    }
    fetchDetails();
  }

  Future<bool> search([bool pagination = false]) async {
    if (searchController.text.trim().isEmpty) {
      return false;
    }
    if (!pagination) {
      channels.clear();
      pageToken = '';
    }

    var res = await _viewModel.searchChannels(
      query: searchController.text.trim(),
      pageToken: pageToken,
      variant: kVariant,
    );
    channels.addAll(res.$1);
    pageToken = res.$2;
    fetchedResult = true;
    update([SearchView.updateId]);
    return res.$1.isNotEmpty && res.$2.isNotEmpty;
  }

  // Download and save CSV to your Device
  void downloadCSV() async {
    Utility.showLoader();
    Utility.downloadCSV(
      data: [
        [
          'Channel Name',
          'Channel Link',
          'Channel Id',
          'Title',
          'Channel Description',
        ],
        ...channels.map((e) => e.properties.toList()),
      ],
      filename: 'channels',
    );
  }

  void fetchDetails() async {
    var list = channels.map((e) => e.channelId).toList();
    var parameters = {'q': list.encrypt()};
    RouteManagement.goToDashboard(parameters);
    if (Get.isRegistered<DashboardController>()) {
      Get.find<DashboardController>().fetchChannels();
    }
  }
}
