import 'package:flutter/material.dart';
import '../controllers/profile_modal_controller.dart';
import 'company_selection_modal.dart';

class ProfileModalWidgets {
  static Widget buildHeaderWithCloseButton(
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
                        ? Colors.grey[500]
                        : Colors.grey[300],
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
                      color: Colors.grey[600],
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
                  color: Colors.grey[100],
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.close, size: 20, color: Colors.grey),
              ),
              splashRadius: 20,
            ),
          ),
        ],
      ),
    );
  }

  static Widget buildTitleSection(ProfileModalController controller) {
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
                      color: Colors.grey[700],
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
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1A1D1F),
              letterSpacing: -0.5,
            ),
          ),
        ],
      ),
    );
  }

  static Widget buildAnimatedAvatar(
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

  static Widget buildAnimatedForm(ProfileModalController controller) {
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
                controller: controller,
                title: "EMPRESA",
                icon: Icons.info_outline,
                fields: [
                  buildAnimatedField(
                    controller: controller,
                    index: 4,
                    label: "Empresa",
                    hint: "Ej: Tech Solutions SA",
                  ),
                  buildAnimatedField(
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
                controller: controller,
                title: "Información Personal",
                icon: Icons.person_outline,
                fields: [
                  buildAnimatedField(
                    controller: controller,
                    index: 0,
                    label: "Nombre completo",
                    hint: "Ej: Ana Rodríguez",
                  ),
                  buildAnimatedField(
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
    required ProfileModalController controller,
    required String title,
    required IconData icon,
    required List<Widget> fields,
    required int delay,
  }) {
    return AnimatedContainer(
      duration: Duration(milliseconds: 300 + delay),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      curve: Curves.easeInOut,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: Colors.grey[600]),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  /*                   color: Colors.grey[700],
 */
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
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 4),
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              height: 44,
              decoration: BoxDecoration(
                color: isReadOnly ? Colors.white : Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isReadOnly
                      ? Colors.grey[300]!
                      : (controller.focusNodes[index].hasFocus
                            ? Colors.blue[400]!
                            : Colors.white!),
                  width: controller.focusNodes[index].hasFocus ? 1.5 : 1.0,
                ),
                boxShadow: controller.focusNodes[index].hasFocus && !isReadOnly
                    ? [
                        BoxShadow(
                          color: Colors.blue[100]!,
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
                    hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
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

                    enabledBorder: const UnderlineInputBorder(
                      borderSide: BorderSide(
                        color: Colors.transparent,
                        width: 1,
                      ),
                    ),

                    focusedBorder: const UnderlineInputBorder(
                      borderSide: BorderSide(color: Colors.blue, width: 2),
                    ),

                    disabledBorder: const UnderlineInputBorder(
                      borderSide: BorderSide(
                        color: Colors.transparent,
                        width: 0.5,
                      ),
                    ),
                  ),

                  style: TextStyle(
                    fontSize: 14,
                    color: isReadOnly ? Colors.grey[700] : Colors.black,
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
                    backgroundColor: Colors.blue[600],
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 2,
                    shadowColor: Colors.blue.withOpacity(0.3),
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
                    backgroundColor: Colors.red[600],
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 2,
                    shadowColor: Colors.red.withOpacity(0.3),
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
