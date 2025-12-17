import 'package:flutter/material.dart';
import '../services/user_service.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String hintText;
  final VoidCallback onProfilePressed;
  final int notificationCount;
  final VoidCallback onNotificationPressed;
  final ValueChanged<String>? onSearch;
  final TextEditingController? controller;
  final FocusNode? focusNode;

  const CustomAppBar({
    super.key,
    required this.hintText,
    required this.onProfilePressed,
    required this.notificationCount,
    required this.onNotificationPressed,
    this.onSearch,
    this.controller,
    this.focusNode,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return AppBar(
      backgroundColor: isDark ? colorScheme.surface : Colors.white,
      elevation: 2,
      titleSpacing: 0,
      title: Row(
        children: [
          // Campo de búsqueda moderno: tarjeta elevada y pill-shaped
          Expanded(
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
              child: Material(
                elevation: 2,
                shadowColor: Colors.black.withOpacity(isDark ? 0.3 : 0.08),
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  height: 46,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: isDark ? colorScheme.background : Colors.white,
                    borderRadius: BorderRadius.circular(28),
                  ),
                  child: Row(
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0),
                        child: Icon(
                          Icons.search,
                          color: isDark
                              ? colorScheme.onSurface.withOpacity(0.6)
                              : Colors.grey,
                        ),
                      ),
                      Expanded(
                        child: TextField(
                          controller: controller,
                          focusNode: focusNode,
                          onChanged: (value) => onSearch?.call(value),
                          style: TextStyle(
                            color: isDark
                                ? colorScheme.onSurface
                                : Colors.black87,
                          ),
                          decoration: InputDecoration(
                            hintText: hintText,
                            hintStyle: TextStyle(
                              color: isDark
                                  ? colorScheme.onSurface.withOpacity(0.5)
                                  : Colors.grey.shade600,
                            ),
                            border: InputBorder.none,
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(
                              vertical: 12,
                            ),
                          ),
                        ),
                      ),
                      // Optional: quick clear button when there's text (kept simple)
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Avatar con estilo moderno: degradado, sombra y status dot
          Padding(
            padding: const EdgeInsets.only(left: 10, right: 8),
            child: InkWell(
              borderRadius: BorderRadius.circular(999),
              onTap: onProfilePressed,
              child: _UserInitialsAvatar(modern: true),
            ),
          ),
        ],
      ),
    );
  }
}

// Widget privado que muestra las iniciales del usuario dentro de un CircleAvatar
class _UserInitialsAvatar extends StatelessWidget {
  final bool modern;
  const _UserInitialsAvatar({Key? key, this.modern = false}) : super(key: key);

  String _computeInitials(String fullName) {
    if (fullName.trim().isEmpty) return '';
    final parts = fullName.trim().split(RegExp(r'\s+'));
    // Usar primera letra del primer nombre y primera letra del primer apellido
    final firstInitial = parts[0].substring(0, 1).toUpperCase();
    final secondInitial = parts.length > 1
        ? parts[1].substring(0, 1).toUpperCase()
        : '';
    return (firstInitial + secondInitial).trim();
  }

  @override
  Widget build(BuildContext context) {
    // Obtener nombre desde el servicio de usuario
    final userName = UserService().currentUserName;
    final initials = _computeInitials(userName);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    if (!modern) {
      return Container(
        margin: const EdgeInsets.only(left: 10, right: 16),
        child: CircleAvatar(
          radius: 16,
          backgroundColor: isDark
              ? colorScheme.primary
              : Colors.indigo.shade700,
          child: Text(
            initials.isNotEmpty ? initials : '?',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),
        ),
      );
    }

    // Modern avatar: gradient background, subtle shadow, status dot
    return Container(
      margin: const EdgeInsets.only(left: 10, right: 16),
      width: 44,
      height: 44,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Gradient circle with shadow
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.indigo.shade700, Colors.purple.shade400],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.12),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            alignment: Alignment.center,
            child: Text(
              initials.isNotEmpty ? initials : '?',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 14,
              ),
            ),
          ),

          // Small status dot (bottom-right)
          Positioned(
            right: -2,
            bottom: -2,
            child: Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: Colors.greenAccent.shade400,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
