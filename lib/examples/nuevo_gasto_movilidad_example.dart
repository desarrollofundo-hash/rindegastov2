import 'package:flutter/material.dart';
import '../widgets/nuevo_gasto_movilidad.dart';
import '../models/dropdown_option.dart';

/// Ejemplo completo del flujo para gastos de movilidad
class NuevoGastoMovilidadExample extends StatelessWidget {
  const NuevoGastoMovilidadExample({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ejemplo - Gasto Movilidad'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: ElevatedButton.icon(
          onPressed: () => _showNuevoGastoMovilidad(context),
          icon: const Icon(Icons.directions_car),
          label: const Text('Nuevo Gasto de Movilidad'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          ),
        ),
      ),
    );
  }

  void _showNuevoGastoMovilidad(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => NuevoGastoMovilidad(
        politicaSeleccionada: DropdownOption(
          id: 'movilidad',
          value: 'GASTOS DE MOVILIDAD',
        ),
        onSave: (gastoData) {
          print('=== GASTO DE MOVILIDAD GUARDADO ===');
          print('Política: ${gastoData['politica']}');
          print('Categoría: ${gastoData['categoria']}');
          print('Tipo Gasto: ${gastoData['tipoGasto']}');
          print('Proveedor: ${gastoData['proveedor']}');
          print('Fecha: ${gastoData['fecha']}');
          print('Total: ${gastoData['total']} ${gastoData['moneda']}');
          print('RUC: ${gastoData['ruc']}');
          print('Tipo Doc: ${gastoData['tipoDocumento']}');
          print('Número Doc: ${gastoData['numeroDocumento']}');
          print('Origen: ${gastoData['origen']}');
          print('Destino: ${gastoData['destino']}');
          print('Motivo: ${gastoData['motivoViaje']}');
          print('Transporte: ${gastoData['tipoTransporte']}');
          print('Nota: ${gastoData['nota']}');
          print('Archivo: ${gastoData['archivo']}');
          print('=====================================');

          // Mostrar confirmación al usuario
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Gasto de movilidad guardado: ${gastoData['proveedor']} - ${gastoData['total']} ${gastoData['moneda']}',
              ),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 3),
            ),
          );
        },
        onCancel: () {
          Navigator.pop(context);
        },
      ),
    );
  }
}

/// Notas sobre el modal de movilidad:
/// 
/// 1. **Campos específicos de movilidad:**
///    - Origen del viaje (obligatorio)
///    - Destino del viaje (obligatorio)
///    - Motivo del viaje (obligatorio)
///    - Tipo de transporte (Taxi, Uber, Bus, Metro, Avión, Otro)
/// 
/// 2. **Categorías específicas:**
///    - Se cargan automáticamente desde la API filtradas por "GASTOS DE MOVILIDAD"
///    - Ejemplos esperados: VIAJES, MOVILIZACION, etc.
/// 
/// 3. **Validaciones obligatorias:**
///    - Todos los campos básicos (proveedor, fecha, total, etc.)
///    - Campos específicos de movilidad (origen, destino, motivo)
///    - Al menos un archivo de evidencia
/// 
/// 4. **Diferencias con el modal general:**
///    - Header específico con icono de auto y color azul
///    - Sección adicional "Detalles de Movilidad"
///    - Campos específicos para rutas y transporte
///    - Categorías filtradas por política de movilidad
/// 
/// 5. **API integration:**
///    - Categorías: getRendicionCategorias(politica: "GASTOS DE MOVILIDAD")
///    - Tipos de gasto: getTiposGasto() (mismos tipos que gastos generales)
/// 
/// 6. **Uso en el flujo:**
///    - Se abre desde politica_test_modal.dart cuando se selecciona política de movilidad
///    - Retorna datos completos para procesar y guardar en backend
///    - Incluye validaciones específicas para campos de movilidad