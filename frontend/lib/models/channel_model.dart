import 'dart:convert';

import 'package:frontend/res/res.dart';

class ChannelModel {
  final String channelId;
  final String channelName;
  final String title;
  final String description;
  final String channelLink;

  const ChannelModel({
    required this.channelId,
    required this.channelName,
    required this.title,
    required this.description,
    required this.channelLink,
  });

  Iterable get properties => [
        channelName,
        channelLink,
        title,
        description,
      ];

  ChannelModel copyWith({
    String? channelId,
    String? channelName,
    String? title,
    String? description,
    String? channelLink,
  }) {
    return ChannelModel(
      channelId: channelId ?? this.channelId,
      channelName: channelName ?? this.channelName,
      title: title ?? this.title,
      description: description ?? this.description,
      channelLink: channelLink ?? this.channelLink,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'channelId': channelId,
      'channelName': channelName,
      'title': title,
      'description': description,
      'channelLink': channelLink,
    };
  }

  factory ChannelModel.fromMap(Map<String, dynamic> map) {
    return ChannelModel(
      channelId: map['channelId'] as String,
      channelName: map['channelName'] as String,
      title: map['title'] as String,
      description: map['description'] as String,
      channelLink: '${AppConstants.youtubeBase}channel/${map['channelId']}',
    );
  }

  String toJson() => json.encode(toMap());

  factory ChannelModel.fromJson(String source) => ChannelModel.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() {
    return 'ChannelModel(channelId: $channelId, channelName: $channelName, title: $title, description: $description, channelLink: $channelLink)';
  }

  @override
  bool operator ==(covariant ChannelModel other) {
    if (identical(this, other)) return true;

    return other.channelId == channelId &&
        other.channelName == channelName &&
        other.title == title &&
        other.description == description &&
        other.channelLink == channelLink;
  }

  @override
  int get hashCode {
    return channelId.hashCode ^ channelName.hashCode ^ title.hashCode ^ description.hashCode ^ channelLink.hashCode;
  }
}
