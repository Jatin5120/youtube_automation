import 'dart:convert';
import 'dart:typed_data';

import 'package:csv/csv.dart';
import 'package:file_saver/file_saver.dart';
import 'package:flutter/material.dart';
import 'package:frontend/controllers/controllers.dart';
import 'package:frontend/main.dart';
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

  final RxBool _isAnalyzing = false.obs;
  bool get isAnalyzing => _isAnalyzing.value;
  set isAnalyzing(bool value) {
    if (value == isAnalyzing) {
      return;
    }
    _isAnalyzing.value = value;
  }

  final RxDouble _analyzeProgress = 0.0.obs;
  double get analyzeProgress => _analyzeProgress.value;
  set analyzeProgress(double value) {
    if (value == analyzeProgress) {
      return;
    }
    _analyzeProgress.value = value;
  }

  @override
  void onInit() {
    super.onInit();
    var parameters = Get.parameters;
    if (parameters.isNotEmpty) {
      try {
        var list = parameters['q']?.decrypt();
        list = (list as List).cast<String>();
        Utility.updateLater(() {
          onChannelByChanged(ChannelBy.channelId);
          searchController.text = list.join(', ');
          getVideos();
        });
      } catch (e) {
        AppLog.error(e);
      }
    }
  }

  void onChannelByChanged(ChannelBy? value) {
    channelBy = value!;
    update([DashboardView.updateId]);
  }

  void getVideos() async {
    if (searchController.text.trim().isEmpty) {
      return;
    }

    videos = await _getVideosByChannelIdentifier();
    fetchedResult = true;
    parseData();
    // analyzeData();
    update([DashboardView.updateId]);
  }

  Future<List<VideoModel>> _getVideosByChannelIdentifier() async {
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
      return [];
    }
    return await _viewModel.getVideosByChannelIdentifier(
      usernames: userNames,
      useId: channelBy == ChannelBy.channelId,
      variant: kVariant,
    );
  }

  void parseData() {
    videos = videos.where((e) => e.subscriberCount > 100 && e.totalVideosLastMonth > 2 && e.totalVideosLastThreeMonths > 5).toList();
  }

  void analyzeData() async {
    isAnalyzing = true;
    for (var data in videos.indexed) {
      var video = data.$2;
      var index = data.$1;
      analyzeProgress = (index / videos.length);
      if (video.analyzedName.trim().isNotEmpty && video.analyzedTitle.trim().isNotEmpty) {
        continue;
      }
      var title = await _analyticsController.analyzeTitle(video.latestVideoTitle);
      var name = await _analyticsController.analyzeName(
        username: video.userName,
        channelName: video.channelName,
        description: video.description,
      );
      videos[index] = video.copyWith(
        analyzedTitle: title,
        analyzedName: name,
      );
    }
    analyzeProgress = 100;
    isAnalyzing = false;
    update([DashboardView.updateId]);
    downloadCSV();
  }

  // Download and save CSV to your Device
  void downloadCSV() async {
    Utility.showLoader();
    String file = const ListToCsvConverter().convert(
      [
        [
          'Analyzed Name',
          'Email',
          'Last Video Analyzed Title',
          'Channel Name',
          'Instagram',
          'LinkedIn',
          'Twitter',
          'UserName',
          'Channel Link',
          'Channel Description',
          'Subscriber Count',
          'Total Videos',
          'Total Videos Last Month',
          'Total Videos Last 3 Months',
          'Latest Video Title',
          'Last Upload Date',
          'Uploaded this Month?',
          'Channel Country',
          'isEnglish?',
          'Default Language',
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
    Utility.showInfoDialog(ResponseModel.message('Channel data is downloaded', isSuccess: true));
  }
}
