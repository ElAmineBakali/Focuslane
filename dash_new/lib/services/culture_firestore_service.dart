import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/culture_models.dart';

class CultureFirestoreService {
  CultureFirestoreService._();
  static final CultureFirestoreService I = CultureFirestoreService._();

  final _db = FirebaseFirestore.instance;
  String get _uid => FirebaseAuth.instance.currentUser!.uid;

  CollectionReference get _root =>
      _db.collection('users').doc(_uid).collection('culture');
  CollectionReference get _booksCol => _root.doc('data').collection('books');
  CollectionReference get _seriesCol => _root.doc('data').collection('series');
  CollectionReference get _moviesCol => _root.doc('data').collection('movies');
  CollectionReference get _albumsCol => _root.doc('data').collection('albums');
  CollectionReference get _gamesCol => _root.doc('data').collection('games');
  CollectionReference get _collectionsCol =>
      _root.doc('data').collection('collections');

  Stream<List<Book>> watchBooks({ItemStatus? status}) {
    Query q = _booksCol.orderBy('title');
    if (status != null) q = q.where('status', isEqualTo: status.name);
    return q.snapshots().map((s) => s.docs.map(Book.fromSnap).toList());
  }

  Future<void> addBook(Book b) async => _booksCol.add(b.toMap());
  Future<void> updateBook(Book b) async =>
      _booksCol.doc(b.id).update(b.toMap());
  Future<void> deleteBook(String id) async => _booksCol.doc(id).delete();

  CollectionReference _bookSessions(String bookId) =>
      _booksCol.doc(bookId).collection('sessions');
  CollectionReference _bookQuotes(String bookId) =>
      _booksCol.doc(bookId).collection('quotes');

  Stream<List<BookSession>> watchBookSessions(String bookId) =>
      _bookSessions(bookId)
          .orderBy('date', descending: true)
          .snapshots()
          .map((s) => s.docs.map(BookSession.fromSnap).toList());
  Future<void> addBookSession(String bookId, BookSession x) async =>
      _bookSessions(bookId).add(x.toMap());

  Stream<List<BookQuote>> watchBookQuotes(String bookId) => _bookQuotes(bookId)
      .orderBy('page')
      .snapshots()
      .map((s) => s.docs.map(BookQuote.fromSnap).toList());
  Future<void> addBookQuote(String bookId, BookQuote q) async =>
      _bookQuotes(bookId).add(q.toMap());
  Future<void> deleteBookQuote(String bookId, String quoteId) async =>
      _bookQuotes(bookId).doc(quoteId).delete();

  Future<void> setBookCurrentPage(String bookId, int page) async =>
      _booksCol.doc(bookId).update({'currentPage': page});

  Stream<List<Series>> watchSeries({ItemStatus? status}) {
    Query q = _seriesCol.orderBy('title');
    if (status != null) q = q.where('status', isEqualTo: status.name);
    return q.snapshots().map((s) => s.docs.map(Series.fromSnap).toList());
  }

  Future<void> addSeries(Series x) async => _seriesCol.add(x.toMap());
  Future<void> updateSeries(Series x) async =>
      _seriesCol.doc(x.id).update(x.toMap());
  Future<void> deleteSeries(String id) async => _seriesCol.doc(id).delete();

  CollectionReference _episodesCol(String seriesId) =>
      _seriesCol.doc(seriesId).collection('episodes');

  Stream<List<Episode>> watchEpisodes(String seriesId) => _episodesCol(seriesId)
      .orderBy('season')
      .orderBy('number')
      .snapshots()
      .map((s) => s.docs.map(Episode.fromSnap).toList());

  Future<void> addEpisode(String seriesId, Episode e) async =>
      _episodesCol(seriesId).add(e.toMap());
  Future<void> updateEpisode(String seriesId, Episode e) async =>
      _episodesCol(seriesId).doc(e.id).update(e.toMap());
  Future<void> deleteEpisode(String seriesId, String episodeId) async =>
      _episodesCol(seriesId).doc(episodeId).delete();

  Future<void> setEpisodeWatched(
    String seriesId,
    Episode e,
    bool watched,
  ) async => _episodesCol(seriesId).doc(e.id).update({
    'watched': watched,
    'watchedAt': watched ? Timestamp.now() : null,
  });

  Stream<List<Movie>> watchMovies({ItemStatus? status}) {
    Query q = _moviesCol.orderBy('title');
    if (status != null) q = q.where('status', isEqualTo: status.name);
    return q.snapshots().map((s) => s.docs.map(Movie.fromSnap).toList());
  }

  Future<void> addMovie(Movie m) async => _moviesCol.add(m.toMap());
  Future<void> updateMovie(Movie m) async =>
      _moviesCol.doc(m.id).update(m.toMap());
  Future<void> deleteMovie(String id) async => _moviesCol.doc(id).delete();

  Stream<List<Album>> watchAlbums({ItemStatus? status}) {
    Query q = _albumsCol.orderBy('artist').orderBy('title');
    if (status != null) q = q.where('status', isEqualTo: status.name);
    return q.snapshots().map((s) => s.docs.map(Album.fromSnap).toList());
  }

  Future<void> addAlbum(Album a) async => _albumsCol.add(a.toMap());
  Future<void> updateAlbum(Album a) async =>
      _albumsCol.doc(a.id).update(a.toMap());
  Future<void> deleteAlbum(String id) async => _albumsCol.doc(id).delete();

  Stream<List<Game>> watchGames({ItemStatus? status}) {
    Query q = _gamesCol.orderBy('title');
    if (status != null) q = q.where('status', isEqualTo: status.name);
    return q.snapshots().map((s) => s.docs.map(Game.fromSnap).toList());
  }

  Future<void> addGame(Game g) async => _gamesCol.add(g.toMap());
  Future<void> updateGame(Game g) async =>
      _gamesCol.doc(g.id).update(g.toMap());
  Future<void> deleteGame(String id) async => _gamesCol.doc(id).delete();

  CollectionReference _gameSessions(String gameId) =>
      _gamesCol.doc(gameId).collection('sessions');
  Stream<List<GameSession>> watchGameSessions(String gameId) =>
      _gameSessions(gameId)
          .orderBy('date', descending: true)
          .snapshots()
          .map((s) => s.docs.map(GameSession.fromSnap).toList());
  Future<void> addGameSession(String gameId, GameSession s) async =>
      _gameSessions(gameId).add(s.toMap());

  Stream<List<CultureCollection>> watchCollections() => _collectionsCol
      .orderBy('name')
      .snapshots()
      .map((s) => s.docs.map(CultureCollection.fromSnap).toList());

  Future<void> addCollection(CultureCollection c) async =>
      _collectionsCol.add(c.toMap());
  Future<void> updateCollection(CultureCollection c) async =>
      _collectionsCol.doc(c.id).update(c.toMap());
  Future<void> deleteCollection(String id) async =>
      _collectionsCol.doc(id).delete();

  Future<Map<String, dynamic>> quickKpis() async {
    final books =
        await _booksCol
            .where('status', isEqualTo: ItemStatus.completed.name)
            .get();
    final movies =
        await _moviesCol
            .where('status', isEqualTo: ItemStatus.completed.name)
            .get();
    final series =
        await _seriesCol
            .where('status', isEqualTo: ItemStatus.completed.name)
            .get();
    final games =
        await _gamesCol
            .where(
              'status',
              whereIn: [ItemStatus.completed.name, ItemStatus.inProgress.name],
            )
            .get();

    double hoursGames = 0;
    for (final d in games.docs) {
      final m = d.data() as Map<String, dynamic>;
      hoursGames += (m['hours'] is num) ? (m['hours'] as num).toDouble() : 0.0;
    }

    return {
      'booksDone': books.docs.length,
      'moviesDone': movies.docs.length,
      'seriesDone': series.docs.length,
      'gameHours': hoursGames,
    };
  }
}
