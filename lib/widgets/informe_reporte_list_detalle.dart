import 'package:flu2/widgets/empty_state.dart';
import 'package:flutter/material.dart';
import '../models/reporte_informe_detalle.dart';

class InformeReporteListDetalle extends StatelessWidget {
  final List<ReporteInformeDetalle> detalles;
  final Function(ReporteInformeDetalle) onDetalleUpdated;
  final Function(ReporteInformeDetalle) onDetalleDeleted;
  final bool showEmptyStateButton;
  final VoidCallback? onEmptyStateButtonPressed;
  final Future<void> Function()? onRefresh;

  const InformeReporteListDetalle({
    super.key,
    required this.detalles,
    required this.onDetalleUpdated,
    required this.onDetalleDeleted,
    this.showEmptyStateButton = true,
    this.onEmptyStateButtonPressed,
    this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    if (detalles.isEmpty) {
      return RefreshIndicator(
        onRefresh: onRefresh ?? () async {},
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Container(
            height: MediaQuery.of(context).size.height * 0.7,
            child: EmptyState(
              message: "No hay detalles disponibles",
              buttonText: showEmptyStateButton ? "Agregar Detalle" : null,
              onButtonPressed: showEmptyStateButton
                  ? onEmptyStateButtonPressed
                  : null,
              icon: Icons.receipt_long,
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
        itemCount: detalles.length,
        itemBuilder: (context, index) {
          final detalle = detalles[index];
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
                onTap: () => _handleMenuAction(context, 'ver', detalle),
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
                          Icons.receipt_long,
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
                            // Columna izquierda: Proveedor, Categoría, Comprobante
                            Expanded(
                              flex: 2,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Proveedor o RUC
                                  Text(
                                    detalle.proveedorOrRuc,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black87,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 2),
                                  // Categoría y Tipo de gasto
                                  Text(
                                    '${detalle.categoria ?? 'Sin categoría'} - ${detalle.tipogasto ?? 'Sin tipo'}',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  // Comprobante
                                  Text(
                                    detalle.comprobanteCompleto,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            // Columna derecha: Total, Estado, Fecha
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                // Total
                                Text(
                                  detalle.totalFormatted,
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
                                      detalle.estadoactual,
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    detalle.estadoFormatted,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                // Fecha del gasto
                                Text(
                                  _formatDate(detalle.fecha),
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                    fontWeight: FontWeight.w500,
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

    return fecha;
  }

  Color _getStatusColor(String? estado) {
    switch (estado?.toUpperCase()) {
      case 'EN INFORME':
        return Colors.blue;
      case 'APROBADO':
        return Colors.green;
      case 'RECHAZADO':
        return Colors.red;
      case 'BORRADOR':
        return Colors.orange;
      case 'PENDIENTE':
        return Colors.amber;
      default:
        return Colors.grey;
    }
  }

  void _handleMenuAction(
    BuildContext context,
    String action,
    ReporteInformeDetalle detalle,
  ) {
    switch (action) {
      case 'ver':
        _showDetalleDialog(context, detalle);
        break;
      case 'editar':
        onDetalleUpdated(detalle);
        break;
      case 'eliminar':
        _showDeleteConfirmation(context, detalle);
        break;
    }
  }

  void _showDetalleDialog(BuildContext context, ReporteInformeDetalle detalle) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Detalle #${detalle.id}'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildDetailRow('Proveedor:', detalle.proveedorOrRuc),
                _buildDetailRow(
                  'Categoría:',
                  detalle.categoria ?? 'Sin categoría',
                ),
                _buildDetailRow('Tipo Gasto:', detalle.tipogasto ?? 'Sin tipo'),
                _buildDetailRow('Comprobante:', detalle.comprobanteCompleto),
                _buildDetailRow('Total:', detalle.totalFormatted),
                _buildDetailRow('IGV:', detalle.igvFormatted),
                _buildDetailRow('Estado:', detalle.estadoFormatted),
                _buildDetailRow('Fecha:', _formatDate(detalle.fecha)),
                if (detalle.obs != null && detalle.obs!.isNotEmpty)
                  _buildDetailRow('Observaciones:', detalle.obs!),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cerrar'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
          ),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 14))),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(
    BuildContext context,
    ReporteInformeDetalle detalle,
  ) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirmar eliminación'),
          content: Text(
            '¿Estás seguro de que quieres eliminar el detalle #${detalle.id}?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                onDetalleDeleted(detalle);
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
