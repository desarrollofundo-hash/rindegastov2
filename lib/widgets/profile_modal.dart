import 'package:flutter/material.dart';
import '../controllers/profile_modal_controller.dart';
import 'profile_modal_widgets.dart';

class ProfileModal extends StatefulWidget {
  const ProfileModal({super.key});

  @override
  State<ProfileModal> createState() => _ProfileModalState();
}

class _ProfileModalState extends State<ProfileModal>
    with TickerProviderStateMixin {
  late ProfileModalController _controller;

  @override
  void initState() {
    super.initState();
    _controller = ProfileModalController();
    _controller.initializeAnimations(this);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _controller.startAnimation();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onAvatarTap() {
    _controller.onAvatarTap();
    _controller.showImageSourceDialog(context);
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _controller,
      builder: (context, child) {
        return GestureDetector(
          onVerticalDragUpdate: _controller.handleDragUpdate,
          onVerticalDragEnd: (details) =>
              _controller.handleDragEnd(details, context),
          behavior: HitTestBehavior.opaque,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            color: Colors.black.withOpacity(_controller.isDragging ? 0.3 : 0.0),
            child: Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                top: _controller.isDragging
                    ? _controller.totalDragOffset * 0.5
                    : 0.0,
              ),
              child: SingleChildScrollView(
                physics: _controller.isDragging
                    ? const NeverScrollableScrollPhysics()
                    : null,
                child: Transform.translate(
                  offset: Offset(
                    0,
                    _controller.isDragging ? _controller.totalDragOffset : 0,
                  ),
                  child: ScaleTransition(
                    scale: _controller.scaleAnimation,
                    child: FadeTransition(
                      opacity: _controller.fadeAnimation,
                      child: Container(
                        padding: const EdgeInsets.fromLTRB(24, 12, 24, 30),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(24),
                            topRight: Radius.circular(24),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(
                                _controller.isDragging ? 0.1 : 0.3,
                              ),
                              blurRadius: 20,
                              offset: Offset(
                                0,
                                _controller.isDragging ? -2 : 0,
                              ),
                            ),
                          ],
                        ),
                        child: Form(
                          key: _controller.formKey,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Header con botón de cerrar
                              ProfileModalWidgets.buildHeaderWithCloseButton(
                                _controller,
                                () => _controller.closeModal(context),
                              ),

                              // Título con animación de slide
                              SlideTransition(
                                position: _controller.slideAnimation,
                                child: ProfileModalWidgets.buildTitleSection(
                                  _controller,
                                ),
                              ),

                             /*  // Avatar con animación de escala
                              ProfileModalWidgets.buildAnimatedAvatar(
                                _controller,
                                _onAvatarTap,
                              ), */

                              const SizedBox(height: 32),

                              // Formulario con animaciones escalonadas
                              ProfileModalWidgets.buildAnimatedForm(
                                _controller,
                              ),

                              const SizedBox(height: 32),

                              // Botones animados
                              ProfileModalWidgets.buildAnimatedActionButtons(
                                _controller,
                                () => _controller.logout(context),
                                () => _controller.closeModal(context),
                                () => _controller.onChangeCompany(context),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
