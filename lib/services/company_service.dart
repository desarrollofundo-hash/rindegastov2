import 'package:flutter/material.dart';
import '../models/user_company.dart';

/// Servicio singleton para gestionar la empresa seleccionada por el usuario
///
/// Este servicio mantiene la empresa activa durante toda la sesión
/// y permite acceder a ella desde cualquier parte de la aplicación.
class CompanyService extends ChangeNotifier {
  static final CompanyService _instance = CompanyService._internal();

  /// Factory constructor para retornar la misma instancia (singleton)
  factory CompanyService() {
    return _instance;
  }

  /// Constructor interno privado
  CompanyService._internal();

  /// Empresa seleccionada actualmente
  UserCompany? _currentCompany;

  /// Getter para obtener la empresa seleccionada
  UserCompany? get currentCompany => _currentCompany;

  /// Getter para verificar si hay una empresa seleccionada
  bool get isLoggedIn => _currentCompany != null;

  /// Getter para obtener el nombre de la empresa seleccionada
  String get currentUserCompany => _currentCompany?.empresa ?? '';

  /// Getter para obtener el ID de la empresa seleccionada
  int get companyId => _currentCompany?.id ?? 0;

  /// Getter para obtener la sucursal de la empresa seleccionada
  String get companySucursal => _currentCompany?.sucursal ?? '';

  /// Getter para obtener el tipo de gasto de la empresa seleccionada
  String get companyTipogasto => _currentCompany?.tipogasto ?? '';

  /// Getter para obtener el consumidor de la empresa seleccionada
  String get companyConsumidor => _currentCompany?.consumidor ?? '';

  /// Getter para obtener el régimen de la empresa seleccionada
  String get companyRegimen => _currentCompany?.regimen ?? '';
  String get companyRuc => _currentCompany?.ruc ?? '';

  /// Setter para establecer la empresa seleccionada
  void setCurrentCompany(UserCompany company) {
    _currentCompany = company;
    print('🏢 Empresa seleccionada: ${company.empresa}');
    print('📍 Sucursal: ${company.sucursal}');
    print('🏷️ Tipo gasto: ${company.tipogasto}');
    print('👤 Consumidor: ${company.consumidor}');
    notifyListeners();
  }

  /// Limpiar la empresa seleccionada (útil para logout)
  void clearCurrentCompany() {
    print(
      '🧹 Limpiando empresa seleccionada: ${_currentCompany?.empresa ?? 'ninguna'}',
    );
    _currentCompany = null;
    notifyListeners();
  }

  /// Obtener información completa de la empresa como Map
  /// Útil para enviar en APIs que requieren datos de empresa
  Map<String, dynamic> getCompanyDataForAPI() {
    if (_currentCompany == null) {
      return {};
    }

    return {
      'empresaId': _currentCompany!.id,
      'empresa': _currentCompany!.empresa,
      'sucursal': _currentCompany!.sucursal,
      'tipogasto': _currentCompany!.tipogasto,
      'consumidor': _currentCompany!.consumidor,
      'regimen': _currentCompany!.regimen,
      'destino': _currentCompany!.destino,
      'ruc': _currentCompany!.ruc,
    };
  }

  /// Verificar si la empresa actual es válida
  bool isCompanyValid() {
    return _currentCompany?.isValid ?? false;
  }

  /// Obtener información de debug de la empresa
  String getDebugInfo() {
    if (_currentCompany == null) {
      return 'No hay empresa seleccionada';
    }

    return '''
🏢 Empresa seleccionada:
  - ID: ${_currentCompany!.id}
  - Nombre: ${_currentCompany!.empresa}
  - Sucursal: ${_currentCompany!.sucursal}
  - Tipo gasto: ${_currentCompany!.tipogasto}
  - Consumidor: ${_currentCompany!.consumidor}
  - Régimen: ${_currentCompany!.regimen}
  - RUC: ${_currentCompany!.ruc}
  - Es válida: ${_currentCompany!.isValid}
''';
  }
}
