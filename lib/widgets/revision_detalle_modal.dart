import 'package:flu2/models/reporte_auditioria_model.dart';
import 'package:flu2/models/reporte_revision_detalle.dart';
import 'package:flu2/models/reporte_revision_model.dart';
import 'package:flu2/models/user_company.dart';
import 'package:flu2/services/user_service.dart';
import 'package:flu2/utils/navigation_utils.dart';
import 'package:flu2/widgets/detalle_modal_gasto.dart';
import 'package:flu2/widgets/editar_auditoria_modal.dart';
import 'package:flu2/widgets/editar_revision_modal.dart';
import 'package:flutter/material.dart';
import '../models/reporte_auditoria_detalle.dart';
import '../services/api_service.dart';

class RevisionDetalleModal extends StatefulWidget {
  final ReporteRevision revision; // callback opcional

  const RevisionDetalleModal({super.key, required this.revision});

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

  final _notaController = TextEditingController();

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
              //para poder llamar el detalle de revision
              idrev: widget.revision.idRev.toString(),
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

  /* 
  Future<void> _mostrarConfirmacionEnvio() async {
    final confirmar = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return AlertDialog(
          icon: const Icon(
            Icons.check_circle_outline,
            size: 32,
            color: Colors.blue,
          ),
          title: const Text(
            'Confirmar Aprobación',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
            textAlign: TextAlign.center,
          ),

          content: const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '¿Desea aprobar el informe?',
                style: TextStyle(fontSize: 16),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 8),
              Text(
                'Una vez aprobado, no podrás realizar modificaciones.',
                style: TextStyle(fontSize: 14, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
            ],
          ),

          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 8, // Sombra más pronunciada
          actionsAlignment: MainAxisAlignment.spaceBetween,
          actions: [
            // Botón Cancelar - Secundario
            OutlinedButton(
              onPressed: () => Navigator.of(context).pop(false),
              style: OutlinedButton.styleFrom(
                foregroundColor: isDark ? Colors.grey[400] : Colors.grey,
                side: BorderSide(
                  color: isDark ? Colors.grey[600]! : Colors.grey,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
              ),
              child: const Text('Cancelar'),
            ),

            // Botón Confirmar - Primario
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue, // Color más profesional
                foregroundColor: Colors.white,
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.check, size: 18),
                  SizedBox(width: 6),
                  Text('Aprobar '),
                ],
              ),
            ),
          ],
        );
      },
    );

    // Si confirma, llama a _actualizarAuditoria()
    if (confirmar == true) {
      await _aprobarDocumento();
    }
  }
 */
  Future<void> _mostrarConfirmacionEnvio() async {
    final confirmar = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return AlertDialog(
          icon: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: 1.0),
            duration: const Duration(milliseconds: 1800),
            curve: Curves.easeOutBack,
            builder: (context, scale, child) {
              return Transform.scale(
                scale: scale,
                child: const Icon(
                  Icons.check_circle_outline,
                  size: 36,
                  color: Colors.blue,
                ),
              );
            },
          ),

          title: const Text(
            'Confirmar Aprobación',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
            textAlign: TextAlign.center,
          ),

          content: const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '¿Desea aprobar el informe?',
                style: TextStyle(fontSize: 16),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 8),
              Text(
                'Una vez aprobado, no podrás realizar modificaciones.',
                style: TextStyle(fontSize: 14, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
            ],
          ),

          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 8,
          actionsAlignment: MainAxisAlignment.spaceBetween,
          actions: [
            OutlinedButton(
              onPressed: () => Navigator.of(context).pop(false),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.grey,
                side: const BorderSide(color: Colors.grey),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
              ),
              child: const Text('Cancelar'),
            ),

            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.check, size: 18),
                  SizedBox(width: 6),
                  Text('Aprobar'),
                ],
              ),
            ),
          ],
        );
      },
    );
    // Si confirma, llama a _actualizarAuditoria()
    if (confirmar == true) {
      await _aprobarDocumento();
    }
  }

  Future<void> _aprobarDocumento() async {
    try {
      setState(() => _isLoading = true);
      print("🚀 Iniciando envío de informe...");

      for (final detalless in _detalles) {
        final detallePayload = {
          "idRev": detalless.idRev, // Relación con la cabecera
          "idAd": widget.revision.idAd,
          "idAdDet": detalless.idAdDet, // usar idrend como id de factura
          "idInf": detalless.idInf,
          "idRend": detalless.idRend,
          // Preferir el idUser del detalle; si no está, usar el del informe
          "idUser": detalless.idUser,
          // El modelo de detalle no tiene 'dni', por eso mantenemos el dni del revision
          "dni": (widget.revision.dni ?? '').toString(),
          // Usar ruc del detalle si existe, si no, el ruc del revision
          "ruc": widget.revision.ruc.toString(),
          "obs": _notaController.text,
          "estadoActual": 'APROBADO',
          "estado": 'S',
          "fecCre": DateTime.now().toIso8601String(),
          "useReg": UserService().currentUserCode,
          "hostname": 'FLUTTER',
          "fecEdit": DateTime.now().toIso8601String(),
          "useEdit": UserService().currentUserCode,
          "useElim": 0,
        };

        print("📤 Enviando detalle (id: ${detalless.idRev}): $detallePayload");

        final detalleGuardado = await _apiService.saveRendicionRevisionDetalle(
          detallePayload,
        );

        if (!detalleGuardado) {
          throw Exception(
            'Error al guardar el detalle revision para id ${detalless.idRev}',
          );
        }

        print("✅ Detalle ${detalless.idRev} guardado correctamente");
      }

      showMessageError(context, "INFORME APROBADO");
      Navigator.of(context).pop(true);
    } catch (e, stack) {
      print("❌ Error al aprobar revision: $e");
      print(stack);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error al aprobar revision: $e")));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _apiService.dispose();
    //_notaController.dispose();
    super.dispose();
  }

  Future<void> _rechazarDocumento() async {
    try {
      setState(() => _isLoading = true);
      print("🚀 Iniciando envío...");

      for (final detalless in _detalles) {
        final detallePayload = {
          "idRev": detalless.idRev, // Relación con la cabecera
          "idAd": widget.revision.idAd,
          "idAdDet": detalless.idAdDet, // usar idrend como id de factura
          "idInf": detalless.idInf,
          "idRend": detalless.idRend,
          // Preferir el idUser del detalle; si no está, usar el del informe
          "idUser": detalless.idUser,
          // El modelo de detalle no tiene 'dni', por eso mantenemos el dni del revision
          "dni": (widget.revision.dni ?? '').toString(),
          // Usar ruc del detalle si existe, si no, el ruc del revision
          "ruc": widget.revision.ruc.toString(),
          "obs": _notaController.text,
          "estadoActual": 'RECHAZADO',
          "estado": 'S',
          "fecCre": DateTime.now().toIso8601String(),
          "useReg": UserService().currentUserCode,
          "hostname": 'FLUTTER',
          "fecEdit": DateTime.now().toIso8601String(),
          "useEdit": UserService().currentUserCode,
          "useElim": 0,
        };

        print(
          "📤 Rechazando detalle (id: ${detalless.idRev}): $detallePayload",
        );

        final detalleGuardado = await _apiService.saveRendicionRevisionDetalle(
          detallePayload,
        );

        if (!detalleGuardado) {
          throw Exception('Error al guardar el rechazo ${detalless.idRev}');
        }
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.red, // Fondo verde
          content: Row(
            children: const [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 10),
              Text("INFORME RECHAZADO ", style: TextStyle(color: Colors.white)),
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
      print("❌ Error al finalizar rechazado: $e");
      print(stack);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error al finalizar rechazo: $e")));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _mostrarDialogoComentario(BuildContext context) {
    // Controlador para el cuadro de texto();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        String comentario = '';
        String error = '';

        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.red.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.close_rounded,
                      color: Colors.red.shade700,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'MOTIVO DE RECHAZO',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 8),
                  Text(
                    'Explica brevemente el motivo del rechazo',
                    style: TextStyle(
                      fontSize: 13,
                      color: isDark ? Colors.grey[400] : Colors.grey.shade600,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _notaController,
                    onChanged: (value) {
                      setState(() {
                        comentario = value;
                        error = '';
                      });
                    },
                    maxLines: 5,
                    style: TextStyle(
                      fontSize: 14,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                    decoration: InputDecoration(
                      hintText:
                          'Ejemplo: La factura 1728 es rechazada porque...',
                      hintStyle: TextStyle(
                        fontSize: 13,
                        color: isDark ? Colors.grey[500] : Colors.grey.shade400,
                      ),
                      filled: true,
                      fillColor: isDark
                          ? Colors.grey[700]
                          : Colors.grey.shade50,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: isDark
                              ? Colors.grey[600]!
                              : Colors.grey.shade300,
                          width: 1,
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: isDark
                              ? Colors.grey[600]!
                              : Colors.grey.shade300,
                          width: 1,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: Colors.red,
                          width: 2,
                        ),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                    ),
                  ),
                  if (error.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: Colors.red.shade200,
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.info_rounded,
                            color: Colors.red.shade700,
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              error,
                              style: TextStyle(
                                color: Colors.red.shade700,
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  style: TextButton.styleFrom(
                    foregroundColor: isDark
                        ? Colors.grey[400]
                        : Colors.grey.shade600,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                  ),
                  child: const Text(
                    'CANCELAR',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (comentario.trim().length < 5) {
                      setState(() {
                        error = 'Debe escribir al menos 5 caracteres';
                      });
                    } else {
                      _rechazarDocumento();
                      Navigator.pop(context);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red.shade600,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    elevation: 2,
                  ),
                  child: const Text(
                    'RECHAZAR',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                  ),
                ),
              ],
              actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              elevation: 8,
            );
            /* return AlertDialog(
              title: const Text('MOTIVO DE RECHAZO'),
              backgroundColor: isDark ? Colors.grey[800] : Colors.white,
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: _notaController,
                    onChanged: (value) {
                      setState(() {
                        comentario = value;
                        error = ''; // Limpia el error al escribir
                      });
                    },
                    decoration: const InputDecoration(
                      hintText:
                          'Ejemplo: la factura 1728 es rechazada porque ...',
                    ),
                    maxLines: 4,
                  ),
                  if (error.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(
                        error,
                        style: const TextStyle(color: Colors.red, fontSize: 13),
                      ),
                    ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    if (comentario.trim().length < 5) {
                      setState(() {
                        error = 'Debe escribir al menos 5 caracteres';
                      });
                    } else {
                      _rechazarDocumento();
                      Navigator.pop(context);
                    }
                  },
                  child: const Text('ACEPTAR'),
                ),
              ],
            ); */
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

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
          backgroundColor: isDark ? Colors.grey[900] : Colors.grey[50],
          appBar: AppBar(
            backgroundColor: isDark ? Colors.grey[850] : Colors.white,
            elevation: 0.1,
            leadingWidth: 50,
            titleSpacing: 12,
            toolbarHeight: 80,
            title: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 4),
                Text(
                  'DETALLE REVISIÓN',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 4),
                Row(
                  mainAxisSize: MainAxisSize.max,
                  mainAxisAlignment: MainAxisAlignment.center,
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
                    Expanded(
                      child: Text(
                        widget.revision.usuario.toString(), // ← valor dinámico
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: Colors.white,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 4),
                Row(
                  mainAxisSize: MainAxisSize.max,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'AUDITOR: ',
                      style: TextStyle(
                        fontSize: 12,
                        color: Color.fromARGB(255, 9, 136, 13),
                        fontStyle: FontStyle.normal,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        widget.revision.usuarioAuditor
                            .toString(), // ← valor dinámico
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Colors.black,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 4),
              ],
            ),
            centerTitle: true,
            actions: [
              IconButton(
                icon: Icon(
                  Icons.close,
                  color: isDark ? Colors.white70 : Colors.grey,
                ),
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
                    padding: const EdgeInsets.fromLTRB(12, 4, 12, 4),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,

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
                color: isDark ? Colors.grey[850] : Colors.white,
                child: TabBar(
                  controller: _tabController,
                  labelColor: Colors.indigo,
                  unselectedLabelColor: isDark
                      ? Colors.grey[400]
                      : Colors.grey[600],
                  indicatorColor: Colors.indigo,
                  indicatorWeight: 3,
                  dividerColor: Colors.grey.withOpacity(0.4),
                  dividerHeight: 0.5,
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
                      color: isDark ? Colors.grey[900] : Colors.grey[50],
                      child: Builder(
                        builder: (context) {
                          print(
                            '📱 Building Gastos Tab - Loading: $_isLoading, Items: ${_detalles.length}',
                          );

                          if (_isLoading) {
                            return Center(
                              child: CircularProgressIndicator(
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.blue,
                                ),
                                backgroundColor: isDark
                                    ? Colors.grey[700]
                                    : null,
                              ),
                            );
                          }

                          if (_detalles.isEmpty) {
                            return Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.receipt_long,
                                    size: 64,
                                    color: isDark
                                        ? Colors.grey[400]
                                        : Colors.grey,
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'No hay gastos en esta auditoria',
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: isDark
                                          ? Colors.grey[400]
                                          : Colors.grey,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  /* ElevatedButton(
                                    onPressed: _loadDetalles,
                                    child: const Text('Recargar'),
                                  ), */
                                  ElevatedButton.icon(
                                    onPressed: _loadDetalles,
                                    icon: const Icon(Icons.refresh, size: 20),
                                    label: const Text(
                                      'Recargar',
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.blue,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 24,
                                        vertical: 12,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      elevation: 2,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }

                          return RefreshIndicator(
                            backgroundColor: isDark
                                ? Colors.grey[800]
                                : Colors.white,
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
                      color: isDark ? Colors.grey[900] : Colors.grey[50],
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
                                'RUC',
                                widget.revision.ruc ?? 'N/A',
                              ),
                              _buildDetailRow(
                                'DNI',
                                widget.revision.dni ?? 'N/A',
                              ),
                            ]),
                            const SizedBox(height: 10),
                            _buildDetailSection('Estadísticas', [
                              _buildDetailRow(
                                'Total Gastos',
                                widget.revision.cantidad.toString(),
                              ),
                              _buildDetailRow(
                                'Aprobados',
                                '${widget.revision.cantidadAprobado} (${widget.revision.totalAprobado.toStringAsFixed(2)} PEN)',
                                valueColor: Colors.green,
                              ),
                              _buildDetailRow(
                                'Rechazados',
                                '${widget.revision.cantidadDesaprobado} (${widget.revision.totalDesaprobado.toStringAsFixed(2)} PEN)',
                                valueColor: Colors.red,
                              ),
                            ]),

                            const SizedBox(height: 10),
                            _buildDetailSection('Motivo de rechazo', [
                              _buildDetailRow(
                                'Motivo: ',
                                widget.revision.obs.toString(),
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
                color: isDark ? Colors.grey[850] : Colors.white,
                padding: const EdgeInsets.all(20),
                child: SafeArea(
                  top: false,
                  child: Row(
                    children: [
                      // Botón Editar
                      Expanded(
                        child: OutlinedButton(
                          onPressed:
                              widget.revision.estadoActual == 'EN REVISION'
                              ? () => _mostrarDialogoComentario(context)
                              : null,

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
                            'RECHAZAR',
                            style: TextStyle(
                              color:
                                  widget.revision.estadoActual == 'EN REVISION'
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
                              widget.revision.estadoActual == 'EN REVISION'
                              ? _mostrarConfirmacionEnvio //_aprobarDocumento
                              : null, // 🔒 Deshabilitado
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                widget.revision.estadoActual == 'EN REVISION'
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
                            'APROBAR',
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: () {
        // 👈 Agregar debugging para verificar el ID
        print('📱 Abriendo detalle del gasto con idAdDet: ${detalle.idAdDet}');
        print('📱 Abriendo detalle del gasto con idRend: ${detalle.idRend}');
        print('📱 Abriendo detalle del gasto con idInf: ${detalle.idInf}');
        print('📱 Datos completos del detalle: $detalle');
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
          color: isDark ? Colors.grey[800] : Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: isDark ? Colors.black26 : Colors.grey.withOpacity(0.1),
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
                color: isDark ? Colors.grey[700] : Colors.blue[50],
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isDark ? Colors.grey[600]! : Colors.blue[200]!,
                  width: 1.5,
                ),
              ),
              child: Icon(
                Icons.receipt_long,
                color: isDark ? Colors.grey[400] : Colors.blue[600],
                size: 20,
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
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 0),
                  Text(
                    detalle.categoria != null && detalle.categoria!.isNotEmpty
                        ? '${detalle.categoria}'
                        : 'Sin categoría',
                    style: TextStyle(
                      fontSize: 14,
                      color: isDark ? Colors.grey[400] : Colors.grey[600],
                    ),
                  ),
                  Row(
                    children: [
                      Text(
                        formatDate(detalle.fecha),
                        style: TextStyle(
                          fontSize: 14,
                          color: isDark ? Colors.grey[400] : Colors.grey[600],
                        ),
                      ),
                      SizedBox(width: 8), // Espacio entre los textos
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 2,
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
                            fontWeight: FontWeight.w600,
                            color: Colors.white, // Color del texto
                            fontFamily: 'Poppins',
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[800] : Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black26 : Colors.grey.withOpacity(0.1),
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
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black87,
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

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
                color: isDark ? Colors.grey[400] : Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 14,
                color:
                    valueColor ??
                    (isDark
                        ? Colors.white
                        : Colors.black87), // 👈 usa el color dinámico
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
