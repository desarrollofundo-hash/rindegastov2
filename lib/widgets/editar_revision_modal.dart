import 'package:flu2/models/reporte_auditioria_model.dart';
import 'package:flu2/models/reporte_revision_detalle.dart';
import 'package:flu2/models/reporte_revision_model.dart';
import 'package:flu2/services/api_service.dart';
import 'package:flu2/services/company_service.dart';
import 'package:flu2/services/user_service.dart';
import 'package:flu2/utils/navigation_utils.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/reporte_auditoria_detalle.dart';

class EditarRevisionModal extends StatefulWidget {
  final ReporteRevision revision;
  final List<ReporteRevisionDetalle> detalles;

  const EditarRevisionModal({
    super.key,
    required this.revision,
    required this.detalles,
  });

  @override
  State<EditarRevisionModal> createState() => _EditarRevisionModalState();
}

class _EditarRevisionModalState extends State<EditarRevisionModal> {
  String filtroSeleccionado = 'Todos';
  List<ReporteRevisionDetalle> detallesFiltrados = [];
  Map<int, bool> detallesSeleccionados = {};
  bool todosMarcados = true;

  final ApiService _apiService = ApiService();

  @override
  void initState() {
    super.initState();
    detallesFiltrados = widget.detalles;
    // Inicializar todos como seleccionados por defecto
    for (var det in widget.detalles) {
      detallesSeleccionados[det.idAdDet] = true;
    }
  }

  void _toggleTodos() {
    setState(() {
      todosMarcados = !todosMarcados;
      for (var det in detallesFiltrados) {
        detallesSeleccionados[det.idAdDet] = todosMarcados;
      }
    });
  }

  void _toggleSeleccion(int idDetalle) {
    setState(() {
      detallesSeleccionados[idDetalle] =
          !(detallesSeleccionados[idDetalle] ?? false);
      todosMarcados = detallesFiltrados.every(
        (d) => detallesSeleccionados[d.idAdDet] == true,
      );
    });
  }

  int _getSeleccionadosCount() {
    return detallesSeleccionados.values
        .where((seleccionado) => seleccionado == true)
        .length;
  }

  double _getTotalSeleccionado() {
    double total = 0.0;
    for (var gasto in detallesFiltrados) {
      if (detallesSeleccionados[gasto.idAdDet] == true) {
        total += gasto.total;
      }
    }
    return total;
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
          'Editar revision',
          style: TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.close, color: Colors.black),
            onPressed: () {
              Navigator.of(context).pop();
            },
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
                  widget.revision.politica ?? 'General',
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
            padding: const EdgeInsets.symmetric(horizontal: 10),
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
                // 🔹 Botón RECHAZAR (condicional)
                Expanded(
                  child: ElevatedButton(
                    onPressed: _getSeleccionadosCount() > 0
                        ? () {
                            // Acción solo si hay seleccionados
                            _eliminarRevision();
                          }
                        : null, // 🔸 Desactiva el botón si no hay seleccionados
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _getSeleccionadosCount() > 0
                          ? Colors.red
                          : Colors.grey.shade300, // Color según estado
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(5),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 1),
                    ),
                    child: Text(
                      'RECHAZAR',
                      style: TextStyle(
                        color: _getSeleccionadosCount() > 0
                            ? Colors.white
                            : Colors.grey.shade600,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
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
                final isSelected = detallesSeleccionados[det.idAdDet] ?? false;
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: InkWell(
                    onTap: () => _toggleSeleccion(det.idAdDet),
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
                                  det.categoria ?? 'Sin estado',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  formatDate(det.fecha),
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
                              Text(
                                '${det.total} PEN',
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
                                  color: getStatusColor(det.estadoActual),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  det.estadoActual ?? 'En revisión',
                                  style: const TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
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
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _eliminarRevision() async {
    // Filtrar gastos seleccionados y no seleccionados
    debugPrint("SECCION ELIMINAR:");

    final gastosSeleccionadosList = detallesFiltrados
        .where((g) => detallesSeleccionados[g.idAdDet] == true)
        .toList();
    final gastosNoSeleccionadosList = detallesFiltrados
        .where((g) => detallesSeleccionados[g.idAdDet] != true)
        .toList();

    if (detallesFiltrados.isEmpty) return;

    try {
      // Mostrar loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );
      // 3️⃣ Guardar DETALLES seleccionados (estadoACTUAL = RECHAZADO)
      debugPrint("INICIO GUARDAR ELIMINAR:");
      for (final gasto in gastosSeleccionadosList) {
        final detalleData = {
          "idRev": gasto.idRev, // Relación con la cabecera
          "idAd": gasto.idAd,
          "idAdDet": gasto.idAdDet, // usar idrend como id de factura
          "idRend": gasto.idRend,
          // Preferir el idUser del detalle; si no está, usar el del informe
          "idUser": gasto.idUser,
          // El modelo de detalle no tiene 'dni', por eso mantenemos el dni del informe
          "dni": ('').toString(),
          // Usar ruc del detalle si existe, si no, el ruc del informe
          "ruc": (gasto.ruc ?? '').toString(),
          "obs": gasto.obs ?? '',
          "estadoActual": 'RECHAZADO',
          "estado": gasto.estado ?? 'S',
          "fecCre": gasto.fecCre,
          "useReg": gasto.idUser,
          "hostname": 'FLUTTER',
          "fecEdit": DateTime.now().toIso8601String(),
          "useEdit": gasto.idUser,
          "useElim": 0,
        };

        debugPrint("Guardar detalle rechazado:");

        final ok = await _apiService.saveRendicionAuditoriaDetalle(detalleData);
        if (!ok) {
          throw Exception(
            'Error al guardar detalle del gasto ${gasto.idAdDet}',
          );
        }
      }

      // 5️⃣ Cerrar loading
      if (mounted) Navigator.of(context).pop();

      // 6️⃣ Mostrar mensaje de éxito
      if (mounted) {
        final total = gastosSeleccionadosList.length;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white, size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'GASTOS RECHAZADOS (${_getSeleccionadosCount()})',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );

        // Volver después de 1 seg
        Future.delayed(const Duration(seconds: 1), () {
          if (mounted) Navigator.of(context).pop(true);
        });
      }
    } catch (e) {
      if (mounted) Navigator.of(context).pop();

      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Error'),
            content: Text(
              'Error al crear/actualizar el informe: ${e.toString()}',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    }
  }
}
