import 'package:flu2/models/gasto_model.dart';
import 'package:flu2/models/reporte_model.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/reporte_informe_model.dart';
import '../models/reporte_informe_detalle.dart';
import '../services/api_service.dart';
import '../services/user_service.dart';
import '../services/company_service.dart';
import '../utils/navigation_utils.dart';

class EditarInformeModal extends StatefulWidget {
  final ReporteInforme informe;
  final List<ReporteInformeDetalle> gastos;

  const EditarInformeModal({
    super.key,
    required this.informe,
    required this.gastos,
  });

  @override
  State<EditarInformeModal> createState() => _EditarInformeModalState();
}

class _EditarInformeModalState extends State<EditarInformeModal> {
  String filtroSeleccionado = 'Todos';
  List<ReporteInformeDetalle> gastosFiltrados = [];
  Map<int, bool> gastosSeleccionados = {};
  bool todosMarcados = true;

  final ApiService _apiService = ApiService();

  List<Reporte> _facturasFiltradas = [];
  List<Reporte> _facturasSeleccionadas = [];
  String _searchQuery = '';
  bool _isLoadingFacturas = true;

  @override
  void initState() {
    super.initState();
    gastosFiltrados = widget.gastos;
    // Inicializar todos los gastos como seleccionados usando sus IDs
    for (var gasto in widget.gastos) {
      gastosSeleccionados[gasto.id] = true;
    }
    _loadFacturas(); // 🔹 Cargar facturas al iniciar
  }

  void _toggleTodosLosGastos() {
    setState(() {
      todosMarcados = !todosMarcados;
      for (var gasto in gastosFiltrados) {
        gastosSeleccionados[gasto.id] = todosMarcados;
      }
    });
  }

  void _toggleGastoSelection(int gastoId) {
    setState(() {
      gastosSeleccionados[gastoId] = !(gastosSeleccionados[gastoId] ?? false);
      // Verificar si todos están marcados para actualizar el estado del filtro "Todos"
      todosMarcados = gastosFiltrados.every(
        (gasto) => gastosSeleccionados[gasto.id] == true,
      );
    });
  }

  int _getGastosSeleccionadosCount() {
    return gastosSeleccionados.values
        .where((seleccionado) => seleccionado == true)
        .length;
  }

  double _getTotalSeleccionado() {
    double total = 0.0;
    for (var gasto in gastosFiltrados) {
      if (gastosSeleccionados[gasto.id] == true) {
        total += gasto.total;
      }
    }
    return total;
  }

  String _formatearFechaCorta(String? fecha) {
    if (fecha == null || fecha.isEmpty) {
      return DateFormat('yyyy-MM-dd').format(DateTime.now());
    }

    try {
      // Intentar parsear diferentes formatos de fecha
      DateTime fechaDateTime;
      if (fecha.contains('/')) {
        // Formato dd/MM/yyyy o dd/MM/yy
        List<String> partes = fecha.split('/');
        if (partes.length == 3) {
          int dia = int.parse(partes[0]);
          int mes = int.parse(partes[1]);
          int anio = int.parse(partes[2]);
          // Si el año es de 2 dígitos, convertir a 4 dígitos
          if (anio < 100) {
            anio += 2000;
          }
          fechaDateTime = DateTime(anio, mes, dia);
        } else {
          fechaDateTime = DateTime.now();
        }
      } else if (fecha.contains('-')) {
        // Formato yyyy-MM-dd
        fechaDateTime = DateTime.parse(fecha);
      } else {
        // Si no se puede parsear, usar fecha actual
        fechaDateTime = DateTime.now();
      }

      // Formatear a yyyy-MM-dd (formato ISO)
      return DateFormat('yyyy-MM-dd').format(fechaDateTime);
    } catch (e) {
      // Si hay error al parsear, usar fecha actual
      return DateFormat('yyyy-MM-dd').format(DateTime.now());
    }
  }

  Future<void> _loadFacturas() async {
    setState(() {
      _isLoadingFacturas = true;
    });

    try {
      final facturas = await _apiService.getReportesRendicionGasto(
        id: '1',
        idrend: '1',
        user: UserService().currentUserCode,
        ruc: CompanyService().companyRuc,
      );

      // Solo facturas con política del informe y en BORRADOR
      _facturasFiltradas = facturas
          .where(
            (f) =>
                f.politica == widget.informe.politica &&
                f.estadoActual == 'BORRADOR',
          )
          .toList();

      setState(() {
        _isLoadingFacturas = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingFacturas = false;
      });
      debugPrint('Error al cargar facturas: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'EDITAR INFORMES',
          style: TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.close, color: Colors.black),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Header con política
          Container(
            width: double.infinity,
            color: Colors.blue.shade50,
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
            child: Row(
              children: [
                const Text(
                  'Política',
                  style: TextStyle(
                    color: Colors.blue,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  widget.informe.politica ?? 'General',
                  style: const TextStyle(
                    color: Colors.black,
                    fontSize: 14,
                    fontWeight: FontWeight.normal,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          // Paso único
          // Título Gastos
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                const Text(
                  'Gastos',
                  style: TextStyle(
                    color: Colors.blue,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Filtro Todos con icono de filtro
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                GestureDetector(
                  onTap: _toggleTodosLosGastos,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: todosMarcados ? Colors.blue : Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          todosMarcados ? Icons.check : Icons.remove,
                          color: todosMarcados
                              ? Colors.white
                              : Colors.grey.shade600,
                          size: 16,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Todos',
                          style: TextStyle(
                            color: todosMarcados
                                ? Colors.white
                                : Colors.grey.shade600,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.tune, color: Colors.grey),
                  onPressed: () {
                    // Lógica para abrir filtros
                  },
                ),
              ],
            ),
          ),

          //  LISTA DE GASTOS
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: gastosFiltrados.length,
              itemBuilder: (context, index) {
                final gasto = gastosFiltrados[index];
                final isSelected = gastosSeleccionados[gasto.id] ?? false;

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: InkWell(
                    onTap: () => _toggleGastoSelection(gasto.id),
                    borderRadius: BorderRadius.circular(8),
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Row(
                        children: [
                          // Checkbox
                          Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? Colors.blue
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(
                                color: isSelected
                                    ? Colors.blue
                                    : Colors.grey.shade400,
                                width: 2,
                              ),
                            ),
                            child: isSelected
                                ? const Icon(
                                    Icons.check,
                                    color: Colors.white,
                                    size: 16,
                                  )
                                : null,
                          ),
                          const SizedBox(width: 12),

                          // Icono de documento
                          Container(
                            width: 20,
                            height: 20,
                            decoration: BoxDecoration(
                              color: Colors.grey.shade200,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              Icons.description,
                              color: Colors.grey.shade600,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 12),

                          // Información del gasto
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  gasto.proveedor ?? gasto.ruc ?? 'SIN RUC',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.black,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  gasto.categoria ?? 'Sin categoría...',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  _formatearFechaCorta(gasto.fecha),
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Monto y estado
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                '${gasto.total.toStringAsFixed(2)} PEN',
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: getStatusColor(gasto.estadoactual),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  gasto.estadoactual ?? 'PENDIENTE',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
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
          ),

          // ===================== FACTURAS DISPONIBLES =====================
          Container(
            width: double.infinity,
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
            child: const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Facturas disponibles',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                ),
              ),
            ),
          ),

          Expanded(
            child: _isLoadingFacturas
                ? const Center(child: CircularProgressIndicator())
                : _facturasFiltradas.isEmpty
                ? const Center(
                    child: Text(
                      'No hay facturas disponibles',
                      style: TextStyle(color: Colors.grey, fontSize: 14),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _facturasFiltradas.length,
                    itemBuilder: (context, index) {
                      final factura = _facturasFiltradas[index];
                      final isSelected = _facturasSeleccionadas.contains(
                        factura,
                      );

                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        elevation: isSelected ? 3 : 1,
                        color: isSelected ? Colors.blue.shade50 : Colors.white,
                        child: CheckboxListTile(
                          value: isSelected,
                          onChanged: (bool? value) {
                            setState(() {
                              if (value == true) {
                                _facturasSeleccionadas.add(factura);
                              } else {
                                _facturasSeleccionadas.remove(factura);
                              }
                            });
                          },
                          title: Text(
                            factura.proveedor ?? factura.ruc ?? 'SIN RUC',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: isSelected
                                  ? Colors.blue.shade700
                                  : Colors.black,
                            ),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(factura.categoria ?? 'Sin categoría'),
                              Text(
                                factura.fecha ?? 'Sin fecha',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isSelected
                                      ? Colors.blue.shade600
                                      : Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                          secondary: Container(
                            width: 80,
                            height: 40,
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? Colors.blue.shade100
                                  : Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Center(
                              child: Text(
                                'S/. ${factura.total?.toStringAsFixed(2) ?? '0.00'}',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: isSelected
                                      ? Colors.blue.shade700
                                      : Colors.grey.shade700,
                                ),
                              ),
                            ),
                          ),
                          controlAffinity: ListTileControlAffinity.leading,
                          activeColor: Colors.blue,
                        ),
                      );
                    },
                  ),
          ),

          // Footer con total y botones
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.2),
                  spreadRadius: 1,
                  blurRadius: 4,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
              top: false,
              child: Column(
                children: [
                  // Total
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Total (${_getGastosSeleccionadosCount()})',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.black,
                        ),
                      ),
                      Text(
                        '${_getTotalSeleccionado().toStringAsFixed(2)} PEN',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Botones
                  Row(
                    children: [
                      // Botón Cancelar
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(
                              color: Colors.orange,
                              width: 2,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          child: const Text(
                            'Cancelar',
                            style: TextStyle(
                              color: Colors.orange,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),

                      // Botón Guardar
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            // Lógica para guardar
                            _crearInforme();
                            _guardarFacturasSeleccionadas();
                            //Navigator.of(context).pop();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          child: const Text(
                            'Guardar',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _crearInforme() async {
    // Filtrar gastos seleccionados y no seleccionados
    final gastosSeleccionadosList = gastosFiltrados
        .where((g) => gastosSeleccionados[g.id] == true)
        .toList();
    final gastosNoSeleccionadosList = gastosFiltrados
        .where((g) => gastosSeleccionados[g.id] != true)
        .toList();

    if (gastosFiltrados.isEmpty) return;

    try {
      // Mostrar loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      int idInf = widget.informe.idInf ?? 0;

      // 1️⃣ Crear cabecera SOLO si no existe
      if (idInf == 0) {
        final primerGasto = widget.gastos.first;

        final informeData = {
          "idUser": int.tryParse(primerGasto.iduser.toString()) ?? 0,
          "dni": UserService().currentUserDni,
          "ruc": CompanyService().companyRuc,
          "titulo": widget.informe.titulo ?? "Sin título",
          "nota": widget.informe.nota ?? "",
          "politica": widget.informe.politica ?? "General",
          "obs": "",
          "estadoactual": "EN INFORME",
          "estado": "S",
          "fecCre": DateTime.now().toIso8601String(),
          "useReg": int.tryParse(UserService().currentUserCode) ?? 0,
          "hostname": "",
          "fecEdit": DateTime.now().toIso8601String(),
          "useEdit": int.tryParse(UserService().currentUserCode) ?? 0,
          "useElim": 0,
        };

        final idInf = await _apiService.saveRendicionInforme(informeData);

        if (idInf == null) {
          throw Exception('Error al guardar la cabecera del informe');
        }

        debugPrint('🆕 Informe creado con idInf: $idInf');
      } else {
        debugPrint(
          '✏️ Informe existente detectado (idInf: $idInf), actualizando detalles...',
        );
      }

      // 2️⃣ Primero limpiar o actualizar detalles antiguos (opcional)
      // Si tu API permite eliminar o actualizar los detalles previos del informe:
      // await _apiService.deleteDetallesByInforme(idInf);

      // 3️⃣ Guardar DETALLES seleccionados (estado "S")
      for (final gasto in gastosSeleccionadosList) {
        final detalleData = {
          "idInf": idInf,
          "idRend": gasto.idrend,
          "idUser": int.tryParse(UserService().currentUserCode) ?? 0,
          "ruc": CompanyService().companyRuc,
          "obs": "",
          "estadoactual": "EN INFORME",
          "estado": "S",
          "fecCre": DateTime.now().toIso8601String(),
          "useReg": int.tryParse(UserService().currentUserCode) ?? 0,
          "hostname": "FLUTTER",
          "fecEdit": DateTime.now().toIso8601String(),
          "useEdit": int.tryParse(UserService().currentUserCode) ?? 0,
          "useElim": 0,
        };

        final ok = await _apiService.saveRendicionInformeDetalle(detalleData);
        if (!ok) {
          throw Exception('Error al guardar detalle del gasto ${gasto.idrend}');
        }
      }

      // 4️⃣ Guardar DETALLES no seleccionados (estado "N")
      for (final gasto in gastosNoSeleccionadosList) {
        final detalleData = {
          "idInf": idInf,
          "idRend": gasto.idrend,
          "idUser": int.tryParse(UserService().currentUserCode) ?? 0,
          "ruc": CompanyService().companyRuc,
          "obs": "",
          "estadoactual": "EN INFORME",
          "estado": "N",
          "fecCre": DateTime.now().toIso8601String(),
          "useReg": int.tryParse(UserService().currentUserCode) ?? 0,
          "hostname": "FLUTTER",
          "fecEdit": DateTime.now().toIso8601String(),
          "useEdit": int.tryParse(UserService().currentUserCode) ?? 0,
          "useElim": 0,
        };

        final ok = await _apiService.saveRendicionInformeDetalle(detalleData);
        if (!ok) {
          throw Exception(
            'Error al guardar detalle (no seleccionado) ${gasto.idrend}',
          );
        }
      }

      // 5️⃣ Cerrar loading
      if (mounted) Navigator.of(context).pop();

      // 6️⃣ Mostrar mensaje de éxito
      if (mounted) {
        final total = gastosSeleccionadosList.length;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white, size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        idInf == 0
                            ? 'Informe creado exitosamente'
                            : 'Informe actualizado correctamente',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 4),
          ),
        );

        // Volver después de 1 seg
        Future.delayed(const Duration(seconds: 1), () {
          if (mounted) Navigator.of(context).pop(true);
        });
      }
    } catch (e) {
      if (mounted) Navigator.of(context).pop();

      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Error'),
            content: Text(
              'Error al crear/actualizar el informe: ${e.toString()}',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    }
  }

  /// Guarda únicamente los detalles de las facturas disponibles seleccionadas (check marcados)
  Future<void> _guardarFacturasSeleccionadas() async {
    if (_facturasSeleccionadas.isEmpty) {
      return;
    }

    try {
      // Mostrar loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      // 🔹 Verifica que el informe exista
      int idInf = widget.informe.idInf ?? 0;
      if (idInf == 0) {
        Navigator.of(context).pop(); // cerrar loading
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'No se puede guardar detalles sin un informe creado.',
            ),
            backgroundColor: Colors.redAccent,
          ),
        );
        return;
      }

      // 🔹 Recorre las facturas seleccionadas y guarda cada una
      for (final factura in _facturasSeleccionadas) {
        final detalleData = {
          "idInf": idInf,
          "idRend": factura.idrend,
          "idUser": int.tryParse(UserService().currentUserCode) ?? 0,
          "ruc": CompanyService().companyRuc,
          "obs": "",
          "estadoactual": "EN INFORME",
          "estado": "S", // ✅ Solo las seleccionadas van con estado S
          "fecCre": DateTime.now().toIso8601String(),
          "useReg": int.tryParse(UserService().currentUserCode) ?? 0,
          "hostname": "FLUTTER",
          "fecEdit": DateTime.now().toIso8601String(),
          "useEdit": int.tryParse(UserService().currentUserCode) ?? 0,
          "useElim": 0,
        };

        final ok = await _apiService.saveRendicionInformeDetalle(detalleData);
        if (!ok) {
          throw Exception(
            'Error al guardar detalle de la factura ${factura.idrend}',
          );
        }
      }

      // Cerrar loading
      if (mounted) Navigator.of(context).pop();

      // Mostrar éxito
    } catch (e) {
      if (mounted) Navigator.of(context).pop(); // cerrar loading
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Error'),
            content: Text(
              'Error al guardar las facturas seleccionadas: ${e.toString()}',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    }
  }
}
