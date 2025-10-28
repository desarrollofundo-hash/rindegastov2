class Gasto {
  final String titulo;
  final String categoria;
  final String fecha;
  final String monto;
  final String estado;
  final String? descripcion;
  final String? factura;

  Gasto({
    required this.titulo,
    required this.categoria,
    required this.fecha,
    required this.monto,
    required this.estado,
    this.descripcion,
    this.factura,
  });

  Map<String, dynamic> toMap() {
    return {
      'titulo': titulo,
      'categoria': categoria,
      'fecha': fecha,
      'monto': monto,
      'estado': estado,
      'descripcion': descripcion,
      'factura': factura,
    };
  }

  factory Gasto.fromMap(Map<String, dynamic> map) {
    return Gasto(
      titulo: map['titulo'] ?? '',
      categoria: map['categoria'] ?? '',
      fecha: map['fecha'] ?? '',
      monto: map['monto'] ?? '',
      estado: map['estado'] ?? '',
      descripcion: map['descripcion'],
      factura: map['factura'],
    );
  }

  Gasto copyWith({
    String? titulo,
    String? categoria,
    String? fecha,
    String? monto,
    String? estado,
    String? descripcion,
    String? factura,
  }) {
    return Gasto(
      titulo: titulo ?? this.titulo,
      categoria: categoria ?? this.categoria,
      fecha: fecha ?? this.fecha,
      monto: monto ?? this.monto,
      estado: estado ?? this.estado,
      descripcion: descripcion ?? this.descripcion,
      factura: factura ?? this.factura,
    );
  }
}
