import 'dart:math';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import '../screens/theme_provide.dart';
import '../services/player_service.dart';
import '../services/profile_provider.dart';

// ------------------------------------------------------------------ helpers

void showAppSnack(BuildContext context, String message) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(message)));
}

/// Runs the file picker and explains any permission problem to the user.
Future<void> pickAudioWithUi(BuildContext context) async {
  final service = context.read<PlayerService>();
  final result = await service.pickFiles();
  if (!context.mounted) return;
  switch (result) {
    case PickResult.permanentlyDenied:
      showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Permission required'),
          content: const Text(
            'Please enable storage or audio permission in app settings.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                openAppSettings();
                Navigator.of(ctx).pop();
              },
              child: const Text('Open settings'),
            ),
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancel'),
            ),
          ],
        ),
      );
    case PickResult.denied:
      showAppSnack(context, 'Permission denied to read audio files');
    case PickResult.added:
    case PickResult.cancelled:
      break;
  }
}

// ----------------------------------------------------------------- surfaces

/// White rounded sheet that rises from the coloured ground.
class AppSheet extends StatelessWidget {
  final Widget child;
  final double radius;
  final EdgeInsetsGeometry padding;

  const AppSheet({
    super.key,
    required this.child,
    this.radius = 32,
    this.padding = EdgeInsets.zero,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(radius)),
      ),
      child: child,
    );
  }
}

class SheetLabel extends StatelessWidget {
  final String text;
  const SheetLabel(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: bodyStyle(
        12,
        weight: FontWeight.w700,
        color: kMuted,
        letterSpacing: 1.5,
      ),
    );
  }
}

class AppBackButton extends StatelessWidget {
  final bool onSheet;
  final VoidCallback? onPressed;
  final IconData icon;
  final String tooltip;

  const AppBackButton({
    super.key,
    this.onSheet = false,
    this.onPressed,
    this.icon = Icons.chevron_left_rounded,
    this.tooltip = 'Back',
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: onSheet ? kSurface : Colors.white.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onPressed ?? () => Navigator.of(context).maybePop(),
          child: SizedBox(
            width: 44,
            height: 44,
            child: Icon(icon, size: 28, color: kInk),
          ),
        ),
      ),
    );
  }
}

/// Small square icon button on a pale background.
class SquareIconButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;
  final Color? background;
  final Color color;
  final double size;

  const SquareIconButton({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.background,
    this.color = kInk,
    this.size = 44,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: background ?? kSurface,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onPressed,
          child: SizedBox(
            width: size,
            height: size,
            child: Icon(icon, size: 22, color: color),
          ),
        ),
      ),
    );
  }
}

class PrimaryButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;
  final bool outlined;
  final bool light;

  const PrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.outlined = false,
    this.light = false,
  });

  @override
  Widget build(BuildContext context) {
    final bg = outlined ? Colors.white : (light ? Colors.white : kInk);
    final fg = (outlined || light) ? kInk : Colors.white;
    return Material(
      color: bg,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: outlined
            ? const BorderSide(color: kInk, width: 2)
            : BorderSide.none,
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onPressed,
        child: Container(
          height: 56,
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 20, color: fg),
                const SizedBox(width: 8),
              ],
              Flexible(
                child: Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  style: bodyStyle(15, weight: FontWeight.w700, color: fg),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ------------------------------------------------------------------ artwork

void _dashedCircle(
  Canvas canvas,
  Offset center,
  double radius,
  Paint paint, {
  double dash = 2,
  double gap = 6,
}) {
  final path = Path()..addOval(Rect.fromCircle(center: center, radius: radius));
  for (final metric in path.computeMetrics()) {
    var d = 0.0;
    while (d < metric.length) {
      canvas.drawPath(
        metric.extractPath(d, min(d + dash, metric.length)),
        paint,
      );
      d += dash + gap;
    }
  }
}

/// Decorative dotted rings (used on the favourites card).
class DashedRings extends StatelessWidget {
  final double size;
  final Color color;
  const DashedRings({super.key, required this.size, required this.color});

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: CustomPaint(size: Size.square(size), painter: _RingsPainter(color)),
  );
}

class _RingsPainter extends CustomPainter {
  final Color color;
  _RingsPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = size.width / 2;
    final p = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    _dashedCircle(canvas, c, r - 2, p);
    _dashedCircle(canvas, c, r * 0.64, p);
  }

  @override
  bool shouldRepaint(_RingsPainter old) => old.color != color;
}

/// Generic cover art: sun, rings and a wave in the theme colours.
class AlbumArt extends StatelessWidget {
  final double width;
  final double height;
  final double radius;

  const AlbumArt({
    super.key,
    required this.width,
    required this.height,
    this.radius = 18,
  });

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeProvider>();
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: CustomPaint(
        size: Size(width, height),
        painter: _ArtPainter(theme.soft, theme.ground),
      ),
    );
  }
}

class _ArtPainter extends CustomPainter {
  final Color soft;
  final Color ground;
  _ArtPainter(this.soft, this.ground);

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    canvas.drawRect(Offset.zero & size, Paint()..color = soft);

    final c = Offset(w / 2, h * 0.43);
    final r = min(w, h) * 0.32;
    canvas.drawCircle(c, r, Paint()..color = ground);
    final ring = Paint()
      ..color = kInk
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    _dashedCircle(canvas, c, r, ring);
    _dashedCircle(canvas, c, r * 0.64, ring, dash: 1, gap: 5);

    final wave = Path()
      ..moveTo(0, h * 0.74)
      ..quadraticBezierTo(w * 0.25, h * 0.56, w * 0.5, h * 0.74)
      ..quadraticBezierTo(w * 0.75, h * 0.92, w, h * 0.74)
      ..lineTo(w, h)
      ..lineTo(0, h)
      ..close();
    canvas.drawPath(wave, Paint()..color = kInk);
    canvas.drawCircle(
      Offset(w * 0.75, h * 0.22),
      min(w, h) * 0.055,
      Paint()..color = kInk,
    );
  }

  @override
  bool shouldRepaint(_ArtPainter old) =>
      old.soft != soft || old.ground != ground;
}

/// Round vinyl-like disc used for the mini player.
class DiscArt extends StatelessWidget {
  final double size;
  const DiscArt({super.key, this.size = 46});

  @override
  Widget build(BuildContext context) {
    final ground = context.watch<ThemeProvider>().ground;
    return CustomPaint(size: Size.square(size), painter: _DiscPainter(ground));
  }
}

class _DiscPainter extends CustomPainter {
  final Color ground;
  _DiscPainter(this.ground);

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = size.width / 2;
    canvas.drawCircle(c, r, Paint()..color = ground);
    _dashedCircle(
      canvas,
      c,
      r * 0.74,
      Paint()
        ..color = kInk
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
      dash: 2,
      gap: 4,
    );
    canvas.drawCircle(c, r * 0.22, Paint()..color = kInk);
  }

  @override
  bool shouldRepaint(_DiscPainter old) => old.ground != ground;
}

// --------------------------------------------------------------- waveforms

class WaveBars extends StatelessWidget {
  final List<double> bars; // 0..1
  final double progress; // 0..1, bars before this are "played"
  final double height;
  final Color activeColor;
  final Color inactiveColor;
  final double gap;

  const WaveBars({
    super.key,
    required this.bars,
    required this.height,
    this.progress = 1,
    this.activeColor = kInk,
    this.inactiveColor = const Color(0xFFE4E4E4),
    this.gap = 3,
  });

  @override
  Widget build(BuildContext context) {
    final played = (bars.length * progress).round();
    return SizedBox(
      height: height,
      child: ExcludeSemantics(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            for (var i = 0; i < bars.length; i++) ...[
              if (i > 0) SizedBox(width: gap),
              Expanded(
                child: Align(
                  child: Container(
                    height: max(4.0, bars[i].clamp(0.0, 1.0) * height),
                    decoration: BoxDecoration(
                      color: i < played ? activeColor : inactiveColor,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ------------------------------------------------------------------ avatar

class ProfileAvatar extends StatelessWidget {
  final double size;
  final double fontSize;
  final Color background;
  final Color foreground;
  final VoidCallback? onTap;

  const ProfileAvatar({
    super.key,
    this.size = 44,
    this.fontSize = 15,
    this.background = kInk,
    this.foreground = const Color(0xFFFFC727),
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final profile = context.watch<ProfileProvider>();
    final image = profile.image;
    final initial = profile.initial;
    final circle = Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: background,
        image: image != null
            ? DecorationImage(image: FileImage(image), fit: BoxFit.cover)
            : null,
      ),
      child: image != null
          ? null
          : initial != null
          ? Text(
              initial,
              style: fontSize > 30
                  ? displayStyle(fontSize, color: foreground)
                  : bodyStyle(
                      fontSize,
                      weight: FontWeight.w800,
                      color: foreground,
                    ),
            )
          : Icon(Icons.person_rounded, size: size * 0.5, color: foreground),
    );
    if (onTap == null) return circle;
    return Semantics(
      button: true,
      label: 'Profile',
      child: InkResponse(onTap: onTap, radius: size / 2 + 4, child: circle),
    );
  }
}

// --------------------------------------------------------------- bottom nav

class AppBottomNav extends StatelessWidget {
  final int index;
  final ValueChanged<int> onSelected;

  const AppBottomNav({
    super.key,
    required this.index,
    required this.onSelected,
  });

  static const _items = <(IconData, IconData, String)>[
    (Icons.home_outlined, Icons.home_rounded, 'Home'),
    (Icons.mic_none_rounded, Icons.mic_rounded, 'Record'),
    (Icons.favorite_border_rounded, Icons.favorite_rounded, 'Favorites'),
    (Icons.tune_rounded, Icons.tune_rounded, 'Settings'),
  ];

  @override
  Widget build(BuildContext context) {
    final soft = context.watch<ThemeProvider>().soft;
    return SizedBox(
      height: 64,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            for (var i = 0; i < _items.length; i++)
              _NavItem(
                icon: i == index ? _items[i].$2 : _items[i].$1,
                label: _items[i].$3,
                selected: i == index,
                soft: soft,
                onTap: () => onSelected(i),
              ),
          ],
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final Color soft;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.soft,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          constraints: const BoxConstraints(minWidth: 48, minHeight: 44),
          padding: EdgeInsets.symmetric(horizontal: selected ? 14 : 12),
          decoration: BoxDecoration(
            color: selected ? soft : Colors.transparent,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 22, color: kInk),
              if (selected) ...[
                const SizedBox(width: 6),
                Text(label, style: bodyStyle(12, weight: FontWeight.w800)),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ------------------------------------------------------------------ switch

/// Pill switch matching the design (ink track, white knob).
class AppSwitch extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;
  final String label;

  const AppSwitch({
    super.key,
    required this.value,
    required this.onChanged,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      toggled: value,
      label: label,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => onChanged(!value),
        child: SizedBox(
          width: 52,
          height: 44,
          child: Center(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              width: 52,
              height: 32,
              padding: const EdgeInsets.all(3),
              alignment: value ? Alignment.centerRight : Alignment.centerLeft,
              decoration: BoxDecoration(
                color: value ? kInk : const Color(0xFFD4D4D4),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Container(
                width: 26,
                height: 26,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Color(0x40000000),
                      blurRadius: 3,
                      offset: Offset(0, 1),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Row of mutually exclusive text options (segmented control).
class Segmented<T> extends StatelessWidget {
  final List<T> values;
  final T selected;
  final String Function(T) labelOf;
  final ValueChanged<T> onSelected;
  final Color trackColor;
  final double itemHeight;

  const Segmented({
    super.key,
    required this.values,
    required this.selected,
    required this.labelOf,
    required this.onSelected,
    this.trackColor = const Color(0xFFF2F2F2),
    this.itemHeight = 40,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: trackColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          for (final v in values)
            Expanded(
              child: Semantics(
                button: true,
                selected: v == selected,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => onSelected(v),
                  child: Container(
                    height: itemHeight,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: v == selected ? kInk : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      labelOf(v),
                      style: bodyStyle(
                        12,
                        weight: FontWeight.w800,
                        color: v == selected ? Colors.white : kInk,
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Pill chip used for genres and equalizer presets.
class PillChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final Color selectedColor;
  final Color borderColor;
  final Color selectedForeground;

  const PillChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    this.selectedColor = kInk,
    this.borderColor = kInk,
    this.selectedForeground = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Container(
          height: 40,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: selected ? selectedColor : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: selected ? selectedColor : borderColor,
              width: 2,
            ),
          ),
          child: Center(
            widthFactor: 1,
            child: Text(
              label,
              style: bodyStyle(
                13,
                weight: FontWeight.w700,
                color: selected ? selectedForeground : kInk,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
