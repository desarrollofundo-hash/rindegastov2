import 'package:flutter/material.dart';

class NuevoInformeFab extends StatelessWidget {
  final VoidCallback onPressed;
  final Color backgroundColor;
  final double elevation;
  final Widget? icon;
  final String label;
  final TextStyle? labelStyle;

  const NuevoInformeFab({
    Key? key,
    required this.onPressed,
    this.backgroundColor = const Color(0xFFE0E5EC),
    this.elevation = 4.0,
    this.icon,
    this.label = 'Informe',
    this.labelStyle,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: isDark
            ? [
                BoxShadow(
                  color: Colors.black.withOpacity(0.4),
                  blurRadius: 8,
                  offset: const Offset(4, 4),
                ),
                BoxShadow(
                  color: Colors.grey.shade800.withOpacity(0.4),
                  blurRadius: 8,
                  offset: const Offset(-4, -4),
                ),
              ]
            : [
                BoxShadow(
                  color: Colors.grey.shade500,
                  blurRadius: 8,
                  offset: const Offset(4, 4),
                ),
                BoxShadow(
                  color: Colors.white,
                  blurRadius: 8,
                  offset: const Offset(-4, -4),
                ),
              ],
      ),
      child: Material(
        color: isDark ? Colors.grey.shade900 : backgroundColor,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.add_chart_rounded,
                  color: isDark ? Colors.white : Colors.blue.shade700,
                  size: 22,
                ),
                const SizedBox(width: 8),
                Text(
                  label,
                  style:
                      labelStyle ??
                      TextStyle(
                        color: isDark ? Colors.white : Colors.blue.shade700,
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
