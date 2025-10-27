import 'dart:convert';

import 'package:frontend/res/res.dart';

class ChannelModel {
  final String channelId;
  final String channelName;
  final String channelDescription;
  final String channelLink;

  const ChannelModel({
    required this.channelId,
    required this.channelName,
    required this.channelDescription,
    required this.channelLink,
  });

  Iterable get properties => [
        channelName,
        channelLink,
        channelId,
        channelDescription,
      ];

  ChannelModel copyWith({
    String? channelId,
    String? channelName,
    String? channelDescription,
    String? channelLink,
  }) {
    return ChannelModel(
      channelId: channelId ?? this.channelId,
      channelName: channelName ?? this.channelName,
      channelDescription: channelDescription ?? this.channelDescription,
      channelLink: channelLink ?? this.channelLink,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'channelId': channelId,
      'channelName': channelName,
      'channelDescription': channelDescription,
      'channelLink': channelLink,
    };
  }

  factory ChannelModel.fromMap(Map<String, dynamic> map) {
    return ChannelModel(
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
    return 'ChannelModel(channelId: $channelId, channelName: $channelName, channelDescription: $channelDescription, channelLink: $channelLink)';
  }

  @override
  bool operator ==(covariant ChannelModel other) {
    if (identical(this, other)) return true;

    return other.channelId == channelId &&
        other.channelName == channelName &&
        other.channelDescription == channelDescription &&
        other.channelLink == channelLink;
  }

  @override
  int get hashCode {
    return channelId.hashCode ^ channelName.hashCode ^ channelDescription.hashCode ^ channelLink.hashCode;
  }
}
