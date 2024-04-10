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
