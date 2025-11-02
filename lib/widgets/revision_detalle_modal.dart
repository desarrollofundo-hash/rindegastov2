import 'package:flu2/models/reporte_auditioria_model.dart';
import 'package:flu2/models/reporte_revision_detalle.dart';
import 'package:flu2/models/reporte_revision_model.dart';
import 'package:flu2/utils/navigation_utils.dart';
import 'package:flu2/widgets/detalle_modal_gasto.dart';
import 'package:flu2/widgets/editar_auditoria_modal.dart';
import 'package:flu2/widgets/editar_revision_modal.dart';
import 'package:flutter/material.dart';
import '../models/reporte_auditoria_detalle.dart';
import '../services/api_service.dart';

class RevisionDetalleModal extends StatefulWidget {
  final ReporteRevision revision;
  final VoidCallback? onRefresh; // callback opcional

  const RevisionDetalleModal({
    super.key,
    required this.revision,
    this.onRefresh,
  });

  @override
  State<RevisionDetalleModal> createState() => RevisionDetalleModalState();
}

class RevisionDetalleModalState extends State<RevisionDetalleModal>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<ReporteRevisionDetalle> _detalles = [];
  bool _isLoading = true;
  bool _isSending = false;
  final ApiService _apiService = ApiService();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadDetalles();
  }

  Future<void> _loadDetalles() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
      });
    }

    try {
      // Intentar llamar al API primero para obtener los detalles reales
      List<ReporteRevisionDetalle> reportesRevision = [];

      try {
        reportesRevision = await _apiService
            .getReportesRendicionRevision_Detalle(
              idRev: widget.revision.idRev.toString(),
            );
      } catch (apiError) {
        // fallback: dejar la lista vacía para mostrar el estado "No hay gastos"
        reportesRevision = [];
      }

      if (mounted) {
        setState(() {
          _detalles = reportesRevision;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _detalles = [];
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _enviarInforme() async {
    try {
      setState(() => _isLoading = true);
      print("🚀 Iniciando envío de informe...");

      // 1️⃣ GUARDAR CABECERA (saveRendicionAuditoria)
      final cabeceraPayload = {
        "idRev": 0,
        "idAd": widget.revision.idAd,
        "idUser": widget.revision.idUser,
        "dni": widget.revision.dni,
        "ruc": widget.revision.ruc,
        "obs": widget.revision.obs ?? "",
        "estadoActual": "EN REVISION",
        "estado": "S",
        "fecCre": DateTime.now().toIso8601String(),
        "useReg": widget.revision.idUser,
        "hostname": "",
        "fecEdit": DateTime.now().toIso8601String(),
        "useEdit": widget.revision.idUser,
        "useElim": 0,
      };

      print("📤 Enviando cabecera: $cabeceraPayload");

      final idAd = await _apiService.saveRendicionAuditoria(cabeceraPayload);
      if (idAd == null) throw Exception("Error al guardar cabecera.");

      print("✅ Cabecera guardada con idAd: $idAd");

      // 2️⃣ GUARDAR DETALLES: usamos los campos del modelo ReporteInformeDetalle
      if (_detalles.isEmpty) {
        print('⚠️ No hay detalles para enviar.');
      }

      for (final detalless in _detalles) {
        final detallePayload = {
          "idRev": idAd, // Relación con la cabecera
          "idAd": detalless.idAd,
          "idAdDet": detalless.idAdDet, // usar idrend como id de factura
          "idRend": detalless.idRend,
          // Preferir el idUser del detalle; si no está, usar el del informe
          "idUser": detalless.idUser != 0
              ? detalless.idUser
              : widget.revision.idUser,
          // El modelo de detalle no tiene 'dni', por eso mantenemos el dni del revision
          "dni": (widget.revision.dni ?? '').toString(),
          // Usar ruc del detalle si existe, si no, el ruc del revision
          "ruc": (detalless.ruc ?? widget.revision.ruc ?? '').toString(),
          "obs": detalless.obs ?? '',
          "estadoActual": detalless.estadoActual ?? 'EN REVISION',
          "estado": detalless.estado ?? 'S',
          "fecCre": detalless.fecCre ?? DateTime.now().toIso8601String(),
          "useReg": detalless.idUser != 0
              ? detalless.idUser
              : widget.revision.idUser,
          "hostname": 'FLUTTER',
          "fecEdit": DateTime.now().toIso8601String(),
          "useEdit": detalless.idUser != 0
              ? detalless.idUser
              : widget.revision.idUser,
          "useElim": 0,
        };

        print("📤 Enviando detalle (id: ${detalless.idRev}): $detallePayload");

        final detalleGuardado = await _apiService.saveRendicionAuditoriaDetalle(
          detallePayload,
        );

        if (!detalleGuardado) {
          throw Exception(
            'Error al guardar el detalle de la rendición de auditoría para id ${detalless.idRev}',
          );
        }

        print("✅ Detalle ${detalless.idRev} guardado correctamente");
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("✅ Informe enviado correctamente")),
      );
      Navigator.pop(context);
    } catch (e, stack) {
      print("❌ Error al enviar informe: $e");
      print(stack);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error al enviar informe: $e")));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _apiService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.only(top: 100), // Solo margen superior
      clipBehavior: Clip.antiAliasWithSaveLayer,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
      ),
      child: SizedBox(
        width: double.maxFinite,
        height: double
            .maxFinite, // Usa toda la altura disponible desde el margen superior
        child: Scaffold(
          backgroundColor: Colors.grey[50],

          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 0.5,
            leading: IconButton(
              icon: const Icon(Icons.more_horiz, color: Colors.grey),
              onPressed: () => Navigator.of(context).pop(true),
            ),
            title: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'DETALLE REVISION',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),

                const SizedBox(height: 2),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'RENDIDOR: ',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.blue,
                        fontStyle: FontStyle.normal,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      widget.revision.usuario.toString(), // ← valor dinámico
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            centerTitle: true,
            actions: [
              IconButton(
                icon: const Icon(Icons.close, color: Colors.grey),
                onPressed: () => Navigator.of(context).pop(true),
              ),
            ],
          ),

          body: Column(
            children: [
              // Cabecera ultra compacta
              Container(
                width: double.infinity,
                color: const Color(0xFF1976D2),
                child: SafeArea(
                  bottom: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,

                      children: [
                        // COLUMNA IZQUIERDA
                        Expanded(
                          flex: 3,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // PRIMERA FILA: Nombre del informe + ID
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      widget.revision.titulo ??
                                          'Sin título asignado',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 20,
                                        fontWeight: FontWeight.w700,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                ],
                              ),

                              const SizedBox(height: 8),

                              // SEGUNDA FILA: Fecha
                              Row(
                                children: [
                                  Icon(
                                    Icons.calendar_today,
                                    color: Colors.white.withOpacity(0.8),
                                    size: 14,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    formatDate(
                                      widget.revision.fecCre
                                              ?.toIso8601String() ??
                                          '',
                                    ),
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.9),
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(width: 8),

                                  Text(
                                    '|',
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.6),
                                      fontSize: 24,
                                      fontWeight: FontWeight.w300,
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 3,
                                    ),

                                    child: Text(
                                      '#${widget.revision.idAd}',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 17,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 6),

                              // TERCERA FILA: Política
                              Row(
                                children: [
                                  Icon(
                                    Icons.policy,
                                    color: Colors.white.withOpacity(0.8),
                                    size: 14,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    widget.revision.politica ?? 'General',
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.9),
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(width: 16),

                        // COLUMNA DERECHA
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            // Monto
                            Text(
                              'S/ ${widget.revision.total.toStringAsFixed(2)}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.w900,
                                letterSpacing: -0.5,
                              ),
                            ),

                            const SizedBox(height: 4),

                            // Estado del revision
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.transparent,
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: getStatusColor(
                                    widget.revision.estadoActual,
                                  ),
                                  width: 1,
                                ),
                              ),
                              child: Text(
                                widget.revision.estadoActual ?? 'Borrador',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),

                            const SizedBox(height: 8),

                            // Gastos debajo
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),

                              child: Text(
                                '${widget.revision.cantidad} ${widget.revision.cantidad == 1 ? 'gasto' : 'gastos'}',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.9),
                                  fontSize: 17,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Tabs mejoradas
              Container(
                color: Colors.white,
                child: TabBar(
                  controller: _tabController,
                  labelColor: Colors.blue,
                  unselectedLabelColor: Colors.grey[600],
                  indicatorColor: Colors.blue,
                  indicatorWeight: 3,
                  labelStyle: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                  unselectedLabelStyle: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                  tabs: [
                    Tab(text: 'Gastos (${widget.revision.cantidad})'),
                    const Tab(text: 'Detalle'),
                  ],
                ),
              ),

              // Contenido de las tabs
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    // Tab de Gastos
                    Container(
                      color: Colors.grey[50],
                      child: Builder(
                        builder: (context) {
                          print(
                            '📱 Building Gastos Tab - Loading: $_isLoading, Items: ${_detalles.length}',
                          );

                          if (_isLoading) {
                            return const Center(
                              child: CircularProgressIndicator(
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.blue,
                                ),
                              ),
                            );
                          }

                          if (_detalles.isEmpty) {
                            return Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(
                                    Icons.receipt_long,
                                    size: 64,
                                    color: Colors.grey,
                                  ),
                                  const SizedBox(height: 16),
                                  const Text(
                                    'No hay gastos en esta auditoria',
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Colors.grey,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  ElevatedButton(
                                    onPressed: _loadDetalles,
                                    child: const Text('Recargar'),
                                  ),
                                ],
                              ),
                            );
                          }

                          return RefreshIndicator(
                            onRefresh: _loadDetalles,
                            child: ListView.separated(
                              padding: const EdgeInsets.all(16),
                              itemCount: _detalles.length,
                              separatorBuilder: (context, index) =>
                                  const SizedBox(height: 12),
                              itemBuilder: (context, index) {
                                final detalle = _detalles[index];
                                print(
                                  '🏗️ Building card for item $index: ${detalle.estadoActual}',
                                );
                                return _buildGastoCard(detalle, context);
                              },
                            ),
                          );
                        },
                      ),
                    ),
                    // Tab de Detalle
                    Container(
                      color: Colors.grey[50],
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildDetailSection('Información General', [
                              _buildDetailRow(
                                'ID Audtoría',
                                '#${widget.revision.idAd}',
                              ),
                              _buildDetailRow(
                                'Usuario',
                                widget.revision.idUser.toString(),
                              ),
                              _buildDetailRow(
                                'RUC',
                                widget.revision.ruc ?? 'N/A',
                              ),
                              _buildDetailRow(
                                'DNI',
                                widget.revision.dni ?? 'N/A',
                              ),
                            ]),
                            const SizedBox(height: 20),
                            _buildDetailSection('Estadísticas', [
                              _buildDetailRow(
                                'Total Gastos',
                                widget.revision.cantidad.toString(),
                              ),
                              _buildDetailRow(
                                'Aprobados',
                                '${widget.revision.cantidadAprobado} (${widget.revision.totalAprobado.toStringAsFixed(2)} PEN)',
                              ),
                              _buildDetailRow(
                                'Desaprobados',
                                '${widget.revision.cantidadDesaprobado} (${widget.revision.totalDesaprobado.toStringAsFixed(2)} PEN)',
                              ),
                            ]),
                            if (widget.revision.nota != null &&
                                widget.revision.nota!.isNotEmpty) ...[
                              const SizedBox(height: 20),
                              _buildDetailSection('Observaciones', [
                                Text(
                                  widget.revision.nota!,
                                  style: const TextStyle(fontSize: 14),
                                ),
                              ]),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Botones de acción mejorados
              Container(
                color: Colors.white,
                padding: const EdgeInsets.all(20),
                child: SafeArea(
                  top: false,
                  child: Row(
                    children: [
                      // Botón Editar
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () async {
                            // Abres el modal y esperas a que se cierre
                            final result = await Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => EditarRevisionModal(
                                  revision: widget.revision,
                                  detalles: _detalles,
                                ),
                              ),
                            );

                            // Si el modal devolvió "true" (por ejemplo, tras guardar cambios), recargas
                            if (result == true) {
                              _loadDetalles();
                            }
                          },
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(
                              color: Colors.blue,
                              width: 2,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          child: const Text(
                            'Editar auditoria',
                            style: TextStyle(
                              color: Colors.blue,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),

                      // Botón Enviar
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.of(context).pop(true);
                          },
                          //_enviarInforme,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            elevation: 2,
                          ),
                          child: const Text(
                            'Enviar Revision',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGastoCard(ReporteRevisionDetalle detalle, BuildContext context) {
    return GestureDetector(
      onTap: () {
        // Llamar al modal y pasar el detalle
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return DetalleModalGasto(id: detalle.idRend.toString());
          },
        );
      },
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              spreadRadius: 1,
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Imagen placeholder
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.receipt_long,
                color: Colors.grey[600],
                size: 24,
              ),
            ),
            const SizedBox(width: 16),

            // Información del gasto
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    detalle.ruc ?? 'Proveedor no especificado',
                    maxLines: 1,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 0),
                  Text(
                    detalle.categoria != null && detalle.categoria!.isNotEmpty
                        ? '${detalle.categoria}'
                        : 'Sin categoría',
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                  ),
                  Text(
                    formatDate(detalle.fecha),
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),

            // Monto y estado
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${detalle.total} ${detalle.moneda ?? 'PEN'}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: getStatusColor(detalle.estadoActual),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    detalle.estadoActual ?? 'Sin estado',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /*
  Widget _buildGastoCard(ReporteAuditoriaDetalle detalle) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),

      child: Row(
        children: [
          // Imagen placeholder
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(Icons.receipt_long, color: Colors.grey[600], size: 24),
          ),
          const SizedBox(width: 16),

          // Información del gasto
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  detalle.ruc ?? 'Proveedor no especificado',
                  maxLines: 1,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 0),
                Text(
                  detalle.categoria != null && detalle.categoria!.isNotEmpty
                      ? '${detalle.categoria}'
                      : 'Sin categoría',
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                ),
                Text(
                  formatDate(detalle.fecha),
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                ),
              ],
            ),
          ),

          // Monto y estado
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${detalle.total} ${detalle.moneda ?? 'PEN'}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                ),
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: getStatusColor(detalle.estadoActual),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  detalle.estadoActual ?? 'Sin estado',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
*/
  Widget _buildDetailSection(String title, List<Widget> children) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.black87,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
