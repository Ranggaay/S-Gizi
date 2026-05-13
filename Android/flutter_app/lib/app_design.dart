import 'package:flutter/material.dart';

const String sgiziLogoAsset = 'assets/image/logo_sgizi.png';

class SgColors {
  const SgColors._();

  static const primary = Color(0xFF4B8E96);
  static const primaryDark = Color(0xFF2F737A);
  static const secondary = Color(0xFFA8D5BA);
  static const background = Color(0xFFF5F7F6);
  static const surface = Colors.white;
  static const textPrimary = Color(0xFF1E1E1E);
  static const textSecondary = Color(0xFF6B7280);
  static const border = Color(0xFFE0E7E4);
  static const danger = Color(0xFFE53935);
  static const warning = Color(0xFFF59E0B);
  static const success = Color(0xFF34A853);
}

class AppTypography {
  const AppTypography._();

  static const h1 = TextStyle(
    fontSize: 24,
    height: 1.2,
    fontWeight: FontWeight.w800,
    color: SgColors.textPrimary,
  );
  static const h2 = TextStyle(
    fontSize: 18,
    height: 1.3,
    fontWeight: FontWeight.w700,
    color: SgColors.textPrimary,
  );
  static const h3 = TextStyle(
    fontSize: 15,
    height: 1.35,
    fontWeight: FontWeight.w600,
    color: SgColors.textPrimary,
  );
  static const body = TextStyle(
    fontSize: 14,
    height: 1.5,
    fontWeight: FontWeight.w400,
    color: SgColors.textSecondary,
  );
  static const caption = TextStyle(
    fontSize: 12,
    height: 1.35,
    fontWeight: FontWeight.w500,
    color: SgColors.textSecondary,
  );
}

class AppLogo extends StatelessWidget {
  const AppLogo({super.key, this.size = 56, this.showLabel = false});

  final double size;
  final bool showLabel;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(size * 0.24),
          child: Image.asset(
            sgiziLogoAsset,
            width: size,
            height: size,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                color: SgColors.primary,
                borderRadius: BorderRadius.circular(size * 0.24),
              ),
              child: const Icon(Icons.bolt, color: Colors.white),
            ),
          ),
        ),
        if (showLabel) ...[
          const SizedBox(width: 12),
          Text(
            'S-Gizi',
            style: AppTypography.h1.copyWith(
              color: SgColors.primaryDark,
              fontSize: 22,
            ),
          ),
        ],
      ],
    );
  }
}

class ChildAvatar extends StatelessWidget {
  const ChildAvatar({
    super.key,
    required this.name,
    required this.gender,
    this.photoUrl,
    this.radius = 28,
  });

  final String name;
  final String gender;
  final String? photoUrl;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final imageUrl = photoUrl?.trim();
    if (imageUrl != null && imageUrl.isNotEmpty) {
      return CircleAvatar(
        radius: radius,
        backgroundColor: const Color(0xFFD9EEE7),
        backgroundImage: NetworkImage(imageUrl),
      );
    }

    final isFemale = gender.toLowerCase().startsWith('p');
    final accent = isFemale ? const Color(0xFFFF8FA3) : SgColors.primary;

    return CircleAvatar(
      radius: radius,
      backgroundColor: accent.withValues(alpha: 0.12),
      child: Icon(
        isFemale ? Icons.face_3_rounded : Icons.face_rounded,
        color: accent,
        size: radius,
      ),
    );
  }
}

class HealthCard extends StatelessWidget {
  const HealthCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.margin,
    this.color = SgColors.surface,
    this.borderColor,
    this.onTap,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final Color color;
  final Color? borderColor;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final card = AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOut,
      margin: margin,
      padding: padding,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor ?? SgColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: child,
    );

    if (onTap == null) {
      return card;
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: card,
      ),
    );
  }
}

class StatusBadge extends StatelessWidget {
  const StatusBadge({
    super.key,
    required this.text,
    this.color = SgColors.success,
  });

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.36)),
      ),
      child: Text(
        text,
        style: AppTypography.caption.copyWith(
          color: color,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.isOutlined = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool isOutlined;

  @override
  Widget build(BuildContext context) {
    final child = Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (icon != null) ...[Icon(icon, size: 20), const SizedBox(width: 8)],
        Flexible(
          child: Text(
            label,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
        ),
      ],
    );

    if (isOutlined) {
      return SizedBox(
        width: double.infinity,
        height: 56,
        child: OutlinedButton(
          onPressed: onPressed,
          style: OutlinedButton.styleFrom(
            foregroundColor: SgColors.primary,
            side: const BorderSide(color: SgColors.primary),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
          ),
          child: child,
        ),
      );
    }

    return SizedBox(
      width: double.infinity,
      height: 56,
      child: FilledButton(
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: SgColors.primary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          elevation: 1,
          shadowColor: SgColors.primary.withValues(alpha: 0.32),
        ),
        child: child,
      ),
    );
  }
}

class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: HealthCard(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircleAvatar(
                radius: 32,
                backgroundColor: Color(0xFFE9F6F2),
                child: Icon(Icons.inbox_outlined, color: SgColors.primary),
              ),
              const SizedBox(height: 16),
              Text(title, style: AppTypography.h2, textAlign: TextAlign.center),
              const SizedBox(height: 8),
              Text(
                message,
                style: AppTypography.body,
                textAlign: TextAlign.center,
              ),
              if (actionLabel != null && onAction != null) ...[
                const SizedBox(height: 16),
                PrimaryButton(label: actionLabel!, onPressed: onAction),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class ErrorState extends StatelessWidget {
  const ErrorState({super.key, required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: HealthCard(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircleAvatar(
                radius: 32,
                backgroundColor: Color(0xFFFFEBEE),
                child: Icon(Icons.wifi_off_rounded, color: SgColors.danger),
              ),
              const SizedBox(height: 16),
              const Text('Terjadi Kendala', style: AppTypography.h2),
              const SizedBox(height: 8),
              Text(
                message,
                style: AppTypography.body,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              PrimaryButton(
                label: 'Coba Lagi',
                icon: Icons.refresh_rounded,
                onPressed: onRetry,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class MetricProgress extends StatelessWidget {
  const MetricProgress({
    super.key,
    required this.label,
    required this.description,
    required this.status,
    required this.value,
    required this.icon,
  });

  final String label;
  final String description;
  final String status;
  final double value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final clampedValue = value.clamp(0.0, 1.0).toDouble();

    return HealthCard(
      margin: const EdgeInsets.only(bottom: 12),
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: const Color(0xFFE9F6F2),
                child: Icon(icon, color: SgColors.primary, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label, style: AppTypography.h3),
                    const SizedBox(height: 2),
                    Text(description, style: AppTypography.caption),
                  ],
                ),
              ),
              Text(
                status.toUpperCase(),
                textAlign: TextAlign.right,
                style: AppTypography.caption.copyWith(
                  color: SgColors.textPrimary,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: clampedValue),
              duration: const Duration(milliseconds: 850),
              curve: Curves.easeOutCubic,
              builder: (context, animatedValue, _) {
                return LinearProgressIndicator(
                  value: animatedValue,
                  minHeight: 8,
                  backgroundColor: const Color(0xFFEAF4F1),
                  valueColor: const AlwaysStoppedAnimation(SgColors.primary),
                );
              },
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Text('Kurang', style: AppTypography.caption),
              Text(
                'Ideal',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: SgColors.primary,
                ),
              ),
              Text('Berlebih', style: AppTypography.caption),
            ],
          ),
        ],
      ),
    );
  }
}

PageRouteBuilder<T> fadeRoute<T>(Widget page) {
  return PageRouteBuilder<T>(
    transitionDuration: const Duration(milliseconds: 260),
    reverseTransitionDuration: const Duration(milliseconds: 220),
    pageBuilder: (_, __, ___) => page,
    transitionsBuilder: (_, animation, __, child) {
      return FadeTransition(
        opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0.03, 0),
            end: Offset.zero,
          ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOut)),
          child: child,
        ),
      );
    },
  );
}
