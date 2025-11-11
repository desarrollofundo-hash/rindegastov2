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

class _ReportesListState extends State<ReportesList> {
  final ReportesListController _controller = ReportesListController();
  // Función para abrir el escáner QR
  void _abrirEscaneadorQR() =>
      _controller.abrirEscaneadorQR(context, () => mounted);

  void _crearGasto() => _controller.crearGasto(context, () => mounted);

  void _escanerIA() => _controller.escanerIA(context, () => mounted);

  // Función para escanear documentos con IA (el botón está inactivo)

  // Nota: la lógica adicional (procesamiento IA, navegación de políticas, etc.)
  // fue movida al controlador `ReportesListController`.

  @override
  Widget build(BuildContext context) {
    if (widget.isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Cargando reportes...'),
          ],
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white, // COLOR DE FONDO DE REPORTE LIST
      body: DefaultTabController(
        length: 3,
        child: Column(
          children: [
            const TabBar(
              labelColor: Colors.indigo,
              unselectedLabelColor: Colors.grey,
              indicatorColor: Colors.indigo,
              tabs: [
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
    final data = _controller.filtrarReportes(widget.reportes, filtro);

    return RefreshIndicator(
      backgroundColor: Colors.white,
      onRefresh: widget.onRefresh,
      child: data.isEmpty
          ? ListView(
              children: [
                const SizedBox(height: 120),
                Center(
                  child: Column(
                    children: [
                      Image.asset(
                        'assets/icon/doc.png',
                        width: 120,
                        height: 140,
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        "No hay facturas registradas",
                        style: TextStyle(
                          color: Colors.black54,
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
              padding: const EdgeInsets.all(12),
              itemCount: data.length,
              itemBuilder: (context, index) {
                final reporte = data[index];

                return GestureDetector(
                  onTap: widget.onTap != null
                      ? () => widget.onTap!(reporte)
                      : null,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.grey.shade200, width: 1),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black12.withOpacity(0.05),
                          blurRadius: 6,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // 🔹 Icono + información
                          Expanded(
                            child: Row(
                              children: [
                                // 🔸 Ícono decorativo fuera de lo común
                                const SizedBox(width: 5),

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
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 14,
                                          color: Color(0xFF1E293B),
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 2),
                                      Row(
                                        children: [
                                          Icon(
                                            Icons.local_offer_rounded,
                                            size: 14,
                                            color: Colors.amberAccent.shade700,
                                          ),
                                          const SizedBox(width: 4),
                                          Expanded(
                                            child: Text(
                                              reporte.categoria ?? '',
                                              style: const TextStyle(
                                                fontSize: 12,
                                                color: Colors.black54,
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
                                            color: Colors.grey,
                                          ),
                                          const SizedBox(width: 4),
                                          // Fecha + etiqueta de días juntos
                                          Expanded(
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Text(
                                                  formatDate(reporte.fecha),
                                                  style: const TextStyle(
                                                    fontSize: 12,
                                                    color: Colors.black54,
                                                  ),
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                                const SizedBox(
                                                  width: 4,
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
                                                          6,
                                                        ),
                                                  ),
                                                  child: Text(
                                                    '${diferenciaEnDias(reporte.fecha.toString(), reporte.feccre.toString())} DÍAS',
                                                    style: const TextStyle(
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
                                  const Icon(
                                    Icons.payments_rounded,
                                    color: Color(0xFF2563EB),
                                    size: 17,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${reporte.total} PEN',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                      color: Color(0xFF2563EB),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
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
                                    const SizedBox(width: 3),
                                    Text(
                                      reporte.estadoActual ?? '',
                                      style: const TextStyle(
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
                );
              },
            ),
    );
  }

  // El color del estado se obtiene desde el controlador.
}
