import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
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
        // Verificar si es un error de versión desactualizada
        if (e.toString().contains('VERSION_DESACTUALIZADA')) {
          final errorCompleto = e.toString();
          print('🔍 Error completo: $errorCompleto');
          final parts = errorCompleto.split('|');
          final enlaceDescarga = parts.length > 1 ? parts[1] : '';
          print('🔗 Enlace de descarga: $enlaceDescarga');
          _showVersionDialog(enlaceDescarga);
        } else {
          final errorMessage = _loginController.getErrorMessage(e);
          _showErrorSnackBar(errorMessage);
        }
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

  void _showVersionDialog(String enlaceDescarga) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.system_update, color: Colors.orange, size: 28),
              SizedBox(width: 12),
              Text('Actualización'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Hay una nueva versión disponible de la aplicación.',
                style: TextStyle(fontSize: 16),
              ),
              SizedBox(height: 12),
              Text(
                'Por favor, descarga e instala la última versión para continuar.',
                style: TextStyle(fontSize: 14, color: Colors.grey[700]),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Cancelar'),
            ),
            ElevatedButton.icon(
              onPressed: () async {
                try {
                  final Uri url = Uri.parse(enlaceDescarga);
                  print('🔗 Intentando abrir URL: $url');
                  await launchUrl(url, mode: LaunchMode.externalApplication);
                } catch (e) {
                  print('❌ Error al abrir URL: $e');
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('No se pudo abrir el enlace de descarga'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
              icon: Icon(Icons.download),
              label: Text('Descargar'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        );
      },
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
