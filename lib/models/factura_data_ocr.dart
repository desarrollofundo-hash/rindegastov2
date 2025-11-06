class FacturaOcrData {
  String? rucEmisor;
  String? razonSocialEmisor;
  String? tipoComprobante;
  String? serie;
  String? numero;
  String? fecha;
  String? subtotal;
  String? igv;
  String? total;
  String? moneda;
  String? rucCliente;
  String? razonSocialCliente;

  // HELPER: Determinar tipo de comprobante según código SUNAT
  static String? getTipoComprobante(String codigo) {
    final tipos = {
      '01': 'FACTURA ELECTRONICA',
      '03': 'BOLETA DE VENTA',
      '07': 'NOTA DE CREDITO',
      '08': 'NOTA DE DEBITO',
      '09': 'GUÍA DE REMISION',
    };
    return tipos[codigo] ?? '($codigo)';
  }

  // HELPER: Determinar tipo de comprobante según código SUNAT
  static String? getTipoMoneda(String moneda) {
    final tipos = {
      'PEN': 'PEN',
      'USD': 'USD',
      'S': 'PEN',
      'D': 'USD',
    };
    return tipos[moneda] ?? '($moneda)';
  }

  @override
  String toString() =>
      '''
RUC emisor: $rucEmisor
Razón social emisor: $razonSocialEmisor
Tipo comprobante: $tipoComprobante
Serie: $serie
Número: $numero
Fecha: $fecha
Subtotal: $subtotal
IGV: $igv
Total: $total
Moneda: $moneda
RUC cliente: $rucCliente
Razón social cliente: $razonSocialCliente
''';
}
