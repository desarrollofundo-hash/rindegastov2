import 'package:flu2/models/reporte_auditioria_model.dart';
import 'package:flu2/models/reporte_auditoria_detalle.dart';
import 'package:flu2/models/reporte_model.dart';
import 'package:flu2/screens/informes/detalle_informe_screen.dart';
import 'package:flu2/utils/navigation_utils.dart';
import 'package:flu2/widgets/detalle_modal_gasto.dart';
import 'package:flu2/widgets/edit_reporte_modal.dart';
import 'package:flu2/widgets/editar_auditoria_modal.dart';
import 'package:flutter/material.dart';
import '../models/reporte_informe_model.dart';
import '../models/reporte_informe_detalle.dart';
import '../services/api_service.dart';
import '../services/user_service.dart';
import '../services/company_service.dart';
import 'editar_informe_modal.dart';

class AuditoriaDetalleModal extends StatefulWidget {
  final ReporteAuditoria auditoria;

  const AuditoriaDetalleModal({super.key, required this.auditoria});

  @override
  State<AuditoriaDetalleModal> createState() => _AuditoriaDetalleModalState();
}

class _AuditoriaDetalleModalState extends State<AuditoriaDetalleModal>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<ReporteAuditoriaDetalle> _detalles = [];
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
      List<ReporteAuditoriaDetalle> reportesAuditoria = [];

      try {
        reportesAuditoria = await _apiService
            .getReportesRendicionAuditoria_Detalle(
              idAd: widget.auditoria.idAd.toString(),
            );
      } catch (apiError) {
        // fallback: dejar la lista vacía para mostrar el estado "No hay gastos"
        reportesAuditoria = [];
      }

      if (mounted) {
        setState(() {
          _detalles = reportesAuditoria;
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

  Future<void> _enviarAuditoria() async {
    try {
      setState(() => _isLoading = true);
      print("🚀 Iniciando envío de auditoría...");

      // 1️⃣ GUARDAR CABECERA (saveRendicionAuditoria)
      final cabeceraPayload = {
        "idRev": 0,
        "idAd": widget.auditoria.idAd,
        "idInf": widget.auditoria.idInf,
        "idUser": widget.auditoria.idUser,
        "dni": widget.auditoria.dni,
        "ruc": widget.auditoria.ruc,
        "obs": "",
        "estadoActual": "EN REVISION",
        "estado": "S",
        "fecCre": DateTime.now().toIso8601String(),
        "useReg": UserService().currentUserCode,
        "hostname": "FLUTTER",
        "fecEdit": DateTime.now().toIso8601String(),
        "useEdit": UserService().currentUserCode,
        "useElim": 0,
      };

      print("📤 Enviando cabecera: $cabeceraPayload");

      final idRev = await _apiService.saveRendicionRevision(cabeceraPayload);
      if (idRev == null) throw Exception("Error al guardar cabecera.");

      print("✅ Cabecera guardada con idRev: $idRev");

      // 2️⃣ GUARDAR DETALLES: usamos los campos del modelo ReporteauditoriaDetalle
      if (_detalles.isEmpty) {
        print('⚠️ No hay detalles para enviar.');
      }

      for (final detalless in _detalles) {
        // Verifica si el detalle está RECHAZADO y no lo envía
        if (detalless.estadoActual == 'RECHAZADO') {
          continue; // No enviar el detalle, pasa al siguiente
        }

        final detallePayload = {
          "idRev": idRev, // Relación con la cabecera
          "idAd": detalless.idAd,
          "idAdDet": detalless.id, // usar idrend como id de factura
          "idInf": detalless.idInf,
          "idRend": detalless.idRend,
          // Preferir el idUser del detalle; si no está, usar el del auditoria
          "idUser": detalless.idUser,
          // El modelo de detalle no tiene 'dni', por eso mantenemos el dni del auditoria
          "dni": (widget.auditoria.dni ?? '').toString(),
          // Usar ruc del detalle si existe, si no, el ruc del auditoria
          "ruc": widget.auditoria.ruc ?? '',
          "obs": '',
          "estadoActual": 'EN REVISION',
          "estado": 'S',
          "fecCre": DateTime.now().toIso8601String(),
          "useReg": UserService().currentUserCode,
          "hostname": 'FLUTTER',
          "fecEdit": DateTime.now().toIso8601String(),
          "useEdit": UserService().currentUserCode,
          "useElim": 0,
        };

        print("📤 Enviando detalle con ID: ${detalless.id}: $detallePayload");

        final detalleGuardado = await _apiService.saveRendicionRevisionDetalle(
          detallePayload,
        );

        if (!detalleGuardado) {
          throw Exception(
            'Error al guardar el detalle de auditoría a revisión id ${detalless.id}',
          );
        }
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.green, // Fondo verde
          content: Row(
            children: const [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 10),
              Text("ENVIADO A REVISION", style: TextStyle(color: Colors.white)),
            ],
          ),
          duration: Duration(seconds: 2),
          behavior:
              SnackBarBehavior.floating, // Hace que flote sobre el contenido
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
      ).showSnackBar(SnackBar(content: Text("Error al enviar auditoría: $e")));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _mostrarConfirmacionHabilitar() async {
    final confirmar = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text(
            'Habilitar',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: const Text('¿Estás seguro que desea habilitar el informe?'),
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
              child: const Text('Sí, habilitar'),
            ),
          ],
        );
      },
    );

    // Si confirma, llama a _actualizarAuditoria()
    if (confirmar == true) {
      await _habilitarAuditoria();
    }
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
            '¿Estás seguro que deseas enviar este informe a revisión?',
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
      await _enviarAuditoriaRevision();
    }
  }

  Future<void> _habilitarAuditoria() async {
    try {
      setState(() => _isLoading = true);
      print("🚀 Iniciando envío de auditoría...");

      // 1️⃣ GUARDAR CABECERA (saveRendicionAuditoria)
      final cabeceraPayload = {
        "idRev": widget.auditoria.idRev,
        "idAd": widget.auditoria.idAd,
        "idInf": widget.auditoria.idInf,
        "idUser": widget.auditoria.idUser,
        "dni": widget.auditoria.dni,
        "ruc": widget.auditoria.ruc,
        "obs": widget.auditoria.obs,
        "estadoActual": "EN AUDITORIA",
        "estado": "S",
        "fecCre": DateTime.now().toIso8601String(),
        "useReg": UserService().currentUserCode,
        "hostname": "FLUTTER",
        "fecEdit": DateTime.now().toIso8601String(),
        "useEdit": UserService().currentUserCode,
        "useElim": 0,
      };

      print("📤 Id Rev: $widget.auditoria.idRev");

      //final idrendicion;
      final idRev;
      if (widget.auditoria.idRev == 0) {
        idRev = await _apiService.saveRendicionRevision(cabeceraPayload);
        if (idRev == null) throw Exception("Error al guardar cabecera.");
      } else {
        idRev = widget.auditoria.idRev;
      }

      print("📤 Id Rev despues: $idRev");
      // 2️⃣ GUARDAR DETALLES: usamos los campos del modelo ReporteauditoriaDetalle
      if (_detalles.isEmpty) {
        print('⚠️ No hay detalles para enviar.');
      }

      for (final detalless in _detalles) {
        // Verifica si el detalle está RECHAZADO y no lo envía
        if (detalless.estadoActual == 'RECHAZADO') {
          final detallePayload = {
            "idRev": idRev, // Relación con la cabecera
            "idAd": detalless.idAd,
            "idAdDet": detalless.id, // usar idrend como id de factura
            "idInf": detalless.idInf,
            "idRend": detalless.idRend,
            // Preferir el idUser del detalle; si no está, usar el del auditoria
            "idUser": detalless.idUser,
            // El modelo de detalle no tiene 'dni', por eso mantenemos el dni del auditoria
            "dni": (widget.auditoria.dni ?? '').toString(),
            // Usar ruc del detalle si existe, si no, el ruc del auditoria
            "ruc": widget.auditoria.ruc ?? '',
            "obs": widget.auditoria.obsRechazo,
            "estadoActual": 'EN AUDITORIA',
            "estado": 'S',
            "fecCre": DateTime.now().toIso8601String(),
            "useReg": UserService().currentUserCode,
            "hostname": 'FLUTTER',
            "fecEdit": DateTime.now().toIso8601String(),
            "useEdit": UserService().currentUserCode,
            "useElim": 0,
          };

          print("📤 Enviando detalle con ID: ${detalless.id}: $detallePayload");

          final detalleGuardado = await _apiService
              .saveRendicionRevisionDetalle(detallePayload);

          if (!detalleGuardado) {
            throw Exception(
              'Error al guardar el detalle de auditoría a revisión id ${detalless.id}',
            );
          }
        }
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.green, // Fondo verde
          content: Row(
            children: const [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 10),
              Text("INFORME HABILITADO", style: TextStyle(color: Colors.white)),
            ],
          ),
          duration: Duration(seconds: 2),
          behavior:
              SnackBarBehavior.floating, // Hace que flote sobre el contenido
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
      ).showSnackBar(SnackBar(content: Text("Error al enviar auditoría: $e")));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _enviarAuditoriaRevision() async {
    try {
      setState(() => _isLoading = true);
      print("🚀 Iniciando envío de auditoría...");

      // 1️⃣ GUARDAR CABECERA (saveRendicionAuditoria)
      final cabeceraPayload = {
        "idRev": widget.auditoria.idRev,
        "idAd": widget.auditoria.idAd,
        "idInf": widget.auditoria.idInf,
        "idUser": widget.auditoria.idUser,
        "dni": widget.auditoria.dni,
        "ruc": widget.auditoria.ruc,
        "obs": widget.auditoria.obs,
        "estadoActual": "EN REVISION",
        "estado": "S",
        "fecCre": DateTime.now().toIso8601String(),
        "useReg": UserService().currentUserCode,
        "hostname": "FLUTTER",
        "fecEdit": DateTime.now().toIso8601String(),
        "useEdit": UserService().currentUserCode,
        "useElim": 0,
      };

      print("📤 Id Rev: $widget.auditoria.idRev");

      //final idrendicion;
      final idRev;
      if (widget.auditoria.idRev == 0) {
        idRev = await _apiService.saveRendicionRevision(cabeceraPayload);
        if (idRev == null) throw Exception("Error al guardar cabecera.");
      } else {
        idRev = widget.auditoria.idRev;
      }

      print("📤 Id Rev despues: $idRev");
      // 2️⃣ GUARDAR DETALLES: usamos los campos del modelo ReporteauditoriaDetalle
      if (_detalles.isEmpty) {
        print('⚠️ No hay detalles para enviar.');
      }

      for (final detalless in _detalles) {
        // Verifica si el detalle está RECHAZADO y no lo envía
        //if (detalless.estadoActual == 'RECHAZADO') {
        final detallePayload = {
          "idRev": idRev, // Relación con la cabecera
          "idAd": detalless.idAd,
          "idAdDet": detalless.id, // usar idrend como id de factura
          "idInf": detalless.idInf,
          "idRend": detalless.idRend,
          // Preferir el idUser del detalle; si no está, usar el del auditoria
          "idUser": detalless.idUser,
          // El modelo de detalle no tiene 'dni', por eso mantenemos el dni del auditoria
          "dni": (widget.auditoria.dni ?? '').toString(),
          // Usar ruc del detalle si existe, si no, el ruc del auditoria
          "ruc": widget.auditoria.ruc ?? '',
          "obs": widget.auditoria.obsRechazo,
          "estadoActual": 'EN REVISION',
          "estado": 'S',
          "fecCre": DateTime.now().toIso8601String(),
          "useReg": UserService().currentUserCode,
          "hostname": 'FLUTTER',
          "fecEdit": DateTime.now().toIso8601String(),
          "useEdit": UserService().currentUserCode,
          "useElim": 0,
        };

        print("📤 Enviando detalle con ID: ${detalless.id}: $detallePayload");

        final detalleGuardado = await _apiService.saveRendicionRevisionDetalle(
          detallePayload,
        );

        if (!detalleGuardado) {
          throw Exception(
            'Error al guardar el detalle de auditoría a revisión id ${detalless.id}',
          );
        }
        //}
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.green, // Fondo verde
          content: Row(
            children: const [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 10),
              Text("ENVIADO A REVISION", style: TextStyle(color: Colors.white)),
            ],
          ),
          duration: Duration(seconds: 2),
          behavior:
              SnackBarBehavior.floating, // Hace que flote sobre el contenido
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
      ).showSnackBar(SnackBar(content: Text("Error al enviar auditoría: $e")));
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
            elevation: 0.1,
            leading: IconButton(
              icon: const Icon(Icons.more_horiz, color: Colors.grey),
              onPressed: () => Navigator.of(context).pop(true),
            ),
            title: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 2),
                const Text(
                  'DETALLE AUDITORIA',
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
                        fontSize: 13,
                        color: Colors.blue,
                        fontStyle: FontStyle.normal,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      widget.auditoria.usuario.toString(), // ← valor dinámico
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
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
                                      widget.auditoria.titulo ??
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
                                      widget.auditoria.fecCre.toString(),
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
                                      '#${widget.auditoria.idInf}',
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
                                    widget.auditoria.politica ?? 'General',
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
                              'S/ ${widget.auditoria.total.toStringAsFixed(2)}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.w900,
                                letterSpacing: -0.5,
                              ),
                            ),

                            const SizedBox(height: 4),

                            // Estado del auditoria
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
                                    widget.auditoria.estadoActual,
                                  ),
                                  width: 1,
                                ),
                              ),
                              child: Text(
                                widget.auditoria.estadoActual ?? 'Borrador',
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
                                '${widget.auditoria.cantidad} ${widget.auditoria.cantidad == 1 ? 'gasto' : 'gastos'}',
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
                    Tab(text: 'Gastos (${widget.auditoria.cantidad})'),
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
                                    'No hay gastos en este auditoria',
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
                                '#${widget.auditoria.idInf}',
                              ),
                              _buildDetailRow(
                                'RUC',
                                widget.auditoria.ruc ?? 'N/A',
                              ),
                              _buildDetailRow(
                                'DNI',
                                widget.auditoria.dni ?? 'N/A',
                              ),
                            ]),
                            const SizedBox(height: 20),
                            _buildDetailSection('Estadísticas', [
                              _buildDetailRow(
                                'Total Gastos',
                                widget.auditoria.cantidad.toString(),
                              ),
                              _buildDetailRow(
                                'Aprobados',
                                '${widget.auditoria.cantidadAprobado} (${widget.auditoria.totalAprobado.toStringAsFixed(2)} PEN)',
                                valueColor: Colors.green,
                              ),
                              _buildDetailRow(
                                'Rechazados',
                                '${widget.auditoria.cantidadDesaprobado} (${widget.auditoria.totalDesaprobado.toStringAsFixed(2)} PEN)',
                                valueColor: Colors.red,
                              ),
                            ]),

                            const SizedBox(height: 10),
                            _buildDetailSection('Motivo de rechazo', [
                              _buildDetailRow(
                                'Motivo: ',
                                widget.auditoria.obsRechazo.toString(),
                              ),
                            ]),

                            if (widget.auditoria.nota != null &&
                                widget.auditoria.nota!.isNotEmpty) ...[
                              const SizedBox(height: 20),
                              _buildDetailSection('Observaciones', [
                                Text(
                                  widget.auditoria.nota!,
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
                      // Botón Habilitar
                      if (widget.auditoria.estadoActual == 'RECHAZADO')
                        Expanded(
                          child: OutlinedButton(
                            onPressed:
                                _mostrarConfirmacionHabilitar, //_habilitarAuditoria,
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
                              'Habilitar',
                              style: TextStyle(
                                color: Colors.blue,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      const SizedBox(width: 16),

                      // Botón Editar
                      if (widget.auditoria.estadoActual != 'RECHAZADO')
                        Expanded(
                          child: OutlinedButton(
                            onPressed:
                                widget.auditoria.estadoActual ==
                                        'EN AUDITORIA' ||
                                    widget.auditoria.estadoActual == 'RECHAZADO'
                                ? () async {
                                    // Abre el modal y espera a que se cierre
                                    final result = await Navigator.of(context)
                                        .push(
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                EditarAuditoriaModal(
                                                  auditoria: widget.auditoria,
                                                  detalles: _detalles,
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
                              'Editar auditoria',
                              style: TextStyle(
                                color:
                                    widget.auditoria.estadoActual ==
                                            'EN AUDITORIA' ||
                                        widget.auditoria.estadoActual ==
                                            'RECHAZADO'
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
                          onPressed:
                              widget.auditoria.estadoActual == 'EN AUDITORIA'
                              ? _mostrarConfirmacionEnvio //_enviarAuditoria
                              : null, // 🔒 Deshabilitado
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                widget.auditoria.estadoActual == 'EN AUDITORIA'
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

  /*
  Future<void> _habilitarAuditoria() async {
    try {
      setState(() => _isLoading = true);
      print("🚀 habilitando auditoría...");

      // 2️⃣ GUARDAR DETALLES: usamos los campos del modelo ReporteauditoriaDetalle
      if (_detalles.isEmpty) {
        print('⚠️ No hay detalles para enviar.');
      }

      for (final detalless in _detalles) {
        // Verifica si el detalle está RECHAZADO y no lo envía
        if (detalless.estadoActual == 'RECHAZADO') {
          final detallePayload = {
            "idRev": detalless.idRev, // Relación con la cabecera
            "idAd": detalless.idAd,
            "idAdDet": detalless.id, // usar idrend como id de factura
            "idInf": detalless.idInf,
            "idRend": detalless.idRend,
            // Preferir el idUser del detalle; si no está, usar el del auditoria
            "idUser": detalless.idUser,
            // El modelo de detalle no tiene 'dni', por eso mantenemos el dni del auditoria
            "dni": (widget.auditoria.dni ?? '').toString(),
            // Usar ruc del detalle si existe, si no, el ruc del auditoria
            "ruc": widget.auditoria.ruc ?? '',
            "obs": '',
            "estadoActual": 'HABILITADO',
            "estado": 'S',
            "fecCre": DateTime.now().toIso8601String(),
            "useReg": UserService().currentUserCode,
            "hostname": 'FLUTTER',
            "fecEdit": DateTime.now().toIso8601String(),
            "useEdit": UserService().currentUserCode,
            "useElim": 0,
          };

          print("📤 Habilitando: ${detalless.id}: $detallePayload");

          final detalleGuardado = await _apiService
              .saveRendicionRevisionDetalle(detallePayload);

          if (!detalleGuardado) {
            throw Exception('Error al habilitar auditoría ${detalless.id}');
          }
        }
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.green, // Fondo verde
          content: Row(
            children: const [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 10),
              Text("INFORME HABILITADO", style: TextStyle(color: Colors.white)),
            ],
          ),
          duration: Duration(seconds: 2),
          behavior:
              SnackBarBehavior.floating, // Hace que flote sobre el contenido
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(8)),
          ),
        ),
      );

      Navigator.of(context).pop(true);
    } catch (e, stack) {
      print("❌ Error al habilitar informe: $e");
      print(stack);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error al habilitar auditoría: $e")),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }
*/

  Widget _buildGastoCard(
    ReporteAuditoriaDetalle detalle,
    BuildContext context,
  ) {
    return GestureDetector(
      onTap: () {
        // Abrir modal al hacer click
        showDialog(
          context: context,
          builder: (BuildContext context) {
            // Aquí pasas el detalle que necesites al modal
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
            GestureDetector(
              onTap: widget.auditoria.estadoActual == 'EN AUDITORIA'
                  ? () {
                      _mostrarEditarReporte(detalle.toReporte());
                    }
                  : null, // 🔒 Si no está en AUDITORIA, no hace nada
              child: Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: widget.auditoria.estadoActual == 'EN AUDITORIA'
                        ? Colors.green
                        : Colors.grey, // cambia color si está deshabilitado
                  ),
                ),
                child: Icon(
                  Icons.edit,
                  color: widget.auditoria.estadoActual == 'EN AUDITORIA'
                      ? Colors.green
                      : Colors.grey, // gris si está deshabilitado
                  size: 30,
                ),
              ),
            ),

            const SizedBox(
              width: 16,
            ), // Espacio entre el ícono y el siguiente elemento
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
                          '${diferenciaEnDias(detalle.fecha.toString(), detalle.fecCre.toString())} DIAS',
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

  void _mostrarEditarReporte(Reporte reporte) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) => EditReporteModal(reporte: reporte),
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

  /*
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
*/
}
