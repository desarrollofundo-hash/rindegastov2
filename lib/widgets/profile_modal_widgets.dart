import 'package:flutter/material.dart';
import '../controllers/profile_modal_controller.dart';

class ProfileModalWidgets {
  static Widget buildHeaderWithCloseButton(
    BuildContext context,
    ProfileModalController controller,
    VoidCallback onClose,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Espacio para alinear el título centrado
          const SizedBox(width: 40),

          // Indicador de arrastre
          Expanded(
            child: Column(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 20,
                  height: 2,
                  decoration: BoxDecoration(
                    color: controller.isDragging
                        ? (Theme.of(context).brightness == Brightness.dark
                              ? Theme.of(context).hintColor
                              : Colors.grey[500])
                        : (Theme.of(context).brightness == Brightness.dark
                              ? Theme.of(context).dividerColor
                              : Colors.grey[300]),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                if (controller.isDragging) ...[
                  const SizedBox(height: 8),
                  Text(
                    controller.totalDragOffset > 100
                        ? "Suelta para cerrar"
                        : "Desliza para cerrar",
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Theme.of(
                              context,
                            ).textTheme.bodyMedium?.color?.withOpacity(0.6)
                          : Colors.grey[600],
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Botón de cerrar (X)
          AnimatedOpacity(
            duration: const Duration(milliseconds: 200),
            opacity: controller.isDragging ? 0.0 : 1.0,
            child: IconButton(
              onPressed: onClose,
              icon: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.grey[800]
                      : Colors.grey[100],
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.close,
                  size: 20,
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Theme.of(context).iconTheme.color
                      : Colors.grey,
                ),
              ),
              splashRadius: 20,
            ),
          ),
        ],
      ),
    );
  }

  static Widget buildTitleSection(
    BuildContext context,
    ProfileModalController controller,
  ) {
    final userName = controller.getFieldValue(0);

    return AnimatedOpacity(
      duration: const Duration(milliseconds: 200),
      opacity: controller.isDragging ? 0.7 : 1.0,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Línea de bienvenida (más pequeña) con mano animada
          AnimatedBuilder(
            animation: controller.handAnimation,
            builder: (context, child) {
              final angle = controller.handAnimation.value;
              return Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Bienvenido ',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w500,
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Theme.of(
                              context,
                            ).textTheme.bodyLarge?.color?.withOpacity(0.7)
                          : Colors.grey[700],
                    ),
                  ),
                  Transform.rotate(
                    angle: angle,
                    alignment: Alignment.bottomCenter,
                    child: const Text('👋', style: TextStyle(fontSize: 25)),
                  ),
                ],
              );
            },
          ),
          // Nombre del usuario (resaltado)
          Text(
            userName.isNotEmpty ? userName : 'Perfil de Usuario',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: Theme.of(context).brightness == Brightness.dark
                  ? Theme.of(context).textTheme.headlineSmall?.color
                  : const Color(0xFF1A1D1F),
              letterSpacing: -0.5,
            ),
          ),
        ],
      ),
    );
  }

  static Widget buildAnimatedAvatar(
    BuildContext context,
    ProfileModalController controller,
    VoidCallback onAvatarTap,
  ) {
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 200),
      opacity: controller.isDragging ? 0.5 : 1.0,
      child: AnimatedScale(
        scale: controller.avatarScale,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        child: GestureDetector(
          onTap: controller.isDragging ? null : onAvatarTap,
          child: MouseRegion(
            cursor: controller.isDragging
                ? SystemMouseCursors.basic
                : SystemMouseCursors.click,
            child: Column(children: [Stack(alignment: Alignment.center)]),
          ),
        ),
      ),
    );
  }

  static Widget buildAnimatedForm(
    BuildContext context,
    ProfileModalController controller,
  ) {
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 200),
      opacity: controller.isDragging ? 0.3 : 1.0,
      child: SlideTransition(
        position: Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero)
            .animate(
              CurvedAnimation(
                parent: controller.animationController,
                curve: const Interval(0.4, 1.0, curve: Curves.easeOut),
              ),
            ),
        child: FadeTransition(
          opacity: Tween<double>(begin: 0.0, end: 1.0).animate(
            CurvedAnimation(
              parent: controller.animationController,
              curve: const Interval(0.5, 1.0, curve: Curves.easeIn),
            ),
          ),
          child: Column(
            children: [
              buildAnimatedFormSection(
                context: context,
                controller: controller,
                title: "EMPRESA",
                icon: Icons.info_outline,
                fields: [
                  buildAnimatedField(
                    context: context,
                    controller: controller,
                    index: 4,
                    label: "Empresa",
                    hint: "Ej: Tech Solutions SA",
                  ),
                  buildAnimatedField(
                    context: context,
                    controller: controller,
                    index: 5,
                    label: "RUC",
                    hint: "M12432932985",
                  ),
                ],
                delay: 200,
              ),
              const SizedBox(height: 10),
              buildAnimatedFormSection(
                context: context,
                controller: controller,
                title: "Información Personal",
                icon: Icons.person_outline,
                fields: [
                  buildAnimatedField(
                    context: context,
                    controller: controller,
                    index: 0,
                    label: "Nombre completo",
                    hint: "Ej: Ana Rodríguez",
                  ),
                  buildAnimatedField(
                    context: context,
                    controller: controller,
                    index: 1,
                    label: "Dni",
                    hint: "Ej: 12345678",
                  ),
                ],
                delay: 0,
              ),
            ],
          ),
        ),
      ),
    );
  }

  static Widget buildAnimatedFormSection({
    required BuildContext context,
    required ProfileModalController controller,
    required String title,
    IconData? icon,
    String? iconImage,
    required List<Widget> fields,
    required int delay,
  }) {
    return AnimatedContainer(
      duration: Duration(milliseconds: 300 + delay),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? Theme.of(context).cardColor
            : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Theme.of(context).brightness == Brightness.dark
            ? Border.all(
                color: Theme.of(context).dividerColor.withOpacity(0.3),
                width: 0.5,
              )
            : null,
      ),
      curve: Curves.easeInOut,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (iconImage != null)
                ColorFiltered(
                  colorFilter: Theme.of(context).brightness == Brightness.dark
                      ? const ColorFilter.mode(Colors.white70, BlendMode.srcIn)
                      : const ColorFilter.mode(
                          Colors.transparent,
                          BlendMode.multiply,
                        ),
                  child: SizedBox(
                    width: 18,
                    height: 18,
                    child: Image.asset(iconImage),
                  ),
                )
              else if (icon != null)
                Icon(
                  icon,
                  size: 18,
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Theme.of(context).iconTheme.color?.withOpacity(0.6)
                      : Colors.grey[600],
                ),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Theme.of(context).textTheme.titleMedium?.color
                      : Colors.grey[700],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...fields,
        ],
      ),
    );
  }

  static Widget buildAnimatedField({
    required BuildContext context,
    required ProfileModalController controller,
    required int index,
    required String label,
    required String hint,
    TextInputType? keyboardType,
  }) {
    String displayValue = controller.getFieldValue(index);
    bool isReadOnly = controller.isFieldReadOnly(index);

    return AnimatedContainer(
      duration: Duration(milliseconds: 400 + (index * 100)),
      curve: Curves.easeOutBack,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 2),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Theme.of(context).brightness == Brightness.dark
                    ? Theme.of(context).textTheme.bodyMedium?.color
                    : Colors.black,
              ),
            ),
            const SizedBox(height: 3),
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              height: 44,
              decoration: BoxDecoration(
                color: isReadOnly
                    ? (Theme.of(context).brightness == Brightness.dark
                          ? Theme.of(context).disabledColor.withOpacity(0.05)
                          : Colors.white)
                    : (Theme.of(context).brightness == Brightness.dark
                          ? (Theme.of(context).inputDecorationTheme.fillColor ??
                                Theme.of(context).cardColor)
                          : Colors.white),
                borderRadius: BorderRadius.circular(8),
                boxShadow: controller.focusNodes[index].hasFocus && !isReadOnly
                    ? [
                        BoxShadow(
                          color: Theme.of(context).brightness == Brightness.dark
                              ? Theme.of(context).primaryColor.withOpacity(0.3)
                              : Colors.blue[100]!,
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ]
                    : [],
              ),
              child: IgnorePointer(
                ignoring: controller.isDragging,
                child: TextField(
                  focusNode: controller.focusNodes[index],
                  keyboardType: keyboardType,
                  readOnly: isReadOnly,
                  controller: isReadOnly
                      ? (TextEditingController()..text = displayValue)
                      : null,
                  decoration: InputDecoration(
                    hintText: isReadOnly ? null : hint,
                    hintStyle: TextStyle(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Theme.of(context).hintColor
                          : Colors.grey[400],
                      fontSize: 14,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),

                    // Solo subrayado inferior
                    border: const UnderlineInputBorder(
                      borderSide: BorderSide(
                        color: Colors.transparent,
                        width: 1,
                      ),
                    ),

                    enabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Theme.of(context).dividerColor
                            : Colors.grey[300]!,
                        width: 1,
                      ),
                    ),

                    focusedBorder: UnderlineInputBorder(
                      borderSide: BorderSide(
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Theme.of(context).primaryColor
                            : Colors.blue,
                        width: 2,
                      ),
                    ),

                    disabledBorder: const UnderlineInputBorder(),
                  ),

                  style: TextStyle(
                    fontSize: 14,
                    color: isReadOnly
                        ? (Theme.of(context).brightness == Brightness.dark
                              ? Colors
                                    .white // Color para campos deshabilitados en modo oscuro
                              : Colors.grey[700])
                        : (Theme.of(context).brightness == Brightness.dark
                              ? Colors
                                    .white // Texto blanco en modo oscuro
                              : Colors.black), // Texto negro en modo claro
                    fontWeight: isReadOnly
                        ? FontWeight.w500
                        : FontWeight.normal,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static Widget buildAnimatedActionButtons(
    BuildContext context,
    ProfileModalController controller,
    VoidCallback onLogout,
    VoidCallback onCancel,
    VoidCallback onChangeCompany,
  ) {
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 200),
      opacity: controller.isDragging ? 0.0 : 1.0,
      child: SlideTransition(
        position: Tween<Offset>(begin: const Offset(0, 0.5), end: Offset.zero)
            .animate(
              CurvedAnimation(
                parent: controller.animationController,
                curve: const Interval(0.7, 1.0, curve: Curves.easeOut),
              ),
            ),
        child: FadeTransition(
          opacity: Tween<double>(begin: 0.0, end: 1.0).animate(
            CurvedAnimation(
              parent: controller.animationController,
              curve: const Interval(0.8, 1.0, curve: Curves.easeIn),
            ),
          ),
          child: Column(
            children: [
              // Botón de cambiar empresa
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: double.infinity,
                height: 40,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        Theme.of(context).brightness == Brightness.dark
                        ? Colors.blue[700]
                        : Colors.blue[600],
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: Theme.of(context).brightness == Brightness.dark
                        ? 4
                        : 2,
                    shadowColor: Theme.of(context).brightness == Brightness.dark
                        ? Colors.blue.withOpacity(0.5)
                        : Colors.blue.withOpacity(0.3),
                  ),
                  onPressed: onChangeCompany,
                  icon: const Icon(Icons.business, size: 20),
                  label: const Text(
                    "Cambiar Empresa",
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              // Botón de cerrar sesión
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: double.infinity,
                height: 40,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        Theme.of(context).brightness == Brightness.dark
                        ? Colors.red[700]
                        : Colors.red[600],
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: Theme.of(context).brightness == Brightness.dark
                        ? 4
                        : 2,
                    shadowColor: Theme.of(context).brightness == Brightness.dark
                        ? Colors.red.withOpacity(0.5)
                        : Colors.red.withOpacity(0.3),
                  ),
                  onPressed: onLogout,
                  icon: const Icon(Icons.logout, size: 20),
                  label: const Text(
                    "Cerrar sesión",
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                  ),
                ),
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }
}
