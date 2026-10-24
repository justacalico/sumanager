class CatalogGame {
  final int id;
  final String slug;
  final String title;
  final String coverUrl;
  final List<String> categories;
  final int fileSize;
  final bool uncensored;
  final String? publishedAt;
  final String? updatedAt;
  final bool recentlyUpdated;

  const CatalogGame({
    required this.id,
    required this.slug,
    required this.title,
    required this.coverUrl,
    this.categories = const [],
    this.fileSize = 0,
    this.uncensored = false,
    this.publishedAt,
    this.updatedAt,
    this.recentlyUpdated = false,
  });

  factory CatalogGame.fromJson(Map<String, dynamic> j) => CatalogGame(
        id: j['id'] is int ? j['id'] : int.tryParse('${j['id']}') ?? 0,
        slug: j['slug'] ?? '',
        title: _cleanTitle(j['title'] ?? j['name'] ?? j['slug'] ?? ''),
        coverUrl: j['cover_url'] ?? j['cover'] ?? j['image'] ?? '',
        categories: (j['categories'] as List? ?? []).map((e) => '$e').toList(),
        fileSize: j['file_size'] is int ? j['file_size'] : int.tryParse('${j['file_size']}') ?? 0,
        uncensored: j['uncensored'] == true || j['adult'] == true,
        publishedAt: j['published_at']?.toString(),
        updatedAt: j['updated_at']?.toString(),
        recentlyUpdated: j['recently_updated'] == true,
      );

  static String _cleanTitle(String t) =>
      t.replaceAll('&amp;', '&').replaceAll(' Free Download', '').replaceAll(RegExp(r'\s*\(v?[\d.]+[^)]*\)\s*$'), '').trim();

  Map<String, dynamic> toJson() => {
        'id': id, 'slug': slug, 'title': title, 'cover_url': coverUrl,
        'categories': categories, 'file_size': fileSize, 'uncensored': uncensored,
        'published_at': publishedAt, 'updated_at': updatedAt, 'recently_updated': recentlyUpdated,
      };
}

enum DownloadStatus { queued, resolving, downloading, paused, extracting, done, failed, cancelled }

class DownloadItem {
  String id;
  int catalogId;
  String slug;
  String title;
  String coverUrl;
  String savePath;
  int totalSize;
  int downloadedBytes;
  DownloadStatus status;
  String? error;
  int chunksTotal;
  int chunksDone;
  double speed;
  int? etaSecs;
  bool needsExtract;
  int extractDone;
  int extractTotal;
  String? gameFolder;
  String? downloadUrl;
  int addedAt;

  DownloadItem({
    required this.id,
    required this.catalogId,
    required this.slug,
    required this.title,
    this.coverUrl = '',
    this.savePath = '',
    this.totalSize = 0,
    this.downloadedBytes = 0,
    this.status = DownloadStatus.queued,
    this.error,
    this.chunksTotal = 0,
    this.chunksDone = 0,
    this.speed = 0,
    this.etaSecs,
    this.needsExtract = false,
    this.extractDone = 0,
    this.extractTotal = 0,
    this.gameFolder,
    this.downloadUrl,
    this.addedAt = 0,
  });

  double get progress => totalSize > 0 ? downloadedBytes / totalSize : 0;

  Map<String, dynamic> toJson() => {
        'id': id, 'catalog_id': catalogId, 'slug': slug, 'title': title, 'cover_url': coverUrl,
        'save_path': savePath, 'total_size': totalSize, 'downloaded': downloadedBytes,
        'status': status.name, 'error': error, 'chunks_total': chunksTotal, 'chunks_done': chunksDone,
        'needs_extract': needsExtract, 'extract_done': extractDone, 'extract_total': extractTotal,
        'game_folder': gameFolder, 'download_url': downloadUrl, 'added_at': addedAt,
      };

  factory DownloadItem.fromJson(Map<String, dynamic> j) => DownloadItem(
        id: j['id'] ?? '',
        catalogId: j['catalog_id'] ?? 0,
        slug: j['slug'] ?? '',
        title: j['title'] ?? '',
        coverUrl: j['cover_url'] ?? '',
        savePath: j['save_path'] ?? '',
        totalSize: j['total_size'] ?? 0,
        downloadedBytes: j['downloaded'] ?? 0,
        status: DownloadStatus.values.firstWhere((s) => s.name == j['status'], orElse: () => DownloadStatus.paused),
        error: j['error'],
        chunksTotal: j['chunks_total'] ?? 0,
        chunksDone: j['chunks_done'] ?? 0,
        needsExtract: j['needs_extract'] ?? false,
        extractDone: j['extract_done'] ?? 0,
        extractTotal: j['extract_total'] ?? 0,
        gameFolder: j['game_folder'],
        downloadUrl: j['download_url'],
        addedAt: j['added_at'] ?? 0,
      );
}

class LibraryGame {
  String gameKey;
  String title;
  String folderPath;
  String? exePath;
  int? catalogId;
  String? coverUrl;
  int? lastPlayed;
  int playSeconds;
  bool isCustom;
  List<String> collectionIds;

  LibraryGame({
    required this.gameKey,
    required this.title,
    required this.folderPath,
    this.exePath,
    this.catalogId,
    this.coverUrl,
    this.lastPlayed,
    this.playSeconds = 0,
    this.isCustom = false,
    this.collectionIds = const [],
  });

  Map<String, dynamic> toJson() => {
        'game_key': gameKey, 'title': title, 'folder_path': folderPath, 'exe_path': exePath,
        'catalog_id': catalogId, 'cover_url': coverUrl, 'last_played': lastPlayed,
        'play_seconds': playSeconds, 'is_custom': isCustom, 'collection_ids': collectionIds,
      };

  factory LibraryGame.fromJson(Map<String, dynamic> j) => LibraryGame(
        gameKey: j['game_key'] ?? '',
        title: j['title'] ?? '',
        folderPath: j['folder_path'] ?? '',
        exePath: j['exe_path'],
        catalogId: j['catalog_id'],
        coverUrl: j['cover_url'],
        lastPlayed: j['last_played'],
        playSeconds: j['play_seconds'] ?? 0,
        isCustom: j['is_custom'] ?? false,
        collectionIds: (j['collection_ids'] as List? ?? []).map((e) => '$e').toList(),
      );
}

class GameCollection {
  String id;
  String name;
  List<String> gameKeys;
  GameCollection({required this.id, required this.name, this.gameKeys = const []});
  Map<String, dynamic> toJson() => {'id': id, 'name': name, 'game_keys': gameKeys};
  factory GameCollection.fromJson(Map<String, dynamic> j) =>
      GameCollection(id: j['id'] ?? '', name: j['name'] ?? '', gameKeys: (j['game_keys'] as List? ?? []).map((e) => '$e').toList());
}

class ProStatus {
  final bool signedIn;
  final bool isPro;
  final String? email;
  final String? userId;
  final String? expiresAt;
  const ProStatus({this.signedIn = false, this.isPro = false, this.email, this.userId, this.expiresAt});
}

class UpdateInfo {
  final String version;
  final String tag;
  final String url;
  final String? notes;
  final String? pubDate;
  const UpdateInfo({required this.version, required this.tag, required this.url, this.notes, this.pubDate});
}

class ConnectivityResult {
  bool dnsOk, tcpOk, tlsOk, apiOk;
  int latencyMs;
  String? errorDetail;
  ConnectivityResult({this.dnsOk = false, this.tcpOk = false, this.tlsOk = false, this.apiOk = false, this.latencyMs = 0, this.errorDetail});
}

class Version {
  final List<int> parts;
  const Version(this.parts);
  static Version? parse(String s) {
    final m = RegExp(r'^v?(\d+)(?:\.(\d+))?(?:\.(\d+))?').firstMatch(s.trim());
    if (m == null) return null;
    return Version([int.parse(m.group(1)!), int.tryParse(m.group(2) ?? '') ?? 0, int.tryParse(m.group(3) ?? '') ?? 0]);
  }
  int compareTo(Version o) {
    for (var i = 0; i < 3; i++) {
      final a = i < parts.length ? parts[i] : 0;
      final b = i < o.parts.length ? o.parts[i] : 0;
      if (a != b) return a - b;
    }
    return 0;
  }
}
