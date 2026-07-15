import 'dart:ui';

import 'package:flutter/material.dart';

/// Reusable "glassmorphism" building blocks that give Pick2Learn a modern,
/// ChatGPT-style frosted look: a soft gradient background with translucent,
/// blurred cards floating on top.

/// A full-screen gradient background with a couple of soft colored blobs.
///
/// Wrap a screen's body in this and make the Scaffold transparent so the glass
/// cards on top look like frosted panels over a colorful backdrop.
class AppBackground extends StatelessWidget {
  final Widget child;
  const AppBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Base gradient — deep near-black for dark mode, soft off-white for light.
    final gradient = isDark
        ? const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF0B0D12), Color(0xFF12141C), Color(0xFF0B0D12)],
          )
        : const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFF6F7FB), Color(0xFFEFF1F8), Color(0xFFF6F7FB)],
          );

    return DecoratedBox(
      decoration: BoxDecoration(gradient: gradient),
      child: Stack(
        children: [
          // Soft colored glow blobs for depth (kept subtle).
          Positioned(
            top: -80,
            left: -60,
            child: _blob(const Color(0xFF4C6FFF), isDark ? 0.35 : 0.20),
          ),
          Positioned(
            bottom: -100,
            right: -80,
            child: _blob(const Color(0xFF6C5CE7), isDark ? 0.30 : 0.16),
          ),
          child,
        ],
      ),
    );
  }

  Widget _blob(Color color, double opacity) {
    return Container(
      width: 320,
      height: 320,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [color.withValues(alpha: opacity), color.withValues(alpha: 0)],
        ),
      ),
    );
  }
}

/// A frosted-glass panel: translucent fill + real background blur + a thin
/// highlight border. This is the core "glass" surface used across the app.
class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final BorderRadiusGeometry borderRadius;
  final VoidCallback? onTap;

  /// Slightly stronger tint (used for accent cards).
  final Color? tint;

  const GlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.borderRadius = const BorderRadius.all(Radius.circular(22)),
    this.onTap,
    this.tint,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Glass fill: a low-opacity white in dark mode (frost), or low-opacity
    // white over the light gradient. A tint can push it toward an accent color.
    final baseFill = isDark
        ? Colors.white.withValues(alpha: 0.06)
        : Colors.white.withValues(alpha: 0.55);
    final fill = tint != null
        ? Color.alphaBlend(tint!.withValues(alpha: isDark ? 0.18 : 0.14), baseFill)
        : baseFill;

    final borderColor = isDark
        ? Colors.white.withValues(alpha: 0.12)
        : Colors.white.withValues(alpha: 0.8);

    final radius = borderRadius.resolve(Directionality.of(context));

    return ClipRRect(
      borderRadius: radius,
      child: BackdropFilter(
        // The frosted blur that makes it read as glass.
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Material(
          color: fill,
          child: InkWell(
            onTap: onTap,
            child: Container(
              padding: padding,
              decoration: BoxDecoration(
                borderRadius: radius,
                border: Border.all(color: borderColor, width: 1),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.06),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}
