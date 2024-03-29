import 'dart:convert';
import 'dart:typed_data';

import 'package:csv/csv.dart';
import 'package:file_saver/file_saver.dart';
import 'package:flutter/material.dart';
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

  var tableController = ScrollController();

  var searchController = TextEditingController();

  void search() async {
    if (searchController.text.trim().isEmpty) {
      return;
    }

    channels = await _viewModel.searchChannels(searchController.text.trim());
    fetchedResult = true;
    update([SearchView.updateId]);
  }

  // Download and save CSV to your Device
  void downloadCSV() async {
    Utility.showLoader();
    String file = const ListToCsvConverter().convert(
      [
        [
          'Channel Name',
          'Channel Link',
          'Channel Id',
          'Title',
          'Channel Description',
        ],
        ...channels.map((e) => e.properties.toList()),
      ],
    );

    Uint8List bytes = Uint8List.fromList(utf8.encode(file));

    await FileSaver.instance.saveFile(
      name: 'channels-${DateTime.now()}',
      bytes: bytes,
      ext: 'csv',
      mimeType: MimeType.csv,
    );
    Utility.closeLoader();
  }

  void fetchDetails() async {
    var list = channels.map((e) => e.channelId).toList();
    var parameters = {'q': list.encrypt()};
    Get.toNamed(
      AppRoutes.dashboard,
      parameters: parameters,
    );
  }
}
