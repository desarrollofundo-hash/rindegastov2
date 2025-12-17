// ignore_for_file: avoid_print
import 'package:flu2/utils/navigation_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import '../controllers/reportes_list_controller.dart';
import '../models/reporte_model.dart';
import '../models/estado_reporte.dart';

class ReportesList extends StatefulWidget {
  final List<Reporte> reportes;
  final Future<void> Function() onRefresh;
  final bool isLoading;
  final void Function(Reporte)? onTap;

  const ReportesList({
    super.key,
    required this.reportes,
    required this.onRefresh,
    this.isLoading = false,
    this.onTap,
  });

  @override
  State<ReportesList> createState() => _ReportesListState();
}

class _ReportesListState extends State<ReportesList>
    with SingleTickerProviderStateMixin {
  final ReportesListController _controller = ReportesListController();

  AnimationController? _animationController;
  Animation<double>? _animation;

  // Función para abrir el escáner QR
  void _abrirEscaneadorQR() =>
      _controller.abrirEscaneadorQR(context, () => mounted);

  void _crearGasto() => _controller.crearGasto(context, () => mounted);

  void _escanerIA() => _controller.escanerIA(context, () => mounted);

  // 🕹 Widget para puntos de carga animados
  Widget _buildLoadingDot(int index, bool isDark) {
    final delay = index * 0.15;
    return AnimatedBuilder(
      animation: _animationController!,
      builder: (context, child) {
        final progress = (_animationController!.value + delay) % 1.0;
        final opacity = (1 - (progress - 0.5).abs() * 2).clamp(0.0, 1.0);
        return Transform.scale(
          scale: 0.6 + (opacity * 0.4),
          child: Container(
            width: 10,
            height: 10,
            margin: const EdgeInsets.symmetric(horizontal: 4),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: (isDark ? Colors.white : const Color(0xFF2563EB))
                  .withOpacity(opacity),
            ),
          ),
        );
      },
    );
  }

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

  // Función para escanear documentos con IA (el botón está inactivo)

  // Nota: la lógica adicional (procesamiento IA, navegación de políticas, etc.)
  // fue movida al controlador `ReportesListController`.

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (_animationController == null) {
      _animationController = AnimationController(
        duration: const Duration(seconds: 1),
        vsync: this,
      )..repeat(reverse: true);
      final curved = CurvedAnimation(
        parent: _animationController!,
        curve: Curves.bounceInOut,
      );
      _animation = Tween<double>(begin: -20, end: 20).animate(curved);
    }

    if (widget.isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 🎯 Indicador de carga mejorado
            Stack(
              alignment: Alignment.center,
              children: [
                // Fondo circular
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: (isDark ? Colors.white : const Color(0xFF2563EB))
                        .withOpacity(0.1),
                  ),
                ),
                // Indicador de progreso
                CircularProgressIndicator(
                  strokeWidth: 3,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    isDark ? Colors.white : const Color(0xFF2563EB),
                  ),
                  backgroundColor: Colors.transparent,
                ),
              ],
            ),
            const SizedBox(height: 32),

            // 📝 Texto principal
            Text(
              'Cargando reportes...',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : const Color(0xFF1E293B),
              ),
            ),

            const SizedBox(height: 8),

            // 💬 Texto secundario
            Text(
              'Esto puede tomar unos segundos',
              style: TextStyle(
                fontFamily: 'FiraSans',
                fontSize: 13,
                color: isDark ? Colors.grey[400] : Colors.grey[500],
                fontWeight: FontWeight.w400,
              ),
            ),

            const SizedBox(height: 24),

            // ⏳ Puntos animados
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildLoadingDot(0, isDark),
                _buildLoadingDot(1, isDark),
                _buildLoadingDot(2, isDark),
              ],
            ),
          ],
        ),
      );
    }

    return Scaffold(
      backgroundColor: isDark ? Colors.grey[900] : Colors.white,
      body: DefaultTabController(
        length: 3,
        child: Column(
          children: [
            TabBar(
              labelColor: Colors.indigo,
              unselectedLabelColor: Colors.grey,
              indicatorColor: Colors.indigo,
              dividerColor: Colors.grey.withOpacity(0.4),
              dividerHeight: 0.5,
              tabs: const [
                Tab(text: "Todos"),
                Tab(text: "Borradores"),
                Tab(text: "Enviados"),
              ],
            ),
            Expanded(
              child: TabBarView(
                children: [
                  _buildList(EstadoReporte.todos),
                  _buildList(EstadoReporte.borrador),
                  _buildList(EstadoReporte.enviado),
                ],
              ),
            ),
          ],
        ),
      ),

      // 👇 FAB expandible
      floatingActionButton: SpeedDial(
        icon: Icons.add,
        activeIcon: Icons.close,
        iconTheme: const IconThemeData(color: Colors.white),
        backgroundColor: const Color.fromARGB(255, 31, 98, 213),
        overlayColor: Colors.black,
        overlayOpacity: 0.5,
        spacing: 12,
        spaceBetweenChildren: 8,
        children: [
          SpeedDialChild(
            child: const Icon(Icons.document_scanner, color: Colors.white),
            backgroundColor: Colors.green,
            label: 'Escanear IA',
            onTap: _escanerIA,
          ),

          SpeedDialChild(
            child: const Icon(Icons.qr_code_scanner, color: Colors.white),
            backgroundColor: Colors.blue,
            label: 'Lector de códigos',
            onTap: _abrirEscaneadorQR,
          ),
          SpeedDialChild(
            child: const Icon(Icons.note_add, color: Colors.white),
            backgroundColor: Colors.indigo,
            label: 'Crear gasto',
            onTap: _crearGasto,
          ),
        ],
      ),
    );
  }

  Widget _buildList(EstadoReporte filtro) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final data = _controller.filtrarReportes(widget.reportes, filtro);

    // Obtener el mensaje según el filtro
    String _getEmptyMessage(EstadoReporte filtro) {
      switch (filtro) {
        case EstadoReporte.todos:
          return "No hay ninguna factura registrada";
        case EstadoReporte.borrador:
          return "No hay ninguna factura en borrador";
        case EstadoReporte.enviado:
          return "No hay ninguna factura enviada";
      }
    }

    return RefreshIndicator(
      backgroundColor: isDark ? Colors.grey[800] : Colors.white,
      onRefresh: widget.onRefresh,
      child: data.isEmpty
          ? ListView(
              children: [
                const SizedBox(height: 120),
                Center(
                  child: Column(
                    children: [
                      AnimatedBuilder(
                        animation: _animation!,
                        builder: (context, child) {
                          return Transform.translate(
                            offset: Offset(0, _animation!.value),
                            child: child,
                          );
                        },
                        child: Image.asset(
                          'assets/icon/doc1.png',
                          width: 120,
                          height: 140,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _getEmptyMessage(filtro),
                        style: TextStyle(
                          color: isDark ? Colors.grey[400] : Colors.black54,
                          fontSize: 20,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            )
          : ListView.builder(
              padding: const EdgeInsets.all(6),
              itemCount: data.length,
              itemBuilder: (context, index) {
                final reporte = data[index];

                return _AnimatedListItem(
                  key: ValueKey('${reporte.idrend}_animated'),
                  index: index,
                  child: GestureDetector(
                    onTap: widget.onTap != null
                        ? () => widget.onTap!(reporte)
                        : null,

                    ///aqui comienza el card para editar
                    child: Container(
                      margin: const EdgeInsets.symmetric(vertical: 2),

                      decoration: BoxDecoration(
                        color: isDark ? Colors.grey[800] : Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isDark
                              ? Colors.grey[700]!
                              : Colors.grey.shade200,
                          width: 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: isDark
                                ? Colors.black.withOpacity(0.3)
                                : Colors.black12.withOpacity(0.1),
                            blurRadius: 6,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 8,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // 🔹 Icono + información
                            Expanded(
                              child: Row(
                                children: [
                                  // 🔸 Ícono decorativo fuera de lo común
                                  const SizedBox(width: 3),

                                  // 🔸 Datos principales
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          reporte.proveedor ??
                                              reporte.ruc ??
                                              reporte.ruccliente ??
                                              '',
                                          style: TextStyle(
                                            fontWeight: FontWeight.w600,
                                            fontSize: 14,
                                            color: isDark
                                                ? Colors.white
                                                : const Color(0xFF1E293B),
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 2),
                                        Row(
                                          children: [
                                            Icon(
                                              Icons.local_offer_rounded,
                                              size: 14,
                                              color:
                                                  Colors.amberAccent.shade700,
                                            ),
                                            const SizedBox(width: 4),
                                            Expanded(
                                              child: Text(
                                                reporte.categoria ?? '',
                                                style: TextStyle(
                                                  fontWeight: FontWeight.w400,
                                                  fontSize: 12,
                                                  color: isDark
                                                      ? Colors.grey[400]
                                                      : Colors.black54,
                                                ),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 2),

                                        Row(
                                          children: [
                                            Icon(
                                              Icons.calendar_month_rounded,
                                              size: 13,
                                              color: isDark
                                                  ? Colors.grey[500]
                                                  : Colors.grey,
                                            ),
                                            const SizedBox(width: 4),
                                            // Fecha + etiqueta de días juntos
                                            Expanded(
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  /*  Text(
                                                    formatDate(reporte.fecha),
                                                    style: TextStyle(
                                                      fontSize: 12,
                                                      color: isDark
                                                          ? Colors.grey[400]
                                                          : Colors.black54,
                                                    ),
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                  ), */
                                                  Builder(
                                                    builder: (context) {
                                                      debugPrint(
                                                        '📅 Reporte ${reporte.idrend}:',
                                                      );
                                                      debugPrint(
                                                        '   • fecha (emisión): "${reporte.fecha}"',
                                                      );
                                                      debugPrint(
                                                        '   • feccre (creación): "${reporte.feccre}"',
                                                      );

                                                      return Text(
                                                        formatDate(
                                                          reporte.fecha,
                                                        ),
                                                        style: TextStyle(
                                                          fontSize: 12,
                                                          color: isDark
                                                              ? Colors.grey[400]
                                                              : Colors.black54,
                                                        ),
                                                        overflow: TextOverflow
                                                            .ellipsis,
                                                      );
                                                    },
                                                  ),
                                                  const SizedBox(
                                                    width: 8,
                                                  ), // pequeño espacio visual
                                                  Container(
                                                    padding:
                                                        const EdgeInsets.symmetric(
                                                          horizontal: 2,
                                                          vertical: 2,
                                                        ),
                                                    decoration: BoxDecoration(
                                                      color: Colors
                                                          .red, // Fondo de la etiqueta
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            4,
                                                          ),
                                                    ),
                                                    child: Text(
                                                      '${diferenciaEnDias(reporte.fecha.toString(), reporte.feccre.toString())} DÍAS',

                                                      style: const TextStyle(
                                                        fontFamily: 'FiraSans',
                                                        fontSize: 11,
                                                        color: Colors.white,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                      ),
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

                            // 🔹 Monto + estado
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Row(
                                  children: [
                                    /* const Icon(
                                    Icons.payments_rounded,
                                    color: Color(0xFF2563EB),
                                    size: 17,
                                  ), */
                                    /* Image.asset(
                                    'assets/icon/sol.png',
                                    width: 20,
                                    height: 20,
                                    color: const Color.fromARGB(
                                      255,
                                      7,
                                      79,
                                      234,
                                    ),
                                    colorBlendMode: BlendMode.srcIn,
                                  ), */
                                    const SizedBox(width: 4),
                                    Text(
                                      '${reporte.total} ${reporte.moneda} ',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w900,
                                        fontSize: 14,
                                        color: Color(0xFF2563EB),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color: getStatusColor(reporte.estadoActual),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(
                                        Icons.blur_circular_rounded,
                                        size: 12,
                                        color: Colors.white,
                                      ),
                                      const SizedBox(width: 5),
                                      Text(
                                        reporte.estadoActual ?? '',
                                        style: const TextStyle(
                                          fontFamily: 'Poppins',
                                          fontSize: 11,
                                          color: Colors.white,
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
                    ),
                  ),
                );
              },
            ),
    );
  }

  // El color del estado se obtiene desde el controlador.
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
