import 'package:flutter/material.dart';

import 'dashboard/culture_home_screen.dart';
import 'analytics/culture_analytics_screen.dart';

import 'library/books_list_screen.dart';
import 'library/series_list_screen.dart';
import 'library/movies_list_screen.dart';
import 'library/music_list_screen.dart';
import 'library/games_list_screen.dart';
import 'library/collections_screen.dart';

import 'books/book_detail_screen.dart';
import 'books/book_edit_screen.dart';
import 'series/series_detail_screen.dart';
import 'series/series_edit_screen.dart';
import 'movies/movie_detail_screen.dart';
import 'movies/movie_edit_screen.dart';
import 'music/album_detail_screen.dart';
import 'music/album_edit_screen.dart';
import 'games/game_detail_screen.dart';
import 'games/game_edit_screen.dart';

Map<String, WidgetBuilder> cultureRoutes = {
  CultureHomeScreen.route: (_) => const CultureHomeScreen(),
  CultureAnalyticsScreen.route: (_) => const CultureAnalyticsScreen(),

  BooksListScreen.route: (_) => const BooksListScreen(),
  BookEditScreen.route: (_) => const BookEditScreen(),
  BookDetailScreen.route: (_) => const BookDetailScreen(),

  SeriesListScreen.route: (_) => const SeriesListScreen(),
  SeriesEditScreen.route: (_) => const SeriesEditScreen(),
  SeriesDetailScreen.route: (_) => const SeriesDetailScreen(),

  MoviesListScreen.route: (_) => const MoviesListScreen(),
  MovieEditScreen.route: (_) => const MovieEditScreen(),
  MovieDetailScreen.route: (_) => const MovieDetailScreen(),

  MusicListScreen.route: (_) => const MusicListScreen(),
  AlbumEditScreen.route: (_) => const AlbumEditScreen(),
  AlbumDetailScreen.route: (_) => const AlbumDetailScreen(),

  GamesListScreen.route: (_) => const GamesListScreen(),
  GameEditScreen.route: (_) => const GameEditScreen(),
  GameDetailScreen.route: (_) => const GameDetailScreen(),

  CollectionsScreen.route: (_) => const CollectionsScreen(),
};
