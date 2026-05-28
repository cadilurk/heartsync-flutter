import 'package:flutter/material.dart';

import 'appcolors.dart';

class UiCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  final Color? color;
  final Border? border;
  const UiCard({super.key, required this.child, this.padding, this.color, this.border});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding ?? const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color ?? AppColors.card,
        borderRadius: BorderRadius.circular(14),
        border: border ?? Border.all(color: AppColors.border),
      ),
      child: child,
    );
  }
}