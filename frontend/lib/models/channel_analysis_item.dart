class ChannelAnalysisItem {
  final String channelId;
  final String title; // Video title
  final String? userName;
  final String channelName;
  final String? description;

  const ChannelAnalysisItem({
    required this.channelId,
    required this.title,
    required this.channelName,
    this.userName,
    this.description,
  });

  Map<String, dynamic> toJson() {
    return {
      'channelId': channelId,
      'title': title,
      'channelName': channelName,
      if (userName != null) 'userName': userName,
      if (description != null) 'description': description,
    };
  }

  factory ChannelAnalysisItem.fromJson(Map<String, dynamic> json) {
    return ChannelAnalysisItem(
      channelId: json['channelId'] as String,
      title: json['title'] as String,
      channelName: json['channelName'] as String,
      userName: json['userName'] as String?,
      description: json['description'] as String?,
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
