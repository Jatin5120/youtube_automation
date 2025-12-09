import 'dart:convert';

import 'package:frontend/res/res.dart';

class ChannelModel {
  final String query;
  final String channelId;
  final String channelName;
  final String channelDescription;
  final String channelLink;

  const ChannelModel({
    required this.query,
    required this.channelId,
    required this.channelName,
    required this.channelDescription,
    required this.channelLink,
  });

  Iterable get properties => [
        query,
        channelId,
        channelName,
        channelLink,
        channelDescription,
      ];

  ChannelModel copyWith({
    String? query,
    String? channelId,
    String? channelName,
    String? channelDescription,
    String? channelLink,
  }) {
    return ChannelModel(
      query: query ?? this.query,
      channelId: channelId ?? this.channelId,
      channelName: channelName ?? this.channelName,
      channelDescription: channelDescription ?? this.channelDescription,
      channelLink: channelLink ?? this.channelLink,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'query': query,
      'channelId': channelId,
      'channelName': channelName,
      'channelDescription': channelDescription,
      'channelLink': channelLink,
    };
  }

  factory ChannelModel.fromMap(Map<String, dynamic> map) {
    return ChannelModel(
      query: map['query'] as String? ?? '',
      channelId: map['channelId'] as String,
      channelName: map['channelName'] as String,
      channelDescription: map['channelDescription'] as String,
      channelLink: '${AppConstants.youtubeBase}channel/${map['channelId']}',
    );
  }

  String toJson() => json.encode(toMap());

  factory ChannelModel.fromJson(String source) => ChannelModel.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() {
    return 'ChannelModel(query: $query, channelId: $channelId, channelName: $channelName, channelDescription: $channelDescription, channelLink: $channelLink)';
  }

  @override
  bool operator ==(covariant ChannelModel other) {
    if (identical(this, other)) return true;

    return other.channelId == channelId;
  }

  @override
  int get hashCode {
    return channelId.hashCode;
  }
}
