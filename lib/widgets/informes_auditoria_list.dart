import 'dart:convert';

import 'package:flu2/models/reporte_auditioria_model.dart';
import 'package:flu2/widgets/auditoria_detalle_modal.dart';
import 'package:flutter/material.dart';
import 'package:flu2/widgets/empty_state.dart';
import 'package:flu2/widgets/informe_detalle_modal.dart'; // Cambié el nombre aquí

class InformesAuditoriaList extends StatelessWidget {
  final List<ReporteAuditoria> auditorias; // Cambié el tipo de la lista aquí
  final Function(ReporteAuditoria)
  onAuditoriaUpdated; // Cambié el tipo de la función aquí
  final Function(ReporteAuditoria)
  onAuditoriaDeleted; // Cambié el tipo de la función aquí
  final bool showEmptyStateButton;
  final VoidCallback? onEmptyStateButtonPressed;
  final Future<void> Function()? onRefresh;

  const InformesAuditoriaList({
    super.key,
    required this.auditorias,
    required this.onAuditoriaUpdated,
    required this.onAuditoriaDeleted,
    this.showEmptyStateButton = true,
    this.onEmptyStateButtonPressed,
    this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    if (auditorias.isEmpty) {
      return RefreshIndicator(
        onRefresh: onRefresh ?? () async {},
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Container(
            height: MediaQuery.of(context).size.height * 0.7,
            child: EmptyState(
              message: "No hay auditorías disponibles",
              buttonText: showEmptyStateButton ? "Agregar Auditoría" : null,
              onButtonPressed: showEmptyStateButton
                  ? onEmptyStateButtonPressed
                  : null,
              icon: Icons.description,
            ),
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: onRefresh ?? () async {},
      child: ListView.builder(
        padding: const EdgeInsets.all(8),
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: auditorias.length,
        itemBuilder: (context, index) {
          final auditoria = auditorias[index];
          return AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            child: Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              margin: const EdgeInsets.symmetric(vertical: 4),
              child: InkWell(
                onTap: () => _handleMenuAction(context, 'ver', auditoria),
                borderRadius: BorderRadius.circular(16),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      // Icono de la izquierda
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.description,
                          color: Colors.grey[600],
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 16),
                      // Contenido principal
                      Expanded(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Columna izquierda: Título, Creación, Auditoría
                            Expanded(
                              flex: 2,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Título de la auditoría
                                  Text(
                                    auditoria.titulo ?? 'Sin título',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black87,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 2),
                                  // Fecha de creación
                                  Text(
                                    'Creación: ${_formatDate(auditoria.fecCre?.toIso8601String())}',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  // Cantidad de detalles
                                  Text(
                                    '${auditoria.cantidad} detalles',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            // Columna derecha: Total, Estado
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                // Total en PEN
                                Text(
                                  '${_getTotal(auditoria)} PEN',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blue,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                // Estado
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: _getStatusColor(
                                      auditoria.estadoActual,
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    auditoria.estadoActual ?? 'Sin estado',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  String _formatDate(String? fecha) {
    if (fecha == null || fecha.isEmpty) {
      return 'Sin fecha';
    }

    try {
      // Intentar parsear diferentes formatos de fecha
      DateTime? dateTime;

      // Formato ISO: 2025-10-04T00:00:00
      if (fecha.contains('T')) {
        dateTime = DateTime.tryParse(fecha);
      }
      // Formato dd/MM/yyyy
      else if (fecha.contains('/')) {
        final parts = fecha.split('/');
        if (parts.length == 3) {
          dateTime = DateTime.tryParse(
            '${parts[2]}-${parts[1].padLeft(2, '0')}-${parts[0].padLeft(2, '0')}',
          );
        }
      }
      // Formato yyyy-MM-dd
      else if (fecha.contains('-')) {
        dateTime = DateTime.tryParse(fecha);
      }

      if (dateTime != null) {
        return '${dateTime.day.toString().padLeft(2, '0')}/${dateTime.month.toString().padLeft(2, '0')}/${dateTime.year}';
      }
    } catch (e) {
      // Si hay error en el parseo, devolver la fecha original
    }

    return fecha ?? 'Sin fecha';
  }

  Color _getStatusColor(String? estado) {
    switch (estado) {
      case 'Borrador':
        return Colors.orange;
      case 'Enviado':
        return Colors.blue;
      case 'Aprobado':
        return Colors.green;
      case 'Rechazado':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  double _getTotal(ReporteAuditoria auditoria) {
    return auditoria.total;
  }

  void _handleMenuAction(
    BuildContext context,
    String action,
    ReporteAuditoria auditoria, // Cambié el tipo aquí
  ) {
    switch (action) {
      case 'ver':
        showDialog(
          context: context,
          builder: (BuildContext context) => AuditoriaDetalleModal(
            informe: auditoria,
          ), // Usar el modal adecuado
        );
        break;
      case 'editar':
        onAuditoriaUpdated(auditoria);
        break;
      case 'eliminar':
        _showDeleteConfirmation(context, auditoria);
        break;
    }
  }

  void _showDeleteConfirmation(
    BuildContext context,
    ReporteAuditoria auditoria,
  ) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirmar eliminación'),
          content: Text(
            '¿Estás seguro de que quieres eliminar la auditoría "${auditoria.titulo}"?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                onAuditoriaDeleted(auditoria);
              },
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Eliminar'),
            ),
          ],
        );
      },
    );
  }
}
