import 'package:flu2/models/reporte_model.dart';
import 'package:flu2/screens/informes/detalle_informe_screen.dart';
import 'package:flu2/utils/navigation_utils.dart';
import 'package:flu2/widgets/detalle_modal_gasto.dart';
import 'package:flutter/material.dart';
import '../models/reporte_informe_model.dart';
import '../models/reporte_informe_detalle.dart';
import '../services/api_service.dart';
import '../services/user_service.dart';
import '../services/company_service.dart';
import 'editar_informe_modal.dart';

class InformeDetalleModal extends StatefulWidget {
  final ReporteInforme informe;

  const InformeDetalleModal({super.key, required this.informe});

  @override
  State<InformeDetalleModal> createState() => _InformeDetalleModalState();
}

class _InformeDetalleModalState extends State<InformeDetalleModal>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<ReporteInformeDetalle> _detalles = [];
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
      List<ReporteInformeDetalle> reportesInforme = [];

      try {
        reportesInforme = await _apiService.getReportesRendicionInforme_Detalle(
          idinf: widget.informe.idInf.toString(),
        );
      } catch (apiError) {
        // fallback: dejar la lista vacía para mostrar el estado "No hay gastos"
        reportesInforme = [];
      }

      if (mounted) {
        setState(() {
          _detalles = reportesInforme;
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
        "idAd": 0,
        "idInf": widget.informe.idInf,
        "idUser": widget.informe.idUser,
        "dni": widget.informe.dni,
        "ruc": widget.informe.ruc,
        "obs": widget.informe.obs ?? "",
        "estadoActual": "EN AUDITORIA",
        "estado": "S",
        "fecCre": DateTime.now().toIso8601String(),
        "useReg": UserService().currentUserCode,
        "hostname": "",
        "fecEdit": DateTime.now().toIso8601String(),
        "useEdit": UserService().currentUserCode,
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
          "idAd": idAd, // Relación con la cabecera
          "idInf": detalless.idinf,
          "idInfDet": detalless.id, // usar idrend como id de factura
          "idRend": detalless.idrend,
          // Preferir el idUser del detalle; si no está, usar el del informe
          "idUser": detalless.iduser != 0
              ? detalless.iduser
              : widget.informe.idUser,
          // El modelo de detalle no tiene 'dni', por eso mantenemos el dni del informe
          "dni": (widget.informe.dni ?? '').toString(),
          // Usar ruc del detalle si existe, si no, el ruc del informe
          "ruc": (detalless.ruc ?? widget.informe.ruc ?? '').toString(),
          "obs": detalless.obs ?? '',
          "estadoActual": 'EN AUDITORIA',
          "estado": 'S',
          "fecCre": DateTime.now().toIso8601String(),
          "useReg": UserService().currentUserCode,
          "hostname": 'FLUTTER',
          "fecEdit": DateTime.now().toIso8601String(),
          "useEdit": UserService().currentUserCode,
          "useElim": 0,
        };

        print("📤 Enviando detalle (id: ${detalless.id}): $detallePayload");

        final detalleGuardado = await _apiService.saveRendicionAuditoriaDetalle(
          detallePayload,
        );

        if (!detalleGuardado) {
          throw Exception(
            'Error al guardar el detalle de la rendición de auditoría para id ${detalless.id}',
          );
        }

        print("✅ Detalle ${detalless.id} guardado correctamente");
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.green, // Fondo verde
          content: Row(
            children: const [
              Icon(
                Icons.check_circle,
                color: Colors.white,
              ), // Check verde (puedes dejarlo blanco si prefieres contraste)
              SizedBox(width: 10),
              Text(
                "Informe enviada correctamente",
                style: TextStyle(
                  color: Colors.white,
                ), // Texto blanco para contraste
              ),
            ],
          ),
          duration: Duration(seconds: 2),
          behavior: SnackBarBehavior
              .floating, // Hace que flote sobre el contenido (opcional)
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(8)),
          ),
        ),
      );

      Navigator.of(context).pop(true);
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
      insetPadding: const EdgeInsets.only(top: 10), // Solo margen superior
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
            title: const Text(
              'INFORME DETALLE',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
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
                                      widget.informe.titulo ??
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
                                    formatDate(widget.informe.fecCre),
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
                                      '#${widget.informe.idInf}',
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
                                    widget.informe.politica ?? 'General',
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
                              'S/ ${widget.informe.total.toStringAsFixed(2)}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.w900,
                                letterSpacing: -0.5,
                              ),
                            ),

                            const SizedBox(height: 4),

                            // Estado del informe
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
                                    widget.informe.estadoActual,
                                  ),
                                  width: 1,
                                ),
                              ),
                              child: Text(
                                widget.informe.estadoActual ?? 'Borrador',
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
                                '${widget.informe.cantidad} ${widget.informe.cantidad == 1 ? 'gasto' : 'gastos'}',
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
                    Tab(text: 'Gastos (${widget.informe.cantidad})'),
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
                                    'No hay gastos en este informe',
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
                                  '🏗️ Building card for item $index: ${detalle.proveedor}',
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
                                'ID Informe',
                                '#${widget.informe.idInf}',
                              ),
                              _buildDetailRow(
                                'Usuario',
                                widget.informe.idUser.toString(),
                              ),
                              _buildDetailRow(
                                'RUC',
                                widget.informe.ruc ?? 'N/A',
                              ),
                              _buildDetailRow(
                                'DNI',
                                widget.informe.dni ?? 'N/A',
                              ),
                            ]),
                            const SizedBox(height: 20),
                            _buildDetailSection('Estadísticas', [
                              _buildDetailRow(
                                'Total Gastos',
                                widget.informe.cantidad.toString(),
                              ),
                              _buildDetailRow(
                                'Aprobados',
                                '${widget.informe.cantidadAprobado} (${widget.informe.totalAprobado.toStringAsFixed(2)} PEN)',
                                valueColor: Colors.green,
                              ),
                              _buildDetailRow(
                                'Rechazados',
                                '${widget.informe.cantidadDesaprobado} (${widget.informe.totalDesaprobado.toStringAsFixed(2)} PEN)',
                                valueColor: Colors.red,
                              ),
                            ]),

                            const SizedBox(height: 10),
                            _buildDetailSection('Motivo de rechazo', [
                              _buildDetailRow(
                                'Motivo: ',
                                widget.informe.obs.toString(),
                              ),
                            ]),
                            if (widget.informe.nota != null &&
                                widget.informe.nota!.isNotEmpty) ...[
                              const SizedBox(height: 20),
                              _buildDetailSection('Observaciones', [
                                Text(
                                  widget.informe.nota!,
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
                          onPressed: widget.informe.estadoActual == 'EN INFORME'
                              ? () async {
                                  // Abre el modal y espera a que se cierre
                                  final result = await Navigator.of(context)
                                      .push(
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              EditarInformeModal(
                                                informe: widget.informe,
                                                gastos: _detalles,
                                              ),
                                        ),
                                      );

                                  // Si el modal devuelve true (por ejemplo tras guardar cambios), recarga los detalles
                                  if (result == true) {
                                    _loadDetalles(); // <-- Método que refresca tu lista o detalles
                                  }
                                } // Si no está en 'EN INFORME', el botón queda deshabilitado
                              : null, // 🔒 Deshabilitado si no está en estado 'Informe'
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
                          child: Text(
                            'Editar informe',
                            style: TextStyle(
                              color: widget.informe.estadoActual == 'EN INFORME'
                                  ? Colors.blue
                                  : Colors.grey, // gris cuando está bloqueado
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
                          onPressed: widget.informe.estadoActual == 'EN INFORME'
                              ? _mostrarConfirmacionEnvio //_enviarInforme
                              : null, // 🔒 Deshabilitado
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                widget.informe.estadoActual == 'EN INFORME'
                                ? Colors.green
                                : Colors.grey, // gris si bloqueado
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            elevation: 2,
                          ),
                          child: const Text(
                            'Enviar informe',
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


  Future<void> _mostrarConfirmacionEnvio() async {
    final confirmar = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text(
            'Confirmar envío',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: const Text(
            '¿Estás seguro que deseas enviar este informe?',
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false), // ❌ No
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
              onPressed: () => Navigator.of(context).pop(true), // ✅ Sí
              child: const Text('Sí, enviar'),
            ),
          ],
        );
      },
    );

    // Si confirma, llama a _actualizarAuditoria()
    if (confirmar == true) {
      await _enviarInforme();
    }
  }

  Widget _buildGastoCard(ReporteInformeDetalle detalle, BuildContext context) {
    return GestureDetector(
      onTap: () {
        // Abrir modal al hacer click
        showDialog(
          context: context,
          builder: (BuildContext context) {
            // Aquí pasas el detalle que necesites al modal
            return DetalleModalGasto(id: detalle.idrend.toString());
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
              width: 20,
              height: 20,
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
                    detalle.proveedor ??
                        detalle.ruc ??
                        'Proveedor no especificado',
                    maxLines: 1,
                    style: const TextStyle(
                      fontSize: 12,
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
                  Row(
                    children: [
                      Text(
                        formatDate(detalle.fecha),
                        style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                      ),
                      SizedBox(width: 8), // Espacio entre los textos
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 0,
                          vertical: 0,
                        ), // Espaciado interno
                        decoration: BoxDecoration(
                          color: Colors.red, // Fondo del texto
                          borderRadius: BorderRadius.circular(
                            6,
                          ), // Bordes redondeados
                        ),
                        child: Text(
                          '${diferenciaEnDias(detalle.fecha.toString(), detalle.feccre.toString())} DIAS',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.white, // Color del texto
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Monto y estado
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${detalle.total.toStringAsFixed(2)} ${detalle.moneda ?? 'PEN'}',
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
                    color: getStatusColor(detalle.estadoactual),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    detalle.estadoactual ?? 'Sin estado',
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

  Widget _buildDetailRow(
    String label,
    String value, {
    Color? valueColor, // 👈 parámetro opcional
  }) {
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
              style: TextStyle(
                fontSize: 14,
                color: valueColor ?? Colors.black87, // 👈 usa el color dinámico
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
