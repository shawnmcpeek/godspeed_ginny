import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class ChartButton extends StatelessWidget {
  const ChartButton({
    super.key,
    required this.label,
    this.hint,
    this.onPressed,
    this.wide = false,
    this.hot = false,
  });

  final String label;
  final String? hint;
  final VoidCallback? onPressed;
  final bool wide;
  final bool hot;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;
    final border = hot ? AppColors.stamp : AppColors.ink;
    final fg = hot ? AppColors.stamp : AppColors.ink;

    return Opacity(
      opacity: enabled ? 1 : 0.3,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          child: Container(
            width: wide ? double.infinity : null,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
            decoration: BoxDecoration(
              border: Border.all(color: border, width: 1.5),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: AppTheme.display.copyWith(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: fg,
                  ),
                ),
                if (hint != null) ...[
                  const SizedBox(height: 3),
                  Text(
                    hint!,
                    style: AppTheme.mono.copyWith(
                      fontSize: 12,
                      letterSpacing: 1.4,
                      color: fg.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class ChartCardButton extends StatelessWidget {
  const ChartCardButton({
    super.key,
    required this.title,
    this.subtitle,
    this.annotation,
    this.claim,
    this.claimPrefix,
    this.onPressed,
  });

  final String title;
  final String? subtitle;
  final String? annotation;
  final String? claim;
  final String? claimPrefix;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final child = Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 9),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.water, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title.toUpperCase(),
            style: AppTheme.display.copyWith(fontSize: 18, letterSpacing: 0.6),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(
              subtitle!,
              style: AppTheme.mono.copyWith(fontSize: 12, color: AppColors.water),
            ),
          ],
          if (claim != null) ...[
            const SizedBox(height: 4),
            Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: '${claimPrefix ?? 'CHART'}: ',
                    style: AppTheme.mono.copyWith(fontSize: 12, color: AppColors.inkSoft),
                  ),
                  TextSpan(
                    text: claim,
                    style: AppTheme.mono.copyWith(fontSize: 12, color: AppColors.water),
                  ),
                ],
              ),
            ),
          ],
          if (annotation != null) ...[
            const SizedBox(height: 7),
            Transform.rotate(
              angle: -0.02,
              child: Text(
                '↳ $annotation',
                style: AppTheme.handwriting,
              ),
            ),
          ],
        ],
      ),
    );

    if (onPressed == null) return child;
    return Material(
      color: Colors.transparent,
      child: InkWell(onTap: onPressed, child: child),
    );
  }
}
