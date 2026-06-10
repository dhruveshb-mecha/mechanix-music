import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:mechanix_music/core/utils/colors.dart';

class EqualizerIcon extends StatefulWidget {
  final bool isPlaying;
  final Color color;
  final double size;

  const EqualizerIcon({
    super.key,
    required this.isPlaying,
    this.color = MusicColors.progressBarColor,
    this.size = 24,
  });

  @override
  State<EqualizerIcon> createState() => _EqualizerIconState();
}

class _EqualizerIconState extends State<EqualizerIcon> {
  // ─── Pre-baked frame table (computed ONCE at class init, never again) ───────
  // 24 frames × 3 bars = 72 doubles in a flat List<double>.
  // No sin(), no math at runtime — just an array lookup per tick.
  static const _fps = 24; // 8 repaints/sec
  static const _totalFrames = 24; // 24 / 8fps = 3-second seamless loop
  static const _barCount = 3;
  static const _phases = [0.0, 2.094, 4.189]; // 0, 2π/3, 4π/3
  static const _minH = 0.15;
  static const _maxH = 1.0;

  /// Flat array: index = frameIndex * _barCount + barIndex
  static final _frameTable = _buildFrameTable();

  static List<double> _buildFrameTable() {
    final table = List<double>.filled(_totalFrames * _barCount, 0);
    for (int f = 0; f < _totalFrames; f++) {
      final t = f / _totalFrames * math.pi * 2;
      for (int b = 0; b < _barCount; b++) {
        table[f * _barCount + b] =
            _minH + (_maxH - _minH) * (0.5 + 0.5 * math.sin(t + _phases[b]));
      }
    }
    return List.unmodifiable(table);
  }

  int _frame = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    if (widget.isPlaying) _startTimer();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(
      const Duration(milliseconds: 1000 ~/ _fps), // 125 ms
      (_) {
        if (mounted) setState(() => _frame = (_frame + 1) % _totalFrames);
      },
    );
  }

  void _stopTimer() {
    _timer?.cancel();
    _timer = null;
  }

  @override
  void didUpdateWidget(EqualizerIcon old) {
    super.didUpdateWidget(old);
    if (widget.isPlaying == old.isPlaying) return;
    widget.isPlaying ? _startTimer() : _stopTimer();
  }

  @override
  void dispose() {
    _stopTimer();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: SizedBox(
        width: widget.size,
        height: widget.size,
        child: CustomPaint(
          // No `repaint:` listener needed — Timer drives setState instead,
          // which means no vsync / Ticker is alive at all.
          painter: _EqualizerPainter(
            color: widget.color,
            frameOffset: widget.isPlaying ? _frame * _barCount : -1,
            // -1 → painter draws idle (min-height) bars without a table lookup
          ),
        ),
      ),
    );
  }
}

// ─── Painter ──────────────────────────────────────────────────────────────────

class _EqualizerPainter extends CustomPainter {
  final Color color;
  final int frameOffset; // index into _frameTable; -1 = idle

  const _EqualizerPainter({required this.color, required this.frameOffset});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    const barCount = _EqualizerIconState._barCount;
    final barWidth = size.width * 0.22;
    final gap = (size.width - barWidth * barCount) / (barCount + 1);

    for (int i = 0; i < barCount; i++) {
      final h = frameOffset < 0
          ? _EqualizerIconState
                ._minH // idle
          : _EqualizerIconState._frameTable[frameOffset + i]; // playing

      final barHeight = size.height * h;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(
            gap + i * (barWidth + gap),
            size.height - barHeight,
            barWidth,
            barHeight,
          ),
          const Radius.circular(2),
        ),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_EqualizerPainter old) =>
      old.frameOffset != frameOffset || old.color != color;
}
