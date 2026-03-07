import 'package:flutter/material.dart';
import '../theme.dart';
import 'dart:math';


// ─── AppCard ──────────────────────────────────────────
class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final VoidCallback? onTap;
  final Color? borderColor;

  const AppCard({super.key, required this.child, this.padding, this.onTap, this.borderColor});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: padding ?? const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.bgCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderColor ?? AppColors.border),
        ),
        child: child,
      ),
    );
  }
}

// ─── AppButton ────────────────────────────────────────
class AppButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool loading;
  final Color? color;
  final Color? textColor;
  final IconData? icon;
  final bool outlined;
  final double? width;

  const AppButton({
    super.key,
    required this.label,
    this.onPressed,
    this.loading = false,
    this.color,
    this.textColor,
    this.icon,
    this.outlined = false,
    this.width,
  });

  @override
  Widget build(BuildContext context) {
    final bg = color ?? AppColors.accent;
    return SizedBox(
      width: width,
      height: 50,
      child: outlined
          ? OutlinedButton.icon(
              onPressed: loading ? null : onPressed,
              icon: loading
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                  : (icon != null ? Icon(icon, size: 18) : const SizedBox.shrink()),
              label: Text(label),
              style: OutlinedButton.styleFrom(
                foregroundColor: bg,
                side: BorderSide(color: bg),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                textStyle: const TextStyle(fontWeight: FontWeight.w700),
              ),
            )
          : ElevatedButton.icon(
              onPressed: loading ? null : onPressed,
              icon: loading
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : (icon != null ? Icon(icon, size: 18) : const SizedBox.shrink()),
              label: Text(label),
              style: ElevatedButton.styleFrom(
                backgroundColor: bg,
                foregroundColor: textColor ?? Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
              ),
            ),
    );
  }
}

// ─── AppTextField ─────────────────────────────────────
class AppTextField extends StatefulWidget {
  final String label;
  final String? hint;
  final TextEditingController controller;
  final bool obscure;
  final TextInputType? keyboardType;
  final String? errorText;
  final int? maxLines;

  const AppTextField({
    super.key,
    required this.label,
    this.hint,
    required this.controller,
    this.obscure = false,
    this.keyboardType,
    this.errorText,
    this.maxLines = 1,
  });

  @override
  State<AppTextField> createState() => _AppTextFieldState();
}

class _AppTextFieldState extends State<AppTextField> {
  bool _showPass = false;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: widget.controller,
      obscureText: widget.obscure && !_showPass,
      keyboardType: widget.keyboardType,
      maxLines: widget.obscure ? 1 : widget.maxLines,
      style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
      decoration: InputDecoration(
        labelText: widget.label,
        hintText: widget.hint,
        errorText: widget.errorText,
        suffixIcon: widget.obscure
            ? IconButton(
                icon: Icon(
                  _showPass ? Icons.visibility_off : Icons.visibility,
                  color: AppColors.textMuted,
                  size: 20,
                ),
                onPressed: () => setState(() => _showPass = !_showPass),
              )
            : null,
      ),
    );
  }
}

// ─── AppBadge ─────────────────────────────────────────
class AppBadge extends StatelessWidget {
  final String label;
  final Color color;
  final Color bgColor;

  const AppBadge({super.key, required this.label, required this.color, required this.bgColor});

  factory AppBadge.accent(String label) => AppBadge(label: label, color: AppColors.accent, bgColor: AppColors.accentGlow);
  factory AppBadge.success(String label) => AppBadge(label: label, color: AppColors.success, bgColor: AppColors.successGlow);
  factory AppBadge.muted(String label) => AppBadge(label: label, color: AppColors.textSecondary, bgColor: AppColors.bgElevated);
  factory AppBadge.warning(String label) => AppBadge(label: label, color: AppColors.warning, bgColor: const Color(0x26F59E0B));

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(100),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(label, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w700)),
    );
  }
}

// ─── AvatarCircle ─────────────────────────────────────
class AvatarCircle extends StatelessWidget {
  final String initial;
  final Color color;
  final double size;
  final double fontSize;

  const AvatarCircle({super.key, required this.initial, required this.color, this.size = 48, this.fontSize = 18});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        boxShadow: [BoxShadow(color: color.withOpacity(0.3), blurRadius: 12, spreadRadius: 2)],
      ),
      child: Center(
        child: Text(
          initial,
          style: TextStyle(color: Colors.white, fontSize: fontSize, fontWeight: FontWeight.w800),
        ),
      ),
    );
  }
}

// ─── EmptyState ───────────────────────────────────────
class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final Widget? action;

  const EmptyState({super.key, required this.icon, required this.title, required this.description, this.action});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppColors.bgElevated,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.border),
              ),
              child: Icon(icon, color: AppColors.textMuted, size: 32),
            ),
            const SizedBox(height: 16),
            Text(title, style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w700, fontSize: 16)),
            const SizedBox(height: 6),
            Text(description, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13), textAlign: TextAlign.center),
            if (action != null) ...[const SizedBox(height: 20), action!],
          ],
        ),
      ),
    );
  }
}

// ─── StatCard ─────────────────────────────────────────
class StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color accentColor;
  final String? subtitle;

  const StatCard({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    required this.accentColor,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Flexible(
                child: Text(
                  label,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 6),
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: accentColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Icon(icon, color: accentColor, size: 16),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 22,
              fontWeight: FontWeight.w800,
              height: 1.1,
            ),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 2),
            Text(
              subtitle!,
              style: const TextStyle(color: AppColors.textMuted, fontSize: 10),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }
}

// ─── SectionHeader ────────────────────────────────────
class SectionHeader extends StatelessWidget {
  final String title;
  final Widget? trailing;

  const SectionHeader({super.key, required this.title, this.trailing});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: const TextStyle(color: AppColors.textPrimary, fontSize: 17, fontWeight: FontWeight.w700)),
        if (trailing != null) trailing!,
      ],
    );
  }
}

// ─── LoadingCenter ────────────────────────────────────
class LoadingCenter extends StatelessWidget {
  const LoadingCenter({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(child: CircularProgressIndicator(color: AppColors.accent));
  }
}

// ─── SnackHelper ──────────────────────────────────────
void showSuccess(BuildContext context, String msg) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(msg), backgroundColor: AppColors.success, behavior: SnackBarBehavior.floating),
  );
}

void showError(BuildContext context, String msg) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(msg), backgroundColor: AppColors.danger, behavior: SnackBarBehavior.floating),
  );
}

// ─── avatarColorFromName ──────────────────────────────

int getRandomNumber(int max) {
  final random = Random();
  return random.nextInt(max); // 0 -> max-1
}
Color avatarColor(String name) {
  final colors = [AppColors.accent, AppColors.success, AppColors.warning, AppColors.pink, AppColors.teal ,AppColors.borderBright,AppColors.dangerGlow];
  int sum = 0;
  for (var c in name.codeUnits) sum += c;
  return colors[sum % colors.length];
}