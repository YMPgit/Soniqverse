class Song {
  final int id;
  final String title;
  final String artist;
  final String audioUrl;
  final String coverUrl;
  final Duration? duration;

  const Song({
    required this.id,
    required this.title,
    required this.artist,
    required this.audioUrl,
    required this.coverUrl,
    this.duration,
  });

  factory Song.fromJamendoJson(Map<String, dynamic> json) {
    return Song(
      id: int.parse(json['id'] as String),
      title: json['name'] as String,
      artist: json['artist_name'] as String,
      audioUrl: json['audio'] as String,
      coverUrl: (json['album_image'] as String?) ??
          'https://via.placeholder.com/300',
      duration: Duration(seconds: (json['duration'] as num).toInt()),
    );
  }
}
