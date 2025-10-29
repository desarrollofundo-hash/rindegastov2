import 'package:flu2/models/reporte_auditioria_model.dart';
import 'package:flu2/widgets/auditoria_detalle_modal.dart';
import 'package:flutter/material.dart';
import 'package:flu2/widgets/empty_state.dart';
// Nota: se eliminó import innecesario

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
    List<ReporteAuditoria>? auditoria,
  });

  @override
  Widget build(BuildContext context) {
    if (auditorias.isEmpty) {
      return RefreshIndicator(
        // Personalizar indicador para que coincida con la apariencia de Auditoría
        color: Colors.green,
        backgroundColor: Colors.white,
        strokeWidth: 2.5,
        displacement: 40,
        onRefresh: onRefresh ?? () async {},
        child: SingleChildScrollView(
          // AlwaysScrollable + Bouncing ayuda a detectar el gesto incluso
          // cuando hay pocos elementos o estamos dentro de un TabBarView.
          physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics(),
          ),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              // Garantiza suficiente área para que el gesto de pull se detecte
              minHeight: MediaQuery.of(context).size.height * 0.7,
            ),
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
      // Personalizar indicador para que coincida con la apariencia de Auditoría
      color: Colors.green,
      backgroundColor: Colors.white,
      strokeWidth: 2.5,
      displacement: 40,
      onRefresh: onRefresh ?? () async {},
      child: ListView.builder(
        key: const PageStorageKey('auditoria_list'),
        padding: const EdgeInsets.all(8),
        // Siempre scrollable y con rebote para mejorar la detección del pull
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        itemCount: auditorias.length,
        itemBuilder: (context, index) {
          try {
            final auditoria = auditorias[index];
            return AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              child: Card(
                color: Colors.white,
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                margin: const EdgeInsets.symmetric(vertical: 2),
                child: InkWell(
                  onTap: () => _handleMenuAction(context, 'ver', auditoria),
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: Row(
                      children: [
                        // Barra lateral de color que indica el estado
                        Container(
                          width: 4,
                          height: 48,
                          decoration: BoxDecoration(
                            color: _getStatusColor(auditoria.estadoActual),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Icono de la izquierda (más compacto)
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Icon(
                            Icons.description,
                            color: Colors.grey[600],
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
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
                                    // Título de la auditoría (más compacto)
                                    Text(
                                      auditoria.titulo ?? 'Sin título',
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
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
                                        fontSize: 12,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    // Cantidad de detalles
                                    Text(
                                      '${auditoria.cantidad} detalles',
                                      style: const TextStyle(
                                        fontSize: 14,
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
                                  // Total en PEN (más compacto)
                                  Text(
                                    '${_getTotal(auditoria)} PEN',
                                    style: const TextStyle(
                                      fontSize: 14,
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
          } catch (e, st) {
            debugPrint('Error building auditoria item: $e\n$st');
            return Card(
              color: Colors.red.shade50,
              child: ListTile(
                title: const Text('Error al mostrar auditoría'),
                subtitle: Text(e.toString()),
              ),
            );
          }
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

    return fecha;
  }

  Color _getStatusColor(String? estado) {
    switch (estado) {
      case 'EN AUDITORIA':
        return Colors.blue;
      case 'Enviado':
        return Colors.red;
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
        try {
          showDialog(
            context: context,
            builder: (BuildContext context) => AuditoriaDetalleModal(
              informe: auditoria,
            ), // Usar el modal adecuado
          );
        } catch (e, st) {
          debugPrint('Error opening AuditoriaDetalleModal: $e\n$st');
          showDialog(
            context: context,
            builder: (BuildContext ctx) => AlertDialog(
              title: const Text('Error'),
              content: Text('No se pudo abrir el detalle: $e'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: const Text('OK'),
                ),
              ],
            ),
          );
        }
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
