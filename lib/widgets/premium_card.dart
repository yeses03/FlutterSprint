import 'package:flutter/material.dart';
import 'package:workpass/theme/app_theme.dart';

/// Reusable premium card widget with consistent styling
class PremiumCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  final EdgeInsets? margin;
  final VoidCallback? onTap;
  final Color? backgroundColor;
  final double? borderRadius;

  const PremiumCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.onTap,
    this.backgroundColor,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    final card = Container(
      padding: padding ?? const EdgeInsets.all(16),
      margin: margin ?? const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: backgroundColor ?? AppTheme.surfaceWhite,
        borderRadius: BorderRadius.circular(borderRadius ?? 16),
        boxShadow: AppTheme.cardShadow(),
      ),
      child: child,
    );

    if (onTap != null) {
      return Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(borderRadius ?? 16),
          child: card,
        ),
      );
    }

    return card;
  }
}
