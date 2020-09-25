import 'package:finale/env.dart';
import 'package:finale/types/generic.dart';
import 'package:flutter_web_auth/flutter_web_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:spotify/spotify.dart';

class SearchTracksRequest extends PagedRequest<SpotifyBasicTrack> {
  String query;
  SpotifyApi _spotify;

  SearchTracksRequest(this.query, this._spotify);

  @override
  Future<List<SpotifyBasicTrack>> doRequest(int limit, int page,
      {String period}) async {
    print((await _spotify.search
            .get(query, [SearchType.track]).getPage(limit, page))
        .expand((element) => element.items)
        .whereType<Track>()
        .map((e) => e.name));

    return (await _spotify.search
            .get(query, [SearchType.track]).getPage(limit, page))
        .expand((page) => page.items)
        .whereType<Track>()
        .map((e) => SpotifyBasicTrack(e));
    // TODO: Maybe offset = page * limit, not just page.
  }
}

class SpotifyBasicAlbum extends BasicAlbum {
  AlbumSimple _album;

  SpotifyBasicAlbum(this._album);

  @override
  BasicArtist get artist => SpotifyBasicArtist(_album.artists.first);

  @override
  String get name => _album.name;

  @override
  String get url => _album.uri;
}

class SpotifyBasicArtist extends BasicArtist {
  ArtistSimple _artist;

  SpotifyBasicArtist(this._artist);

  @override
  String get name => _artist.name;

  @override
  String get url => _artist.uri;
}

class SpotifyBasicTrack extends BasicTrack {
  Track _track;

  SpotifyBasicTrack(this._track) {
    print('constructing track with name ${_track.name}');
  }

  @override
  String get album => _track.album.name;

  @override
  String get artist => _track.artists.first.name;

  @override
  String get name => _track.name;

  @override
  String get url => _track.uri;
}

class Spotify extends SearchEngine {
  Spotify._();
  static final _instance = Spotify._();
  static Spotify getInstance() => _instance;

  final _redirectUri = Uri(scheme: 'finale', host: 'spotify');

  SpotifyApi _spotify;

  Future<void> login() async {
    try {
      final credentials = await _loadCredentials();
      _spotify = SpotifyApi(credentials);
      return;
    } catch (e) {}

    final credentials = SpotifyApiCredentials(Env.spotify.clientId, null);
    final grant = SpotifyApi.authorizationCodeGrant(credentials);
    final authUri = grant.getAuthorizationUrl(_redirectUri);

    final result = await FlutterWebAuth.authenticate(
        url: authUri.toString(), callbackUrlScheme: 'finale');

    _spotify = SpotifyApi.fromAuthCodeGrant(grant, result);
    await _saveCredentials(await _spotify.getCredentials());
  }

  bool get isLoggedIn => _spotify != null;

  @override
  PagedRequest<SpotifyBasicTrack> searchTracks(String query) {
//    return (int limit, int page, {String period}) async => (await _spotify
//            .search
//            .get(query, [SearchType.track]).getPage(limit, page))
//        .expand((page) => page.items)
//        .map((e) => SpotifyBasicTrack(e));
    // TODO: Maybe offset = page * limit, not just page.
    return SearchTracksRequest(query, _spotify);
  }

  Future<void> _saveCredentials(SpotifyApiCredentials credentials) async {
    final sharedPreferences = await SharedPreferences.getInstance();
    await sharedPreferences.setString(
        'spotify.accessToken', credentials.accessToken);
    await sharedPreferences.setString(
        'spotify.refreshToken', credentials.refreshToken);
    await sharedPreferences.setString(
        'spotify.expiration', credentials.expiration.toString());
  }

  Future<SpotifyApiCredentials> _loadCredentials() async {
    final sharedPreferences = await SharedPreferences.getInstance();
    return SpotifyApiCredentials(Env.spotify.clientId, null,
        accessToken: sharedPreferences.getString('spotify.accessToken'),
        refreshToken: sharedPreferences.getString('spotify.refreshToken'),
        scopes: [],
        expiration:
            DateTime.parse(sharedPreferences.getString('spotify.expiration')));
  }
}
