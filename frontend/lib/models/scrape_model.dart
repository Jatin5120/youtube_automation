import 'dart:convert';

import 'package:frontend/res/res.dart';

class ScrapeModel {
  final String channelId;
  final String channelName;
  final String userName;
  final String subscribers;

  const ScrapeModel({
    required this.channelId,
    required this.channelName,
    required this.userName,
    required this.subscribers,
  });

  Iterable get properties => [
        channelName,
        userName,
        channelId,
        channelLink,
        subscribers,
      ];

  ScrapeModel copyWith({
    String? channelId,
    String? channelName,
    String? userName,
    String? subscribers,
  }) {
    return ScrapeModel(
      channelId: channelId ?? this.channelId,
      channelName: channelName ?? this.channelName,
      userName: userName ?? this.userName,
      subscribers: subscribers ?? this.subscribers,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'channelId': channelId,
      'channelName': channelName,
      'userName': userName,
      'subscribers': subscribers,
    };
  }

  String get channelLink => '${AppConstants.youtubeBase}channel/$channelId';

  factory ScrapeModel.fromMap(Map<String, dynamic> map) {
    return ScrapeModel(
      channelId: map['channelId'] as String? ?? '',
      channelName: map['title'] != null ? map['title']['simpleText'] as String? ?? '' : '',
      userName: map['subscriberCountText'] != null ? map['subscriberCountText']['simpleText'] as String? ?? '' : '',
      subscribers: map['videoCountText'] != null ? map['videoCountText']['simpleText'] as String? ?? '' : '',
    );
  }

  String toJson() => json.encode(toMap());

  factory ScrapeModel.fromJson(String source) => ScrapeModel.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() {
    return 'ScrapeModel(channelId: $channelId, channelName: $channelName, userName: $userName, subscribers: $subscribers)';
  }

  @override
  bool operator ==(covariant ScrapeModel other) {
    if (identical(this, other)) return true;

    return other.channelId == channelId && other.channelName == channelName && other.userName == userName && other.subscribers == subscribers;
  }

  @override
  int get hashCode {
    return channelId.hashCode ^ channelName.hashCode ^ userName.hashCode ^ subscribers.hashCode;
  }
}
