import 'package:flutter/material.dart';
import '../models/gasto_model.dart';

class GastosList extends StatefulWidget {
  final List<Gasto> gastos;
  final Future<void> Function() onRefresh;
  final void Function(Gasto)? onTap;

  const GastosList({
    super.key,
    required this.gastos,
    required this.onRefresh,
    this.onTap,
  });

  @override
  State<GastosList> createState() => _GastosListState();
}

class _GastosListState extends State<GastosList> {
  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      backgroundColor: Colors.white,
      onRefresh: widget.onRefresh,
      child: widget.gastos.isEmpty
          ? ListView(
              children: const [
                SizedBox(height: 100),
                Center(
                  child: Text(
                    "No hay gastos disponibles",
                    style: TextStyle(color: Colors.grey, fontSize: 16),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            )
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: widget.gastos.length,
              itemBuilder: (context, index) {
                final gasto = widget.gastos[index];
                return _AnimatedListItem(
                  key: ValueKey('${gasto.titulo}_$index'),
                  index: index,
                  child: Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(12),
                      title: Text(
                        gasto.titulo,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            gasto.categoria,
                            style: TextStyle(color: Colors.grey[700]),
                          ),
                          Text(
                            gasto.fecha,
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                      trailing: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            gasto.monto,
                            style: const TextStyle(
                              color: Colors.indigo,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 1),
                          Chip(
                            label: Text(
                              gasto.estado,
                              style: const TextStyle(fontSize: 6),
                            ),
                            backgroundColor: gasto.estado == "Borrador"
                                ? Colors.orange[100]
                                : gasto.estado == "Enviados"
                                ? Colors.green[100]
                                : Colors.blue[100],
                          ),
                        ],
                      ),
                      onTap: widget.onTap != null
                          ? () => widget.onTap!(gasto)
                          : null,
                    ),
                  ),
                );
              },
            ),
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
