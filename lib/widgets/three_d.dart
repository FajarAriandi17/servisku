import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme.dart';

/// Card with a "3D" look: a solid depth layer below plus soft shadow and
/// a subtle top highlight — matching the ServisKu logo style.
class Card3D extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color color;
  final Color? depthColor;
  final Gradient? gradient;
  final double radius;
  final double depth;
  final VoidCallback? onTap;

  const Card3D({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.color = Colors.white,
    this.depthColor,
    this.gradient,
    this.radius = 22,
    this.depth = 6,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final dColor =
        depthColor ??
        (gradient != null ? AppColors.primaryDark : const Color(0xFFD4D8F5));
    final content = Container(
      margin: EdgeInsets.only(bottom: depth),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        boxShadow: [
          BoxShadow(color: dColor, offset: Offset(0, depth)),
          BoxShadow(
            color: AppColors.primaryDark.withValues(alpha: 0.18),
            blurRadius: 22,
            offset: Offset(0, depth + 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: Container(
          decoration: BoxDecoration(
            color: gradient == null ? color : null,
            gradient: gradient,
          ),
          child: Stack(
            children: [
              Positioned(
                left: 0,
                right: 0,
                top: 0,
                height: 1.5,
                child: Container(color: Colors.white.withValues(alpha: 0.6)),
              ),
              Padding(padding: padding, child: child),
            ],
          ),
        ),
      ),
    );
    if (onTap == null) return content;
    return _Pressable(onTap: onTap!, child: content);
  }
}

class _Pressable extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;
  const _Pressable({required this.child, required this.onTap});

  @override
  State<_Pressable> createState() => _PressableState();
}

class _PressableState extends State<_Pressable> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => setState(() => _down = true),
      onTapCancel: () => setState(() => _down = false),
      onTapUp: (_) => setState(() => _down = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _down ? 0.97 : 1,
        duration: const Duration(milliseconds: 110),
        child: widget.child,
      ),
    );
  }
}

/// Chunky 3D push button that physically "sinks" when pressed.
class Button3D extends StatefulWidget {
  final String label;
  final IconData? icon;
  final Widget? leading;
  final VoidCallback? onPressed;
  final Color color;
  final Color depthColor;
  final Color textColor;
  final bool loading;
  final double height;

  const Button3D({
    super.key,
    required this.label,
    this.icon,
    this.leading,
    this.onPressed,
    this.color = AppColors.primary,
    this.depthColor = AppColors.primaryDark,
    this.textColor = Colors.white,
    this.loading = false,
    this.height = 56,
  });

  const Button3D.white({
    super.key,
    required this.label,
    this.icon,
    this.leading,
    this.onPressed,
    this.loading = false,
    this.height = 56,
  }) : color = Colors.white,
       depthColor = const Color(0xFFCBD0F0),
       textColor = AppColors.ink;

  const Button3D.accent({
    super.key,
    required this.label,
    this.icon,
    this.leading,
    this.onPressed,
    this.loading = false,
    this.height = 56,
  }) : color = AppColors.accent,
       depthColor = AppColors.accentDark,
       textColor = Colors.white;

  @override
  State<Button3D> createState() => _Button3DState();
}

class _Button3DState extends State<Button3D> {
  bool _down = false;
  static const double _depth = 5;

  @override
  Widget build(BuildContext context) {
    final disabled = widget.onPressed == null || widget.loading;
    final offset = _down ? _depth : 0.0;
    return GestureDetector(
      onTapDown: disabled ? null : (_) => setState(() => _down = true),
      onTapCancel: () => setState(() => _down = false),
      onTapUp: disabled ? null : (_) => setState(() => _down = false),
      onTap: disabled ? null : widget.onPressed,
      child: Opacity(
        opacity: widget.onPressed == null ? 0.55 : 1,
        child: SizedBox(
          height: widget.height + _depth,
          child: Stack(
            children: [
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                height: widget.height,
                child: Container(
                  decoration: BoxDecoration(
                    color: widget.depthColor,
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color: widget.depthColor.withValues(alpha: 0.35),
                        blurRadius: 14,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                ),
              ),
              AnimatedPositioned(
                duration: const Duration(milliseconds: 80),
                left: 0,
                right: 0,
                top: offset,
                height: widget.height,
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(18),
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Color.lerp(widget.color, Colors.white, 0.18)!,
                        widget.color,
                      ],
                    ),
                  ),
                  alignment: Alignment.center,
                  child: widget.loading
                      ? SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.6,
                            color: widget.textColor,
                          ),
                        )
                      : Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (widget.leading != null) ...[
                              widget.leading!,
                              const SizedBox(width: 10),
                            ] else if (widget.icon != null) ...[
                              Icon(
                                widget.icon,
                                color: widget.textColor,
                                size: 22,
                              ),
                              const SizedBox(width: 10),
                            ],
                            Flexible(
                              child: Text(
                                widget.label,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: widget.textColor,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 16,
                                  letterSpacing: 0.2,
                                ),
                              ),
                            ),
                          ],
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Glossy 3D icon tile (like the app logo).
class IconTile3D extends StatelessWidget {
  final IconData icon;
  final Color color;
  final double size;
  const IconTile3D({
    super.key,
    required this.icon,
    this.color = AppColors.primary,
    this.size = 48,
  });

  @override
  Widget build(BuildContext context) {
    final dark = Color.lerp(color, Colors.black, 0.35)!;
    final light = Color.lerp(color, Colors.white, 0.35)!;
    return Container(
      width: size,
      height: size + 4,
      alignment: Alignment.topCenter,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(size * 0.32),
        color: dark,
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.35),
            blurRadius: 10,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(size * 0.32),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [light, color],
          ),
        ),
        child: Icon(icon, color: Colors.white, size: size * 0.52),
      ),
    );
  }
}

/// Inset 3D text field.
class Input3D extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final bool obscure;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;
  final Widget? suffix;
  final String? prefixText;
  final int maxLines;
  final ValueChanged<String>? onChanged;

  const Input3D({
    super.key,
    required this.controller,
    required this.hint,
    required this.icon,
    this.obscure = false,
    this.keyboardType,
    this.validator,
    this.suffix,
    this.prefixText,
    this.maxLines = 1,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: Colors.white,
        boxShadow: const [
          BoxShadow(color: Color(0xFFD4D8F5), offset: Offset(0, 4)),
        ],
      ),
      child: TextFormField(
        controller: controller,
        obscureText: obscure,
        keyboardType: keyboardType,
        validator: validator,
        maxLines: maxLines,
        onChanged: onChanged,
        style: const TextStyle(fontWeight: FontWeight.w600),
        decoration: InputDecoration(
          hintText: hint,
          prefixText: prefixText,
          prefixIcon: Icon(icon, color: AppColors.primary),
          suffixIcon: suffix,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 18,
          ),
          hintStyle: const TextStyle(
            color: AppColors.muted,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

/// Gauge-style progress ring — a nod to the speedometer in the logo.
class GaugeRing extends StatelessWidget {
  final double progress; // 0..1 (1 = due)
  final double size;
  final Color color;
  final Widget? center;
  final double stroke;

  const GaugeRing({
    super.key,
    required this.progress,
    this.size = 64,
    this.color = AppColors.primary,
    this.center,
    this.stroke = 7,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _GaugePainter(progress.clamp(0, 1), color, stroke),
        child: Center(child: center),
      ),
    );
  }
}

class _GaugePainter extends CustomPainter {
  final double p;
  final Color color;
  final double stroke;
  _GaugePainter(this.p, this.color, this.stroke);

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(
      stroke / 2,
      stroke / 2,
      size.width - stroke,
      size.height - stroke,
    );
    const start = math.pi * 0.75;
    const sweep = math.pi * 1.5;
    final bg = Paint()
      ..color = color.withValues(alpha: 0.15)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = stroke;
    canvas.drawArc(rect, start, sweep, false, bg);
    final shadow = Paint()
      ..color = Color.lerp(color, Colors.black, 0.3)!
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = stroke;
    canvas.drawArc(
      rect.shift(const Offset(0, 2)),
      start,
      sweep * p,
      false,
      shadow,
    );
    final fg = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = stroke;
    canvas.drawArc(rect, start, sweep * p, false, fg);
  }

  @override
  bool shouldRepaint(covariant _GaugePainter old) =>
      old.p != p || old.color != color;
}

/// Gradient header background with soft floating orbs.
class GradientHeader extends StatelessWidget {
  final Widget child;
  final double bottomRadius;
  const GradientHeader({
    super.key,
    required this.child,
    this.bottomRadius = 32,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.vertical(
          bottom: Radius.circular(bottomRadius),
        ),
        boxShadow: [
          const BoxShadow(color: AppColors.primaryDark, offset: Offset(0, 6)),
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.35),
            blurRadius: 24,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.vertical(
          bottom: Radius.circular(bottomRadius),
        ),
        child: Stack(
          children: [
            Positioned(right: -40, top: -30, child: _orb(150, 0.12)),
            Positioned(left: -30, bottom: -50, child: _orb(120, 0.08)),
            child,
          ],
        ),
      ),
    );
  }

  Widget _orb(double s, double a) => Container(
    width: s,
    height: s,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      color: Colors.white.withValues(alpha: a),
    ),
  );
}

class StatusChip extends StatelessWidget {
  final String label;
  final Color color;
  const StatusChip({super.key, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: Color.lerp(color, Colors.black, 0.2),
          fontWeight: FontWeight.w800,
          fontSize: 11.5,
        ),
      ),
    );
  }
}

class SectionTitle extends StatelessWidget {
  final String title;
  final Widget? trailing;
  const SectionTitle(this.title, {super.key, this.trailing});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 8, 4, 12),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final Widget? action;
  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconTile3D(icon: icon, size: 72),
          const SizedBox(height: 20),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.muted, height: 1.4),
          ),
          if (action != null) ...[const SizedBox(height: 20), action!],
        ],
      ),
    );
  }
}
