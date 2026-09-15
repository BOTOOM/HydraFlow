import 'dart:math';
import 'package:flutter/material.dart';
import '../../domain/avatar_mood.dart';

/// A living water-drop companion. Breathes, wobbles, blinks, bobs, changes
/// colour/shape with its [state], celebrates when [celebrations] increments and
/// shakes when tapped.
class DropletAvatar extends StatefulWidget {
  const DropletAvatar({
    super.key,
    required this.state,
    this.size = 140,
    this.celebrations = 0,
    this.onTap,
  });

  final AvatarState state;
  final double size;

  /// Bump this counter every time the user logs a drink to trigger a cheer.
  final int celebrations;
  final VoidCallback? onTap;

  @override
  State<DropletAvatar> createState() => _DropletAvatarState();
}

class _DropletAvatarState extends State<DropletAvatar>
    with TickerProviderStateMixin {
  late final AnimationController _idle =
      AnimationController(vsync: this, duration: const Duration(seconds: 6))
        ..repeat();
  late final AnimationController _blink = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 180),
  );
  late final AnimationController _shake = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 700),
  );
  late final AnimationController _cheer = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  );
  final _random = Random();
  int _blinkTick = 0;

  @override
  void initState() {
    super.initState();
    _scheduleBlink();
  }

  void _scheduleBlink() {
    final wait = Duration(milliseconds: 2200 + _random.nextInt(3200));
    final tick = ++_blinkTick;
    Future<void>.delayed(wait, () async {
      if (!mounted || tick != _blinkTick) return;
      await _blink.forward(from: 0);
      if (!mounted) return;
      await _blink.reverse();
      if (mounted) _scheduleBlink();
    });
  }

  @override
  void didUpdateWidget(DropletAvatar old) {
    super.didUpdateWidget(old);
    if (widget.celebrations != old.celebrations) _cheer.forward(from: 0);
  }

  @override
  void dispose() {
    _blinkTick = -1;
    _idle.dispose();
    _blink.dispose();
    _shake.dispose();
    _cheer.dispose();
    super.dispose();
  }

  void _handleTap() {
    _shake.forward(from: 0);
    widget.onTap?.call();
  }

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: _handleTap,
        child: Semantics(
          label: 'Gotita, tu compañera de hidratación',
          button: true,
          child: AnimatedBuilder(
            animation: Listenable.merge([_idle, _blink, _shake, _cheer]),
            builder: (context, _) => CustomPaint(
              size: Size(widget.size, widget.size * 1.2),
              painter: _DropletPainter(
                state: widget.state,
                idle: _idle.value,
                blink: _blink.value,
                shake: _shake.isAnimating ? _shake.value : 0,
                cheer: _cheer.isAnimating ? _cheer.value : 0,
              ),
            ),
          ),
        ),
      );
}

class _Palette {
  const _Palette(this.top, this.bottom, this.face, this.glow);
  final Color top, bottom, face, glow;

  static _Palette lerp(_Palette a, _Palette b, double t) => _Palette(
        Color.lerp(a.top, b.top, t)!,
        Color.lerp(a.bottom, b.bottom, t)!,
        Color.lerp(a.face, b.face, t)!,
        Color.lerp(a.glow, b.glow, t)!,
      );
}

const _dry = _Palette(
  Color(0xFFB9C3C7),
  Color(0xFF7E8F96),
  Color(0xFF3A4A52),
  Color(0x00000000),
);
const _fresh = _Palette(
  Color(0xFF7BE7F4),
  Color(0xFF17A2C7),
  Color(0xFF0B3D4F),
  Color(0x5537D3EA),
);
const _radiant = _Palette(
  Color(0xFF9CF4FF),
  Color(0xFF1FB6E6),
  Color(0xFF0B3D4F),
  Color(0x8837D3EA),
);
const _night = _Palette(
  Color(0xFF7F8CF0),
  Color(0xFF3B47B8),
  Color(0xFF17204E),
  Color(0x556F7BFF),
);
const _nightTired = _Palette(
  Color(0xFF9AA0C4),
  Color(0xFF5B6291),
  Color(0xFF232847),
  Color(0x00000000),
);

class _DropletPainter extends CustomPainter {
  _DropletPainter({
    required this.state,
    required this.idle,
    required this.blink,
    required this.shake,
    required this.cheer,
  });

  final AvatarState state;
  final double idle, blink, shake, cheer;

  Mood get mood => state.mood;

  _Palette get palette => switch (mood) {
        Mood.radiant => _radiant,
        Mood.nightHappy => _night,
        Mood.nightSleepy => _nightTired,
        _ => _Palette.lerp(_dry, _fresh, Curves.easeOut.transform(state.vitality)),
      };

  double get smile => switch (mood) {
        Mood.radiant || Mood.nightHappy => 1,
        Mood.morning || Mood.happy => .8,
        Mood.okay => .25,
        Mood.thirsty => -.3,
        Mood.wilted => -.8,
        Mood.nightSleepy => -.1,
      };

  @override
  void paint(Canvas canvas, Size size) {
    final t = idle * 2 * pi;
    final cheerCurve = cheer == 0 ? 0.0 : sin(cheer * pi);
    final shakeX = shake == 0
        ? 0.0
        : sin(shake * pi * 6) * (1 - shake) * size.width * .08;
    final squash = shake == 0 ? 0.0 : sin(shake * pi * 6) * (1 - shake) * .08;
    final droop = (1 - state.vitality) * .5;
    final bob = sin(t) * size.height * .015 - cheerCurve * size.height * .12;
    final breath = 1 + sin(t * 2) * .02 + cheerCurve * .08;

    final r = size.width * .34 * (1 - droop * .15);
    final center = Offset(
      size.width / 2 + shakeX,
      size.height * .58 + bob + droop * size.height * .06,
    );

    _shadow(canvas, size, bob, cheerCurve);

    final body = _bodyPath(center, r, t, droop, breath, squash);
    final pal = palette;

    if (pal.glow.a > 0) {
      canvas.drawPath(
        body,
        Paint()
          ..color = pal.glow
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, r * .35),
      );
    }
    canvas.drawPath(
      body,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(-.45, -.55),
          radius: 1.1,
          colors: [pal.top, pal.bottom],
        ).createShader(body.getBounds()),
    );
    canvas.save();
    canvas.clipPath(body);
    canvas.drawCircle(
      center.translate(r * .1, r * .55),
      r * .95,
      Paint()
        ..color = Colors.black.withValues(alpha: .08)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, r * .3),
    );
    canvas.restore();

    _highlights(canvas, center, r);
    _face(canvas, center, r, pal, cheerCurve);
    _extras(canvas, center, r, t, size, cheerCurve);
  }

  void _shadow(Canvas canvas, Size size, double bob, double cheerCurve) {
    final w = size.width * (.42 - cheerCurve * .1 - bob / size.height * .3);
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(size.width / 2, size.height * .95),
        width: w,
        height: size.height * .05,
      ),
      Paint()
        ..color = Colors.black.withValues(alpha: .10)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
    );
  }

  Path _bodyPath(
    Offset c,
    double r,
    double t,
    double droop,
    double breath,
    double squash,
  ) {
    const steps = 96;
    final pts = <Offset>[];
    final wobbleAmp = .03 + state.vitality * .02;
    for (var i = 0; i < steps; i++) {
      final a = i / steps * 2 * pi;
      final up = -sin(a); // 1 at the top point
      final tip = pow(max(0.0, up), 6).toDouble() * (.55 - droop * .3);
      final wobble = sin(a * 3 + t * 1.3) * wobbleAmp + sin(a * 2 - t) * wobbleAmp * .6;
      var rad = r * (1 + tip + wobble);
      var x = cos(a) * rad * (1 + droop * .22 + squash);
      var y = sin(a) * rad * (breath - droop * .2 - squash);
      if (y > 0) y *= 1 + droop * .18;
      pts.add(Offset(c.dx + x, c.dy + y));
    }
    final path = Path();
    for (var i = 0; i < steps; i++) {
      final p0 = pts[i], p1 = pts[(i + 1) % steps];
      final mid = Offset((p0.dx + p1.dx) / 2, (p0.dy + p1.dy) / 2);
      if (i == 0) {
        path.moveTo(mid.dx, mid.dy);
      } else {
        path.quadraticBezierTo(p0.dx, p0.dy, mid.dx, mid.dy);
      }
    }
    final last = pts.last, first = pts.first;
    path.quadraticBezierTo(
      last.dx, last.dy, (last.dx + first.dx) / 2, (last.dy + first.dy) / 2);
    path.close();
    return path;
  }

  void _highlights(Canvas canvas, Offset c, double r) {
    final white = Paint()..color = Colors.white.withValues(alpha: .75);
    canvas.save();
    canvas.translate(c.dx - r * .45, c.dy - r * .55);
    canvas.rotate(-.6);
    canvas.drawOval(
      Rect.fromCenter(center: Offset.zero, width: r * .22, height: r * .5),
      white,
    );
    canvas.restore();
    canvas.drawCircle(
      c.translate(-r * .22, -r * .95),
      r * .06,
      white,
    );
  }

  void _face(Canvas canvas, Offset c, double r, _Palette pal, double cheerCurve) {
    final ink = Paint()..color = pal.face;
    final eyeY = c.dy - r * .05 + (1 - state.vitality) * r * .05;
    final eyeDx = r * .34;
    final eyeW = r * .17, eyeH = r * .24;
    final happyEyes = cheerCurve > .35 || mood == Mood.nightHappy;
    final sleepy = mood == Mood.nightSleepy;
    var lid = blink;
    if (sleepy) lid = max(lid, .55);
    if (mood == Mood.wilted) lid = max(lid, .3);

    for (final side in [-1, 1]) {
      final ex = c.dx + side * eyeDx;
      if (happyEyes) {
        final arc = Path()
          ..moveTo(ex - eyeW, eyeY + eyeH * .2)
          ..quadraticBezierTo(ex, eyeY - eyeH * .9, ex + eyeW, eyeY + eyeH * .2);
        canvas.drawPath(
          arc,
          Paint()
            ..color = pal.face
            ..style = PaintingStyle.stroke
            ..strokeWidth = r * .09
            ..strokeCap = StrokeCap.round,
        );
        continue;
      }
      final h = eyeH * (1 - lid).clamp(.08, 1);
      canvas.drawOval(
        Rect.fromCenter(center: Offset(ex, eyeY), width: eyeW, height: h),
        ink,
      );
      if (lid < .5) {
        canvas.drawCircle(
          Offset(ex - eyeW * .18, eyeY - h * .25),
          eyeW * .16,
          Paint()..color = Colors.white.withValues(alpha: .9),
        );
      }
      if (mood == Mood.thirsty || mood == Mood.wilted) {
        canvas.drawLine(
          Offset(ex - side * eyeW * .6, eyeY - eyeH * 1.05),
          Offset(ex + side * eyeW * .6, eyeY - eyeH * .8),
          Paint()
            ..color = pal.face
            ..strokeWidth = r * .05
            ..strokeCap = StrokeCap.round,
        );
      }
    }

    final s = smile + cheerCurve * .5;
    final mouthY = c.dy + r * .38;
    final mouthW = r * (.28 + s.abs() * .1);
    final mouth = Path()
      ..moveTo(c.dx - mouthW, mouthY - s * r * .06)
      ..quadraticBezierTo(c.dx, mouthY + s * r * .32, c.dx + mouthW, mouthY - s * r * .06);
    if (s > .85) {
      mouth.close();
      canvas.drawPath(mouth, ink);
      canvas.save();
      canvas.clipPath(mouth);
      canvas.drawCircle(
        Offset(c.dx, mouthY + r * .36),
        r * .17,
        Paint()..color = const Color(0xFFFF8A9B),
      );
      canvas.restore();
    } else {
      canvas.drawPath(
        mouth,
        Paint()
          ..color = pal.face
          ..style = PaintingStyle.stroke
          ..strokeWidth = r * .08
          ..strokeCap = StrokeCap.round,
      );
    }

    if (s > .3) {
      final blush = Paint()..color = const Color(0xFFFF8A9B).withValues(alpha: .35 + s * .2);
      for (final side in [-1, 1]) {
        canvas.drawOval(
          Rect.fromCenter(
            center: Offset(c.dx + side * r * .55, c.dy + r * .2),
            width: r * .26,
            height: r * .14,
          ),
          blush,
        );
      }
    }
  }

  void _extras(Canvas canvas, Offset c, double r, double t, Size size, double cheerCurve) {
    if (mood == Mood.thirsty || mood == Mood.wilted) {
      final drip = ((t / (2 * pi)) * 1.7) % 1;
      final y = c.dy - r * .5 + drip * r * .7;
      canvas.drawPath(
        _tinyDrop(Offset(c.dx + r * .72, y), r * .09),
        Paint()..color = const Color(0xFF8ED8F0).withValues(alpha: 1 - drip * .6),
      );
    }
    if (mood == Mood.radiant || cheerCurve > 0 || mood == Mood.nightHappy) {
      final sparkle = Paint()..color = const Color(0xFFFFE28A);
      for (var i = 0; i < 5; i++) {
        final a = t * .4 + i * 2 * pi / 5;
        final pulse = .6 + .4 * sin(t * 2 + i);
        final pos = Offset(
          c.dx + cos(a) * r * 1.45,
          c.dy - r * .2 + sin(a) * r * 1.05,
        );
        _star(canvas, pos, r * .09 * pulse * (1 + cheerCurve), sparkle);
      }
    }
    if (mood == Mood.nightSleepy || mood == Mood.nightHappy) {
      final tp = TextPainter(
        text: TextSpan(
          text: 'z',
          style: TextStyle(
            color: Colors.white.withValues(alpha: .8),
            fontSize: r * .34,
            fontWeight: FontWeight.w700,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      final phase = (t / (2 * pi)) % 1;
      tp.paint(canvas, Offset(c.dx + r * .95, c.dy - r * 1.0 - phase * r * .5));
    }
  }

  Path _tinyDrop(Offset p, double s) => Path()
    ..moveTo(p.dx, p.dy - s * 1.6)
    ..quadraticBezierTo(p.dx + s * 1.2, p.dy, p.dx, p.dy + s)
    ..quadraticBezierTo(p.dx - s * 1.2, p.dy, p.dx, p.dy - s * 1.6)
    ..close();

  void _star(Canvas canvas, Offset p, double s, Paint paint) {
    final path = Path()
      ..moveTo(p.dx, p.dy - s)
      ..quadraticBezierTo(p.dx, p.dy, p.dx + s, p.dy)
      ..quadraticBezierTo(p.dx, p.dy, p.dx, p.dy + s)
      ..quadraticBezierTo(p.dx, p.dy, p.dx - s, p.dy)
      ..quadraticBezierTo(p.dx, p.dy, p.dx, p.dy - s)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _DropletPainter old) => true;
}
