import 'package:flutter/material.dart';
import 'package:mechanix_music/core/utils/constants.dart';
import 'package:mechanix_music/features/music/presentation/widgets/player/player_artwork.dart';
import 'package:mechanix_music/features/music/presentation/widgets/player/player_left_timestamp.dart';
import 'package:mechanix_music/features/music/presentation/widgets/player/player_right_timestamp.dart';
import 'package:mechanix_music/features/music/presentation/widgets/player/player_semi_circle_slider.dart';

class PlayerVinyl extends StatelessWidget {
  const PlayerVinyl({super.key});

  @override
  Widget build(BuildContext context) {
    const size = Constants.artworkSize;
    const outerWidth = size + 60;
    const outerHeight = size + 40;
    const center = Offset(outerWidth / 2, outerHeight / 2);
    const radius = size / 2 + 18;

    return SizedBox(
      width: outerWidth,
      height: outerHeight,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // 1. Slider
          const PlayerSemiCircleSlider(size: size),

          // 2. Vinyl
          const Center(child: PlayerArtwork(size: size)),

          // 3. Time labels
          Positioned(
            right: outerWidth - (center.dx - radius) - 12,
            top: center.dy - 20,
            child: const PlayerLeftTimestamp(),
          ),
          Positioned(
            left: center.dx + radius - 12,
            top: center.dy - 20,
            child: const PlayerRightTimestamp(),
          ),
        ],
      ),
    );
  }
}
