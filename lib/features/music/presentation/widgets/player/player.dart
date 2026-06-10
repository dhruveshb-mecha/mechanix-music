import 'package:flutter/material.dart';
import 'package:mechanix_music/features/music/presentation/widgets/player/player_bottom_bar.dart';
import 'package:mechanix_music/features/music/presentation/widgets/player/player_controls.dart';
import 'package:mechanix_music/features/music/presentation/widgets/player/player_header.dart';
import 'package:mechanix_music/features/music/presentation/widgets/player/player_vinyl.dart';

class Player extends StatelessWidget {
  const Player({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      bottomNavigationBar: PlayerBottomBar(),
      body: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [PlayerHeader(), PlayerVinyl(), PlayerControls()],
        ),
      ),
    );
  }
}
