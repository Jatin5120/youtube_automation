import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:frontend/app.dart';
import 'package:frontend/controllers/controllers.dart' as controllers;
import 'package:frontend/main.dart';
import 'package:get/get.dart';

class DashboardController extends GetxController {
  DashboardController(this._viewModel);
  final DashboardViewModel _viewModel;

  controllers.AnalysisController get _analyticsController => Get.find<controllers.AnalysisController>();

  DbClient get _dbClient => Get.find<DbClient>();

  var fetchedResult = false;

  var channels = <ChannelDetailsModel>[];

  var parsedChannels = <ChannelDetailsModel>[];

  var tableController = ScrollController();

  Map<String, List<String>>? queryMap;

  var query = '';

  int get searchCount => query.trim().split(',').length;

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
    queryMap = _dbClient.get(LocalKeys.queriesChannels) as Map<String, List<String>>?;
    if (queryMap != null && queryMap!.isNotEmpty) {
      try {
        final list = queryMap!.entries.map((e) => e.value.join(', ')).toList();
        Utility.updateLater(() {
          onChannelByChanged(ChannelBy.channelId);
          query = list.join(', ');
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
    if (query.trim().isEmpty) {
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
      final channels = AppValidators.validateChannelList(query, channelBy == ChannelBy.channelId);

      if (channels == null) {
        _showError('Validation Error', 'Please enter valid channel names or IDs');
        return;
      }

      _setLoadingState(true, 'Fetching channel data...');

      this.channels = await _getVideosWithRetry(channels);
      fetchedResult = true;

      _setLoadingState(false, 'Processing data...');
      parseData();
      _dbClient.delete(LocalKeys.queriesChannels);
      _setLoadingState(false, '');
    } on ValidationException catch (e) {
      _setLoadingState(false, '');
      _showError('Validation Error', e.message);
    } catch (e) {
      _setLoadingState(false, '');
      _showError('Fetch Error', 'Failed to fetch data: ${e.toString()}');
    }
  }

  void _setLoadingState(bool isLoading, String message) {
    _isLoadingVideos.value = isLoading;
    _isProcessingData.value = isLoading;
    _loadingMessage.value = message;
    update([DashboardView.updateId]);
  }

  void _showError(String title, String message) {
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
        .toSet()
        .where((e) => e.totalVideosLastMonth > 3 && e.totalVideosLastThreeMonths > 5 && AppConstants.targetCountries.contains(e.country))
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
              videoTitle: video.latestVideoTitle,
              channelName: video.channelName,
              userName: video.userName,
              channelDescription: video.channelDescription,
              videoDescription: video.latestVideoDescription,
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
          parsedChannels = parsedChannels.where((channel) => channelsById.containsKey(channel.channelId)).map((channel) {
            final result = channelsById[channel.channelId]!;
            var query = '';
            if (queryMap != null && queryMap!.isNotEmpty) {
              final queryPair = queryMap!.entries.firstWhere(
                (e) => e.value.contains(channel.channelId),
                orElse: () => MapEntry('', []),
              );
              query = queryPair.key;
            } else {
              query = channel.query;
            }
            return channel.copyWith(
              query: query,
              analyzedTitle: result.analyzedTitle,
              analyzedName: result.analyzedName,
              email: result.email,
              emailMessage: result.emailMessage,
            );
          }).toList();

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
    isAnalyzing = false;
    analyzeProgress = 0.0;
    update([DashboardView.updateId]);

    _showError('Analysis Error', error);
  }

  // Download and save CSV to your Device
  void _downloadCSV() async {
    final now = DateTime.now().toString();
    await Utility.downloadCSV(
      data: [
        [
          'Search Query',
          'Channel ID',
          'Channel Link',
          'Analyzed Name',
          'Analyzed Title',
          'Email Id',
          'Channel Name',
          'UserName',
          'Timestamp',
        ],
        ...parsedChannels.map((e) => [...e.properties, now]),
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
        final wakeupService = WakeupService(Get.find<ApiClient>());
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
