class SongResult {
  final int trackId;
  final String trackName;
  final String artistName;
  final String? artworkUrl;
  final String? previewUrl;

  const SongResult({
    required this.trackId,
    required this.trackName,
    required this.artistName,
    this.artworkUrl,
    this.previewUrl,
  });

  factory SongResult.fromJson(Map<String, dynamic> json) {
    // Upgrade artwork from 100x100 to 300x300 for better quality
    final art = json['artworkUrl100']?.toString();
    final betterArt = art?.replaceFirst('100x100', '300x300');
    return SongResult(
      trackId: json['trackId'] as int? ?? 0,
      trackName: json['trackName']?.toString() ?? '',
      artistName: json['artistName']?.toString() ?? '',
      artworkUrl: betterArt,
      previewUrl: json['previewUrl']?.toString(),
    );
  }
}
