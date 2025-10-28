import '../models/user_model.dart';

class UserService {
  static final UserService _instance = UserService._internal();

  factory UserService() {
    return _instance;
  }

  UserService._internal();

  UserModel? _currentUser;

  // Getter para obtener el usuario actual
  UserModel? get currentUser => _currentUser;

  // Setter para establecer el usuario actual
  void setCurrentUser(UserModel user) {
    _currentUser = user;
  }

  // Método para limpiar el usuario (logout)
  void clearCurrentUser() {
    _currentUser = null;
  }

  // Método para verificar si hay un usuario logueado
  bool get isLoggedIn => _currentUser != null;

  // Método para obtener el usecod del usuario actual
  String get currentUserCode => _currentUser?.usecod ?? '';
  String get currentUserDni => _currentUser?.usedoc ?? '';
  String get currentUserName => _currentUser?.usenam ?? '';
}
