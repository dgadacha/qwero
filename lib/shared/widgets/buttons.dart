import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/app_theme.dart';

/// CTA principal (§95) : 54 de haut, dégradé violet, halo discret.
class PrimaryButton extends StatefulWidget {
  const PrimaryButton({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.expanded = true,
    this.gradient,
    this.height = 54,
    this.loading = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool expanded;
  final Gradient? gradient;
  final double height;
  final bool loading;

  @override
  State<PrimaryButton> createState() => _PrimaryButtonState();
}

class _PrimaryButtonState extends State<PrimaryButton> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onPressed != null && !widget.loading;

    return GestureDetector(
      onTapDown: enabled ? (_) => setState(() => _down = true) : null,
      onTapCancel: enabled ? () => setState(() => _down = false) : null,
      onTapUp: enabled
          ? (_) {
              setState(() => _down = false);
              HapticFeedback.mediumImpact();
              widget.onPressed!.call();
            }
          : null,
      child: AnimatedScale(
        scale: _down ? 0.97 : 1,
        duration: AppMotion.micro,
        curve: AppMotion.standard,
        child: AnimatedOpacity(
          opacity: enabled ? 1 : 0.45,
          duration: AppMotion.micro,
          child: Container(
            height: widget.height,
            width: widget.expanded ? double.infinity : null,
            padding: widget.expanded ? null : const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
            decoration: BoxDecoration(
              gradient: widget.gradient ?? AppColors.primaryGradient,
              borderRadius: AppRadius.buttonR,
              boxShadow: enabled ? AppShadows.primaryGlow(opacity: _down ? 0.2 : 0.38) : null,
            ),
            child: Center(
              child: widget.loading
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2.4, color: Colors.white),
                    )
                  : Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (widget.icon != null) ...[
                          Icon(widget.icon, size: 19, color: Colors.white),
                          const SizedBox(width: AppSpacing.xs),
                        ],
                        Text(
                          widget.label,
                          style: const TextStyle(
                            fontFamily: AppTypography.family,
                            fontSize: 15.5,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.1,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Bouton secondaire : contour discret sur fond sombre.
class SecondaryButton extends StatelessWidget {
  const SecondaryButton({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.expanded = true,
    this.height = 52,
    this.color,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool expanded;
  final double height;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final tint = color ?? AppColors.textPrimary;
    return SizedBox(
      height: height,
      width: expanded ? double.infinity : null,
      child: TextButton(
        onPressed: onPressed == null
            ? null
            : () {
                HapticFeedback.lightImpact();
                onPressed!.call();
              },
        style: TextButton.styleFrom(
          backgroundColor: AppColors.surface2,
          shape: const RoundedRectangleBorder(
            borderRadius: AppRadius.buttonR,
            side: BorderSide(color: AppColors.border),
          ),
          padding: EdgeInsets.symmetric(horizontal: expanded ? AppSpacing.xs : AppSpacing.lg),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 18, color: tint),
              const SizedBox(width: 6),
            ],
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: AppTypography.family,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: tint,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Bouton circulaire discret (fermer, retour, options).
class GlassIconButton extends StatelessWidget {
  const GlassIconButton({
    super.key,
    required this.icon,
    this.onPressed,
    this.size = 40,
    this.color = AppColors.textPrimary,
  });

  final IconData icon;
  final VoidCallback? onPressed;
  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface2.withValues(alpha: 0.85),
      shape: const CircleBorder(side: BorderSide(color: AppColors.border)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onPressed == null
            ? null
            : () {
                HapticFeedback.lightImpact();
                onPressed!.call();
              },
        child: SizedBox(
          width: size,
          height: size,
          child: Icon(icon, size: size * 0.46, color: color),
        ),
      ),
    );
  }
}
