import 'package:flu2/models/reporte_auditioria_model.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/reporte_auditoria_detalle.dart';

class EditarAuditoriaModal extends StatefulWidget {
  final ReporteAuditoria auditoria;
  final List<ReporteAuditoriaDetalle> detalles;

  const EditarAuditoriaModal({
    super.key,
    required this.auditoria,
    required this.detalles,
  });

  @override
  State<EditarAuditoriaModal> createState() => _EditarAuditoriaModalState();
}

class _EditarAuditoriaModalState extends State<EditarAuditoriaModal> {
  String filtroSeleccionado = 'Todos';
  List<ReporteAuditoriaDetalle> detallesFiltrados = [];
  Map<int, bool> detallesSeleccionados = {};
  bool todosMarcados = true;

  @override
  void initState() {
    super.initState();
    detallesFiltrados = widget.detalles;
    // Inicializar todos como seleccionados por defecto
    for (var det in widget.detalles) {
      detallesSeleccionados[det.idInfDet] = true;
    }
  }

  void _toggleTodos() {
    setState(() {
      todosMarcados = !todosMarcados;
      for (var det in detallesFiltrados) {
        detallesSeleccionados[det.idInfDet] = todosMarcados;
      }
    });
  }

  void _toggleSeleccion(int idDetalle) {
    setState(() {
      detallesSeleccionados[idDetalle] =
          !(detallesSeleccionados[idDetalle] ?? false);
      todosMarcados = detallesFiltrados.every(
        (d) => detallesSeleccionados[d.idInfDet] == true,
      );
    });
  }

  int _getSeleccionadosCount() {
    return detallesSeleccionados.values
        .where((seleccionado) => seleccionado == true)
        .length;
  }

  double _getTotalSeleccionado() {
    // Si luego ReporteAuditoriaDetalle incluye totales, aquí podrías sumar.
    // Por ahora, solo devolvemos 0.0 (placeholder).
    return 0.0;
  }

  String _formatearFechaCorta(String? fecha) {
    if (fecha == null || fecha.isEmpty) {
      return DateFormat('yyyy-MM-dd').format(DateTime.now());
    }

    try {
      DateTime fechaDateTime;
      if (fecha.contains('/')) {
        List<String> partes = fecha.split('/');
        if (partes.length == 3) {
          int dia = int.parse(partes[0]);
          int mes = int.parse(partes[1]);
          int anio = int.parse(partes[2]);
          if (anio < 100) anio += 2000;
          fechaDateTime = DateTime(anio, mes, dia);
        } else {
          fechaDateTime = DateTime.now();
        }
      } else if (fecha.contains('-')) {
        fechaDateTime = DateTime.parse(fecha);
      } else {
        fechaDateTime = DateTime.now();
      }

      return DateFormat('yyyy-MM-dd').format(fechaDateTime);
    } catch (e) {
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
          'Editar auditoría',
          style: TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              // Lógica de guardado
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
          // Cabecera con política
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
                  widget.auditoria.politica ?? 'General',
                  style: const TextStyle(color: Colors.black, fontSize: 14),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),

          // Título sección
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: const [
                Text(
                  'Detalles',
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

          // Botón "Todos"
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                GestureDetector(
                  onTap: _toggleTodos,
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
                    // Abrir filtros
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Lista de detalles
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: detallesFiltrados.length,
              itemBuilder: (context, index) {
                final det = detallesFiltrados[index];
                final isSelected = detallesSeleccionados[det.idInfDet] ?? false;
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: InkWell(
                    onTap: () => _toggleSeleccion(det.idInfDet),
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

                          // Icono documento
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

                          // Información principal
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  det.ruc ?? 'Sin RUC',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.black,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  det.estadoActual ?? 'Sin estado',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  _formatearFechaCorta(det.fecCre),
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Estado visual
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.amber.shade100,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  det.estadoActual ?? 'En revisión',
                                  style: const TextStyle(
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

          // Footer
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
                  // Total (por ahora simbólico)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Seleccionados (${_getSeleccionadosCount()})',
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
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.of(context).pop(),
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
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            // Guardar lógica
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
