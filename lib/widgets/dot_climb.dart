import 'package:flutter/material.dart';

/// A rising staircase of dots showing how far along the climb the user is.
/// [progress] runs from 0.0 at level 1 to 1.0 at the top.
class DotClimb extends StatelessWidget {
  final double progress;
  final double height;
  final Duration duration;

  const DotClimb({
    super.key,
    required this.progress,
    this.height = 92,
    this.duration = const Duration(milliseconds: 900),
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return SizedBox(
      width: double.infinity,
      height: height,
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: progress.clamp(0.0, 1.0)),
        duration: duration,
        curve: Curves.easeOutCubic,
        builder: (context, value, _) {
          return CustomPaint(
            painter: _DotClimbPainter(
              progress: value,
              climbed: cs.onSurface,
              remaining: cs.onSurfaceVariant.withValues(alpha: 0.28),
              current: cs.secondary,
            ),
          );
        },
      ),
    );
  }
}

class _DotClimbPainter extends CustomPainter {
  final double progress;
  final Color climbed;
  final Color remaining;
  final Color current;

  _DotClimbPainter({
    required this.progress,
    required this.climbed,
    required this.remaining,
    required this.current,
  });

  static const int _columns = 40;
  static const int _steps = 20;

  @override
  void paint(Canvas canvas, Size size) {
    final pitch = size.width / _columns;
    final radius = pitch * 0.29;
    final rows = (size.height / pitch).floor();
    final head = (progress * (_columns - 1)).round();
    final paint = Paint();

    for (var column = 0; column < _columns; column++) {
      final step = column ~/ (_columns / _steps);
      final columnHeight = (rows * (step + 1) / _steps).ceil();
      paint.color = column == head
          ? current
          : (column < head ? climbed : remaining);

      for (var row = 0; row < columnHeight; row++) {
        canvas.drawCircle(
          Offset(
            pitch * (column + 0.5),
            size.height - pitch * (row + 0.5),
          ),
          radius,
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DotClimbPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.climbed != climbed ||
        oldDelegate.remaining != remaining ||
        oldDelegate.current != current;
  }
}

/// Seven dot columns showing XP per day, Monday first, with today in the accent.
class DotWeekChart extends StatelessWidget {
  final List<int> weeklyXP;
  final double height;

  const DotWeekChart({super.key, required this.weeklyXP, this.height = 120});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final today = DateTime.now().weekday - 1;
    const days = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

    return Semantics(
      label: 'XP per day this week: ${weeklyXP.join(', ')}',
      child: Column(
        children: [
          SizedBox(
            width: double.infinity,
            height: height,
            child: CustomPaint(
              painter: _DotWeekPainter(
                weeklyXP: weeklyXP,
                today: today,
                filled: cs.onSurface,
                empty: cs.onSurfaceVariant.withValues(alpha: 0.2),
                current: cs.secondary,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: List.generate(7, (index) {
              return Expanded(
                child: Text(
                  days[index],
                  textAlign: TextAlign.center,
                  style: tt.labelMedium?.copyWith(
                    color: index == today ? cs.onSurface : cs.onSurfaceVariant,
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}

class _DotWeekPainter extends CustomPainter {
  final List<int> weeklyXP;
  final int today;
  final Color filled;
  final Color empty;
  final Color current;

  _DotWeekPainter({
    required this.weeklyXP,
    required this.today,
    required this.filled,
    required this.empty,
    required this.current,
  });

  // Each day is three dots wide, inside an equal seventh of the width.
  static const int _dotsPerDay = 3;

  @override
  void paint(Canvas canvas, Size size) {
    final dayWidth = size.width / 7;
    final pitch = dayWidth / (_dotsPerDay + 1.5);
    final radius = pitch * 0.32;
    final rows = (size.height / pitch).floor();
    final highest = weeklyXP.fold<int>(0, (a, b) => a > b ? a : b);
    final paint = Paint();

    for (var day = 0; day < 7; day++) {
      final xp = day < weeklyXP.length ? weeklyXP[day] : 0;
      var filledRows = highest == 0 ? 0 : (rows * xp / highest).round();
      if (xp > 0 && filledRows == 0) filledRows = 1;
      final left = dayWidth * day + (dayWidth - pitch * _dotsPerDay) / 2;

      for (var column = 0; column < _dotsPerDay; column++) {
        for (var row = 0; row < rows; row++) {
          paint.color = row < filledRows
              ? (day == today ? current : filled)
              : empty;
          canvas.drawCircle(
            Offset(
              left + pitch * (column + 0.5),
              size.height - pitch * (row + 0.5),
            ),
            radius,
            paint,
          );
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DotWeekPainter oldDelegate) {
    return oldDelegate.weeklyXP != weeklyXP ||
        oldDelegate.today != today ||
        oldDelegate.filled != filled ||
        oldDelegate.empty != empty ||
        oldDelegate.current != current;
  }
}

/// Numbers drawn in a 5x7 dot matrix.
class DotNumber extends StatelessWidget {
  final String text;
  final double height;
  final Color? color;

  const DotNumber(this.text, {super.key, this.height = 56, this.color});

  static const Map<String, List<String>> _glyphs = {
    '0': ['01110', '10001', '10001', '10001', '10001', '10001', '01110'],
    '1': ['00100', '01100', '00100', '00100', '00100', '00100', '01110'],
    '2': ['01110', '10001', '00001', '00010', '00100', '01000', '11111'],
    '3': ['01110', '10001', '00001', '00110', '00001', '10001', '01110'],
    '4': ['00010', '00110', '01010', '10010', '11111', '00010', '00010'],
    '5': ['11111', '10000', '11110', '00001', '00001', '10001', '01110'],
    '6': ['00110', '01000', '10000', '11110', '10001', '10001', '01110'],
    '7': ['11111', '00001', '00010', '00100', '01000', '01000', '01000'],
    '8': ['01110', '10001', '10001', '01110', '10001', '10001', '01110'],
    '9': ['01110', '10001', '10001', '01111', '00001', '00010', '01100'],
    ',': ['00', '00', '00', '00', '00', '01', '10'],
  };

  @override
  Widget build(BuildContext context) {
    final pitch = height / 7;
    final glyphs = text.split('').where(_glyphs.containsKey).map((c) => _glyphs[c]!).toList();
    final columns = glyphs.fold<int>(0, (sum, g) => sum + g.first.length + 1) - 1;

    return Semantics(
      label: text,
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: CustomPaint(
          size: Size(columns * pitch, height),
          painter: _DotNumberPainter(
            glyphs: glyphs,
            pitch: pitch,
            color: color ?? Theme.of(context).colorScheme.onSurface,
          ),
        ),
      ),
    );
  }
}

class _DotNumberPainter extends CustomPainter {
  final List<List<String>> glyphs;
  final double pitch;
  final Color color;

  _DotNumberPainter({
    required this.glyphs,
    required this.pitch,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    var x = 0;
    for (final glyph in glyphs) {
      for (var row = 0; row < glyph.length; row++) {
        for (var column = 0; column < glyph[row].length; column++) {
          if (glyph[row][column] == '1') {
            canvas.drawCircle(
              Offset(pitch * (x + column + 0.5), pitch * (row + 0.5)),
              pitch * 0.42,
              paint,
            );
          }
        }
      }
      x += glyph.first.length + 1;
    }
  }

  @override
  bool shouldRepaint(covariant _DotNumberPainter oldDelegate) {
    return oldDelegate.glyphs != glyphs ||
        oldDelegate.pitch != pitch ||
        oldDelegate.color != color;
  }
}
