import 'package:json_annotation/json_annotation.dart';
import 'package:simplescrobble/types/generic.dart';
import 'package:simplescrobble/types/lcommon.dart';

part 'lartist.g.dart';

@JsonSerializable()
class LTopArtistsResponseArtist extends BasicScrobbledArtist {
  String name;
  String url;

  @JsonKey(name: 'playcount', fromJson: int.parse)
  int playCount;

  LTopArtistsResponseArtist(this.name, this.url, this.playCount);

  factory LTopArtistsResponseArtist.fromJson(Map<String, dynamic> json) =>
      _$LTopArtistsResponseArtistFromJson(json);

  Map<String, dynamic> toJson() => _$LTopArtistsResponseArtistToJson(this);
}

@JsonSerializable()
class LTopArtistsResponseTopArtists {
  @JsonKey(name: 'artist')
  List<LTopArtistsResponseArtist> artists;

  LTopArtistsResponseTopArtists(this.artists);

  factory LTopArtistsResponseTopArtists.fromJson(Map<String, dynamic> json) =>
      _$LTopArtistsResponseTopArtistsFromJson(json);

  Map<String, dynamic> toJson() => _$LTopArtistsResponseTopArtistsToJson(this);
}

@JsonSerializable()
class LArtistMatch extends BasicArtist {
  String name;
  String url;

  LArtistMatch(this.name, this.url);

  factory LArtistMatch.fromJson(Map<String, dynamic> json) =>
      _$LArtistMatchFromJson(json);

  Map<String, dynamic> toJson() => _$LArtistMatchToJson(this);
}

@JsonSerializable()
class LArtistSearchResponse {
  @JsonKey(name: 'artist')
  List<LArtistMatch> artists;

  LArtistSearchResponse(this.artists);

  factory LArtistSearchResponse.fromJson(Map<String, dynamic> json) =>
      _$LArtistSearchResponseFromJson(json);

  Map<String, dynamic> toJson() => _$LArtistSearchResponseToJson(this);
}

@JsonSerializable()
class LArtistStats {
  @JsonKey(name: 'playcount', fromJson: int.parse)
  int playCount;

  @JsonKey(fromJson: int.parse)
  int listeners;

  @JsonKey(name: 'userplaycount', fromJson: int.parse)
  int userPlayCount;

  LArtistStats(this.playCount, this.userPlayCount, this.listeners);

  factory LArtistStats.fromJson(Map<String, dynamic> json) =>
      _$LArtistStatsFromJson(json);

  Map<String, dynamic> toJson() => _$LArtistStatsToJson(this);
}

@JsonSerializable()
class LArtist extends FullArtist {
  String name;
  String url;

  LArtistStats stats;

  @JsonKey(name: 'tags')
  LTopTags topTags;

  LArtist(this.name, this.url, this.stats, this.topTags);

  factory LArtist.fromJson(Map<String, dynamic> json) =>
      _$LArtistFromJson(json);

  Map<String, dynamic> toJson() => _$LArtistToJson(this);
}
