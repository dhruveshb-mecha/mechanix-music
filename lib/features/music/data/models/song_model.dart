import 'package:objectbox/objectbox.dart';

@Entity()
class SongModel {
  @Id()
  int obxId;

  @Unique()
  @Index()
  String id;

  @Unique()
  @Index()
  String path;

  String title;
  String artist;
  String? album;
  String? duration;
  String? artworkPath;

  /// UTC timestamp of when this song was last scanned from disk.
  @Property(type: PropertyType.date)
  DateTime lastScannedAt;

  bool isExternal; // If true, this song was imported from an external directory

  SongModel({
    this.obxId = 0,
    required this.id,
    required this.path,
    required this.title,
    required this.artist,
    this.album,
    this.duration,
    this.artworkPath,
    DateTime? lastScannedAt,
    this.isExternal = false,
  }) : lastScannedAt = lastScannedAt ?? DateTime.now().toUtc();
}
