import 'package:flutter/material.dart';
import '../widgets/politica_test_modal.dart';

/// Ejemplo completo del flujo integrado de selección de política
/// que detecta automáticamente si debe abrir modal general o de movilidad
class FlujoPoliticaIntegradoExample extends StatelessWidget {
  const FlujoPoliticaIntegradoExample({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Flujo Política Integrado'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Título principal
            const Icon(Icons.receipt_long, size: 80, color: Colors.green),
            const SizedBox(height: 24),
            const Text(
              'Sistema de Gastos Integrado',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            const Text(
              'Selecciona una política para crear un nuevo gasto.\nEl sistema detectará automáticamente si es gasto general o de movilidad.',
              style: TextStyle(fontSize: 16, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 40),

            // Botón principal para crear gasto
            ElevatedButton.icon(
              onPressed: () => _showPoliticaModal(context),
              icon: const Icon(Icons.add_circle, size: 28),
              label: const Text(
                'CREAR NUEVO GASTO',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 20),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Información sobre las políticas
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info, color: Colors.blue.shade600),
                        const SizedBox(width: 8),
                        const Text(
                          'Tipos de Gastos Disponibles',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _buildPolicyInfo(
                      Icons.business_center,
                      'Gastos Generales',
                      'Alimentación, suministros, servicios, etc.',
                      Colors.green,
                    ),
                    const SizedBox(height: 8),
                    _buildPolicyInfo(
                      Icons.directions_car,
                      'Gastos de Movilidad',
                      'Viajes, transporte, combustible, etc.',
                      Colors.blue,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPolicyInfo(
    IconData icon,
    String title,
    String description,
    Color color,
  ) {
    return Row(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(fontWeight: FontWeight.w600, color: color),
              ),
              Text(
                description,
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _showPoliticaModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => PoliticaTestModal(
        onPoliticaSelected: (politica) {
          print('🎯 Política seleccionada: ${politica.value}');

          // Mostrar confirmación personalizada según el tipo
          final isMovilidad = politica.value.toUpperCase().contains(
            'MOVILIDAD',
          );
          final mensaje = isMovilidad
              ? 'Gasto de movilidad procesado correctamente'
              : 'Gasto general procesado correctamente';
          final icono = isMovilidad
              ? Icons.directions_car
              : Icons.business_center;
          final color = isMovilidad ? Colors.blue : Colors.green;

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  Icon(icono, color: Colors.white),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      mensaje,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
              backgroundColor: color,
              duration: const Duration(seconds: 4),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
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

/// Notas sobre el flujo integrado:
/// 
/// 1. **Detección automática de tipo de gasto:**
///    - Gastos generales: Para políticas que NO contienen "MOVILIDAD"
///    - Gastos de movilidad: Para políticas que contienen "MOVILIDAD"
/// 
/// 2. **Flujo completo:**
///    - Usuario hace clic en "CREAR NUEVO GASTO"
///    - Se abre PoliticaTestModal con políticas desde API
///    - Usuario selecciona política
///    - Sistema detecta tipo automáticamente:
///      * Si contiene "MOVILIDAD" → Abre NuevoGastoMovilidad
///      * Si no contiene "MOVILIDAD" → Abre NuevoGastoModal
/// 
/// 3. **Campos específicos por tipo:**
///    - General: Proveedor, fecha, total, moneda, categoría, tipo gasto, RUC, tipo doc, número doc, nota
///    - Movilidad: Todos los anteriores + origen, destino, motivo viaje, tipo transporte
/// 
/// 4. **APIs utilizadas:**
///    - Políticas: getRendicionCategorias() → extrae políticas únicas
///    - Categorías: getRendicionCategorias(politica: selected) → filtra por política
///    - Tipos de gasto: getTiposGasto() → mismo para ambos tipos
/// 
/// 5. **Validaciones:**
///    - Campos obligatorios según el tipo de gasto
///    - Archivo de evidencia requerido
///    - Validación de formulario en tiempo real
/// 
/// 6. **Beneficios del sistema integrado:**
///    - Un solo punto de entrada para crear gastos
///    - Detección automática de tipo evita confusión al usuario
///    - Formularios específicos optimizados para cada tipo de gasto
///    - Experiencia de usuario consistente y fluida