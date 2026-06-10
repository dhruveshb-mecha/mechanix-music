import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mechanix_music/l10n/music_localizations.dart';
import 'package:mechanix_music/core/utils/app_routes.dart';
import 'package:mechanix_music/core/utils/theme.dart';
import 'package:mechanix_music/features/music/bloc/player/player_bloc.dart';
import 'package:mechanix_music/features/music/bloc/song_bloc.dart';
import 'package:mechanix_music/features/music/bloc/song_event.dart';
import 'package:mechanix_music/features/music/data/repository/song_repository.dart';
import 'package:mechanix_music/features/music/data/repository/song_repository_impl.dart';
import 'package:mechanix_music/features/music/data/repository/playback_repository.dart';
import 'package:mechanix_music/features/music/data/repository/playback_repository_impl.dart';
import 'package:mechanix_music/features/music/presentation/screens/music_screen.dart';
import 'package:mechanix_music/features/music/presentation/screens/player_screen.dart';
import 'package:show_fps/show_fps.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  runApp(
    MultiRepositoryProvider(
      providers: [
        RepositoryProvider<SongRepository>(create: (_) => SongRepositoryImpl()),
        RepositoryProvider<PlaybackRepository>(
          create: (_) => PlaybackRepositoryImpl(),
        ),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider(
            lazy: false,
            create: (context) =>
                SongBloc(songRepository: context.read<SongRepository>())
                  ..add(const SongInitialized()),
          ),
          BlocProvider(
            create: (context) => PlaybackBloc(
              context.read<PlaybackRepository>(),
              context.read<SongBloc>(),
            ),
          ),
        ],
        child: const MusicApp(),
      ),
    ),
  );
}

class MusicApp extends StatelessWidget {
  const MusicApp({super.key});

  @override
  Widget build(BuildContext context) {
    final showFps = Platform.environment['SHOW_FPS'] == 'true';

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      builder: showFps
          ? (context, child) {
              return ShowFPS(visible: showFps, showChart: false, child: child!);
            }
          : null,
      themeMode: ThemeMode.dark,
      darkTheme: AppTheme.dark,
      theme: AppTheme.light,
      locale: const Locale('en'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      routes: {AppRoutes.player: (context) => const PlayerScreen()},
      home: const MusicScreen(),
    );
  }
}
