import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/reporte_informe_model.dart';
import '../models/reporte_informe_detalle.dart';

class EditarInformeModal extends StatefulWidget {
  final ReporteInforme informe;
  final List<ReporteInformeDetalle> gastos;

  const EditarInformeModal({
    super.key,
    required this.informe,
    required this.gastos,
  });

  @override
  State<EditarInformeModal> createState() => _EditarInformeModalState();
}

class _EditarInformeModalState extends State<EditarInformeModal> {
  String filtroSeleccionado = 'Todos';
  List<ReporteInformeDetalle> gastosFiltrados = [];
  Map<int, bool> gastosSeleccionados = {};
  bool todosMarcados = true;

  @override
  void initState() {
    super.initState();
    gastosFiltrados = widget.gastos;
    // Inicializar todos los gastos como seleccionados usando sus IDs
    for (var gasto in widget.gastos) {
      gastosSeleccionados[gasto.id] = true;
    }
  }

  void _toggleTodosLosGastos() {
    setState(() {
      todosMarcados = !todosMarcados;
      for (var gasto in gastosFiltrados) {
        gastosSeleccionados[gasto.id] = todosMarcados;
      }
    });
  }

  void _toggleGastoSelection(int gastoId) {
    setState(() {
      gastosSeleccionados[gastoId] = !(gastosSeleccionados[gastoId] ?? false);
      // Verificar si todos están marcados para actualizar el estado del filtro "Todos"
      todosMarcados = gastosFiltrados.every(
        (gasto) => gastosSeleccionados[gasto.id] == true,
      );
    });
  }

  int _getGastosSeleccionadosCount() {
    return gastosSeleccionados.values
        .where((seleccionado) => seleccionado == true)
        .length;
  }

  double _getTotalSeleccionado() {
    double total = 0.0;
    for (var gasto in gastosFiltrados) {
      if (gastosSeleccionados[gasto.id] == true) {
        total += gasto.total;
      }
    }
    return total;
  }

  String _formatearFechaCorta(String? fecha) {
    if (fecha == null || fecha.isEmpty) {
      return DateFormat('yyyy-MM-dd').format(DateTime.now());
    }

    try {
      // Intentar parsear diferentes formatos de fecha
      DateTime fechaDateTime;
      if (fecha.contains('/')) {
        // Formato dd/MM/yyyy o dd/MM/yy
        List<String> partes = fecha.split('/');
        if (partes.length == 3) {
          int dia = int.parse(partes[0]);
          int mes = int.parse(partes[1]);
          int anio = int.parse(partes[2]);
          // Si el año es de 2 dígitos, convertir a 4 dígitos
          if (anio < 100) {
            anio += 2000;
          }
          fechaDateTime = DateTime(anio, mes, dia);
        } else {
          fechaDateTime = DateTime.now();
        }
      } else if (fecha.contains('-')) {
        // Formato yyyy-MM-dd
        fechaDateTime = DateTime.parse(fecha);
      } else {
        // Si no se puede parsear, usar fecha actual
        fechaDateTime = DateTime.now();
      }

      // Formatear a yyyy-MM-dd (formato ISO)
      return DateFormat('yyyy-MM-dd').format(fechaDateTime);
    } catch (e) {
      // Si hay error al parsear, usar fecha actual
      return DateFormat('yyyy-MM-dd').format(DateTime.now());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Editar informe',
          style: TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              // Lógica para guardar
              Navigator.of(context).pop();
            },
            child: const Text(
              'Guardar',
              style: TextStyle(
                color: Colors.blue,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Header con política
          Container(
            width: double.infinity,
            color: Colors.blue.shade50,
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
            child: Row(
              children: [
                const Text(
                  'Política',
                  style: TextStyle(
                    color: Colors.blue,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  widget.informe.politica ?? 'General',
                  style: const TextStyle(
                    color: Colors.black,
                    fontSize: 14,
                    fontWeight: FontWeight.normal,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          // Paso único
          // Título Gastos
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                const Text(
                  'Gastos',
                  style: TextStyle(
                    color: Colors.blue,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Filtro Todos con icono de filtro
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                GestureDetector(
                  onTap: _toggleTodosLosGastos,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: todosMarcados ? Colors.blue : Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          todosMarcados ? Icons.check : Icons.remove,
                          color: todosMarcados
                              ? Colors.white
                              : Colors.grey.shade600,
                          size: 16,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Todos',
                          style: TextStyle(
                            color: todosMarcados
                                ? Colors.white
                                : Colors.grey.shade600,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.tune, color: Colors.grey),
                  onPressed: () {
                    // Lógica para abrir filtros
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Lista de gastos
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: gastosFiltrados.length,
              itemBuilder: (context, index) {
                final gasto = gastosFiltrados[index];
                final isSelected = gastosSeleccionados[gasto.id] ?? false;
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: InkWell(
                    onTap: () => _toggleGastoSelection(gasto.id),
                    borderRadius: BorderRadius.circular(8),
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Row(
                        children: [
                          // Checkbox
                          Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? Colors.blue
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(
                                color: isSelected
                                    ? Colors.blue
                                    : Colors.grey.shade400,
                                width: 2,
                              ),
                            ),
                            child: isSelected
                                ? const Icon(
                                    Icons.check,
                                    color: Colors.white,
                                    size: 16,
                                  )
                                : null,
                          ),
                          const SizedBox(width: 12),

                          // Icono de documento
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: Colors.grey.shade200,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              Icons.description,
                              color: Colors.grey.shade600,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 12),

                          // Información del gasto
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  gasto.ruc ?? 'CORPORACION D...',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.black,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  gasto.categoria ?? 'Sin categoría...',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  _formatearFechaCorta(gasto.fecha),
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Monto y estado
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                '${gasto.total.toStringAsFixed(2)} PEN',
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.amber.shade100,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Text(
                                  'En informe',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.amber,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // Footer con total y botones
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.2),
                  spreadRadius: 1,
                  blurRadius: 4,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
              top: false,
              child: Column(
                children: [
                  // Total
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Total (${_getGastosSeleccionadosCount()})',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.black,
                        ),
                      ),
                      Text(
                        '${_getTotalSeleccionado().toStringAsFixed(2)} PEN',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Botones
                  Row(
                    children: [
                      // Botón Cancelar
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(
                              color: Colors.orange,
                              width: 2,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          child: const Text(
                            'Cancelar',
                            style: TextStyle(
                              color: Colors.orange,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),

                      // Botón Guardar
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            // Lógica para guardar
                            Navigator.of(context).pop();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          child: const Text(
                            'Guardar',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
