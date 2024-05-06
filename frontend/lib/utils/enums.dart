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
  variant5('API_KEY_VARIANT5'),
  variant6('API_KEY_VARIANT6'),
  variant7('API_KEY_VARIANT7'),
  variant8('API_KEY_VARIANT8'),
  variant9('API_KEY_VARIANT9');

  String? get appName {
    return switch (this) {
      Variant.development => null,
      Variant.variant1 => 'Variant 1',
      Variant.variant2 => 'Variant 2',
      Variant.variant3 => 'Variant 3',
      Variant.variant4 => 'Variant 4',
      Variant.variant5 => 'Variant 5',
      Variant.variant6 => 'Variant 6',
      Variant.variant7 => 'Variant 7',
      Variant.variant8 => 'Variant 8',
      Variant.variant9 => 'Variant 9',
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
        variant6,
        variant7,
        variant8,
        variant9,
      ];
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
