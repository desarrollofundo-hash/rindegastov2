import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/user_service.dart';
import '../services/api_service.dart';

class LoginController extends ChangeNotifier {
  final TextEditingController userController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  final ApiService _apiService = ApiService();

  bool _isLoading = false;
  bool _obscurePassword = true;

  // Getters
  bool get isLoading => _isLoading;
  bool get obscurePassword => _obscurePassword;

  get errorMessage => null;

  // Validaciones
  String? validateUser(String? value) {
    if (value == null || value.isEmpty) {
      return 'Por favor ingresa tu DNI/usuario';
    }
    if (value.length < 8) {
      return 'El DNI debe tener al menos 8 dígitos';
    }
    return null;
  }

  String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Por favor ingresa tu contraseña';
    }
    if (value.length < 8) {
      return 'La contraseña debe tener al menos 8 caracteres';
    }
    return null;
  }

  // Cambiar visibilidad de contraseña
  void togglePasswordVisibility() {
    _obscurePassword = !_obscurePassword;
    notifyListeners();
  }

  // Lógica de login
  Future<Map<String, dynamic>?> login() async {
    if (!formKey.currentState!.validate()) return null;

    _isLoading = true;
    notifyListeners();

    try {
      String usuario = userController.text.trim();
      String contrasena = passwordController.text.trim();

      // Usar el nuevo servicio API
      final userData = await _apiService.loginCredencial(
        usuario: usuario,
        contrasena: contrasena,
        app: 12,
      );

      // Crear el UserModel con los datos del login
      final userModel = UserModel.fromJson(userData);
      // Guardar el usuario en el servicio singleton
      UserService().setCurrentUser(userModel);

      return userData;
    } catch (e) {
      rethrow; // Re-lanzar la excepción para que la maneje la vista
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Manejo de errores
  String getErrorMessage(dynamic error) {
    String errorMessage;
    if (error.toString().contains('TimeoutException')) {
      errorMessage = 'Tiempo de espera agotado. Verifica tu conexión.';
    } else if (error.toString().contains('SocketException')) {
      errorMessage = 'Sin conexión a internet. Verifica tu red.';
    } else if (error.toString().contains('Usuario inactivo')) {
      errorMessage = 'Usuario inactivo. Contacta al administrador.';
    } else if (error.toString().contains('Usuario o contraseña incorrectos')) {
      errorMessage = 'Usuario o contraseña incorrectos';
    } else {
      errorMessage = 'Error al iniciar sesión. Intenta nuevamente.';
    }
    return errorMessage;
  }

  @override
  void dispose() {
    userController.dispose();
    passwordController.dispose();
    _apiService.dispose();
    super.dispose();
  }
}
