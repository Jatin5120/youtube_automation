import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:frontend/controllers/controllers.dart' as controllers;
import 'package:frontend/data/data.dart';
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

  controllers.AnalysisController get _analyticsController => Get.find<controllers.AnalysisController>();

  var fetchedResult = false;

  var channels = <ChannelDetailsModel>[];

  var parsedChannels = <ChannelDetailsModel>[];

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

  // Server wakeup timer to keep Render.com server alive
  Timer? _wakeupTimer;

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
    _startWakeupTimer();
  }

  @override
  void onClose() {
    _debounceTimer?.cancel();
    _wakeupTimer?.cancel();
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
    _debounceTimer = Timer(AppConstants.searchDebounceDelay, () async {
      await _performSearch();
    });
  }

  Future<void> _performSearch() async {
    try {
      final channels = AppValidators.validateChannelList(searchController.text, channelBy == ChannelBy.channelId);

      if (channels == null) {
        _showError('Please enter valid channel names or IDs');
        return;
      }

      _setLoadingState(true, 'Fetching channel data...');

      this.channels = await _getVideosWithRetry(channels);
      fetchedResult = true;

      _setLoadingState(false, 'Processing data...');
      parseData();
      _setLoadingState(false, '');
    } on ValidationException catch (e) {
      _setLoadingState(false, '');
      _showError(e.message);
    } catch (e) {
      _setLoadingState(false, '');
      _showError('Failed to fetch data: ${e.toString()}');
    }
  }

  void _setLoadingState(bool isLoading, String message) {
    _isLoadingVideos.value = isLoading;
    _isProcessingData.value = isLoading;
    _loadingMessage.value = message;
    update([DashboardView.updateId]);
  }

  void _showError(String message) {
    Utility.showInfoDialog(
      ResponseModel.message(message),
      title: 'Error',
    );
  }

  Future<List<ChannelDetailsModel>> _getVideosWithRetry(List<String> channels) async {
    for (int attempt = 0; attempt < AppConstants.maxRetryAttempts; attempt++) {
      try {
        _retryCount.value = attempt;
        update([DashboardView.updateId]);
        return await _getVideosByChannelIdentifier(channels);
      } catch (e) {
        if (attempt == AppConstants.maxRetryAttempts - 1) {
          rethrow;
        }
        _loadingMessage.value = 'Retrying... (${attempt + 1}/${AppConstants.maxRetryAttempts})';
        update([DashboardView.updateId]);
        await Future.delayed(Duration(seconds: AppConstants.retryDelaySeconds * (attempt + 1)));
      }
    }
    return [];
  }

  Future<List<ChannelDetailsModel>> _getVideosByChannelIdentifier(List<String> channels) async {
    if (channels.isEmpty) {
      return [];
    }

    if (channels.length <= 100) {
      return await _viewModel.getVideosByChannelIdentifier(
        usernames: channels,
        useId: channelBy == ChannelBy.channelId,
        variant: kVariant,
      );
    }

    // Use streaming for large batches

    _loadingMessage.value = 'Fetching channel details (0%)...';
    update([DashboardView.updateId]);
    final List<ChannelDetailsModel> streamingVideos = [];
    final Completer<List<ChannelDetailsModel>> streamingCompleter = Completer<List<ChannelDetailsModel>>();

    _viewModel.streamChannelDetails(
      channels: channels,
      useId: channelBy == ChannelBy.channelId,
      variant: kVariant.name,
      onProgress: (current, total, message) {
        final progress = total > 0 ? (current * 100 / total).round() : 0;
        _loadingMessage.value = 'Fetching channel details ($progress%)...';
        update([DashboardView.updateId]);
      },
      onBatchResult: (batchData) {
        streamingVideos.addAll(batchData);
      },
      onComplete: () {
        streamingCompleter.complete(streamingVideos);
      },
      onError: (error) {
        streamingCompleter.completeError(error);
      },
    );
    return streamingCompleter.future;
  }

  void parseData() {
    parsedChannels = channels
        .where((e) =>
            e.subscriberCount > 100 &&
            e.totalVideosLastMonth > 2 &&
            e.totalVideosLastThreeMonths > 5 &&
            AppConstants.targetCountries.contains(e.country))
        .toSet()
        .toList();

    update([DashboardView.updateId]);
  }

  void analyzeData() async {
    isAnalyzing = true;
    analyzeProgress = 0.0;
    update([DashboardView.updateId]);

    // Filter videos that need analysis
    final videosToAnalyze = <int, ChannelDetailsModel>{};
    for (var data in parsedChannels.indexed) {
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

    // Prepare channel data for batch analysis
    final channels = videosToAnalyze.values
        .map((video) => ChannelAnalysisItem(
              channelId: video.channelId,
              title: video.latestVideoTitle,
              channelName: video.channelName,
              userName: video.userName,
              description: video.description,
            ))
        .toList();

    // Use new channel-based batch analysis with SSE
    try {
      // Collect analyzed results first, merge after complete
      final Map<String, ChannelDetailsModel> channelsById = {};

      await _analyticsController.analyzeChannelsBatch(
        channels: channels,
        batchSize: AppConstants.analysisBatchSize,
        onResult: (channel) {
          if (channel == null) {
            return;
          }
          channelsById[channel.channelId] = channel;
        },
        onProgress: (current, total, message) {
          analyzeProgress = current / total;
          update([DashboardView.updateId]);
        },
        onBatchResult: (batchData) {
          for (var video in batchData) {
            channelsById[video.channelId] = video;
          }
        },
        onComplete: () {
          for (var i = 0; i < parsedChannels.length; i++) {
            final v = parsedChannels[i];
            final result = channelsById[v.channelId];
            if (result != null) {
              parsedChannels[i] = v.copyWith(
                analyzedTitle: result.analyzedTitle,
                analyzedName: result.analyzedName,
                email: result.email,
              );
            }
          }
          analyzeProgress = 100;
          isAnalyzing = false;
          update([DashboardView.updateId]);
          _downloadCSV();
        },
        onError: (error) {
          _handleAnalysisError(error);
        },
      );
    } catch (e) {
      _handleAnalysisError(e.toString());
    }
  }

  // Fallback method for when backend analysis fails
  void _handleAnalysisError(String error) {
    AppLog.error('Analysis failed: $error');
    isAnalyzing = false;
    analyzeProgress = 0.0;
    update([DashboardView.updateId]);

    // Show error message to user
    Get.snackbar(
      'Analysis Error',
      'Failed to analyze videos. Please try again.',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.red,
      colorText: Colors.white,
    );
  }

  // Download and save CSV to your Device
  void _downloadCSV() async {
    final query = Get.isRegistered<controllers.SearchController>() ? Get.find<controllers.SearchController>().searchController.text.trim() : '';

    await Utility.downloadCSV(
      data: [
        [
          'Search Query',
          'Channel ID',
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
        ...parsedChannels.map((e) => [
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

  /// Start periodic wakeup timer to keep Render.com server alive
  void _startWakeupTimer() {
    _wakeupTimer = Timer.periodic(const Duration(minutes: 5), (timer) async {
      try {
        final wakeupService = WakeupService(Get.find<ApiWrapper>());
        await wakeupService.wakeupServer();
      } catch (e) {
        // Silently fail - wakeup is not critical
        if (kDebugMode) {
          print('Periodic wakeup failed: $e');
        }
      }
    });
  }
}
