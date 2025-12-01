import 'package:flu2/models/reporte_revision_model.dart';
import 'package:flu2/utils/navigation_utils.dart';
import 'package:flu2/widgets/revision_detalle_modal.dart';
import 'package:flutter/material.dart';
import 'package:flu2/widgets/empty_state.dart';
// Nota: se eliminó import innecesario

class InformesRevisionList extends StatefulWidget {
  final List<ReporteRevision> revision; // Cambié el tipo de la lista aquí
  final Function(ReporteRevision)
  onRevisionUpdated; // Cambié el tipo de la función aquí
  final Function(ReporteRevision)
  onRevisionDeleted; // Cambié el tipo de la función aquí
  final bool showEmptyStateButton;
  final VoidCallback? onEmptyStateButtonPressed;
  final Future<void> Function()? onRefresh;
  final String emptyMessage;

  const InformesRevisionList({
    super.key,
    required this.revision,
    required this.onRevisionUpdated,
    required this.onRevisionDeleted,
    this.showEmptyStateButton = true,
    this.onEmptyStateButtonPressed,
    this.onRefresh,
    this.emptyMessage = "No hay revisión disponibles",
    List<ReporteRevision>? revisio,
  });

  @override
  State<InformesRevisionList> createState() => _InformesRevisionListState();
}

class _InformesRevisionListState extends State<InformesRevisionList> {
  bool _isRefreshing = false;

  Future<void> _handleRefresh() async {
    if (_isRefreshing || widget.onRefresh == null) return;

    setState(() {
      _isRefreshing = true;
    });

    try {
      await widget.onRefresh!();
    } finally {
      if (mounted) {
        setState(() {
          _isRefreshing = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (widget.revision.isEmpty) {
      return RefreshIndicator(
        // Personalizar indicador para que coincida con la apariencia de Auditoría
        color: Colors.green,
        backgroundColor: isDark ? Colors.grey[800] : Colors.white,
        strokeWidth: 2.5,
        displacement: 40,
        onRefresh: _handleRefresh,
        child: SingleChildScrollView(
          // AlwaysScrollableScrollPhysics permite el pull-to-refresh siempre
          physics: const AlwaysScrollableScrollPhysics(),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              // Garantiza suficiente área para que el gesto de pull se detecte
              minHeight: MediaQuery.of(context).size.height * 0.7,
            ),
            child: EmptyState(
              message: widget.emptyMessage,
              buttonText: widget.showEmptyStateButton
                  ? "Agregar Revision"
                  : null,
              onButtonPressed: widget.showEmptyStateButton
                  ? widget.onEmptyStateButtonPressed
                  : null,
              icon: Icons.local_activity,
            ),
          ),
        ),
      );
    }

    return RefreshIndicator(
      // Personalizar indicador para que coincida con la apariencia de Auditoría
      color: Colors.green,
      backgroundColor: isDark ? Colors.grey[800] : Colors.white,
      strokeWidth: 2.5,
      displacement: 40,
      onRefresh: _handleRefresh,
      child: ListView.builder(
        key: const PageStorageKey('auditoria_list'),
        padding: const EdgeInsets.all(8),
        // AlwaysScrollableScrollPhysics permite el pull-to-refresh siempre
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: widget.revision.length,
        itemBuilder: (context, index) {
          try {
            final revisionn = widget.revision[index];
            return _AnimatedListItem(
              key: ValueKey('${revisionn.titulo}_$index'),
              index: index,
              child: Card(
                color: isDark ? Colors.grey[800] : Colors.white,
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                margin: const EdgeInsets.symmetric(vertical: 2),
                child: InkWell(
                  onTap: () => _handleMenuAction(context, 'ver', revisionn),
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
                            color: getStatusColor(revisionn.estadoActual),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Icono de la izquierda (más compacto)
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: isDark ? Colors.grey[700] : Colors.grey[100],
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Icon(
                            Icons.description,
                            color: isDark ? Colors.grey[400] : Colors.grey[600],
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
                                      revisionn.titulo ?? 'Sin título',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: isDark
                                            ? Colors.white
                                            : Colors.black87,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 2),
                                    // Fecha de creación
                                    Text(
                                      'Creación: ${formatDate(revisionn.fecCre?.toIso8601String())}',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: isDark
                                            ? Colors.grey[400]
                                            : Colors.grey[600],
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    // Cantidad de detalles
                                    Text(
                                      '${revisionn.cantidad} detalles',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                        color: isDark
                                            ? Colors.white
                                            : Colors.black,
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
                                    '${_getTotal(revisionn)} PEN',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: isDark
                                          ? Colors.lightBlue[300]
                                          : Colors.blue,
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
                                        revisionn.estadoActual,
                                      ),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      revisionn.estadoActual ?? 'Sin estado',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),

                                  const SizedBox(height: 4),
                                  // Aprobados y Desaprobados con colores (solo si hay cantidades > 0)
                                  if (revisionn.cantidadAprobado > 0 ||
                                      revisionn.cantidadDesaprobado > 0)
                                    RichText(
                                      text: TextSpan(
                                        children: [
                                          if (revisionn.cantidadAprobado > 0)
                                            TextSpan(
                                              text:
                                                  '${revisionn.cantidadAprobado} Aprobrado',
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: Colors.green[600],
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          if (revisionn.cantidadAprobado > 0 &&
                                              revisionn.cantidadDesaprobado > 0)
                                            TextSpan(
                                              text: ' / ',
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: Colors.grey[600],
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          if (revisionn.cantidadDesaprobado > 0)
                                            TextSpan(
                                              text:
                                                  '${revisionn.cantidadDesaprobado} Rechazado',
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
            debugPrint('Error building revision  item: $e\n$st');
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

  double _getTotal(ReporteRevision revision) {
    return revision.total;
  }

  void _handleMenuAction(
    BuildContext context,
    String action,
    ReporteRevision revisionn,
  ) async {
    switch (action) {
      case 'ver':
        try {
          // Esperar el resultado del modal
          final result = await showDialog(
            context: context,
            builder: (BuildContext context) =>
                RevisionDetalleModal(revision: revisionn),
          );

          // Solo refrescar si hay cambios reales y el widget sigue montado
          if (result == true && mounted && widget.onRefresh != null) {
            // Agregar un pequeño delay para evitar múltiples llamadas
            await Future.delayed(const Duration(milliseconds: 100));
            if (mounted) {
              await widget.onRefresh!();
            }
          }
        } catch (e, st) {
          debugPrint('Error opening revision DetalleModal: $e\n$st');
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
        widget.onRevisionUpdated(revisionn);
        break;

      case 'eliminar':
        _showDeleteConfirmation(context, revisionn);
        break;
    }
  }

  void _showDeleteConfirmation(BuildContext context, ReporteRevision revision) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirmar eliminación'),
          content: Text(
            '¿Estás seguro de que quieres eliminar la revision "${revision.titulo}"?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                widget.onRevisionDeleted(revision);
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

// Widget de animación para items de la lista
class _AnimatedListItem extends StatefulWidget {
  final Widget child;
  final int index;

  const _AnimatedListItem({
    super.key,
    required this.child,
    required this.index,
  });

  @override
  State<_AnimatedListItem> createState() => _AnimatedListItemState();
}

class _AnimatedListItemState extends State<_AnimatedListItem>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  bool _hasAnimated = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutBack,
    );

    _startAnimation();
  }

  @override
  void didUpdateWidget(_AnimatedListItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Solo reinicia la animación si realmente cambió el contenido importante
    if (oldWidget.index != widget.index) {
      _controller.reset();
      _hasAnimated = false;
      _startAnimation();
    }
  }

  void _startAnimation() {
    // Cada elemento anima con un delay basado en su índice
    final delay = widget.index < 10
        ? widget.index * 100
        : 100; // Solo los primeros 10 tienen delay incremental

    Future.delayed(Duration(milliseconds: delay), () {
      if (mounted && !_hasAnimated) {
        _controller.forward();
        _hasAnimated = true;
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        final value = _animation.value.clamp(0.0, 1.0);
        return Transform.translate(
          offset: Offset(0, 60 * (1 - value)),
          child: Opacity(
            opacity: value,
            child: Transform.scale(scale: 0.85 + (0.15 * value), child: child),
          ),
        );
      },
      child: widget.child,
    );
  }
}
