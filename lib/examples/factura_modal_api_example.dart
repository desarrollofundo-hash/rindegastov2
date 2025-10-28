/// Ejemplo de uso del FacturaModalPeru con API integrada
/// 
/// Este ejemplo muestra cómo usar el widget modificado que:
/// 1. Consume la API de categorías cuando la política es "GENERAL"
/// 2. Mantiene categorías hardcodeadas para "movilidad"
/// 3. Maneja estados de carga y errores

/*
// Ejemplo de implementación en tu screen:

import 'package:flutter/material.dart';
import '../widgets/factura_modal_peru.dart';
import '../models/factura_data.dart';

class ExampleScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Ejemplo Factura Modal')),
      body: Center(
        child: ElevatedButton(
          onPressed: () => _showFacturaModal(context),
          child: Text('Mostrar Factura Modal'),
        ),
      ),
    );
  }

  void _showFacturaModal(BuildContext context) {
    // Datos de ejemplo de una factura
    final facturaData = FacturaData(
      ruc: '12345678901',
      tipoComprobante: 'Factura',
      serie: 'F001',
      numero: '00000123',
      codigo: 'ABC123',
      fechaEmision: '2024-01-15',
      total: 150.50,
      moneda: 'PEN',
      rucCliente: '98765432109',
      rawData: 'datos-qr-originales',
      format: 'QR',
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => FacturaModalPeru(
        facturaData: facturaData,
        politicaSeleccionada: 'GENERAL', // <- Aquí la API se activará automáticamente
        onSave: (factura, imagePath) {
          // Manejar guardado
          print('Factura guardada: ${factura.toJson()}');
          if (imagePath != null) {
            print('Imagen guardada en: $imagePath');
          }
          Navigator.pop(context);
        },
        onCancel: () {
          Navigator.pop(context);
        },
      ),
    );
  }
}

/// Notas importantes:
/// 
/// 1. Cuando politicaSeleccionada contiene "GENERAL":
///    - Se carga automáticamente las categorías desde la API
///    - Se muestra un indicador de carga mientras se obtienen los datos
///    - Se maneja el estado de error con opción de reintentar
/// 
/// 2. Cuando politicaSeleccionada contiene "movilidad":
///    - Se muestran las categorías hardcodeadas: Transporte, Taxi, Combustible
/// 
/// 3. Para otras políticas:
///    - Se muestran categorías por defecto: Alimentación, Suministros, etc.
/// 
/// 4. La API se consume desde: http://190.119.200.124:45490/maestros/rendicion_categoria?politica=todos
/// 
/// 5. Estados manejados:
///    - Carga inicial
///    - Error de conexión
///    - Sin categorías disponibles
///    - Datos cargados correctamente
*/