/// Ejemplo de uso del FacturaModalMovilidad con API integrada
/// 
/// Este ejemplo muestra cómo el widget modificado ahora:
/// 1. Consume la API de categorías automáticamente para "GASTOS DE MOVILIDAD"
/// 2. Muestra las categorías específicas: VIAJES, MOVILIZACION
/// 3. Maneja estados de carga, errores y casos sin datos

/*
// Ejemplo de implementación en tu screen:

import 'package:flutter/material.dart';
import '../widgets/factura_modal_movilidad.dart';
import '../models/factura_data.dart';

class ExampleMovilidadScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Ejemplo Factura Movilidad')),
      body: Center(
        child: ElevatedButton(
          onPressed: () => _showFacturaModalMovilidad(context),
          child: Text('Mostrar Modal de Movilidad'),
        ),
      ),
    );
  }

  void _showFacturaModalMovilidad(BuildContext context) {
    // Datos de ejemplo de una factura de movilidad
    final facturaData = FacturaData(
      ruc: '12345678901',
      tipoComprobante: 'Boleta',
      serie: 'B001',
      numero: '00000456',
      codigo: 'MOV123',
      fechaEmision: '2024-01-15',
      total: 25.50,
      moneda: 'PEN',
      rucCliente: '98765432109',
      rawData: 'datos-qr-taxi',
      format: 'QR',
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => FacturaModalMovilidad(
        facturaData: facturaData,
        politicaSeleccionada: 'GASTOS DE MOVILIDAD', // <- La API se activará automáticamente
        onSave: (factura, imagePath) {
          // Manejar guardado
          print('Factura de movilidad guardada: ${factura.toJson()}');
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

/// Notas importantes sobre la integración:
/// 
/// 1. **Carga automática de categorías:**
///    - Al inicializar el widget, automáticamente carga categorías desde la API
///    - Filtra específicamente por "GASTOS DE MOVILIDAD"
/// 
/// 2. **Categorías esperadas de la API:**
///    - VIAJES (de la respuesta del servidor)
///    - MOVILIZACION (de la respuesta del servidor)
/// 
/// 3. **Estados manejados:**
///    - 🔄 **Cargando:** Muestra indicador circular con texto "Cargando categorías..."
///    - ❌ **Error:** Muestra mensaje de error con botón "Reintentar"
///    - ⚠️ **Sin datos:** Muestra advertencia si no hay categorías disponibles
///    - ✅ **Éxito:** Dropdown funcional con las categorías obtenidas
/// 
/// 4. **Formateo de nombres:**
///    - "VIAJES" se muestra como "Viajes"
///    - "MOVILIZACION" se muestra como "Movilizacion"
/// 
/// 5. **Campos específicos de movilidad:**
///    - Origen del viaje
///    - Destino del viaje
///    - Motivo del viaje
///    - Tipo de transporte (Taxi, Uber, Bus, Metro, Avión, Otro)
///    - Categoría (cargada desde API)
/// 
/// 6. **API consumida:**
///    - URL: http://190.119.200.124:45490/maestros/rendicion_categoria?politica=todos
///    - Filtro: Solo registros con politica="GASTOS DE MOVILIDAD" y estado="S"
/// 
/// 7. **Interfaz de usuario:**
///    - Diseño en cards con iconos azules (tema de movilidad)
///    - Header con icono de auto y título "Gasto de Movilidad - Perú"
///    - Sección de categorías insertada entre política y datos de factura
///    - Manejo de errores user-friendly con opciones de reintento
/// 
/// Este modal está optimizado para gastos de transporte y movilidad,
/// con campos específicos que facilitan el registro de viajes de trabajo.
*/