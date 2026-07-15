import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import 'glass.dart';

/// A large, frosted-glass, tappable card used for the home-screen features
/// (Scan, Take a Photo, Calculator, …).
///
/// It uses [GlassCard] for the ChatGPT-style translucent look, tinted with the
/// feature's accent color, and gently animates in.
class FeatureCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? subtitle;
  final Color color;
  final VoidCallback onTap;

  /// Used to stagger the entrance animation on the home grid.
  final int index;

  const FeatureCard({
    super.key,
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
    this.subtitle,
    this.index = 0,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GlassCard(
      onTap: onTap,
      tint: color,
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Icon in a soft rounded square glowing with the accent color.
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.22),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.35),
                  blurRadius: 16,
                  spreadRadius: -4,
                ),
              ],
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(height: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 2),
                Text(
                  subtitle!,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    )
        // A subtle, staggered fade + slide-up entrance.
        .animate()
        .fadeIn(duration: 300.ms, delay: (60 * index).ms)
        .slideY(begin: 0.15, end: 0, curve: Curves.easeOutCubic);
  }
}
