import 'package:flutter/material.dart';

/// Indicator widget to show that a feature is Premium-only
class PremiumFeatureIndicator extends StatelessWidget {
  const PremiumFeatureIndicator({
    super.key,
    this.size = 16,
    this.showText = false,
  });

  final double size;
  final bool showText;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (showText) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: Colors.amber,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.star,
              size: size * 0.8,
              color: Colors.white,
            ),
            const SizedBox(width: 2),
            Text(
              'PRO',
              style: theme.textTheme.bodySmall?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: size * 0.6,
              ),
            ),
          ],
        ),
      );
    }

    return Icon(
      Icons.star,
      size: size,
      color: Colors.amber,
    );
  }
}
