class RolUsuarioApp {
  final int idApp;
  final String? app;
  final int idMenu;
  final String? menu;
  final int idSubMenu;
  final String? subMenu;
  final int idPermiso;
  final int idRol;
  final int idUsuario;
  final String? nombres;
  final String? dni;

  RolUsuarioApp({
    required this.idApp,
    this.app,
    required this.idMenu,
    this.menu,
    required this.idSubMenu,
    this.subMenu,
    required this.idPermiso,
    required this.idRol,
    required this.idUsuario,
    this.nombres,
    this.dni,
  });

  factory RolUsuarioApp.fromJson(Map<String, dynamic> json) {
    try {
      return RolUsuarioApp(
        idApp: _parseIntSafe(json['idApp'], 0),
        app: _parseStringSafe(json['app']),
        idMenu: _parseIntSafe(json['idMenu'], 0),
        menu: _parseStringSafe(json['menu']),
        idSubMenu: _parseIntSafe(json['idSubMenu'], 0),
        subMenu: _parseStringSafe(json['subMenu']),
        idPermiso: _parseIntSafe(json['idPermiso'], 0),
        idRol: _parseIntSafe(json['idRol'], 0),
        idUsuario: _parseIntSafe(json['idUsuario'], 0),
        nombres: _parseStringSafe(json['nombres']),
        dni: _parseStringSafe(json['dni']),
      );
    } catch (e) {
      throw Exception(
        'Error al crear RolUsuarioApp desde JSON: $e\nJSON: $json',
      );
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'idApp': idApp,
      'app': app,
      'idMenu': idMenu,
      'menu': menu,
      'idSubMenu': idSubMenu,
      'subMenu': subMenu,
      'idPermiso': idPermiso,
      'idRol': idRol,
      'idUsuario': idUsuario,
      'nombres': nombres,
      'dni': dni,
    };
  }

  static int _parseIntSafe(dynamic value, int defaultValue) {
    if (value == null) return defaultValue;
    if (value is int) return value;
    if (value is String) {
      final parsed = int.tryParse(value);
      if (parsed != null) return parsed;
    }
    if (value is double) return value.toInt();
    return defaultValue;
  }

  static String? _parseStringSafe(dynamic value) {
    if (value == null) return null;
    if (value is String) return value.isEmpty ? null : value;
    return value.toString();
  }

  @override
  String toString() {
    return 'RolUsuarioApp(idApp: $idApp, app: $app, menu: $menu, subMenu: $subMenu, nombres: $nombres, dni: $dni)';
  }
}
