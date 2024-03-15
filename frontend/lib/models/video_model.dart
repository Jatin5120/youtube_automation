import 'dart:convert';

class VideoModel {
  final String subscriberCount;
  final String totalVideos;
  final String channelName;
  final String userName;
  final int totalVideosLastMonth;
  final String latestVideoTitle;
  final DateTime lastUploadDate;
  final bool uploadedThisMonth;

  const VideoModel({
    required this.subscriberCount,
    required this.totalVideos,
    required this.channelName,
    required this.userName,
    required this.totalVideosLastMonth,
    required this.latestVideoTitle,
    required this.lastUploadDate,
    required this.uploadedThisMonth,
  });

  VideoModel copyWith({
    String? subscriberCount,
    String? totalVideos,
    String? channelName,
    String? userName,
    int? totalVideosLastMonth,
    String? latestVideoTitle,
    DateTime? lastUploadDate,
    bool? uploadedThisMonth,
  }) {
    return VideoModel(
      subscriberCount: subscriberCount ?? this.subscriberCount,
      totalVideos: totalVideos ?? this.totalVideos,
      channelName: channelName ?? this.channelName,
      userName: userName ?? this.userName,
      totalVideosLastMonth: totalVideosLastMonth ?? this.totalVideosLastMonth,
      latestVideoTitle: latestVideoTitle ?? this.latestVideoTitle,
      lastUploadDate: lastUploadDate ?? this.lastUploadDate,
      uploadedThisMonth: uploadedThisMonth ?? this.uploadedThisMonth,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'subscriberCount': subscriberCount,
      'totalVideos': totalVideos,
      'channelName': channelName,
      'userName': userName,
      'totalVideosLastMonth': totalVideosLastMonth,
      'latestVideoTitle': latestVideoTitle,
      'lastUploadDate': lastUploadDate.millisecondsSinceEpoch,
      'uploadedThisMonth': uploadedThisMonth,
    };
  }

  factory VideoModel.fromMap(Map<String, dynamic> map) {
    return VideoModel(
      subscriberCount: map['subscriberCount'] as String,
      totalVideos: map['totalVideos'] as String,
      channelName: map['channelName'] as String,
      userName: map['userName'] as String,
      totalVideosLastMonth: map['totalVideosLastMonth'] as int,
      latestVideoTitle: map['latestVideoTitle'] as String,
      lastUploadDate: DateTime.parse(map['lastUploadDate'] as String),
      uploadedThisMonth: map['uploadedThisMonth'] as bool,
    );
  }

  String toJson() => json.encode(toMap());

  factory VideoModel.fromJson(String source) => VideoModel.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() {
    return 'VideoModel(subscriberCount: $subscriberCount, totalVideos: $totalVideos, channelName: $channelName, userName: $userName, totalVideosLastMonth: $totalVideosLastMonth, latestVideoTitle: $latestVideoTitle, lastUploadDate: $lastUploadDate, uploadedThisMonth: $uploadedThisMonth)';
  }

  @override
  bool operator ==(covariant VideoModel other) {
    if (identical(this, other)) return true;

    return other.subscriberCount == subscriberCount &&
        other.totalVideos == totalVideos &&
        other.channelName == channelName &&
        other.userName == userName &&
        other.totalVideosLastMonth == totalVideosLastMonth &&
        other.latestVideoTitle == latestVideoTitle &&
        other.lastUploadDate == lastUploadDate &&
        other.uploadedThisMonth == uploadedThisMonth;
  }

  @override
  int get hashCode {
    return subscriberCount.hashCode ^
        totalVideos.hashCode ^
        channelName.hashCode ^
        userName.hashCode ^
        totalVideosLastMonth.hashCode ^
        latestVideoTitle.hashCode ^
        lastUploadDate.hashCode ^
        uploadedThisMonth.hashCode;
  }
}
