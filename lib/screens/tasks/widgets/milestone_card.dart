import 'package:flutter/material.dart';
import '../../../models/user_model.dart';

class MilestoneCard extends StatelessWidget {
  final UserModel user;
  final List<dynamic> milestones;
  final bool showRoadmap;
  final VoidCallback onWatchAd;

  const MilestoneCard({
    super.key,
    required this.user,
    required this.milestones,
    required this.showRoadmap,
    required this.onWatchAd,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    final adsWatched = user.adsWatchedThisMonth;
    const maxAds = 50;
    final progress = (adsWatched / maxAds).clamp(0.0, 1.0);

    // Extract milestone ads for calculation
    final milestoneAds = milestones.map((m) => m['ads'] as int).toList();
    final nextMilestone = milestoneAds.firstWhere((m) => m > adsWatched, orElse: () => 50);
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: cs.outlineVariant.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Monthly Milestone',
                    style: tt.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Watch ads to earn extra tokens',
                    style: tt.bodySmall?.copyWith(
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: cs.primaryContainer.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$adsWatched / $maxAds Ads',
                  style: tt.labelMedium?.copyWith(
                    color: cs.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 10,
              backgroundColor: cs.surfaceContainerHighest.withValues(alpha: 0.5),
              valueColor: AlwaysStoppedAnimation<Color>(cs.primary),
            ),
          ),
          const SizedBox(height: 16),
          
          // Roadmap/Track (Collapsible)
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            height: showRoadmap ? 110 : 0,
            curve: Curves.easeInOut,
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 200),
              opacity: showRoadmap ? 1.0 : 0.0,
              child: SingleChildScrollView(
                physics: const NeverScrollableScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Reward Roadmap',
                      style: tt.labelMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 80,
                      child: milestones.isEmpty
                          ? Center(
                              child: Text(
                                'Loading milestones...',
                                style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                              ),
                            )
                          : ListView.builder(
                              scrollDirection: Axis.horizontal,
                              itemCount: milestones.length,
                              itemBuilder: (context, index) {
                                final milestone = milestones[index];
                                final targetAds = milestone['ads'] as int;
                                final reward = milestone['reward'] as String;
                                final isAchieved = adsWatched >= targetAds;
                                
                                String assetPath = 'assets/token_easy.png';
                                if (reward == 'medium') assetPath = 'assets/token_medium.png';
                                if (reward == 'hard') assetPath = 'assets/token_hard.png';
                                if (reward == 'epic') assetPath = 'assets/token_epic.png';

                                return Container(
                                  width: 70,
                                  margin: const EdgeInsets.only(right: 8),
                                  child: Column(
                                    children: [
                                      Stack(
                                        children: [
                                          Opacity(
                                            opacity: isAchieved ? 1.0 : 0.4,
                                            child: Image.asset(
                                              assetPath,
                                              width: 36,
                                              height: 36,
                                              errorBuilder: (context, error, stackTrace) => Icon(
                                                Icons.stars_rounded,
                                                size: 36,
                                                color: cs.primary.withValues(alpha: 0.5),
                                              ),
                                            ),
                                          ),
                                          if (isAchieved)
                                            Positioned(
                                              right: 0,
                                              bottom: 0,
                                              child: Container(
                                                padding: const EdgeInsets.all(2),
                                                decoration: BoxDecoration(
                                                  color: cs.primary,
                                                  shape: BoxShape.circle,
                                                  border: Border.all(
                                                    color: Theme.of(context).cardTheme.color ?? Colors.white,
                                                    width: 1.5,
                                                  ),
                                                ),
                                                child: Icon(
                                                  Icons.check,
                                                  size: 10,
                                                  color: cs.onPrimary,
                                                ),
                                              ),
                                            ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '$targetAds Ads',
                                        style: tt.labelSmall?.copyWith(
                                          fontWeight: FontWeight.w700,
                                          color: isAchieved ? cs.onSurface : cs.onSurfaceVariant,
                                        ),
                                      ),
                                      Text(
                                        reward.toUpperCase(),
                                        style: tt.labelSmall?.copyWith(
                                          fontSize: 8,
                                          color: isAchieved ? cs.primary : cs.onSurfaceVariant.withValues(alpha: 0.7),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Next reward at $nextMilestone ads',
                style: tt.bodySmall?.copyWith(
                  color: cs.onSurfaceVariant,
                ),
              ),
              ElevatedButton.icon(
                onPressed: onWatchAd,
                icon: const Icon(Icons.play_circle_fill_rounded, size: 18),
                label: const Text('Watch Ad'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
