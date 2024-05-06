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
  final int totalVideosLastThreeMonths;
  final String latestVideoTitle;
  final DateTime lastUploadDate;
  final bool uploadedThisMonth;
  final String analyzedTitle;
  final String analyzedName;
  final String language;
  final String country;

  const VideoModel({
    required this.subscriberCount,
    required this.totalVideos,
    required this.channelName,
    required this.userName,
    required this.channelLink,
    required this.description,
    required this.totalVideosLastMonth,
    required this.totalVideosLastThreeMonths,
    required this.latestVideoTitle,
    required this.lastUploadDate,
    required this.uploadedThisMonth,
    this.analyzedTitle = '',
    this.analyzedName = '',
    required this.language,
    required this.country,
  });

  Iterable get properties => [
        analyzedName,
        analyzedTitle,
        '',
        '',
        '',
        '',
        channelLink,
        country,
        '',
        '',
        '',
        '',
        '',
        '',
        channelName,
        userName,
        subscriberCount,
        totalVideos,
        totalVideosLastMonth,
        totalVideosLastThreeMonths,
        latestVideoTitle,
        lastUploadDate,
      ];

  VideoModel copyWith({
    int? subscriberCount,
    int? totalVideos,
    String? channelName,
    String? userName,
    String? channelLink,
    String? description,
    int? totalVideosLastMonth,
    int? totalVideosLastThreeMonths,
    String? latestVideoTitle,
    DateTime? lastUploadDate,
    bool? uploadedThisMonth,
    String? analyzedTitle,
    String? analyzedName,
    String? language,
    String? country,
  }) {
    return VideoModel(
      subscriberCount: subscriberCount ?? this.subscriberCount,
      totalVideos: totalVideos ?? this.totalVideos,
      channelName: channelName ?? this.channelName,
      userName: userName ?? this.userName,
      channelLink: channelLink ?? this.channelLink,
      description: description ?? this.description,
      totalVideosLastMonth: totalVideosLastMonth ?? this.totalVideosLastMonth,
      totalVideosLastThreeMonths: totalVideosLastThreeMonths ?? this.totalVideosLastThreeMonths,
      latestVideoTitle: latestVideoTitle ?? this.latestVideoTitle,
      lastUploadDate: lastUploadDate ?? this.lastUploadDate,
      uploadedThisMonth: uploadedThisMonth ?? this.uploadedThisMonth,
      analyzedTitle: analyzedTitle ?? this.analyzedTitle,
      analyzedName: analyzedName ?? this.analyzedName,
      language: language ?? this.language,
      country: country ?? this.country,
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
      'totalVideosLastThreeMonths': totalVideosLastThreeMonths,
      'latestVideoTitle': latestVideoTitle,
      'lastUploadDate': lastUploadDate.millisecondsSinceEpoch,
      'uploadedThisMonth': uploadedThisMonth,
      'analyzedTitle': analyzedTitle,
      'analyzedName': analyzedName,
      'language': language,
      'country': country,
    };
  }

  factory VideoModel.fromMap(Map<String, dynamic> map) {
    var model = VideoModel(
      subscriberCount: int.parse(map['subscriberCount'] as String? ?? '0'),
      totalVideos: int.parse(map['totalVideos'] as String? ?? '0'),
      channelName: map['channelName'] as String? ?? '',
      userName: map['userName'] as String? ?? '',
      description: map['description'] as String? ?? '',
      channelLink: '',
      totalVideosLastMonth: map['totalVideosLastMonth'] as int? ?? 0,
      totalVideosLastThreeMonths: map['totalVideosLastThreeMonths'] as int? ?? 0,
      latestVideoTitle: map['latestVideoTitle'] as String? ?? '',
      lastUploadDate: DateTime.parse(map['lastUploadDate'] as String),
      uploadedThisMonth: map['uploadedThisMonth'] as bool? ?? false,
      language: map['language'] as String? ?? 'N/A',
      country: map['country'] as String? ?? 'N/A',
    );
    model = model.copyWith(
      channelLink: '${AppConstants.youtubeBase}${model.userName}',
    );
    return model;
  }

  String toJson() => json.encode(toMap());

  factory VideoModel.fromJson(String source) => VideoModel.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() {
    return 'VideoModel(subscriberCount: $subscriberCount, totalVideos: $totalVideos, channelName: $channelName, userName: $userName, decription: $description, channelLink: $channelLink, totalVideosLastMonth: $totalVideosLastMonth, totalVideosLastThreeMonths: $totalVideosLastThreeMonths, latestVideoTitle: $latestVideoTitle, lastUploadDate: $lastUploadDate, uploadedThisMonth: $uploadedThisMonth, analyzedTitle: $analyzedTitle, analyzedName: $analyzedTitle, language: $language, country: $country)';
  }

  @override
  bool operator ==(covariant VideoModel other) {
    if (identical(this, other)) return true;
    return other.userName == userName;
    // return other.subscriberCount == subscriberCount &&
    //     other.totalVideos == totalVideos &&
    //     other.channelName == channelName &&
    //     other.userName == userName &&
    //     other.description == description &&
    //     other.channelLink == channelLink &&
    //     other.totalVideosLastMonth == totalVideosLastMonth &&
    //     other.totalVideosLastThreeMonths == totalVideosLastThreeMonths &&
    //     other.latestVideoTitle == latestVideoTitle &&
    //     other.lastUploadDate == lastUploadDate &&
    //     other.uploadedThisMonth == uploadedThisMonth &&
    //     other.analyzedTitle == analyzedTitle &&
    //     other.analyzedName == analyzedName &&
    //     other.language == language &&
    //     other.country == country;
  }

  @override
  int get hashCode {
    return userName.hashCode;
    // return subscriberCount.hashCode ^
    //     totalVideos.hashCode ^
    //     channelName.hashCode ^
    //     userName.hashCode ^
    //     description.hashCode ^
    //     channelLink.hashCode ^
    //     totalVideosLastMonth.hashCode ^
    //     totalVideosLastThreeMonths.hashCode ^
    //     latestVideoTitle.hashCode ^
    //     lastUploadDate.hashCode ^
    //     uploadedThisMonth.hashCode ^
    //     analyzedTitle.hashCode ^
    //     analyzedName.hashCode ^
    //     language.hashCode ^
    //     country.hashCode;
  }
}
