import 'dart:convert';
import 'dart:typed_data';

import 'package:csv/csv.dart';
import 'package:file_saver/file_saver.dart';
import 'package:flutter/material.dart';
import 'package:frontend/controllers/controllers.dart';
import 'package:frontend/models/models.dart';
import 'package:frontend/utils/utils.dart';
import 'package:frontend/view_models/view_models.dart';
import 'package:frontend/views/views.dart';
import 'package:get/get.dart';

class DashboardController extends GetxController {
  DashboardController(this._viewModel);
  final DashboardViewModel _viewModel;

  AnalysisController get _analyticsController => Get.find();

  var fetchedResult = false;

  var videos = <VideoModel>[];

  var tableController = ScrollController();

  var searchController = TextEditingController();

  final Rx<ChannelBy> _channelBy = ChannelBy.username.obs;
  ChannelBy get channelBy => _channelBy.value;
  set channelBy(ChannelBy value) => _channelBy.value = value;

  void onChannelByChanged(ChannelBy? value) {
    channelBy = value!;
    searchController.clear();
    update([DashboardView.updateId]);
  }

  void getVideos() async {
    if (searchController.text.trim().isEmpty) {
      return;
    }
    var userNames = searchController.text
        .trim()
        .replaceAll('@', '')
        .replaceAll(',', ' ')
        .replaceAll('  ', ' ')
        .trim()
        .split(' ')
        .map(
          (e) => e.trim(),
        )
        .toList();

    if (userNames.isEmpty) {
      return;
    }

    videos = await _viewModel.getVideos(
      userNames,
      channelBy == ChannelBy.channelId,
    );
    fetchedResult = true;
    analyzeData();
    update([DashboardView.updateId]);
  }

  void analyzeData() async {
    Utility.showLoader('Analzing data');
    var titles = <Future<String?>>[];
    var names = <Future<String?>>[];
    for (var video in videos) {
      titles.add(_analyticsController.analyzeTitle(video.latestVideoTitle));
      names.add(_analyticsController.analyzeName(video.userName, video.description));
    }
    final output = await Future.wait([
      Future.wait(titles),
      Future.wait(names),
    ]);
    final analyzedTitles = output[0];
    final analyzedNames = output[1];
    for (var i = 0; i < videos.length; i++) {
      videos[i] = videos[i].copyWith(
        analyzedTitle: analyzedTitles[i],
        analyzedName: analyzedNames[i],
      );
    }
    Utility.closeLoader();
    update([DashboardView.updateId]);
  }

  // Download and save CSV to your Device
  void downloadCSV() async {
    Utility.showLoader();
    String file = const ListToCsvConverter().convert(
      [
        [
          'Channel Name',
          'UserName',
          'Analyzed Name',
          'Channel Link',
          'Channel Description',
          'Subscriber Count',
          'Total Videos',
          'Total Videos Last Month',
          'Latest Video Title',
          'Analyzed Title',
          'Last Upload Date',
          'Uploaded this Month?',
        ],
        ...videos.map((e) => e.properties.toList()),
      ],
    );

    Uint8List bytes = Uint8List.fromList(utf8.encode(file));

    await FileSaver.instance.saveFile(
      name: 'videos-${DateTime.now()}',
      bytes: bytes,
      ext: 'csv',
      mimeType: MimeType.csv,
    );
    Utility.closeLoader();
  }
}
