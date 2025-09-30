import 'dart:async';

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

  // Loading states
  final RxBool _isLoadingVideos = false.obs;
  final RxBool _isProcessingData = false.obs;
  final RxString _loadingMessage = ''.obs;
  final RxInt _retryCount = 0.obs;

  bool get isLoadingVideos => _isLoadingVideos.value;
  bool get isProcessingData => _isProcessingData.value;
  String get loadingMessage => _loadingMessage.value;
  int get retryCount => _retryCount.value;

  // Request debouncing
  Timer? _debounceTimer;

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

  @override
  void onClose() {
    _debounceTimer?.cancel();
    super.onClose();
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

    // Cancel previous debounce timer
    _debounceTimer?.cancel();

    // Set up debounced search
    _debounceTimer = Timer(const Duration(milliseconds: 500), () async {
      await _performSearch();
    });
  }

  Future<void> _performSearch() async {
    // Validate input
    final validationError = _validateInput();
    if (validationError != null) {
      Utility.showInfoDialog(
        ResponseModel.message(validationError),
        title: 'Invalid Input',
      );
      return;
    }

    _isLoadingVideos.value = true;
    _loadingMessage.value = 'Fetching channel data...';
    _retryCount.value = 0;
    update([DashboardView.updateId]);

    try {
      videos = await _getVideosWithRetry();
      fetchedResult = true;
      _isProcessingData.value = true;
      _isLoadingVideos.value = false;
      _loadingMessage.value = 'Processing data...';
      update([DashboardView.updateId]);

      parseData();

      _isProcessingData.value = false;
      _isLoadingVideos.value = false;
      _loadingMessage.value = '';
      update([DashboardView.updateId]);
    } catch (e) {
      _isLoadingVideos.value = false;
      _isLoadingVideos.value = false;
      _isProcessingData.value = false;
      _loadingMessage.value = '';
      update([DashboardView.updateId]);

      Utility.showInfoDialog(
        ResponseModel.message('Failed to fetch data: ${e.toString()}'),
        title: 'Error',
      );
    }
  }

  String? _validateInput() {
    final text = searchController.text.trim();
    if (text.isEmpty) {
      return 'Please enter channel names or IDs';
    }

    final channels = text
        .replaceAll('@', '')
        .replaceAll(',', ' ')
        .replaceAll('  ', ' ')
        .trim()
        .split(' ')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();

    if (channels.isEmpty) {
      return 'Please enter valid channel names or IDs';
    }

    // Validate channel format
    for (final channel in channels) {
      if (channelBy == ChannelBy.channelId) {
        if (!_isValidChannelId(channel)) {
          return 'Invalid channel ID format: $channel';
        }
      } else {
        if (!_isValidUsername(channel)) {
          return 'Invalid username format: $channel';
        }
      }
    }

    return null;
  }

  bool _isValidChannelId(String id) {
    // YouTube channel ID format validation
    return RegExp(r'^UC[a-zA-Z0-9_-]{22}$').hasMatch(id);
  }

  bool _isValidUsername(String username) {
    // Username format validation (3-30 characters, alphanumeric and underscores)
    return RegExp(r'^[a-zA-Z0-9_]{3,30}$').hasMatch(username);
  }

  Future<List<VideoModel>> _getVideosWithRetry() async {
    const maxRetries = 3;

    for (int attempt = 0; attempt < maxRetries; attempt++) {
      try {
        _retryCount.value = attempt;
        update([DashboardView.updateId]);

        return await _getVideosByChannelIdentifier();
      } catch (e) {
        if (attempt == maxRetries - 1) {
          rethrow;
        }

        _loadingMessage.value = 'Retrying... (${attempt + 1}/$maxRetries)';
        update([DashboardView.updateId]);

        await Future.delayed(Duration(seconds: 2 * (attempt + 1)));
      }
    }

    return [];
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
    analyzeProgress = 0.0;
    update([DashboardView.updateId]);

    // Clear cache at the start of analysis to ensure fresh results
    _analyticsController.clearCache();

    // Filter videos that need analysis
    final videosToAnalyze = <int, VideoModel>{};
    for (var data in parsedVideos.indexed) {
      var video = data.$2;
      var index = data.$1;

      // Skip if both are already analyzed
      if (video.analyzedName.trim().isNotEmpty && video.analyzedTitle.trim().isNotEmpty) {
        continue;
      }

      videosToAnalyze[index] = video;
    }

    if (videosToAnalyze.isEmpty) {
      isAnalyzing = false;
      analyzeProgress = 100;
      update([DashboardView.updateId]);
      _downloadCSV();
      return;
    }

    // Process videos in parallel batches for better performance
    const batchSize = 1; // Process 5 videos at a time
    final batches = <List<MapEntry<int, VideoModel>>>[];

    final entries = videosToAnalyze.entries.toList();
    for (int i = 0; i < entries.length; i += batchSize) {
      final end = (i + batchSize < entries.length) ? i + batchSize : entries.length;
      batches.add(entries.sublist(i, end));
    }

    int completedVideos = 0;
    final totalVideos = videosToAnalyze.length;

    for (final batch in batches) {
      // Process batch in parallel
      final futures = batch.map((entry) => _analyzeVideo(entry.key, entry.value));
      final results = await Future.wait(futures);

      // Update results
      for (int i = 0; i < batch.length; i++) {
        final index = batch[i].key;
        final result = results[i];
        parsedVideos[index] = result;
        completedVideos++;
      }

      // Update progress
      analyzeProgress = completedVideos / totalVideos;
      update([DashboardView.updateId]);

      // Small delay between batches to prevent rate limiting
      if (batches.indexOf(batch) < batches.length - 1) {
        await Future.delayed(const Duration(milliseconds: 1000));
      }
    }

    analyzeProgress = 100;
    isAnalyzing = false;
    update([DashboardView.updateId]);
    _downloadCSV();
  }

  Future<VideoModel> _analyzeVideo(int index, VideoModel video) async {
    // Analyze title and name in parallel if both are needed
    final needsTitle = video.analyzedTitle.trim().isEmpty;
    final needsName = video.analyzedName.trim().isEmpty;

    if (needsTitle && needsName) {
      // Both need analysis - run in parallel
      final title = await _analyticsController.analyzeTitle(video.latestVideoTitle);

      await Future.delayed(const Duration(milliseconds: 500));

      final name = await _analyticsController.analyzeName(
        username: video.userName,
        channelName: video.channelName,
        description: video.description,
      );

      return video.copyWith(
        analyzedTitle: title ?? '',
        analyzedName: name ?? 'Team ${video.channelName}',
      );
    } else if (needsTitle) {
      // Only title needs analysis
      final title = await _analyticsController.analyzeTitle(video.latestVideoTitle);
      return video.copyWith(analyzedTitle: title ?? '');
    } else if (needsName) {
      // Only name needs analysis
      final name = await _analyticsController.analyzeName(
        username: video.userName,
        channelName: video.channelName,
        description: video.description,
      );
      return video.copyWith(analyzedName: name ?? 'Team ${video.channelName}');
    }

    // Both already analyzed
    return video;
  }

  // Download and save CSV to your Device
  void _downloadCSV() async {
    final query = Get.isRegistered<SearchController>() ? Get.find<SearchController>().searchController.text.trim() : '';

    await Utility.downloadCSV(
      data: [
        [
          'Search Query',
          'Channel Link',
          'Analyzed Name',
          'Analyzed Title',
          'Email Id',
          'Instagram',
          'LinkedIn',
          'Twitter',
          'Channel Country',
          '',
          '',
          '',
          'Channel Name',
          'UserName',
          'Subscriber Count',
          'Total Videos',
          'Total Videos Last Month',
          // 'Total Videos Last 3 Months',
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
