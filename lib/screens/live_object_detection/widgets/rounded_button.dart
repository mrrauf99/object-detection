import 'package:flutter/material.dart';

class RoundedButton extends StatelessWidget {
  const RoundedButton({
    this.size = 60,
    this.padding,
    this.onTap,
    this.child,
    this.side,
    this.color,
    super.key,
  });

  final double size;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry? padding;
  final Widget? child;
  final BorderSide? side;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        padding: padding,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.fromBorderSide(
            side ?? const BorderSide(color: Colors.white, width: 2),
          ),
        ),
        child: child ??
            Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
            ),
      ),
    );
  }
}
