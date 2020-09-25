import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:finale/env.dart';
import 'package:finale/types/generic.dart';
import 'package:finale/types/lalbum.dart';
import 'package:finale/types/lartist.dart';
import 'package:finale/types/lcommon.dart';
import 'package:finale/types/ltrack.dart';
import 'package:finale/types/luser.dart';
import 'package:http/http.dart';
import 'package:http_throttle/http_throttle.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum RequestVerb { get, post }

final _client = ThrottleClient(10);

Uri _buildUri(String method, Map<String, dynamic> data) {
  final allData = {
    ...data.map((key, value) => MapEntry(key, value.toString())),
    'api_key': Env.lastfm.apiKey,
    'method': method,
  };

  final hash = (allData.keys.toList()..sort())
          .map((key) => '$key${allData[key]}')
          .join() +
      Env.lastfm.apiSecret;
  final signature = md5.convert(utf8.encode(hash));
  allData['api_sig'] = signature.toString();
  allData['format'] = 'json';

  return Uri(
      scheme: 'https',
      host: 'ws.audioscrobbler.com',
      path: '2.0',
      queryParameters: allData);
}

Future<Map<String, dynamic>> _doRequest(
    String method, Map<String, dynamic> data,
    {RequestVerb verb = RequestVerb.get}) async {
  final uri = _buildUri(method, data);

  final response = verb == RequestVerb.get
      ? await _client.get(uri)
      : await _client.post(uri);

  if (response.statusCode == 200) {
    return json.decode(utf8.decode(response.bodyBytes));
  } else if (response.statusCode == 400) {
    final error = LError.fromJson(json.decode(utf8.decode(response.bodyBytes)));
    throw LException(error.code, error.message);
  } else {
    throw Exception('Could not do request $method');
  }
}

//abstract class PagedLastfmRequest<T> {
//  Future<List<T>> doRequest(int limit, int page, {String period});
//}

abstract class PagedLastfmRequest<T extends Displayable>
    extends PagedRequest<T> {}

class GetRecentTracksRequest
    extends PagedLastfmRequest<LRecentTracksResponseTrack> {
  String username;

  GetRecentTracksRequest(this.username);

  @override
  doRequest(int limit, int page, {String period}) async {
    final rawResponse = await _doRequest('user.getRecentTracks',
        {'user': username, 'limit': limit, 'page': page});
    final tracks =
        LRecentTracksResponseRecentTracks.fromJson(rawResponse['recenttracks'])
            .tracks;

    // For some reason, this endpoint always returns the currently-playing
    // song regardless of which page you request.
    if (page != 1 && tracks.isNotEmpty && tracks.first.date == null) {
      tracks.removeAt(0);
    }

    return tracks;
  }
}

class GetTopArtistsRequest
    extends PagedLastfmRequest<LTopArtistsResponseArtist> {
  String username;

  GetTopArtistsRequest(this.username);

  @override
  doRequest(int limit, int page, {String period}) async {
    final rawResponse = await _doRequest('user.getTopArtists',
        {'user': username, 'limit': limit, 'page': page, 'period': period});
    return LTopArtistsResponseTopArtists.fromJson(rawResponse['topartists'])
        .artists;
  }
}

class GetTopAlbumsRequest extends PagedLastfmRequest<LTopAlbumsResponseAlbum> {
  String username;

  GetTopAlbumsRequest(this.username);

  @override
  doRequest(int limit, int page, {String period}) async {
    final rawResponse = await _doRequest('user.getTopAlbums',
        {'user': username, 'limit': limit, 'page': page, 'period': period});
    return LTopAlbumsResponseTopAlbums.fromJson(rawResponse['topalbums'])
        .albums;
  }
}

class GetTopTracksRequest extends PagedLastfmRequest<LTopTracksResponseTrack> {
  String username;

  GetTopTracksRequest(this.username);

  @override
  doRequest(int limit, int page, {String period}) async {
    final rawResponse = await _doRequest('user.getTopTracks',
        {'user': username, 'limit': limit, 'page': page, 'period': period});
    return LTopTracksResponseTopTracks.fromJson(rawResponse['toptracks'])
        .tracks;
  }
}

class GetFriendsRequest extends PagedLastfmRequest<LUser> {
  String username;

  GetFriendsRequest(this.username);

  @override
  doRequest(int limit, int page, {String period}) async {
    final rawResponse = await _doRequest(
        'user.getFriends', {'user': username, 'limit': limit, 'page': page});
    return LUserFriendsResponse.fromJson(rawResponse['friends']).friends;
  }
}

class SearchTracksRequest extends PagedLastfmRequest<LTrackMatch> {
  String query;

  SearchTracksRequest(this.query);

  @override
  Future<List<LTrackMatch>> doRequest(int limit, int page,
      {String period}) async {
    final rawResponse = await _doRequest(
        'track.search', {'track': query, 'limit': limit, 'page': page});
    return LTrackSearchResponse.fromJson(rawResponse['results']['trackmatches'])
        .tracks;
  }
}

class SearchArtistsRequest extends PagedLastfmRequest<LArtistMatch> {
  String query;

  SearchArtistsRequest(this.query);

  @override
  Future<List<LArtistMatch>> doRequest(int limit, int page,
      {String period}) async {
    final rawResponse = await _doRequest(
        'artist.search', {'artist': query, 'limit': limit, 'page': page});
    return LArtistSearchResponse.fromJson(
            rawResponse['results']['artistmatches'])
        .artists;
  }
}

class SearchAlbumsRequest extends PagedLastfmRequest<LAlbumMatch> {
  String query;

  SearchAlbumsRequest(this.query);

  @override
  Future<List<LAlbumMatch>> doRequest(int limit, int page,
      {String period}) async {
    final rawResponse = await _doRequest(
        'album.search', {'album': query, 'limit': limit, 'page': page});
    return LAlbumSearchResponse.fromJson(rawResponse['results']['albummatches'])
        .albums;
  }
}

class ArtistGetTopAlbumsRequest extends PagedLastfmRequest<LArtistTopAlbum> {
  String artist;

  ArtistGetTopAlbumsRequest(this.artist);

  @override
  Future<List<LArtistTopAlbum>> doRequest(int limit, int page,
      {String period}) async {
    final rawResponse = await _doRequest('artist.getTopAlbums',
        {'artist': artist, 'limit': limit, 'page': page});
    return LArtistGetTopAlbumsResponse.fromJson(rawResponse['topalbums'])
        .albums;
  }
}

class ArtistGetTopTracksRequest extends PagedLastfmRequest<LArtistTopTrack> {
  String artist;

  ArtistGetTopTracksRequest(this.artist);

  @override
  Future<List<LArtistTopTrack>> doRequest(int limit, int page,
      {String period}) async {
    final rawResponse = await _doRequest('artist.getTopTracks',
        {'artist': artist, 'limit': limit, 'page': page});
    return LArtistGetTopTracksResponse.fromJson(rawResponse['toptracks'])
        .tracks;
  }
}

class Lastfm extends SearchEngine {
  Lastfm._();
  static final _instance = Lastfm._();
  static Lastfm getInstance() => _instance;

  static Future<Response> get(String url) => _client.get(url);

  static Future<LAuthenticationResponseSession> authenticate(
      String token) async {
    final rawResponse = await _doRequest('auth.getSession', {'token': token},
        verb: RequestVerb.post);
    return LAuthenticationResponseSession.fromJson(rawResponse['session']);
  }

  static Future<LUser> getUser(String username) async {
    final rawResponse = await _doRequest('user.getInfo', {'user': username});
    return LUser.fromJson(rawResponse['user']);
  }

  static Future<LTrack> getTrack(BasicTrack track) async {
    final username = (await SharedPreferences.getInstance()).getString('name');

    final rawResponse = await _doRequest('track.getInfo',
        {'track': track.name, 'artist': track.artist, 'username': username});
    return LTrack.fromJson(rawResponse['track']);
  }

  static Future<LAlbum> getAlbum(BasicAlbum album) async {
    final username = (await SharedPreferences.getInstance()).getString('name');

    final rawResponse = await _doRequest('album.getInfo', {
      'album': album.name,
      'artist': album.artist.name,
      'username': username
    });
    return LAlbum.fromJson(rawResponse['album']);
  }

  static Future<LArtist> getArtist(BasicArtist artist) async {
    final username = (await SharedPreferences.getInstance()).getString('name');

    final rawResponse = await _doRequest(
        'artist.getInfo', {'artist': artist.name, 'username': username});
    return LArtist.fromJson(rawResponse['artist']);
  }

  static Future<int> getNumArtists(String username) async {
    final rawResponse = await _doRequest('user.getTopArtists',
        {'user': username, 'period': 'overall', 'limit': '1', 'page': '1'});
    return LTopArtistsResponseTopArtists.fromJson(rawResponse['topartists'])
        .attr
        .total;
  }

  static Future<int> getNumAlbums(String username) async {
    final rawResponse = await _doRequest('user.getTopAlbums',
        {'user': username, 'period': 'overall', 'limit': '1', 'page': '1'});
    return LTopAlbumsResponseTopAlbums.fromJson(rawResponse['topalbums'])
        .attr
        .total;
  }

  static Future<int> getNumTracks(String username) async {
    final rawResponse = await _doRequest('user.getTopTracks',
        {'user': username, 'period': 'overall', 'limit': '1', 'page': '1'});
    return LTopTracksResponseTopTracks.fromJson(rawResponse['toptracks'])
        .attr
        .total;
  }

  static Future<List<LTopArtistsResponseArtist>> getGlobalTopArtists(
      int limit) async {
    final rawResponse =
        await _doRequest('chart.getTopArtists', {'limit': limit, 'page': 1});
    return LChartTopArtists.fromJson(rawResponse['artists']).artists;
  }

  static Future<LScrobbleResponseScrobblesAttr> scrobble(
      List<BasicTrack> tracks, List<DateTime> timestamps) async {
    final Map<String, dynamic> data = {};
    data['sk'] = (await SharedPreferences.getInstance()).getString('key');

    tracks.asMap().forEach((i, track) {
      data['album[$i]'] = track.album;
      data['artist[$i]'] = track.artist;
      data['track[$i]'] = track.name;
      data['timestamp[$i]'] = timestamps[i].millisecondsSinceEpoch ~/ 1000;
    });

    final rawResponse =
        await _doRequest('track.scrobble', data, verb: RequestVerb.post);
    return LScrobbleResponseScrobblesAttr.fromJson(
        rawResponse['scrobbles']['@attr']);
  }

  /// Loves or unloves a track. If [love] is true, the track will be loved;
  /// otherwise, it will be unloved.
  static Future<bool> love(FullTrack track, bool love) async {
    await _doRequest(
        love ? 'track.love' : 'track.unlove',
        {
          'track': track.name,
          'artist': track.artist.name,
          'sk': (await SharedPreferences.getInstance()).getString('key')
        },
        verb: RequestVerb.post);
    return true;
  }

  @override
  PagedRequest<LTrackMatch> searchTracks(String query) {
//    return (int limit, int page, {String period}) async {
//      final rawResponse = await _doRequest(
//          'track.search', {'track': query, 'limit': limit, 'page': page});
//      return LTrackSearchResponse.fromJson(
//              rawResponse['results']['trackmatches'])
//          .tracks;
//    };
    return SearchTracksRequest(query);
  }
}

class LException implements Exception {
  int code;
  String message;

  LException(this.code, this.message);

  @override
  String toString() {
    return 'Error $code: $message';
  }
}
