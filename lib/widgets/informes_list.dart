import 'package:flu2/widgets/empty_state.dart';
import 'package:flutter/material.dart';
import '../models/gasto_model.dart';
import '../screens/informes/detalle_informe_screen.dart';

class InformesList extends StatefulWidget {
  final List<Gasto> informes;
  final Function(Gasto) onInformeUpdated;
  final Function(Gasto) onInformeDeleted;
  final bool showEmptyStateButton;
  final VoidCallback? onEmptyStateButtonPressed;

  const InformesList({
    super.key,
    required this.informes,
    required this.onInformeUpdated,
    required this.onInformeDeleted,
    this.showEmptyStateButton = true,
    this.onEmptyStateButtonPressed,
  });

  @override
  State<InformesList> createState() => _InformesListState();
}

class _InformesListState extends State<InformesList> {
  @override
  Widget build(BuildContext context) {
    if (widget.informes.isEmpty) {
      return EmptyState(
        message: "No hay informes disponibles",
        buttonText: widget.showEmptyStateButton ? "Agregar Informe" : null,
        onButtonPressed: widget.showEmptyStateButton
            ? widget.onEmptyStateButtonPressed
            : null,
        icon: Icons.description,
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: widget.informes.length,
      itemBuilder: (context, index) {
        final inf = widget.informes[index];
        return _AnimatedListItem(
          key: ValueKey('${inf.titulo}_$index'),
          index: index,
          child: Card(
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            margin: const EdgeInsets.symmetric(vertical: 8),
            child: ListTile(
              contentPadding: const EdgeInsets.all(12),
              title: Text(
                inf.titulo,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    inf.categoria,
                    style: TextStyle(color: Colors.grey[700]),
                  ),
                  Text(
                    inf.fecha,
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  ),
                ],
              ),
              trailing: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    inf.monto,
                    style: const TextStyle(
                      color: Colors.indigo,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Chip(
                    label: Text(
                      inf.estado,
                      style: const TextStyle(fontSize: 10),
                    ),
                    backgroundColor: inf.estado == "Borrador"
                        ? Colors.orange[100]
                        : Colors.green[100],
                  ),
                ],
              ),
              onTap: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => DetalleInformeScreen(informe: inf),
                  ),
                );
                _handleInformeResult(result, inf);
              },
            ),
          ),
        );
      },
    );
  }

  void _handleInformeResult(dynamic result, Gasto informe) {
    if (result != null && result is Map) {
      if (result["accion"] == "eliminar") {
        widget.onInformeDeleted(informe);
      } else if (result["accion"] == "editar" && result["data"] is Gasto) {
        widget.onInformeUpdated(result["data"]);
      }
    }
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
    // Reinicia la animación cuando el widget se actualiza (ej: refresh)
    if (oldWidget.index != widget.index || oldWidget.child != widget.child) {
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
