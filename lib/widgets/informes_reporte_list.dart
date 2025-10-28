import 'package:flu2/widgets/empty_state.dart';
import 'package:flu2/widgets/informe_detalle_modal.dart';
import 'package:flutter/material.dart';
import '../models/reporte_informe_model.dart';

class InformesReporteList extends StatelessWidget {
  final List<ReporteInforme> informes;
  final Function(ReporteInforme) onInformeUpdated;
  final Function(ReporteInforme) onInformeDeleted;
  final bool showEmptyStateButton;
  final VoidCallback? onEmptyStateButtonPressed;
  final Future<void> Function()? onRefresh;

  const InformesReporteList({
    super.key,
    required this.informes,
    required this.onInformeUpdated,
    required this.onInformeDeleted,
    this.showEmptyStateButton = true,
    this.onEmptyStateButtonPressed,
    this.onRefresh,
    required List<ReporteInforme> informe,
  });

  @override
  Widget build(BuildContext context) {
    if (informes.isEmpty) {
      return RefreshIndicator(
        onRefresh: onRefresh ?? () async {},
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Container(
            height: MediaQuery.of(context).size.height * 0.7,
            child: EmptyState(
              message: "No hay informes disponibles",
              buttonText: showEmptyStateButton ? "Agregar Informe" : null,
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
        itemCount: informes.length,
        itemBuilder: (context, index) {
          final inf = informes[index];
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
                onTap: () => _handleMenuAction(context, 'ver', inf),
                borderRadius: BorderRadius.circular(16),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Barra lateral de color que indica el estado
                        Container(
                          width: 6,
                          decoration: BoxDecoration(
                            color: _getStatusColor(inf.estadoActual),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        const SizedBox(width: 12),
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
                              // Columna izquierda: Título, Creación, Gastos
                              Expanded(
                                flex: 2,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Título del informe
                                    Text(
                                      inf.titulo ?? 'Sin título',
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
                                      'Creación: ${_formatDate(inf.fecCre)}',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    // Cantidad de gastos
                                    Text(
                                      '${inf.cantidad} gastos',
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              // Columna derecha: Total, Estado, Aprobados/Desaprobados
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  // Total en PEN
                                  Text(
                                    '${inf.total.toStringAsFixed(2)} PEN',
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
                                      color: _getStatusColor(inf.estadoActual),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      inf.estadoActual ?? 'Sin estado',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  // Aprobados y Desaprobados con colores (solo si hay cantidades > 0)
                                  if (inf.cantidadAprobado > 0 ||
                                      inf.cantidadDesaprobado > 0)
                                    RichText(
                                      text: TextSpan(
                                        children: [
                                          if (inf.cantidadAprobado > 0)
                                            TextSpan(
                                              text:
                                                  '${inf.cantidadAprobado} Aprob.',
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: Colors.green[600],
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          if (inf.cantidadAprobado > 0 &&
                                              inf.cantidadDesaprobado > 0)
                                            TextSpan(
                                              text: ' / ',
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: Colors.grey[600],
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          if (inf.cantidadDesaprobado > 0)
                                            TextSpan(
                                              text:
                                                  '${inf.cantidadDesaprobado} Desaprob.',
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: Colors.red[600],
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                        ],
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

  //COLORES DE ESTADO
  Color _getStatusColor(String? estado) {
    switch (estado) {
      case 'EN AUDITORIA':
        return Colors.blue;
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

  void _handleMenuAction(
    BuildContext context,
    String action,
    ReporteInforme informe,
  ) {
    switch (action) {
      case 'ver':
        showDialog(
          context: context,
          builder: (BuildContext context) =>
              InformeDetalleModal(informe: informe),
        );
        break;
      case 'editar':
        onInformeUpdated(informe);
        break;
      case 'eliminar':
        _showDeleteConfirmation(context, informe);
        break;
    }
  }

  void _showDeleteConfirmation(BuildContext context, ReporteInforme informe) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirmar eliminación'),
          content: Text(
            '¿Estás seguro de que quieres eliminar el informe "${informe.titulo}"?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                onInformeDeleted(informe);
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
