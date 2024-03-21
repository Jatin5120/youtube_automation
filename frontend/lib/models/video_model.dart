import 'dart:convert';

import 'package:frontend/res/res.dart';

class VideoModel {
  final int subscriberCount;
  final int totalVideos;
  final String channelName;
  final String userName;
  final String channelLink;
  final String description;
  final int totalVideosLastMonth;
  final String latestVideoTitle;
  final DateTime lastUploadDate;
  final bool uploadedThisMonth;
  final String analyzedTitle;
  final String analyzedName;

  const VideoModel({
    required this.subscriberCount,
    required this.totalVideos,
    required this.channelName,
    required this.userName,
    required this.channelLink,
    required this.description,
    required this.totalVideosLastMonth,
    required this.latestVideoTitle,
    required this.lastUploadDate,
    required this.uploadedThisMonth,
    this.analyzedTitle = '',
    this.analyzedName = '',
  });

  Iterable get properties => [
        channelName,
        userName,
        analyzedName,
        channelLink,
        description,
        subscriberCount,
        totalVideos,
        totalVideosLastMonth,
        latestVideoTitle,
        analyzedTitle,
        lastUploadDate,
        uploadedThisMonth,
      ];

  VideoModel copyWith({
    int? subscriberCount,
    int? totalVideos,
    String? channelName,
    String? userName,
    String? channelLink,
    String? description,
    int? totalVideosLastMonth,
    String? latestVideoTitle,
    DateTime? lastUploadDate,
    bool? uploadedThisMonth,
    String? analyzedTitle,
    String? analyzedName,
  }) {
    return VideoModel(
      subscriberCount: subscriberCount ?? this.subscriberCount,
      totalVideos: totalVideos ?? this.totalVideos,
      channelName: channelName ?? this.channelName,
      userName: userName ?? this.userName,
      channelLink: channelLink ?? this.channelLink,
      description: description ?? this.description,
      totalVideosLastMonth: totalVideosLastMonth ?? this.totalVideosLastMonth,
      latestVideoTitle: latestVideoTitle ?? this.latestVideoTitle,
      lastUploadDate: lastUploadDate ?? this.lastUploadDate,
      uploadedThisMonth: uploadedThisMonth ?? this.uploadedThisMonth,
      analyzedTitle: analyzedTitle ?? this.analyzedTitle,
      analyzedName: analyzedName ?? this.analyzedName,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'subscriberCount': subscriberCount,
      'totalVideos': totalVideos,
      'channelName': channelName,
      'userName': userName,
      'channelLink': channelLink,
      'description': description,
      'totalVideosLastMonth': totalVideosLastMonth,
      'latestVideoTitle': latestVideoTitle,
      'lastUploadDate': lastUploadDate.millisecondsSinceEpoch,
      'uploadedThisMonth': uploadedThisMonth,
      'analyzedTitle': analyzedTitle,
      'analyzedName': analyzedName,
    };
  }

  factory VideoModel.fromMap(Map<String, dynamic> map) {
    return VideoModel(
      subscriberCount: int.parse(map['subscriberCount'] as String),
      totalVideos: int.parse(map['totalVideos'] as String),
      channelName: map['channelName'] as String,
      userName: map['userName'] as String,
      description: map['description'] as String,
      channelLink: '${AppConstants.youtubeBase}${(map['userName'] as String)}',
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
    return 'VideoModel(subscriberCount: $subscriberCount, totalVideos: $totalVideos, channelName: $channelName, userName: $userName, decription: $description, channelLink: $channelLink, totalVideosLastMonth: $totalVideosLastMonth, latestVideoTitle: $latestVideoTitle, lastUploadDate: $lastUploadDate, uploadedThisMonth: $uploadedThisMonth, analyzedTitle: $analyzedTitle, analyzedName: $analyzedTitle)';
  }

  @override
  bool operator ==(covariant VideoModel other) {
    if (identical(this, other)) return true;

    return other.subscriberCount == subscriberCount &&
        other.totalVideos == totalVideos &&
        other.channelName == channelName &&
        other.userName == userName &&
        other.description == description &&
        other.channelLink == channelLink &&
        other.totalVideosLastMonth == totalVideosLastMonth &&
        other.latestVideoTitle == latestVideoTitle &&
        other.lastUploadDate == lastUploadDate &&
        other.uploadedThisMonth == uploadedThisMonth &&
        other.analyzedTitle == analyzedTitle &&
        other.analyzedName == analyzedName;
  }

  @override
  int get hashCode {
    return subscriberCount.hashCode ^
        totalVideos.hashCode ^
        channelName.hashCode ^
        userName.hashCode ^
        description.hashCode ^
        channelLink.hashCode ^
        totalVideosLastMonth.hashCode ^
        latestVideoTitle.hashCode ^
        lastUploadDate.hashCode ^
        uploadedThisMonth.hashCode ^
        analyzedTitle.hashCode ^
        analyzedName.hashCode;
  }
}
