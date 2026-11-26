import 'dart:math';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';
import 'main_shell.dart';
import 'theme_provide.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen>
    with TickerProviderStateMixin {
  late final AnimationController _spin = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 9),
  )..repeat();
  late final AnimationController _ring = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2400),
  )..repeat();

  @override
  void dispose() {
    _spin.dispose();
    _ring.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeProvider>();
    final reduceMotion = MediaQuery.of(context).disableAnimations;
    if (reduceMotion) {
      _spin.stop();
      _ring.stop();
    } else if (!_spin.isAnimating) {
      _spin.repeat();
      _ring.repeat();
    }

    return Scaffold(
      backgroundColor: theme.ground,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(28, 24, 28, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: kInk,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.music_note_rounded,
                      size: 18,
                      color: theme.ground,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'BeatNest',
                    style: displayStyle(24).copyWith(letterSpacing: 0.5),
                  ),
                ],
              ),
              Expanded(
                child: Center(
                  child: ExcludeSemantics(
                    child: SizedBox(
                      width: 330,
                      height: 330,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          for (final offset in const [0.0, 0.5])
                            AnimatedBuilder(
                              animation: _ring,
                              builder: (context, _) {
                                final t = (_ring.value + offset) % 1;
                                return Opacity(
                                  opacity: 0.55 * (1 - t),
                                  child: Transform.scale(
                                    scale: 1 + 0.35 * t,
                                    child: Container(
                                      width: 270,
                                      height: 270,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: kInk,
                                          width: 2,
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          RotationTransition(
                            turns: _spin,
                            child: CustomPaint(
                              size: const Size.square(270),
                              painter: _VinylPainter(theme.ground),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              Text(
                'Music that moves with you.',
                style: displayStyle(56).copyWith(
                  fontWeight: FontWeight.w700,
                  height: 0.95,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 14),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 300),
                child: Text(
                  'Play local files, record your voice, add effects and keep your favourites close.',
                  style: bodyStyle(
                    15,
                    weight: FontWeight.w500,
                    color: const Color(0xFF2A2410),
                    height: 1.5,
                  ),
                ),
              ),
              const SizedBox(height: 26),
              Row(
                children: [
                  Container(
                    width: 28,
                    height: 6,
                    decoration: BoxDecoration(
                      color: kInk,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                  for (var i = 0; i < 2; i++) ...[
                    const SizedBox(width: 6),
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: kInk.withValues(alpha: 0.3),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 22),
              Material(
                color: kInk,
                borderRadius: BorderRadius.circular(20),
                child: InkWell(
                  borderRadius: BorderRadius.circular(20),
                  onTap: () => Navigator.of(context).pushReplacement(
                    MaterialPageRoute(builder: (_) => const MainShell()),
                  ),
                  child: Container(
                    height: 60,
                    padding: const EdgeInsets.only(left: 24, right: 10),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Get started',
                          style: bodyStyle(
                            16,
                            weight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                        Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            color: theme.ground,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Icon(
                            Icons.arrow_forward_rounded,
                            size: 22,
                            color: kInk,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Center(
                child: Text(
                  'We’ll ask for storage, audio and microphone access.',
                  style: bodyStyle(
                    12,
                    weight: FontWeight.w500,
                    color: kOnGround,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _VinylPainter extends CustomPainter {
  final Color ground;
  _VinylPainter(this.ground);

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = size.width / 2;
    canvas.drawShadow(
      Path()..addOval(Rect.fromCircle(center: c, radius: r)),
      const Color(0x66141414),
      18,
      true,
    );
    canvas.drawCircle(c, r, Paint()..color = kInk);
    final groove = Paint()
      ..color = const Color(0xFF262626)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    for (var g = r - 8; g > 52; g -= 5) {
      canvas.drawCircle(c, g, groove);
    }
    // Label
    canvas.drawCircle(c, 48, Paint()..color = Colors.white);
    canvas.drawCircle(c, 48, Paint()..color = const Color(0xFFFFF1C2));
    canvas.save();
    canvas.clipPath(Path()..addOval(Rect.fromCircle(center: c, radius: 48)));
    final wave = Path()
      ..moveTo(c.dx - 48, c.dy + 12)
      ..quadraticBezierTo(c.dx - 24, c.dy - 8, c.dx, c.dy + 12)
      ..quadraticBezierTo(c.dx + 24, c.dy + 32, c.dx + 48, c.dy + 12)
      ..lineTo(c.dx + 48, c.dy + 48)
      ..lineTo(c.dx - 48, c.dy + 48)
      ..close();
    canvas.drawPath(wave, Paint()..color = ground);
    canvas.restore();
    canvas.drawCircle(c, 7, Paint()..color = kInk);
    canvas.drawCircle(
      c + Offset(cos(-0.9), sin(-0.9)) * 30,
      6,
      Paint()..color = kInk,
    );
  }

  @override
  bool shouldRepaint(_VinylPainter old) => old.ground != ground;
}
