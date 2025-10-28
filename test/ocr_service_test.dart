import 'package:flutter_test/flutter_test.dart';
import 'package:flu2/services/ocr_service.dart';

void main() {
  test('extraerDatosFactura extrae campos básicos de un sample OCR', () {
    final sample = '''
GUES HOUSE
CABALLERO SORIA ESMERALDA JUANA
AV BRASIL N° 3333
MAGDALENA DEL MAR - LIMA - LIMA
RUC 10077149231
FACTURA ELECTRONICA
FPP1-002358
CLIENTE
RUC: 20555837659
AGRICOLA SANTA AZUL S.R.L.
FECHA EMISION: 27/05/2025
MONEDA: SOLES
GRAVADA S/ 7.73
IGV S/ 0.77
TOTAL S/ 8.50
''';

    final factura = extraerDatosFactura(sample);

    expect(factura.rucEmisor, '10077149231');
    expect(factura.rucCliente, '20555837659');
    expect(factura.tipoComprobante, contains('FACTURA'));
    expect(factura.serie?.toUpperCase(), 'FPP1');
    expect(factura.numero, '002358');
    expect(factura.fecha, '27/05/2025');
    expect(factura.subtotal, '7.73');
    expect(factura.igv, '0.77');
    expect(factura.total, '8.50');
    expect(factura.moneda, 'S');
    expect(factura.razonSocialCliente, isNotNull);
  });

  test('extraerDatosFactura con factura real (GYU) extrae totales y RUCs', () {
    final sample = '''
GYU SAC
RUC: 20605100008
GYU GRILL HOUSE
FACTURA ELECTRONICA
F002-0013014
FECHA DE EMISION: 28/05/2025
MESA M 33
RUC: 20555837659
NOMBRE : AGRICOLA SANTA AZUL S.R.L
OP.GRAVADAS S/ 30.00
IGV S/ 3.00
IMPORTE TOTAL S/ 36.90
''';

    final factura = extraerDatosFactura(sample);

    // Imprimir resultado para inspección durante el test
    print('--- Resultado extraerDatosFactura (GYU) ---');
    print(factura.toString());
    print(
      'subtotal="${factura.subtotal}", igv="${factura.igv}", total="${factura.total}"',
    );

    expect(factura.rucEmisor, '20605100008');
    expect(factura.rucCliente, '20555837659');
    expect(factura.serie?.toUpperCase(), 'F002');
    expect(factura.numero, '0013014');
    expect(factura.fecha, '28/05/2025');
    expect(factura.subtotal, isNotNull);
    expect(factura.igv, isNotNull);
    expect(factura.total, isNotNull);
    expect(factura.total, anyOf('36.90', contains('36.9')));
  });
}
