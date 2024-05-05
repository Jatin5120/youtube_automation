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
  development('API_KEY'),
  variant1('API_KEY_VARIANT1'),
  variant2('API_KEY_VARIANT2'),
  variant3('API_KEY_VARIANT3'),
  variant4('API_KEY_VARIANT4'),
  variant5('API_KEY_VARIANT5');

  String? get appName {
    return switch (this) {
      Variant.development => null,
      Variant.variant1 => 'Variant 1',
      Variant.variant2 => 'Variant 2',
      Variant.variant3 => 'Variant 3',
      Variant.variant4 => 'Variant 4',
      Variant.variant5 => 'Variant 5',
    };
  }

  const Variant(this.key);
  final String key;

  static List<Variant> get variants => [
        variant1,
        variant2,
        variant3,
        variant4,
        variant5,
      ];
}
