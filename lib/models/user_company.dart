/// Modelo para representar las empresas asociadas a un usuario
///
/// Este modelo se utiliza para mapear la respuesta de la API
/// /reporte/usuarioconsumidor que devuelve las empresas donde
/// un usuario puede trabajar según sus permisos y asignaciones.
class UserCompany {
  /// ID único de la relación usuario-empresa
  final int id;

  /// ID del usuario
  final int iduser;

  /// DNI del usuario
  final String dni;

  /// Apellidos y nombres del usuario
  final String apeNom;

  /// Nombre de la empresa
  final String empresa;

  /// Sucursal de la empresa
  final String sucursal;

  /// Tipo de gasto permitido
  final String tipogasto;

  /// Código de consumidor
  final String consumidor;

  /// Régimen fiscal
  final String regimen;

  /// Destino de la configuración
  final String destino;
  final String placa;
  final String ruc;

  const UserCompany({
    required this.id,
    required this.iduser,
    required this.dni,
    required this.apeNom,
    required this.empresa,
    required this.sucursal,
    required this.tipogasto,
    required this.consumidor,
    required this.regimen,
    required this.destino,
    required this.placa,
    required this.ruc,
  });

  /// Crear instancia desde JSON de la API
  factory UserCompany.fromJson(Map<String, dynamic> json) {
    return UserCompany(
      id: json['id'] ?? 0,
      iduser: json['iduser'] ?? 0,
      dni: json['dni'] ?? '',
      apeNom: json['apeNom'] ?? '',
      empresa: json['empresa'] ?? '',
      sucursal: json['sucursal'] ?? '',
      tipogasto: json['tipogasto'] ?? '',
      consumidor: json['consumidor'] ?? '',
      regimen: json['regimen'] ?? '',
      destino: json['destino'] ?? '',
      placa: json['placa'] ?? '',
      ruc: json['ruc'] ?? '',
    );
  }

  /// Convertir a JSON para envío a API
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'iduser': iduser,
      'dni': dni,
      'apeNom': apeNom,
      'empresa': empresa,
      'sucursal': sucursal,
      'tipogasto': tipogasto,
      'consumidor': consumidor,
      'regimen': regimen,
      'destino': destino,
      'placa': placa,
      'ruc': ruc,
    };
  }

  /// Convertir a Map simplificado para uso en DropdownButton
  Map<String, String> toCompanyMap() {
    return {
      'id': id.toString(),
      'name': empresa,
      'sucursal': sucursal,
      'tipogasto': tipogasto,
      'consumidor': consumidor,
      'placa': placa,
      'ruc': ruc,
    };
  }

  /// Obtener nombre completo para mostrar en UI
  String get displayName => empresa.isNotEmpty ? empresa : 'Sin nombre';

  /// Obtener información completa de la empresa
  String get fullCompanyInfo {
    final parts = <String>[];
    if (empresa.isNotEmpty) parts.add(empresa);
    if (sucursal.isNotEmpty) parts.add(sucursal);
    return parts.join(' - ');
  }

  /// Verificar si la empresa está completa (tiene datos mínimos)
  bool get isValid => id > 0 && empresa.isNotEmpty;

  @override
  String toString() {
    return 'UserCompany(id: $id, empresa: $empresa, sucursal: $sucursal)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is UserCompany &&
        other.id == id &&
        other.iduser == iduser &&
        other.empresa == empresa &&
        other.placa == placa &&
        other.ruc == ruc;
  }

  @override
  int get hashCode =>
      id.hashCode ^ iduser.hashCode ^ empresa.hashCode ^ ruc.hashCode;

  /// Crear copia con campos modificados
  UserCompany copyWith({
    int? id,
    int? iduser,
    String? dni,
    String? apeNom,
    String? empresa,
    String? sucursal,
    String? tipogasto,
    String? consumidor,
    String? regimen,
    String? destino,
    String? placa,
    String? ruc,
  }) {
    return UserCompany(
      id: id ?? this.id,
      iduser: iduser ?? this.iduser,
      dni: dni ?? this.dni,
      apeNom: apeNom ?? this.apeNom,
      empresa: empresa ?? this.empresa,
      sucursal: sucursal ?? this.sucursal,
      tipogasto: tipogasto ?? this.tipogasto,
      consumidor: consumidor ?? this.consumidor,
      regimen: regimen ?? this.regimen,
      destino: destino ?? this.destino,
      placa: placa ?? this.placa,
      ruc: ruc ?? this.ruc,
    );
  }
}
