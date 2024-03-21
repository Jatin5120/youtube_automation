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

  const ChannelBy(this.label);
  final String label;
}
