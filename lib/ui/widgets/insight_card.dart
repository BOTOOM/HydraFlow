import 'package:flutter/material.dart';

import '../../domain/hydration_insights.dart';
import '../theme.dart';

class InsightCard extends StatelessWidget {
  const InsightCard({super.key, required this.insight});

  final HydrationInsight insight;

  @override
  Widget build(BuildContext context) {
    final onSurfaceVariant = Theme.of(context).colorScheme.onSurfaceVariant;
    final Color accent;
    final IconData icon;
    switch (insight.level) {
      case InsightLevel.info:
        accent = HydraTheme.aqua;
        icon = Icons.water_drop_outlined;
      case InsightLevel.caution:
        accent = Colors.amber.shade700;
        icon = Icons.warning_amber_rounded;
      case InsightLevel.urgent:
        accent = HydraTheme.coral;
        icon = Icons.error_outline;
    }

    return Card(
      color: accent.withValues(alpha: .18),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                color: accent.withValues(alpha: .22),
                shape: BoxShape.circle,
              ),
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Icon(icon, color: accent),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    insight.title,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(insight.body),
                  const SizedBox(height: 8),
                  Text(
                    insightDisclaimer,
                    style: TextStyle(
                      color: onSurfaceVariant,
                      fontSize: 11,
                      height: 1.25,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
