import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mechanix_music/core/utils/colors.dart';
import 'package:mechanix_music/core/utils/constants.dart';
import 'package:mechanix_music/features/music/bloc/player/player_bloc.dart';
import 'package:mechanix_music/features/music/bloc/player/player_event.dart';
import 'package:mechanix_music/features/music/bloc/player/player_state.dart';
import 'package:mechanix_music/features/music/data/repository/playback_repository.dart';

class PlayerSemiCircleSlider extends StatefulWidget {
  final double size;
  const PlayerSemiCircleSlider({super.key, this.size = Constants.artworkSize});

  @override
  State<PlayerSemiCircleSlider> createState() => _PlayerSemiCircleSliderState();
}

class _PlayerSemiCircleSliderState extends State<PlayerSemiCircleSlider> {
  Duration _position = Duration.zero;
  bool _isDragging = false;
  double _dragProgress = 0.0;
  bool _isDragValid = false;
  StreamSubscription<Duration>? _positionSubscription;
  MouseCursor _cursor = MouseCursor.defer;

  @override
  void initState() {
    super.initState();
    final repo = context.read<PlaybackRepository>();

    repo.getCurrentPosition().then((pos) {
      if (mounted && pos != null && !_isDragging) {
        setState(() => _position = pos);
      }
    });

    _positionSubscription = repo.onPositionChanged.listen((pos) {
      if (mounted && !_isDragging) {
        setState(() => _position = pos);
      }
    });
  }

  @override
  void dispose() {
    _positionSubscription?.cancel();
    super.dispose();
  }

  void _handleGesture(Offset localPosition, double size, {bool isTap = false}) {
    final outerWidth = size + 60;
    final outerHeight = size + 40;
    final center = Offset(outerWidth / 2, outerHeight / 2);
    final dx = localPosition.dx - center.dx;
    final dy = localPosition.dy - center.dy;

    final dist = sqrt(dx * dx + dy * dy);
    final radius = size / 2 + 18;

    if (isTap || !_isDragging) {
      final isNearArc = dy >= -10 && (dist - radius).abs() <= 25;
      if (!isNearArc) {
        _isDragValid = false;
        return;
      }
      _isDragValid = true;
    }

    if (!_isDragValid) return;

    double angle = atan2(dy, dx);
    if (angle < 0) {
      if (dx < 0) {
        angle = pi;
      } else {
        angle = 0.0;
      }
    }

    double progress = (pi - angle) / pi;
    progress = progress.clamp(0.0, 1.0);

    setState(() {
      _isDragging = true;
      _dragProgress = progress;
    });
  }

  void _handleGestureEnd() {
    final songDuration = context.read<PlaybackBloc>().state.songDuration;

    if (_isDragValid && _isDragging && songDuration.inMilliseconds > 0) {
      final seekPosition = Duration(
        milliseconds: (_dragProgress * songDuration.inMilliseconds).round(),
      );
      context.read<PlaybackBloc>().add(PlaybackSeek(seekPosition));
      setState(() {
        _isDragging = false;
        _position = seekPosition;
      });
    } else {
      setState(() {
        _isDragging = false;
      });
    }
    _isDragValid = false;
  }

  void _handleHover(Offset localPosition, double size) {
    final outerWidth = size + 60;
    final outerHeight = size + 40;
    final center = Offset(outerWidth / 2, outerHeight / 2);
    final dx = localPosition.dx - center.dx;
    final dy = localPosition.dy - center.dy;

    final dist = sqrt(dx * dx + dy * dy);
    final radius = size / 2 + 18;

    final isNearArc =
        dy >= -10 && dist >= (radius - 20) && dist <= (radius + 20);

    final newCursor = isNearArc ? SystemMouseCursors.click : MouseCursor.defer;
    if (_cursor != newCursor) {
      setState(() {
        _cursor = newCursor;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final radius = widget.size / 2 + 18;

    return BlocBuilder<PlaybackBloc, PlaybackState>(
      buildWhen: (previous, current) =>
          previous.songDuration != current.songDuration,
      builder: (context, state) {
        final songDuration = state.songDuration;
        final displayProgress = _isDragging
            ? _dragProgress
            : (songDuration.inMilliseconds > 0
                  ? (_position.inMilliseconds / songDuration.inMilliseconds)
                        .clamp(0.0, 1.0)
                  : 0.0);

        return Positioned.fill(
          child: MouseRegion(
            cursor: _cursor,
            onHover: (event) => _handleHover(event.localPosition, widget.size),
            onExit: (_) => setState(() => _cursor = MouseCursor.defer),
            child: GestureDetector(
              onPanStart: (details) =>
                  _handleGesture(details.localPosition, widget.size),
              onPanUpdate: (details) =>
                  _handleGesture(details.localPosition, widget.size),
              onPanEnd: (_) => _handleGestureEnd(),
              onTapDown: (details) => _handleGesture(
                details.localPosition,
                widget.size,
                isTap: true,
              ),
              onTapUp: (_) => _handleGestureEnd(),
              behavior: HitTestBehavior.opaque,
              child: RepaintBoundary(
                child: CustomPaint(
                  painter: SemiCircularSliderPainter(
                    progress: displayProgress,
                    trackColor: MusicColors.progressBarColor,
                    progressColor: MusicColors.titleColor,
                    thumbColor: Colors.white,
                    radius: radius,
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class SemiCircularSliderPainter extends CustomPainter {
  final double progress;
  final Color trackColor;
  final Color progressColor;
  final Color thumbColor;
  final double radius;

  SemiCircularSliderPainter({
    required this.progress,
    required this.trackColor,
    required this.progressColor,
    required this.thumbColor,
    required this.radius,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final rect = Rect.fromCircle(center: center, radius: radius);

    // Draw track arc
    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.0
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(rect, pi, -pi, false, trackPaint);

    // Draw progress arc
    if (progress > 0) {
      final progressPaint = Paint()
        ..shader = LinearGradient(
          colors: [progressColor.withValues(alpha: 0.5), progressColor],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ).createShader(rect)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 6.0
        ..strokeCap = StrokeCap.round;

      canvas.drawArc(rect, pi, -progress * pi, false, progressPaint);
    }

    // Draw thumb at current position
    final thumbAngle = pi - progress * pi;
    final thumbCenter = Offset(
      center.dx + radius * cos(thumbAngle),
      center.dy + radius * sin(thumbAngle),
    );

    // Draw outer thumb glow
    final thumbGlowPaint = Paint()
      ..color = progressColor.withValues(alpha: 0.3)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(thumbCenter, 10.0, thumbGlowPaint);

    // Draw inner thumb
    final thumbPaint = Paint()
      ..color = thumbColor
      ..style = PaintingStyle.fill;
    canvas.drawCircle(thumbCenter, 6.0, thumbPaint);

    // Draw thumb border
    final thumbBorderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawCircle(thumbCenter, 6.0, thumbBorderPaint);
  }

  @override
  bool shouldRepaint(covariant SemiCircularSliderPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.trackColor != trackColor ||
        oldDelegate.progressColor != progressColor ||
        oldDelegate.thumbColor != thumbColor ||
        oldDelegate.radius != radius;
  }
}
