/// Modelo genérico para opciones de dropdown que se obtienen desde la API
class DropdownOption {
  /// ID único de la opción
  final String id;

  /// Valor que se mostrará al usuario
  final String value;

  /// Descripción opcional adicional
  final String? description;

  /// Indica si esta opción está activa/habilitada
  final bool isActive;

  /// Datos adicionales que pueden ser útiles (ej: metadata)
  final Map<String, dynamic>? metadata;

  const DropdownOption({
    required this.id,
    required this.value,
    this.description,
    this.isActive = true,
    this.metadata,
  });

  /// Constructor desde JSON de la API
  factory DropdownOption.fromJson(Map<String, dynamic> json) {
    return DropdownOption(
      id: json['id']?.toString() ?? '',
      value:
          json['categoria']?.toString() ??
          json['politica']?.toString() ??
          json['nombre']?.toString() ??
          json['value']?.toString() ??
          '',
      description: json['description']?.toString(),
      isActive:
          json['isActive'] ??
          json['is_active'] ??
          json['active'] ??
          (json['estado']?.toString() == 'S') ??
          true,
      metadata:
          json['metadata'] as Map<String, dynamic>? ??
          (json.containsKey('politica') || json.containsKey('categoria')
              ? Map<String, dynamic>.from(json)
              : null),
    );
  }

  /// Convertir a JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'value': value,
      'description': description,
      'isActive': isActive,
      'metadata': metadata,
    };
  }

  /// Método para crear una opción vacía/default
  static DropdownOption get empty =>
      const DropdownOption(id: '', value: 'Seleccionar...', isActive: false);

  @override
  String toString() => value;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DropdownOption &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}

/// Respuesta de la API que contiene las opciones del dropdown
class DropdownOptionsResponse {
  final List<DropdownOption> options;
  final String? message;
  final bool success;

  const DropdownOptionsResponse({
    required this.options,
    this.message,
    this.success = true,
  });

  factory DropdownOptionsResponse.fromJson(Map<String, dynamic> json) {
    // Si la respuesta es una lista directa
    if (json['data'] is List) {
      final List<dynamic> dataList = json['data'];
      return DropdownOptionsResponse(
        options: dataList
            .map((item) => DropdownOption.fromJson(item))
            .where((option) => option.isActive)
            .toList(),
        message: json['message']?.toString(),
        success: json['success'] ?? true,
      );
    }

    // Si la respuesta tiene estructura diferente
    final List<dynamic> optionsList = json['options'] ?? json['data'] ?? [];
    return DropdownOptionsResponse(
      options: optionsList
          .map((item) => DropdownOption.fromJson(item))
          .where((option) => option.isActive)
          .toList(),
      message: json['message']?.toString(),
      success: json['success'] ?? true,
    );
  }
}
