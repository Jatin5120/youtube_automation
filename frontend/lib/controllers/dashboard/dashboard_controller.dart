import 'dart:convert';
import 'dart:typed_data';

import 'package:csv/csv.dart';
import 'package:file_saver/file_saver.dart';
import 'package:flutter/material.dart';
import 'package:frontend/models/models.dart';
import 'package:frontend/utils/utils.dart';
import 'package:frontend/view_models/view_models.dart';
import 'package:frontend/views/views.dart';
import 'package:get/get.dart';

class DashboardController extends GetxController {
  DashboardController(this._viewModel);
  final DashboardViewModel _viewModel;

  var fetchedResult = false;

  var videos = <VideoModel>[];

  var searchController = TextEditingController();

  void getVideos() async {
    if (searchController.text.trim().isEmpty) {
      return;
    }
    var userNames = searchController.text.trim().split(',').join(' ').split(' ').map((e) => e.trim()).toList();
    videos = await _viewModel.getVideos(userNames);
    fetchedResult = true;
    update([DashboardView.updateId]);
  }

  // Download and save CSV to your Device
  void downloadCSV() async {
    Utility.showLoader();
    String file = const ListToCsvConverter().convert(
      [
        [
          'Subscriber Count',
          'Total Videos',
          'Channel Name',
          'Username',
          'Total Videos Last Month',
          'Latest Video Title',
          'Last Upload Date',
          'Uploaded this Month?',
        ],
        ...videos.map((e) => e.properties.toList()),
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
}
