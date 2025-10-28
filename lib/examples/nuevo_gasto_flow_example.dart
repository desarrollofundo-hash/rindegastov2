import 'package:flutter/material.dart';
import '../widgets/politica_test_modal.dart';
import '../widgets/nuevo_gasto_modal.dart';
import '../models/dropdown_option.dart';

/// Ejemplo de cómo usar el flujo completo de selección de política + nuevo gasto
class NuevoGastoFlowExample extends StatelessWidget {
  const NuevoGastoFlowExample({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ejemplo Nuevo Gasto'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Flujo Completo: Seleccionar Política + Crear Gasto',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 30),

            // Botón para iniciar el flujo completo
            ElevatedButton.icon(
              onPressed: () => _mostrarFlujoPolitica(context),
              icon: const Icon(Icons.policy),
              label: const Text('Iniciar Flujo: Seleccionar Política'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.indigo,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 16,
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Botón para probar directamente el modal de gasto
            ElevatedButton.icon(
              onPressed: () => _mostrarModalGastoDirecto(context),
              icon: const Icon(Icons.add_business),
              label: const Text('Probar Modal Gasto Directo'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 16,
                ),
              ),
            ),

            const SizedBox(height: 40),

            const Padding(
              padding: EdgeInsets.all(20),
              child: Text(
                'Características del nuevo modal:\n\n'
                '✅ Adjuntar PDFs e imágenes\n'
                '✅ Campos: Proveedor, Fecha, Total, Moneda\n'
                '✅ Categorías cargadas por API\n'
                '✅ Tipos de Gasto con opciones predefinidas\n'
                '✅ Dropdown tipo documento (Factura, Boleta, Comprobante)\n'
                '✅ RUC Proveedor con validación\n'
                '✅ Número de documento\n'
                '✅ Campo de notas\n'
                '✅ Validaciones completas\n'
                '✅ Botones Cancelar y Guardar',
                style: TextStyle(fontSize: 14),
                textAlign: TextAlign.left,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Mostrar el flujo completo: primero política, luego gasto
  void _mostrarFlujoPolitica(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => PoliticaTestModal(
        onPoliticaSelected: (politica) {
          // Este callback se ejecutará después de guardar el gasto
          _mostrarMensajeExito(context, politica);
        },
        onCancel: () {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Selección de política cancelada'),
              backgroundColor: Colors.orange,
            ),
          );
        },
      ),
    );
  }

  /// Mostrar directamente el modal de gasto (para pruebas)
  void _mostrarModalGastoDirecto(BuildContext context) {
    // Crear una política de ejemplo
    final politicaEjemplo = DropdownOption(
      id: '1',
      value: 'GENERAL',
      metadata: {'estado': 'S'},
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => NuevoGastoModal(
        politicaSeleccionada: politicaEjemplo,
        onCancel: () {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Creación de gasto cancelada'),
              backgroundColor: Colors.orange,
            ),
          );
        },
        onSave: (gastoData) {
          Navigator.pop(context);
          _mostrarDetallesGasto(context, gastoData);
        },
      ),
    );
  }

  /// Mostrar mensaje de éxito después del flujo completo
  void _mostrarMensajeExito(BuildContext context, DropdownOption politica) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '🎉 Flujo completado exitosamente con política: ${politica.value}',
        ),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  /// Mostrar detalles del gasto guardado
  void _mostrarDetallesGasto(
    BuildContext context,
    Map<String, dynamic> gastoData,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green),
            SizedBox(width: 8),
            Text('Gasto Guardado'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow('Política', gastoData['politica']),
              _buildDetailRow('Proveedor', gastoData['proveedor']),
              _buildDetailRow('Fecha', gastoData['fecha']),
              _buildDetailRow(
                'Total',
                '${gastoData['moneda']} ${gastoData['total']}',
              ),
              _buildDetailRow('Categoría', gastoData['categoria']),
              _buildDetailRow('Tipo de Gasto', gastoData['tipoGasto']),
              _buildDetailRow('RUC Proveedor', gastoData['rucProveedor']),
              _buildDetailRow('Tipo Documento', gastoData['tipoDocumento']),
              _buildDetailRow('Número Documento', gastoData['numeroDocumento']),
              _buildDetailRow('Nota', gastoData['nota']),
              _buildDetailRow(
                'Evidencia',
                gastoData['evidenciaName'] ?? 'Sin evidencia',
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green.shade300),
                ),
                child: const Text(
                  'En una implementación real, aquí se enviarían los datos a la API para guardar el gasto.',
                  style: TextStyle(fontStyle: FontStyle.italic, fontSize: 12),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, dynamic value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(
            child: Text(
              value?.toString() ?? 'No especificado',
              style: TextStyle(
                color: value == null || value.toString().isEmpty
                    ? Colors.grey
                    : Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
