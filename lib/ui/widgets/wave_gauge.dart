import 'dart:math';
import 'package:flutter/material.dart';
import '../../domain/models.dart';
import '../theme.dart';
import '../formatters.dart';

class WaveGauge extends StatefulWidget {
  const WaveGauge({super.key, required this.progress, required this.total, required this.goal, this.unit = UnitPreference.ml});
  final double progress;
  final int total;
  final int goal;
  final UnitPreference unit;
  @override State<WaveGauge> createState() => _WaveGaugeState();
}
class _WaveGaugeState extends State<WaveGauge> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(vsync: this, duration: const Duration(seconds: 3))..repeat();
  @override void dispose() { _controller.dispose(); super.dispose(); }
  @override Widget build(BuildContext context) => AnimatedBuilder(
    animation: _controller, builder: (context, child) => CustomPaint(
      painter: _WaveGaugePainter(widget.progress, _controller.value),
      child: SizedBox(width: 260, height: 260, child: Center(child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('${(widget.total / max(widget.goal, 1) * 100).round()}%', style: const TextStyle(fontSize: 44, fontWeight: FontWeight.w800)),
          Text(formatVolumePair(widget.total, widget.goal, widget.unit), style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 14)),
        ],
      ))),
    ),
  );
}
class _WaveGaugePainter extends CustomPainter {
  _WaveGaugePainter(this.progress, this.phase);
  final double progress, phase;
  @override void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero), radius = size.shortestSide / 2 - 9;
    final track = Paint()..style = PaintingStyle.stroke..strokeWidth = 11..color = HydraTheme.aqua.withValues(alpha: .14);
    canvas.drawCircle(center, radius, track);
    canvas.save();
    canvas.clipPath(Path()..addOval(Rect.fromCircle(center: center, radius: radius - 4)));
    final fillTop = size.height - 8 - (size.height - 16) * progress.clamp(0, 1);
    final wave = Path()..moveTo(0, fillTop);
    for (var x = 0.0; x <= size.width; x += 3) {
      wave.lineTo(x, fillTop + sin(x / 24 + phase * 2 * pi) * 5);
    }
    wave..lineTo(size.width, size.height)..lineTo(0, size.height)..close();
    canvas.drawPath(wave, Paint()..color = HydraTheme.aqua.withValues(alpha: .85));
    canvas.restore();
    canvas.drawCircle(center, radius, track);
  }
  @override bool shouldRepaint(covariant _WaveGaugePainter old) => old.progress != progress || old.phase != phase;
}
