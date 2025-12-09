import 'dart:convert';

import 'package:frontend/res/res.dart';

class ChannelDetailsModel {
  final String query;
  final String channelId;
  final String email;
  final int subscriberCount;
  final int totalVideos;
  final String channelName;
  final String userName;
  final String channelLink;
  final String channelDescription;
  final int totalVideosLastMonth;
  final int totalVideosLastThreeMonths;
  final String latestVideoTitle;
  final String latestVideoDescription;
  final DateTime? lastUploadDate;
  final bool uploadedThisMonth;
  final String analyzedTitle;
  final String analyzedName;
  final String language;
  final String country;
  final String emailMessage;

  const ChannelDetailsModel({
    required this.query,
    required this.channelId,
    required this.email,
    required this.subscriberCount,
    required this.totalVideos,
    required this.channelName,
    required this.userName,
    required this.channelLink,
    required this.channelDescription,
    required this.totalVideosLastMonth,
    required this.totalVideosLastThreeMonths,
    required this.latestVideoTitle,
    required this.latestVideoDescription,
    required this.lastUploadDate,
    required this.uploadedThisMonth,
    this.analyzedTitle = '',
    this.analyzedName = '',
    required this.language,
    required this.country,
    required this.emailMessage,
  });

  Iterable get properties => [
        query,
        channelId,
        channelLink,
        analyzedName,
        analyzedTitle,
        email,
        channelName,
        userName,
      ];

  ChannelDetailsModel copyWith({
    String? query,
    String? channelId,
    String? email,
    int? subscriberCount,
    int? totalVideos,
    String? channelName,
    String? userName,
    String? channelLink,
    String? channelDescription,
    int? totalVideosLastMonth,
    int? totalVideosLastThreeMonths,
    String? latestVideoTitle,
    String? latestVideoDescription,
    DateTime? lastUploadDate,
    bool? uploadedThisMonth,
    String? analyzedTitle,
    String? analyzedName,
    String? language,
    String? country,
    String? emailMessage,
  }) {
    return ChannelDetailsModel(
      query: query ?? this.query,
      channelId: channelId ?? this.channelId,
      email: email ?? this.email,
      subscriberCount: subscriberCount ?? this.subscriberCount,
      totalVideos: totalVideos ?? this.totalVideos,
      channelName: channelName ?? this.channelName,
      userName: userName ?? this.userName,
      channelLink: channelLink ?? this.channelLink,
      channelDescription: channelDescription ?? this.channelDescription,
      totalVideosLastMonth: totalVideosLastMonth ?? this.totalVideosLastMonth,
      totalVideosLastThreeMonths: totalVideosLastThreeMonths ?? this.totalVideosLastThreeMonths,
      latestVideoTitle: latestVideoTitle ?? this.latestVideoTitle,
      latestVideoDescription: latestVideoDescription ?? this.latestVideoDescription,
      lastUploadDate: lastUploadDate ?? this.lastUploadDate,
      uploadedThisMonth: uploadedThisMonth ?? this.uploadedThisMonth,
      analyzedTitle: analyzedTitle ?? this.analyzedTitle,
      analyzedName: analyzedName ?? this.analyzedName,
      language: language ?? this.language,
      country: country ?? this.country,
      emailMessage: emailMessage ?? this.emailMessage,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'query': query,
      'channelId': channelId,
      'email': email,
      'subscriberCount': subscriberCount,
      'totalVideos': totalVideos,
      'channelName': channelName,
      'userName': userName,
      'channelLink': channelLink,
      'channelDescription': channelDescription,
      'totalVideosLastMonth': totalVideosLastMonth,
      'totalVideosLastThreeMonths': totalVideosLastThreeMonths,
      'latestVideoTitle': latestVideoTitle,
      'latestVideoDescription': latestVideoDescription,
      'lastUploadDate': lastUploadDate?.millisecondsSinceEpoch,
      'uploadedThisMonth': uploadedThisMonth,
      'analyzedTitle': analyzedTitle,
      'analyzedName': analyzedName,
      'language': language,
      'country': country,
      'emailMessage': emailMessage,
    };
  }

  factory ChannelDetailsModel.fromMap(Map<String, dynamic> map) {
    var model = ChannelDetailsModel(
      query: map['query'] as String? ?? '',
      channelId: map['channelId'] as String? ?? '',
      email: map['email'] as String? ?? '',
      subscriberCount: int.parse(map['subscriberCount'] as String? ?? '0'),
      totalVideos: int.parse(map['totalVideos'] as String? ?? '0'),
      channelName: map['channelName'] as String? ?? '',
      userName: map['userName'] as String? ?? '',
      channelDescription: map['channelDescription'] as String? ?? '',
      channelLink: '',
      totalVideosLastMonth: map['totalVideosLastMonth'] as int? ?? 0,
      totalVideosLastThreeMonths: map['totalVideosLastThreeMonths'] as int? ?? 0,
      latestVideoTitle: map['latestVideoTitle'] as String? ?? '',
      latestVideoDescription: map['latestVideoDescription'] as String? ?? '',
      lastUploadDate: map['lastUploadDate'] != null ? DateTime.parse(map['lastUploadDate'] as String) : null,
      uploadedThisMonth: map['uploadedThisMonth'] as bool? ?? false,
      language: map['language'] as String? ?? 'N/A',
      country: map['country'] as String? ?? 'N/A',
      analyzedTitle: map['analyzedTitle'] as String? ?? '',
      analyzedName: map['analyzedName'] as String? ?? '',
      emailMessage: map['emailMessage'] as String? ?? '',
    );
    model = model.copyWith(
      channelLink: '${AppConstants.youtubeBase}${model.userName}',
    );
    return model;
  }

  String toJson() => json.encode(toMap());

  factory ChannelDetailsModel.fromJson(String source) => ChannelDetailsModel.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() {
    return 'ChannelDetailsModel(query: $query, channelId: $channelId, email: $email, subscriberCount: $subscriberCount, totalVideos: $totalVideos, channelName: $channelName, userName: $userName, channelDescription: $channelDescription, channelLink: $channelLink, totalVideosLastMonth: $totalVideosLastMonth, totalVideosLastThreeMonths: $totalVideosLastThreeMonths, latestVideoTitle: $latestVideoTitle, latestVideoDescription: $latestVideoDescription, lastUploadDate: $lastUploadDate, uploadedThisMonth: $uploadedThisMonth, analyzedTitle: $analyzedTitle, analyzedName: $analyzedTitle, language: $language, country: $country, emailMessage: $emailMessage)';
  }

  @override
  bool operator ==(covariant ChannelDetailsModel other) {
    if (identical(this, other)) return true;
    return other.channelId == channelId;
  }

  @override
  int get hashCode {
    return channelId.hashCode;
  }
}
