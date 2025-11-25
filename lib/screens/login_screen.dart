import 'package:flutter/material.dart';
import '../widgets/company_selection_modal.dart';
import '../controllers/login_controller.dart';
import '../widgets/login_view.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  late LoginController _loginController;

  @override
  void initState() {
    super.initState();
    _loginController = LoginController();
    _loginController.addListener(_onControllerUpdate);
  }

  void _onControllerUpdate() {
    setState(() {});
  }

  void _handleLogin() async {
    try {
      final userData = await _loginController.login();

      if (userData != null && mounted) {
        // Mostrar modal de selección de empresa
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext context) {
            return CompanySelectionModal(
              userName: userData['usenam'] ?? 'Usuario',
              userId: int.tryParse(userData['usecod'] ?? '0') ?? 0,
              shouldNavigateToHome: true,
            );
          },
        );
      }
    } catch (e) {
      if (mounted) {
        final errorMessage = _loginController.getErrorMessage(e);
        _showErrorSnackBar(errorMessage);
      }
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red.shade700,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  void _handleForgotPassword() {
    // Navegar a pantalla de recuperación
  }

  void _handleRegister() {
    // Navegar a pantalla de registro
  }

  @override
  void dispose() {
    _loginController.removeListener(_onControllerUpdate);
    _loginController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LoginView(
      controller: _loginController,
      onLogin: _handleLogin,
      onForgotPassword: _handleForgotPassword,
      onRegister: _handleRegister,
    );
  }
}
