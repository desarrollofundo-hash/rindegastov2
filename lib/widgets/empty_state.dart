import 'package:flutter/material.dart';

class EmptyState extends StatelessWidget {
  final String message;
  final String? buttonText;
  final VoidCallback? onButtonPressed;
  final IconData? icon;

  const EmptyState({
    super.key,
    required this.message,
    this.buttonText,
    this.onButtonPressed,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        const SizedBox(height: 100),
        Center(
          child: Column(
            children: [
              if (icon != null) ...[
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
      ],
    );
  }
}
