class _Lastfm {
  const _Lastfm();

  final apiKey = '';
  final apiSecret = '';
}

class _AcrCloud {
  const _AcrCloud();

  final accessKey = '';
  final accessSecret = '';
  final host = '';
}

class _Spotify {
  const _Spotify();

  final clientId = '';
}

class Env {
  static const lastfm = _Lastfm();
  static const acrCloud = _AcrCloud();
  static const spotify = _Spotify();
}
