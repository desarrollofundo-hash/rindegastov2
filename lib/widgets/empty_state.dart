import 'package:flutter/material.dart';

class EmptyState extends StatelessWidget {
  final String message;
  final String? buttonText;
  final VoidCallback? onButtonPressed;
  final IconData? icon;
  final Widget? image;

  const EmptyState({
    super.key,
    required this.message,
    this.buttonText,
    this.onButtonPressed,
    this.icon,
    this.image,
  });

  @override
  Widget build(BuildContext context) {
    // Usar Column centrado en lugar de ListView para evitar anidar
    // scrollables (causa de crash cuando el padre ya es un ScrollView).
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (image != null) ...[
              image!,
              const SizedBox(height: 16),
            ] else if (icon != null) ...[
              Icon(icon, size: 64, color: Colors.grey),
              const SizedBox(height: 16),
            ],
            Text(
              message,
              style: const TextStyle(color: Colors.grey, fontSize: 16),
              textAlign: TextAlign.center,
            ),
            if (buttonText != null && onButtonPressed != null) ...[
              const SizedBox(height: 20),
              ElevatedButton.icon(
                icon: const Icon(Icons.add),
                label: Text(buttonText!),
                onPressed: onButtonPressed,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
