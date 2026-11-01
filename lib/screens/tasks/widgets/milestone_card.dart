import 'package:flutter/material.dart';
import '../../../models/user_model.dart';
import '../../../widgets/climb_ui.dart';

class MilestoneCard extends StatelessWidget {
  final UserModel user;
  final List<dynamic> milestones;
  final VoidCallback onWatchAd;

  const MilestoneCard({
    super.key,
    required this.user,
    required this.milestones,
    required this.onWatchAd,
  });

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;

    final adsWatched = user.adsWatchedThisMonth;
    const maxAds = 50;

    // Extract milestone ads for calculation
    final milestoneAds = milestones.map((m) => m['ads'] as int).toList();
    final next = milestones.where((m) => (m['ads'] as int) > adsWatched).firstOrNull;
    final reward = next?['reward'] as String?;
    final rewardName = reward == null
        ? null
        : reward[0].toUpperCase() + reward.substring(1);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: AppCard(
        padding: const EdgeInsets.fromLTRB(18, 14, 8, 6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(child: Text('Monthly tokens', style: tt.titleSmall)),
                Padding(
                  padding: const EdgeInsets.only(right: 10),
                  child: MutedLabel('$adsWatched of $maxAds ads'),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.only(right: 10),
              child: _AdDots(watched: adsWatched, total: maxAds, milestones: milestoneAds),
            ),
            const SizedBox(height: 2),
            Row(
              children: [
                Expanded(
                  child: MutedLabel(
                    next == null
                        ? 'All tokens earned this month'
                        : '$rewardName token at ${next['ads']} ads',
                  ),
                ),
                TextButton(
                  onPressed: onWatchAd,
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                  ),
                  child: const Text('Watch ad'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _AdDots extends StatelessWidget {
  final int watched;
  final int total;
  final List<int> milestones;

  const _AdDots({
    required this.watched,
    required this.total,
    required this.milestones,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return SizedBox(
      height: 8,
      width: double.infinity,
      child: CustomPaint(
        painter: _AdDotsPainter(
          watched: watched,
          total: total,
          milestones: milestones,
          filled: cs.onSurface,
          empty: cs.onSurfaceVariant.withValues(alpha: 0.28),
          milestone: cs.secondary,
        ),
      ),
    );
  }
}

class _AdDotsPainter extends CustomPainter {
  final int watched;
  final int total;
  final List<int> milestones;
  final Color filled;
  final Color empty;
  final Color milestone;

  _AdDotsPainter({
    required this.watched,
    required this.total,
    required this.milestones,
    required this.filled,
    required this.empty,
    required this.milestone,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final pitch = size.width / total;
    final paint = Paint();
    for (var i = 0; i < total; i++) {
      final ad = i + 1;
      final isMilestone = milestones.contains(ad);
      paint.color = ad <= watched
          ? filled
          : (isMilestone ? milestone : empty);
      canvas.drawCircle(
        Offset(pitch * (i + 0.5), size.height / 2),
        isMilestone ? pitch * 0.42 : pitch * 0.26,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _AdDotsPainter oldDelegate) {
    return oldDelegate.watched != watched ||
        oldDelegate.milestones != milestones ||
        oldDelegate.filled != filled ||
        oldDelegate.empty != empty ||
        oldDelegate.milestone != milestone;
  }
}
