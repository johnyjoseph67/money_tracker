import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'app_state.dart';
import 'theme.dart';

/// Full-screen overlay shown in the centre of the page while any API call is running.
class LoadingOverlay extends StatelessWidget {
  const LoadingOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    final busy = context.select<AppState, bool>((a) => a.busy);
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 180),
      child: busy ? const _Scrim(key: ValueKey('busy')) : const SizedBox.shrink(key: ValueKey('idle')),
    );
  }
}

class _Scrim extends StatelessWidget {
  const _Scrim({super.key});

  @override
  Widget build(BuildContext context) => Material(
        type: MaterialType.transparency,
        child: SizedBox.expand(
          child: Stack(alignment: Alignment.center, children: [
            const ModalBarrier(dismissible: false, color: Color(0x730F172A)), // blocks taps while loading
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 28),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(28),
                boxShadow: const [BoxShadow(color: Color(0x330F172A), blurRadius: 32, offset: Offset(0, 12))],
              ),
              child: const Column(mainAxisSize: MainAxisSize.min, children: [
                ModernSpinner(),
                SizedBox(height: 18),
                Text('Please wait…', style: TextStyle(color: C.navy, fontWeight: FontWeight.w600, fontSize: 14)),
              ]),
            ),
          ]),
        ),
      );
}

/// Two counter-rotating gradient arcs (teal outside, gold inside).
class ModernSpinner extends StatefulWidget {
  final double size;
  const ModernSpinner({super.key, this.size = 56});
  @override
  State<ModernSpinner> createState() => _ModernSpinnerState();
}

class _ModernSpinnerState extends State<ModernSpinner> with SingleTickerProviderStateMixin {
  late final AnimationController c = AnimationController(vsync: this, duration: const Duration(milliseconds: 1100))..repeat();

  @override
  void dispose() {
    c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.size;
    return SizedBox(
      width: s,
      height: s,
      child: Stack(alignment: Alignment.center, children: [
        RotationTransition(turns: c, child: CustomPaint(size: Size(s, s), painter: _Arc(C.teal, s * 0.11))),
        RotationTransition(turns: ReverseAnimation(c), child: CustomPaint(size: Size(s * 0.56, s * 0.56), painter: _Arc(const Color(0xFFF59E0B), s * 0.09))),
      ]),
    );
  }
}

class _Arc extends CustomPainter {
  final Color color;
  final double stroke;
  _Arc(this.color, this.stroke);

  @override
  void paint(Canvas canvas, Size size) {
    final rect = (Offset.zero & size).deflate(stroke / 2);
    canvas.drawArc(
      rect,
      0,
      2 * math.pi,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..color = color.withOpacity(0.12),
    );
    canvas.drawArc(
      rect,
      0,
      math.pi * 1.4,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..strokeCap = StrokeCap.round
        ..shader = SweepGradient(startAngle: 0, endAngle: math.pi * 1.4, colors: [color.withOpacity(0.15), color]).createShader(rect),
    );
  }

  @override
  bool shouldRepaint(covariant _Arc old) => old.color != color || old.stroke != stroke;
}