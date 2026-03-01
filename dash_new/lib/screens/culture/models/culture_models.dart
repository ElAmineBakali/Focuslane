import 'package:cloud_firestore/cloud_firestore.dart';

enum ItemStatus { pending, inProgress, paused, completed, abandoned }

double _asDouble(dynamic v) => (v is num) ? v.toDouble() : 0.0;
int _asInt(dynamic v) => (v is num) ? v.toInt() : 0;
DateTime _asDate(dynamic v) => (v is Timestamp) ? v.toDate() : DateTime.now();

class Book {
  final String id;
  final String title;
  final String? author;
  final int? year;
  final String? genre;
  final int? pagesTotal;
  final int currentPage;
  final String? shortSummary;
  final String? deepSummary;
  final double? rating;
  final ItemStatus status;
  final List<String> tags;
  final String? coverUrl;
  final String? pdfUrl;
  final DateTime? startedAt;
  final DateTime? finishedAt;

  Book({
    required this.id,
    required this.title,
    this.author,
    this.year,
    this.genre,
    this.pagesTotal,
    this.currentPage = 0,
    this.shortSummary,
    this.deepSummary,
    this.rating,
    this.status = ItemStatus.pending,
    this.tags = const [],
    this.coverUrl,
    this.pdfUrl,
    this.startedAt,
    this.finishedAt,
  });

  Map<String, dynamic> toMap() => {
    'title': title,
    'author': author,
    'year': year,
    'genre': genre,
    'pagesTotal': pagesTotal,
    'currentPage': currentPage,
    'shortSummary': shortSummary,
    'deepSummary': deepSummary,
    'rating': rating,
    'status': status.name,
    'tags': tags,
    'coverUrl': coverUrl,
    'pdfUrl': pdfUrl,
    'startedAt': startedAt != null ? Timestamp.fromDate(startedAt!) : null,
    'finishedAt': finishedAt != null ? Timestamp.fromDate(finishedAt!) : null,
  };

  static Book fromSnap(DocumentSnapshot s) {
    final d = s.data() as Map<String, dynamic>;
    return Book(
      id: s.id,
      title: (d['title'] ?? '') as String,
      author: d['author'] as String?,
      year: (d['year'] as num?)?.toInt(),
      genre: d['genre'] as String?,
      pagesTotal: (d['pagesTotal'] as num?)?.toInt(),
      currentPage: (d['currentPage'] as num?)?.toInt() ?? 0,
      shortSummary: d['shortSummary'] as String?,
      deepSummary: d['deepSummary'] as String?,
      rating: (d['rating'] as num?)?.toDouble(),
      status: ItemStatus.values.firstWhere(
        (e) => e.name == (d['status'] ?? 'pending'),
        orElse: () => ItemStatus.pending,
      ),
      tags: (d['tags'] as List?)?.map((e) => e.toString()).toList() ?? const [],
      coverUrl: d['coverUrl'] as String?,
      pdfUrl: d['pdfUrl'] as String?,
      startedAt: (d['startedAt'] as Timestamp?)?.toDate(),
      finishedAt: (d['finishedAt'] as Timestamp?)?.toDate(),
    );
  }
}

class BookSession {
  final String id;
  final DateTime date;
  final int pages;
  final int minutes;
  final String? notes;

  BookSession({
    required this.id,
    required this.date,
    required this.pages,
    required this.minutes,
    this.notes,
  });

  Map<String, dynamic> toMap() => {
    'date': Timestamp.fromDate(date),
    'pages': pages,
    'minutes': minutes,
    'notes': notes,
  };

  static BookSession fromSnap(DocumentSnapshot s) {
    final d = s.data() as Map<String, dynamic>;
    return BookSession(
      id: s.id,
      date: _asDate(d['date']),
      pages: _asInt(d['pages']),
      minutes: _asInt(d['minutes']),
      notes: d['notes'] as String?,
    );
  }
}

class BookQuote {
  final String id;
  final int? page;
  final String text;
  final String? note;

  BookQuote({required this.id, this.page, required this.text, this.note});

  Map<String, dynamic> toMap() => {'page': page, 'text': text, 'note': note};

  static BookQuote fromSnap(DocumentSnapshot s) {
    final d = s.data() as Map<String, dynamic>;
    return BookQuote(
      id: s.id,
      page: (d['page'] as num?)?.toInt(),
      text: (d['text'] ?? '') as String,
      note: d['note'] as String?,
    );
  }
}

class Series {
  final String id;
  final String title;
  final String? platform;
  final ItemStatus status;
  final double? rating;
  final List<String> tags;
  final DateTime? startedAt;
  final DateTime? finishedAt;
  final String? posterUrl;

  Series({
    required this.id,
    required this.title,
    this.platform,
    this.status = ItemStatus.pending,
    this.rating,
    this.tags = const [],
    this.startedAt,
    this.finishedAt,
    this.posterUrl,
  });

  Map<String, dynamic> toMap() => {
    'title': title,
    'platform': platform,
    'status': status.name,
    'rating': rating,
    'tags': tags,
    'startedAt': startedAt != null ? Timestamp.fromDate(startedAt!) : null,
    'finishedAt': finishedAt != null ? Timestamp.fromDate(finishedAt!) : null,
    'posterUrl': posterUrl,
  };

  static Series fromSnap(DocumentSnapshot s) {
    final d = s.data() as Map<String, dynamic>;
    return Series(
      id: s.id,
      title: (d['title'] ?? '') as String,
      platform: d['platform'] as String?,
      status: ItemStatus.values.firstWhere(
        (e) => e.name == (d['status'] ?? 'pending'),
        orElse: () => ItemStatus.pending,
      ),
      rating: (d['rating'] as num?)?.toDouble(),
      tags: (d['tags'] as List?)?.map((e) => e.toString()).toList() ?? const [],
      startedAt: (d['startedAt'] as Timestamp?)?.toDate(),
      finishedAt: (d['finishedAt'] as Timestamp?)?.toDate(),
      posterUrl: d['posterUrl'] as String?,
    );
  }
}

class Episode {
  final String id;
  final int season;
  final int number;
  final String? title;
  final int? minutes;
  final bool watched;
  final DateTime? watchedAt;
  final double? rating;
  final String? notes;

  Episode({
    required this.id,
    required this.season,
    required this.number,
    this.title,
    this.minutes,
    this.watched = false,
    this.watchedAt,
    this.rating,
    this.notes,
  });

  Map<String, dynamic> toMap() => {
    'season': season,
    'number': number,
    'title': title,
    'minutes': minutes,
    'watched': watched,
    'watchedAt': watchedAt != null ? Timestamp.fromDate(watchedAt!) : null,
    'rating': rating,
    'notes': notes,
  };

  static Episode fromSnap(DocumentSnapshot s) {
    final d = s.data() as Map<String, dynamic>;
    return Episode(
      id: s.id,
      season: _asInt(d['season']),
      number: _asInt(d['number']),
      title: d['title'] as String?,
      minutes: (d['minutes'] as num?)?.toInt(),
      watched: (d['watched'] ?? false) as bool,
      watchedAt: (d['watchedAt'] as Timestamp?)?.toDate(),
      rating: (d['rating'] as num?)?.toDouble(),
      notes: d['notes'] as String?,
    );
  }
}

class Movie {
  final String id;
  final String title;
  final int? year;
  final int? minutes;
  final String? saga;
  final ItemStatus status;
  final double? rating;
  final List<String> tags;
  final String? posterUrl;
  final DateTime? watchedAt;
  final String? notes;

  Movie({
    required this.id,
    required this.title,
    this.year,
    this.minutes,
    this.saga,
    this.status = ItemStatus.pending,
    this.rating,
    this.tags = const [],
    this.posterUrl,
    this.watchedAt,
    this.notes,
  });

  Map<String, dynamic> toMap() => {
    'title': title,
    'year': year,
    'minutes': minutes,
    'saga': saga,
    'status': status.name,
    'rating': rating,
    'tags': tags,
    'posterUrl': posterUrl,
    'watchedAt': watchedAt != null ? Timestamp.fromDate(watchedAt!) : null,
    'notes': notes,
  };

  static Movie fromSnap(DocumentSnapshot s) {
    final d = s.data() as Map<String, dynamic>;
    return Movie(
      id: s.id,
      title: (d['title'] ?? '') as String,
      year: (d['year'] as num?)?.toInt(),
      minutes: (d['minutes'] as num?)?.toInt(),
      saga: d['saga'] as String?,
      status: ItemStatus.values.firstWhere(
        (e) => e.name == (d['status'] ?? 'pending'),
        orElse: () => ItemStatus.pending,
      ),
      rating: (d['rating'] as num?)?.toDouble(),
      tags: (d['tags'] as List?)?.map((e) => e.toString()).toList() ?? const [],
      posterUrl: d['posterUrl'] as String?,
      watchedAt: (d['watchedAt'] as Timestamp?)?.toDate(),
      notes: d['notes'] as String?,
    );
  }
}

class Album {
  final String id;
  final String title;
  final String artist;
  final int? year;
  final ItemStatus status;
  final double? rating;
  final List<String> favoriteTracks;
  final List<String> tags;
  final String? coverUrl;
  final DateTime? listenedAt;
  final String? notes;

  Album({
    required this.id,
    required this.title,
    required this.artist,
    this.year,
    this.status = ItemStatus.pending,
    this.rating,
    this.favoriteTracks = const [],
    this.tags = const [],
    this.coverUrl,
    this.listenedAt,
    this.notes,
  });

  Map<String, dynamic> toMap() => {
    'title': title,
    'artist': artist,
    'year': year,
    'status': status.name,
    'rating': rating,
    'favoriteTracks': favoriteTracks,
    'tags': tags,
    'coverUrl': coverUrl,
    'listenedAt': listenedAt != null ? Timestamp.fromDate(listenedAt!) : null,
    'notes': notes,
  };

  static Album fromSnap(DocumentSnapshot s) {
    final d = s.data() as Map<String, dynamic>;
    return Album(
      id: s.id,
      title: (d['title'] ?? '') as String,
      artist: (d['artist'] ?? '') as String,
      year: (d['year'] as num?)?.toInt(),
      status: ItemStatus.values.firstWhere(
        (e) => e.name == (d['status'] ?? 'pending'),
        orElse: () => ItemStatus.pending,
      ),
      rating: (d['rating'] as num?)?.toDouble(),
      favoriteTracks:
          (d['favoriteTracks'] as List?)?.map((e) => e.toString()).toList() ??
          const [],
      tags: (d['tags'] as List?)?.map((e) => e.toString()).toList() ?? const [],
      coverUrl: d['coverUrl'] as String?,
      listenedAt: (d['listenedAt'] as Timestamp?)?.toDate(),
      notes: d['notes'] as String?,
    );
  }
}

class Game {
  final String id;
  final String title;
  final String platform;
  final ItemStatus status;
  final double? rating;
  final double hours;
  final int progressPct;
  final List<String> tags;
  final String? coverUrl;
  final String? notes;
  final int? difficulty;
  Game({
    required this.id,
    required this.title,
    required this.platform,
    this.status = ItemStatus.pending,
    this.rating,
    this.hours = 0.0,
    this.progressPct = 0,
    this.tags = const [],
    this.coverUrl,
    this.notes,
    this.difficulty,
  });

  Map<String, dynamic> toMap() => {
    'title': title,
    'platform': platform,
    'status': status.name,
    'rating': rating,
    'hours': hours,
    'progressPct': progressPct,
    'tags': tags,
    'coverUrl': coverUrl,
    'notes': notes,
    'difficulty': difficulty,
  };

  static Game fromSnap(DocumentSnapshot s) {
    final d = s.data() as Map<String, dynamic>;
    return Game(
      id: s.id,
      title: (d['title'] ?? '') as String,
      platform: (d['platform'] ?? '') as String,
      status: ItemStatus.values.firstWhere(
        (e) => e.name == (d['status'] ?? 'pending'),
        orElse: () => ItemStatus.pending,
      ),
      rating: (d['rating'] as num?)?.toDouble(),
      hours: _asDouble(d['hours']),
      progressPct: _asInt(d['progressPct']),
      tags: (d['tags'] as List?)?.map((e) => e.toString()).toList() ?? const [],
      coverUrl: d['coverUrl'] as String?,
      notes: d['notes'] as String?,
      difficulty: (d['difficulty'] as num?)?.toInt(),
    );
  }
}

class GameSession {
  final String id;
  final DateTime date;
  final int minutes;
  final int? progressAfter;
  final String? notes;

  GameSession({
    required this.id,
    required this.date,
    required this.minutes,
    this.progressAfter,
    this.notes,
  });

  Map<String, dynamic> toMap() => {
    'date': Timestamp.fromDate(date),
    'minutes': minutes,
    'progressAfter': progressAfter,
    'notes': notes,
  };

  static GameSession fromSnap(DocumentSnapshot s) {
    final d = s.data() as Map<String, dynamic>;
    return GameSession(
      id: s.id,
      date: _asDate(d['date']),
      minutes: _asInt(d['minutes']),
      progressAfter: (d['progressAfter'] as num?)?.toInt(),
      notes: d['notes'] as String?,
    );
  }
}

class CultureCollectionItemRef {
  final String type;
  final String id;
  final int order;
  CultureCollectionItemRef({
    required this.type,
    required this.id,
    this.order = 0,
  });

  Map<String, dynamic> toMap() => {'type': type, 'id': id, 'order': order};

  static CultureCollectionItemRef fromMap(Map m) => CultureCollectionItemRef(
    type: m['type'] as String,
    id: m['id'] as String,
    order: (m['order'] as num?)?.toInt() ?? 0,
  );
}

class CultureCollection {
  final String id;
  final String name;
  final String? description;
  final DateTime? targetDate;
  final List<CultureCollectionItemRef> items;

  CultureCollection({
    required this.id,
    required this.name,
    this.description,
    this.targetDate,
    this.items = const [],
  });

  Map<String, dynamic> toMap() => {
    'name': name,
    'description': description,
    'targetDate': targetDate != null ? Timestamp.fromDate(targetDate!) : null,
    'items': items.map((e) => e.toMap()).toList(),
  };

  static CultureCollection fromSnap(DocumentSnapshot s) {
    final d = s.data() as Map<String, dynamic>;
    return CultureCollection(
      id: s.id,
      name: (d['name'] ?? '') as String,
      description: d['description'] as String?,
      targetDate: (d['targetDate'] as Timestamp?)?.toDate(),
      items:
          (d['items'] as List?)
              ?.map(
                (e) =>
                    CultureCollectionItemRef.fromMap(e as Map<String, dynamic>),
              )
              .toList() ??
          const [],
    );
  }
}
