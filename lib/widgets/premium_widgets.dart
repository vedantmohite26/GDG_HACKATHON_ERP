import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/premium_theme.dart';

class NeoGlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double? width;
  final double? height;
  final VoidCallback? onTap;
  final bool isHovered;

  const NeoGlassCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.width,
    this.height,
    this.onTap,
    this.isHovered = false,
  });

  @override
  Widget build(BuildContext context) {
    bool isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
          onTap: onTap,
          child: Container(
            width: width,
            height: height,
            margin: margin,
            padding: padding ?? const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Theme.of(context).cardTheme.color,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: isDark 
                    ? Colors.white.withValues(alpha: 0.08) 
                    : const Color(0xFFE3EEF7),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: isDark 
                      ? Colors.black.withValues(alpha: 0.1) 
                      : PremiumTheme.primary.withValues(alpha: 0.06),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                  spreadRadius: 0,
                ),
              ],
            ),
            child: child,
          ),
        )
        .animate()
        .fadeIn(duration: 400.ms)
        .slideY(begin: 0.1, end: 0, curve: Curves.easeOut);
  }
}

class FutureButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool isLoading;
  final bool isOutline;

  const FutureButton({
    super.key,
    required this.text,
    this.onPressed,
    this.icon,
    this.isLoading = false,
    this.isOutline = false,
  });

  @override
  Widget build(BuildContext context) {
    if (isOutline) {
      return OutlinedButton(
        onPressed: isLoading ? null : onPressed,
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: PremiumTheme.primary, width: 2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 32),
          foregroundColor: PremiumTheme.primary,
        ),
        child: _buildContent(),
      );
    }

    return Container(
      decoration: BoxDecoration(
        gradient: PremiumTheme.primaryGradient,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: PremiumTheme.primary.withValues(alpha: 0.3),
            blurRadius: 16,
            offset: const Offset(0, 8),
            spreadRadius: -2,
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isLoading ? null : onPressed,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 32),
            child: _buildContent(color: Colors.white),
          ),
        ),
      ),
    ).animate().scale(duration: 200.ms, curve: Curves.easeOut);
  }

  Widget _buildContent({Color? color}) {
    if (isLoading) {
      return SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(
            color ?? PremiumTheme.primary,
          ),
        ),
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (icon != null) ...[
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 8),
        ],
        Text(
          text,
          style: GoogleFonts.outfit(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: color,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }
}

class TechInput extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isPassword;
  final TextEditingController? controller;
  final String? Function(String?)? validator;
  final Widget? suffixIcon;
  final TextInputType? keyboardType;

  const TechInput({
    super.key,
    required this.label,
    required this.icon,
    this.isPassword = false,
    this.controller,
    this.validator,
    this.suffixIcon,
    this.keyboardType,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextFormField(
        controller: controller,
        obscureText: isPassword,
        validator: validator,
        keyboardType: keyboardType,
        style: GoogleFonts.inter(fontSize: 16),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: GoogleFonts.inter(color: PremiumTheme.textSecondary),
          prefixIcon: Icon(
            icon,
            color: PremiumTheme.primary.withValues(alpha: 0.5),
          ),
          suffixIcon: suffixIcon,
          border: InputBorder.none,
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: PremiumTheme.primary, width: 2),
          ),
          enabledBorder: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 16,
          ),
        ),
      ),
    );
  }
}

class HoloBadge extends StatelessWidget {
  final String text;
  final Color color;

  const HoloBadge({
    super.key,
    required this.text,
    this.color = PremiumTheme.primary,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: color.withValues(alpha: 0.25), width: 1),
      ),
      child: Text(
        text.toUpperCase(),
        style: GoogleFonts.outfit(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: color,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
