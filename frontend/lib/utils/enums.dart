enum RequestType {
  get,
  post,
  put,
  patch,
  delete,
  upload;
}

enum ChannelBy {
  username('Username'),
  channelId('Channel Id');
  // url('Search Url');

  const ChannelBy(this.label);
  final String label;

  String get inputHint {
    switch (this) {
      case ChannelBy.username:
      case ChannelBy.channelId:
        return '$label must be separated by comma or space';
      // case ChannelBy.url:
      //   return 'Enter Single $label';
    }
  }

  static List<ChannelBy> get visibleValues => [username, channelId];
}

enum Variant {
  development('DEV_API_KEY'),
  production('API_KEY');

  const Variant(this.key);
  final String key;

  Variant get other => this == development ? production : development;
}

enum ContentItem {
  name,
  title;

  String get text => '{{${this.name}}}';

  static List<ContentItem> remainingValues(String text) {
    if (text.trim().isEmpty) {
      return ContentItem.values;
    }
    return ContentItem.values.where((e) => !text.contains(e.text)).toList();
  }
}
