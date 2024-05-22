import 'package:flutter/widgets.dart';
import 'package:frontend/controllers/controllers.dart';
import 'package:frontend/main.dart';
import 'package:frontend/models/models.dart';
import 'package:frontend/res/res.dart';
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

  var parsedVideos = <VideoModel>[];

  var tableController = ScrollController();

  var searchController = TextEditingController();

  int get searchCount => searchController.text.trim().split(',').length;

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
    fetchChannels();
  }

  void fetchChannels() {
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
    parsedVideos = videos
        .where((e) =>
            e.subscriberCount > 100 &&
            e.totalVideosLastMonth > 2 &&
            e.totalVideosLastThreeMonths > 5 &&
            AppConstants.targetCountries.contains(e.country))
        .toList();

    parsedVideos = parsedVideos.toSet().toList();
    update([DashboardView.updateId]);
  }

  void analyzeData() async {
    isAnalyzing = true;
    for (var data in parsedVideos.indexed) {
      var video = data.$2;
      var index = data.$1;
      if (video.analyzedName.trim().isNotEmpty && video.analyzedTitle.trim().isNotEmpty) {
        continue;
      }

      var title = video.analyzedName.trim().isNotEmpty ? video.analyzedName.trim() : await _analyticsController.analyzeTitle(video.latestVideoTitle);
      await Future.delayed(const Duration(milliseconds: 300));

      analyzeProgress = (index / parsedVideos.length);

      var name = video.analyzedTitle.trim().isNotEmpty
          ? video.analyzedTitle.trim()
          : await _analyticsController.analyzeName(
              username: video.userName,
              channelName: video.channelName,
              description: video.description,
            );
      await Future.delayed(const Duration(milliseconds: 300));

      analyzeProgress = ((2 * index + 1) / (2 * parsedVideos.length));

      parsedVideos[index] = video.copyWith(
        analyzedTitle: title,
        analyzedName: name,
      );
    }
    analyzeProgress = 100;
    isAnalyzing = false;
    update([DashboardView.updateId]);
    _downloadCSV();
  }

  // Download and save CSV to your Device
  void _downloadCSV() async {
    final query = Get.isRegistered<SearchController>() ? Get.find<SearchController>().searchController.text.trim() : '';

    await Utility.downloadCSV(
      data: [
        [
          'Search Query',
          'Analyzed Name',
          'Analyzed Title',
          'Email Id',
          'Instagram',
          'LinkedIn',
          'Twitter',
          'Channel Link',
          'Channel Country',
          '',
          '',
          '',
          'Channel Name',
          'UserName',
          'Subscriber Count',
          'Total Videos',
          'Total Videos Last Month',
          'Total Videos Last 3 Months',
          'Latest Video Title',
          'Last Upload Date',
        ],
        ...parsedVideos.map((e) => [
              query,
              ...e.properties,
            ]),
      ],
      filename: 'lead-analysis',
    );
    Utility.showInfoDialog(
      ResponseModel.message('Your Lead and Analysis data is downloaded'),
      isSuccess: true,
    );
  }
}


// TODO: Data for Lead gen
/*
   
1. Search Query
2. Analyzed Name
3. Analyzed Title
4. Email Id - E
5. Twitter - E
6. LinkedIn - E
7. Instagram - E
8. Channel link
=============
-----------
Instagram username - (N/A)
Email Content
Dm Content
Status - E
Platform - E
Sent Date - E
-----------
=============
Channel Name
UserName
Subscriber Count
Total Videos
Total Videos Last Month
Total Videos Last 3 Months
Latest Video Title
Last Upload Date
Channel Country
 */
