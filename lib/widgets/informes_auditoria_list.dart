import 'package:flu2/models/reporte_auditioria_model.dart';
import 'package:flu2/utils/navigation_utils.dart';
import 'package:flu2/widgets/auditoria_detalle_modal.dart';
import 'package:flutter/material.dart';
import 'package:flu2/widgets/empty_state.dart';
// Nota: se eliminó import innecesario

class InformesAuditoriaList extends StatefulWidget {
  final List<ReporteAuditoria> auditorias; // Cambié el tipo de la lista aquí
  final Function(ReporteAuditoria)
  onAuditoriaUpdated; // Cambié el tipo de la función aquí
  final Function(ReporteAuditoria)
  onAuditoriaDeleted; // Cambié el tipo de la función aquí
  final bool showEmptyStateButton;
  final VoidCallback? onEmptyStateButtonPressed;
  final Future<void> Function()? onRefresh;
  final String emptyMessage;

  const InformesAuditoriaList({
    super.key,
    required this.auditorias,
    required this.onAuditoriaUpdated,
    required this.onAuditoriaDeleted,
    this.showEmptyStateButton = true,
    this.onEmptyStateButtonPressed,
    this.onRefresh,
    this.emptyMessage = "No hay auditorías disponibles",
    List<ReporteAuditoria>? auditori,
  });

  @override
  State<InformesAuditoriaList> createState() => _InformesAuditoriaListState();
}

class _InformesAuditoriaListState extends State<InformesAuditoriaList>
    with SingleTickerProviderStateMixin {
  AnimationController? _animationController;
  Animation<double>? _animation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);
    final curved = CurvedAnimation(
      parent: _animationController!,
      curve: Curves.bounceInOut,
    );
    _animation = Tween<double>(begin: -20, end: 20).animate(curved);
  }

  @override
  void dispose() {
    _animationController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.auditorias.isEmpty) {
      return RefreshIndicator(
        
        // Personalizar indicador para que coincida con la apariencia de Auditoría
        color: Colors.green,
        backgroundColor: Colors.white,
        strokeWidth: 2.5,
        displacement: 40,
        onRefresh: widget.onRefresh ?? () async {},
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
              message: widget.emptyMessage,
              buttonText: widget.showEmptyStateButton
                  ? "Agregar Auditoría"
                  : null,
              onButtonPressed: widget.showEmptyStateButton
                  ? widget.onEmptyStateButtonPressed
                  : null,
              image: AnimatedBuilder(
                animation: _animation!,
                builder: (context, child) {
                  return Transform.translate(
                    offset: Offset(0, _animation!.value),
                    child: child,
                  );
                },
                child: Image.asset(
                  'assets/icon/auditoria.png',
                  width: 64,
                  height: 64,
                ),
              ),
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
      onRefresh: widget.onRefresh ?? () async {},
      child: ListView.builder(
        key: const PageStorageKey('auditoria_list'),
        padding: const EdgeInsets.all(8),
        // Siempre scrollable y con rebote para mejorar la detección del pull
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        itemCount: widget.auditorias.length,
        itemBuilder: (context, index) {
          try {
            final auditoria = widget.auditorias[index];
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
                            color: getStatusColor(auditoria.estadoActual),
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
                                      'Creación: ${formatDate(auditoria.fecCre?.toIso8601String())}',
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
                                      color: getStatusColor(
                                        auditoria.estadoActual,
                                      ),
                                      borderRadius: BorderRadius.circular(6),
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

                                  const SizedBox(height: 4),
                                  // Aprobados y Desaprobados con colores (solo si hay cantidades > 0)
                                  if (auditoria.cantidadAprobado > 0 ||
                                      auditoria.cantidadDesaprobado > 0)
                                    RichText(
                                      text: TextSpan(
                                        children: [
                                          if (auditoria.cantidadAprobado > 0)
                                            TextSpan(
                                              text:
                                                  '${auditoria.cantidadAprobado} Aprobrado',
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: Colors.green[600],
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          if (auditoria.cantidadAprobado > 0 &&
                                              auditoria.cantidadDesaprobado > 0)
                                            TextSpan(
                                              text: ' / ',
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: Colors.grey[600],
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          if (auditoria.cantidadDesaprobado > 0)
                                            TextSpan(
                                              text:
                                                  '${auditoria.cantidadDesaprobado} Rechazado',
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

  double _getTotal(ReporteAuditoria auditoria) {
    return auditoria.total;
  }

  void _handleMenuAction(
    BuildContext context,
    String action,
    ReporteAuditoria auditoria,
  ) async {
    switch (action) {
      case 'ver':
        try {
          // Esperar el resultado del modal
          final result = await showDialog(
            context: context,
            builder: (BuildContext context) => AuditoriaDetalleModal(
              auditoria: auditoria, // <-- sigue pasando el callback
            ),
          );

          // Si el modal devuelve true, refresca la lista
          if (result == true && widget.onRefresh != null) {
            await widget.onRefresh!();
          }
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
        widget.onAuditoriaUpdated(auditoria);
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
                widget.onAuditoriaDeleted(auditoria);
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
