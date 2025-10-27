class ChannelAnalysisItem {
  final String channelId;
  final String? userName;
  final String channelName;
  final String? channelDescription;
  final String videoTitle;
  final String? videoDescription;

  const ChannelAnalysisItem({
    required this.channelId,
    required this.videoTitle,
    required this.channelName,
    this.userName,
    this.channelDescription,
    this.videoDescription,
  });

  Map<String, dynamic> toJson() {
    return {
      'channelId': channelId,
      'videoTitle': videoTitle,
      'channelName': channelName,
      if (userName != null) 'userName': userName,
      if (channelDescription != null) 'channelDescription': channelDescription,
      if (videoDescription != null) 'videoDescription': videoDescription,
    };
  }

  factory ChannelAnalysisItem.fromJson(Map<String, dynamic> json) {
    return ChannelAnalysisItem(
      channelId: json['channelId'] as String,
      videoTitle: json['videoTitle'] as String,
      channelName: json['channelName'] as String,
      userName: json['userName'] as String?,
      channelDescription: json['channelDescription'] as String?,
      videoDescription: json['videoDescription'] as String?,
    );
  }
}

class ChannelAnalysisResult {
  final String channelId;
  final String userName;
  final String analyzedTitle;
  final String analyzedName;

  const ChannelAnalysisResult({
    required this.channelId,
    required this.userName,
    required this.analyzedTitle,
    required this.analyzedName,
  });

  factory ChannelAnalysisResult.fromJson(Map<String, dynamic> json) {
    return ChannelAnalysisResult(
      channelId: json['channelId'] as String,
      userName: json['userName'] as String,
      analyzedTitle: json['analyzedTitle'] as String,
      analyzedName: json['analyzedName'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'channelId': channelId,
      'userName': userName,
      'analyzedTitle': analyzedTitle,
      'analyzedName': analyzedName,
    };
  }
}
