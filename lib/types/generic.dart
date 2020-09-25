import 'dart:async';

import 'package:finale/lastfm.dart';
import 'package:finale/views/album_view.dart';
import 'package:finale/views/artist_view.dart';
import 'package:finale/views/track_view.dart';
import 'package:flutter/widgets.dart';
import 'package:html/parser.dart' show parse;
import 'package:intl/intl.dart';

bool convertStringToBoolean(String text) => text == '1';

int intParseSafe(String text) => text != null ? int.tryParse(text) : null;

DateTime fromSecondsSinceEpoch(dynamic timestamp) =>
    DateTime.fromMillisecondsSinceEpoch(
        (timestamp is int ? timestamp : int.parse(timestamp)) * 1000);

final _numberFormat = NumberFormat();

String formatNumber(int number) => _numberFormat.format(number);

String extractImageId(List<dynamic> /* List<Map<String, dynamic>> */ images) {
  if (images == null ||
      images.isEmpty ||
      !images.first.containsKey('#text') ||
      images.first['#text'].isEmpty) {
    return null;
  }

  final String imageUrl = images.first['#text'];
  return imageUrl.substring(imageUrl.lastIndexOf('/'));
}

enum DisplayableType { track, album, artist, user }

abstract class Displayable {
  DisplayableType get type;

  String get url;

  String get displayTitle;

  String get displaySubtitle => null;

  String get displayTrailing => null;

  String get imageId => null;

  Future<String> get imageIdFuture => null;

  Widget get detailWidget => null;
}

abstract class BasicTrack extends Displayable {
  String get name;

  String get artist;

  String get album;

  @override
  DisplayableType get type => DisplayableType.track;

  @override
  String get displayTitle => name;

  @override
  String get displaySubtitle => artist;

  @override
  Widget get detailWidget => TrackView(track: this);
}

class BasicConcreteTrack extends BasicTrack {
  String name;
  String artist;
  String album;
  String url;
  int duration;

  BasicConcreteTrack(this.name, this.artist, this.album,
      {this.url, this.duration});
}

abstract class BasicScrobbledTrack extends BasicTrack {
  DateTime get date;

  @override
  String get displayTrailing {
    if (date == null) {
      return 'scrobbling now';
    }

    final delta = DateTime.now().difference(date);

    if (delta.inDays == 0) {
      if (delta.inHours == 0) {
        return '${delta.inMinutes} min${delta.inMinutes == 1 ? '' : 's'} ago';
      }

      return '${delta.inHours} hour${delta.inHours == 1 ? '' : 's'} ago';
    }

    return DateFormat('dd MMM HH:mm aa').format(date);
  }
}

abstract class BasicScrobbleableTrack extends BasicTrack {
  int get duration;
}

abstract class FullTrack extends Displayable {
  DisplayableType get type => DisplayableType.track;

  String get name;

  BasicArtist get artist;

  BasicAlbum get album;

  String get url;

  String get displayTitle => name;
}

abstract class BasicAlbum extends Displayable {
  String get name;

  BasicArtist get artist;

  @override
  String get imageId;

  @override
  DisplayableType get type => DisplayableType.album;

  @override
  String get displayTitle => name;

  @override
  String get displaySubtitle => artist.name;

  @override
  Widget get detailWidget => AlbumView(album: this);
}

abstract class FullAlbum extends BasicAlbum {
  List<BasicScrobbleableTrack> get tracks;
}

abstract class BasicScrobbledAlbum extends BasicAlbum {
  int get playCount;

  @override
  String get displayTrailing => '${formatNumber(playCount)} scrobbles';
}

abstract class BasicArtist extends Displayable {
  String get name;

  @override
  Future<String> get imageIdFuture async {
    final lastfmResponse = await Lastfm.get(url);

    try {
      final doc = parse(lastfmResponse.body);
      final rawUrl = doc
          .querySelectorAll('.header-new-gallery--link')
          .first
          .attributes['href'];
      final imageId = rawUrl.substring(rawUrl.lastIndexOf('/'));
      return imageId;
    } catch (e) {
      return null;
    }
  }

  @override
  DisplayableType get type => DisplayableType.artist;

  @override
  String get displayTitle => name;

  @override
  Widget get detailWidget => ArtistView(artist: this);
}

class ConcreteBasicArtist extends BasicArtist {
  String name;
  String url;

  ConcreteBasicArtist(this.name, [this.url]);
}

abstract class BasicScrobbledArtist extends BasicArtist {
  int get playCount;

  @override
  String get displayTrailing => '${formatNumber(playCount)} scrobbles';
}

abstract class FullArtist extends BasicArtist {}

//typedef Future<List<T>> PagedRequest<T>(int limit, int page, {String period});

abstract class PagedRequest<T extends Displayable> {
  Future<List<T>> doRequest(int limit, int page, {String period});
}

abstract class SearchEngine {
  PagedRequest<BasicTrack> searchTracks(String query);
}
