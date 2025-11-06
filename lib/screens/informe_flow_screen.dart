import 'dart:math';

import 'package:flu2/services/company_service.dart';
import 'package:flutter/material.dart';
import '../models/dropdown_option.dart';
import '../models/reporte_model.dart';
import '../services/api_service.dart';
import '../services/user_service.dart';

/// Pantalla de flujo para crear un nuevo informe paso a paso
class InformeFlowScreen extends StatefulWidget {
  final String tituloInforme;
  final DropdownOption politicaSeleccionada;
  final String? nota;

  const InformeFlowScreen({
    super.key,
    required this.tituloInforme,
    required this.politicaSeleccionada,
    this.nota,
  });

  @override
  State<InformeFlowScreen> createState() => _InformeFlowScreenState();
}

class _InformeFlowScreenState extends State<InformeFlowScreen> {
  List<Reporte> _facturasDisponibles = [];
  List<Reporte> _facturasFiltradas = [];
  List<Reporte> _facturasSeleccionadas = [];
  bool _showSuccessMessage = true;
  bool _isLoadingFacturas = true;
  String? _errorFacturas;
  bool _seleccionarTodas =
      false; // Checkbox para seleccionar todas las facturas

  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  final ApiService _apiService = ApiService();

  @override
  void initState() {
    super.initState();
    _loadFacturas();
    // Mostrar mensaje de éxito por unos segundos
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _showSuccessMessage = false;
        });
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _apiService.dispose();
    super.dispose();
  }

  Future<void> _loadFacturas() async {
    setState(() {
      _isLoadingFacturas = true;
      _errorFacturas = null;
    });

    try {
      // Cargar todas las facturas del usuario
      final todasLasFacturas = await _apiService.getReportesRendicionGasto(
        id: '1',
        idrend: '1',
        user: UserService().currentUserCode,
        ruc: CompanyService().companyRuc,
      );

      // Filtrar facturas por la política seleccionada y destino "Borrador"
      final facturasFiltradas = todasLasFacturas.where((factura) {
        return factura.politica == widget.politicaSeleccionada.value &&
            factura.estadoActual == "BORRADOR";
      }).toList();

      _facturasDisponibles = facturasFiltradas;
      _facturasFiltradas = facturasFiltradas;

      setState(() {
        _isLoadingFacturas = false;
      });
    } catch (e) {
      setState(() {
        _errorFacturas = e.toString();
        _isLoadingFacturas = false;
      });
    }
  }

  void _toggleSeleccionarTodas() {
    setState(() {
      if (_seleccionarTodas) {
        // Si está marcado, seleccionar todas las facturas filtradas
        _facturasSeleccionadas = List.from(_facturasFiltradas);
      } else {
        // Si no está marcado, deseleccionar todas
        _facturasSeleccionadas.clear();
      }
    });
  }

  bool get _todasSeleccionadas {
    if (_facturasFiltradas.isEmpty) return false;
    return _facturasFiltradas.every(
      (factura) => _facturasSeleccionadas.contains(factura),
    );
  }

  bool get _algunasSeleccionadas {
    return _facturasSeleccionadas.any(
      (factura) => _facturasFiltradas.contains(factura),
    );
  }

  void _filtrarFacturas(String query) {
    setState(() {
      _searchQuery = query.toLowerCase();
      if (_searchQuery.isEmpty) {
        _facturasFiltradas = _facturasDisponibles;
      } else {
        _facturasFiltradas = _facturasDisponibles.where((factura) {
          // Filtrar por monto
          final monto = factura.total?.toString().toLowerCase() ?? '';
          // Filtrar por fecha
          final fecha = factura.fecha?.toLowerCase() ?? '';
          // Filtrar por número de factura/serie
          final numeroFactura = '${factura.serie ?? ''}-${factura.numero ?? ''}'
              .toLowerCase();
          // Filtrar por empresa/proveedor
          final empresa = factura.proveedor?.toLowerCase() ?? '';
          // Filtrar por categoría
          final categoria = factura.categoria?.toLowerCase() ?? '';
          // Filtrar por tipo de comprobante
          final tipoComprobante = factura.tipocomprobante?.toLowerCase() ?? '';

          return monto.contains(_searchQuery) ||
              fecha.contains(_searchQuery) ||
              numeroFactura.contains(_searchQuery) ||
              empresa.contains(_searchQuery) ||
              categoria.contains(_searchQuery) ||
              tipoComprobante.contains(_searchQuery);
        }).toList();
      }

      // Limpiar selecciones que ya no están en las facturas filtradas
      _facturasSeleccionadas.removeWhere(
        (factura) => !_facturasFiltradas.contains(factura),
      );
    });
  }

  void _crearInforme() async {
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

      // 1. Preparar datos para el API de cabecera
      final informeData = {
        "idUser": int.parse(UserService().currentUserCode),
        "dni": UserService().currentUserDni, // Ajustar según tu lógica
        "ruc": CompanyService().companyRuc,
        "titulo": widget.tituloInforme,
        "nota": widget.nota,
        "politica": widget.politicaSeleccionada.value,
        "obs": "",
        "estadoactual": "EN INFORME", // Estado inicial
        "estado": "S", // Activo
        "fecCre": DateTime.now().toIso8601String(),
        "useReg": int.parse(UserService().currentUserCode),
        "hostname": "", // Agregar hostname si es necesario
        "fecEdit": DateTime.now().toIso8601String(),
        "useEdit": int.parse(UserService().currentUserCode),
        "useElim": 0,
      };

      // 2. Guardar cabecera del informe
      final idInf = await _apiService.saveRendicionInforme(informeData);

      if (idInf == null) {
        throw Exception('Error al guardar la cabecera del informe');
      }

      debugPrint('🆔 IdInf obtenido: $idInf');

      // 4. Guardar detalles de cada factura seleccionada
      for (final factura in _facturasSeleccionadas) {
        final detalleData = {
          "idInf": idInf,
          "idRend": factura.idrend, // Usar idrend del modelo Reporte
          "idUser": int.parse(UserService().currentUserCode),
          "ruc": CompanyService().companyRuc,
          "obs": "",
          "estadoactual": "EN INFORME",
          "estado": "S",
          "fecCre": DateTime.now().toIso8601String(),
          "useReg": int.parse(UserService().currentUserCode),
          "hostname": "",
          "fecEdit": DateTime.now().toIso8601String(),
          "useEdit": int.parse(UserService().currentUserCode),
          "useElim": 0,
        };

        final detalleGuardado = await _apiService.saveRendicionInformeDetalle(
          detalleData,
        );

        if (!detalleGuardado) {
          throw Exception(
            'Error al guardar el detalle de la factura ${factura.idrend}',
          );
        }
      }

      // Cerrar loading
      if (mounted) Navigator.of(context).pop();

      // Mostrar mensaje de éxito
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white, size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Informe creado exitosamente',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        '${_facturasSeleccionadas.length} factura${_facturasSeleccionadas.length != 1 ? 's' : ''} agregada${_facturasSeleccionadas.length != 1 ? 's' : ''} al informe',
                        style: TextStyle(fontSize: 14, color: Colors.white),
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

        // Volver a la pantalla anterior después de un tiempo
        Future.delayed(const Duration(seconds: 1), () {
          if (mounted) {
            Navigator.of(context).pop(true);
          }
        });
      }
    } catch (e) {
      // Cerrar loading
      if (mounted) Navigator.of(context).pop();

      // Mostrar error
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Error'),
            content: Text('Error al crear el informe: ${e.toString()}'),
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

  void _mostrarModalInformeCreado() {
    final totalSeleccionado = _facturasSeleccionadas.fold<double>(
      0.0,
      (sum, factura) => sum + (factura.total ?? 0.0),
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildInformeDetalleFinal(totalSeleccionado),
    );
  }

  Widget _buildInformeDetalleFinal(double totalSeleccionado) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.40,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.only(
              top: 20,
              left: 16,
              right: 16,
              bottom: 16,
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.shade200,
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                IconButton(
                  onPressed: () {},
                  icon: const Icon(Icons.share, color: Colors.black87),
                ),
                Expanded(
                  child: Text(
                    'Informe: ${widget.tituloInforme}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                IconButton(
                  onPressed: () {
                    Navigator.of(context).pop(); // Cerrar modal
                    Navigator.of(
                      context,
                    ).pop(true); // Volver a pantalla anterior
                  },
                  icon: const Icon(Icons.close, color: Colors.black87),
                ),
              ],
            ),
          ),

          // Política
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: Colors.grey.shade50,
            child: Text(
              widget.politicaSeleccionada.value,
              style: TextStyle(
                color: Colors.blue.shade600,
                fontWeight: FontWeight.w500,
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),
          ),

          // Sección información principal (azul)
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.lightBlue.shade200, Colors.blue.shade400],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
            child: Column(
              children: [
                // Aprobador
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  color: Colors.lightBlue.shade100,
                  child: Row(
                    children: [
                      Icon(Icons.person, color: Colors.blue.shade700, size: 16),
                      const SizedBox(width: 8),
                      Text(
                        'Aprobador: Desarrollo Fundo',
                        style: TextStyle(
                          color: Colors.blue.shade700,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),

                // Información principal
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Envío: ${DateTime.now().day.toString().padLeft(2, '0')}/${DateTime.now().month.toString().padLeft(2, '0')}/${DateTime.now().year}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              widget.tituloInforme,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.orange.shade100,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              'En proceso',
                              style: TextStyle(
                                color: Colors.orange.shade700,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '${totalSeleccionado.toStringAsFixed(2)} PEN',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
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

          // Tarjetas de resumen
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Column(
                      children: [
                        const Text(
                          'Aprobados',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          '0,00 PEN',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '0 de ${_facturasSeleccionadas.length} gasto${_facturasSeleccionadas.length != 1 ? 's' : ''}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Column(
                      children: [
                        const Text(
                          'Rechazados',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          '0,00 PEN',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.red,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '0 de ${_facturasSeleccionadas.length} gasto${_facturasSeleccionadas.length != 1 ? 's' : ''}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Tabs
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade600,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Gastos (${_facturasSeleccionadas.length})',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Text(
                  'Detalle',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(width: 16),
                Text(
                  'Historial',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(width: 16),
                Text(
                  'Flujo revisión',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),

          // Lista de gastos
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _facturasSeleccionadas.length,
              itemBuilder: (context, index) {
                final factura = _facturasSeleccionadas[index];
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.receipt_long,
                          color: Colors.grey.shade600,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              factura.proveedor ?? 'Sin proveedor',
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              factura.categoria ?? 'Sin categoría',
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _formatFechaISO(factura.fecha),
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '${factura.total?.toStringAsFixed(2) ?? '0.00'} PEN',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.blue.shade600,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.orange.shade100,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'En Informe',
                              style: TextStyle(
                                color: Colors.orange.shade700,
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  String _formatFechaISO(String? fecha) {
    if (fecha == null || fecha.isEmpty) {
      return '';
    }

    try {
      // Intentar parsear la fecha en diferentes formatos comunes
      DateTime? dateTime;

      // Formato ISO completo (YYYY-MM-DDTHH:mm:ss)
      if (fecha.contains('T')) {
        dateTime = DateTime.tryParse(fecha);
      }
      // Formato con espacios (YYYY-MM-DD HH:mm:ss)
      else if (fecha.contains(' ')) {
        dateTime = DateTime.tryParse(fecha.replaceFirst(' ', 'T'));
      }
      // Solo fecha (YYYY-MM-DD)
      else if (fecha.contains('-') && fecha.length >= 10) {
        dateTime = DateTime.tryParse(fecha.substring(0, 10));
      }
      // Formato DD/MM/YYYY
      else if (fecha.contains('/')) {
        final parts = fecha.split('/');
        if (parts.length >= 3) {
          final day = parts[0].padLeft(2, '0');
          final month = parts[1].padLeft(2, '0');
          final year = parts[2];
          dateTime = DateTime.tryParse('$year-$month-$day');
        }
      }

      if (dateTime != null) {
        // Retornar en formato ISO (YYYY-MM-DD)
        return dateTime.toIso8601String().substring(0, 10);
      }

      return fecha; // Si no se pudo parsear, retornar la fecha original
    } catch (e) {
      return fecha; // En caso de error, retornar la fecha original
    }
  }

  Widget _buildNoResultsFound() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.search_off_rounded,
                size: 48,
                color: Colors.grey.shade400,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Sin resultados',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 12),
            RichText(
              textAlign: TextAlign.center,
              text: TextSpan(
                style: TextStyle(
                  fontSize: 15,
                  color: Colors.grey.shade600,
                  height: 1.4,
                ),
                children: [
                  const TextSpan(
                    text: 'No se encontraron facturas que coincidan con ',
                  ),
                  TextSpan(
                    text: '"$_searchQuery"',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Colors.blue.shade600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                _searchController.clear();
                _filtrarFacturas('');
              },
              icon: const Icon(Icons.clear_all),
              label: const Text('Limpiar búsqueda'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue.shade600,
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
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Column(
            children: [
              // Header personalizado
              _buildCustomHeader(),

              // Información de la política
              _buildPoliticaInfo(),

              // Contenido principal
              Expanded(child: _buildMainContent()),
            ],
          ),

          /*  // Mensaje de éxito flotante
          if (_showSuccessMessage) _buildSuccessMessage(), */
        ],
      ),
    );
  }

  Widget _buildCustomHeader() {
    return Container(
      padding: const EdgeInsets.only(top: 50, left: 16, right: 16, bottom: 2),
      color: Colors.white,
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.arrow_back, color: Colors.black87),
          ),
          Expanded(
            child: Text(
              'NUEVO INFORME',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPoliticaInfo() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: Colors.lightBlue.shade50,
      child: Text(
        widget.politicaSeleccionada.value,
        style: TextStyle(
          color: Colors.blue.shade700,
          fontWeight: FontWeight.w500,
          fontSize: 16,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildMainContent() {
    return _buildAgregarGastosStep();
  }

  Widget _buildSearchAndFilterBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Row(
        children: [
          // Barra de búsqueda
          Expanded(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: _searchQuery.isNotEmpty
                      ? Colors.blue.shade300
                      : Colors.grey.shade300,
                  width: _searchQuery.isNotEmpty ? 2 : 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: _searchQuery.isNotEmpty
                        ? Colors.blue.shade100.withOpacity(0.5)
                        : Colors.grey.shade200.withOpacity(0.8),
                    blurRadius: _searchQuery.isNotEmpty ? 8 : 4,
                    offset: const Offset(0, 2),
                    spreadRadius: _searchQuery.isNotEmpty ? 1 : 0,
                  ),
                ],
              ),
              child: Row(
                children: [
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: Icon(
                      _searchQuery.isNotEmpty
                          ? Icons.search
                          : Icons.search_outlined,
                      key: ValueKey(_searchQuery.isNotEmpty),
                      color: _searchQuery.isNotEmpty
                          ? Colors.blue.shade600
                          : Colors.grey.shade400,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      onChanged: _filtrarFacturas,
                      decoration: InputDecoration(
                        hintText:
                            'Buscar por monto, fecha, factura, empresa...',
                        hintStyle: TextStyle(
                          color: Colors.grey.shade500,
                          fontSize: 15,
                          fontWeight: FontWeight.w400,
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 12,
                        ),
                      ),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Colors.black87,
                      ),
                      cursorColor: Colors.blue.shade600,
                      cursorHeight: 20,
                    ),
                  ),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    child: _searchQuery.isNotEmpty
                        ? Container(
                            key: const ValueKey('clear_button'),
                            margin: const EdgeInsets.only(left: 8),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                borderRadius: BorderRadius.circular(20),
                                onTap: () {
                                  _searchController.clear();
                                  _filtrarFacturas('');
                                },
                                child: Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade100,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.close,
                                    color: Colors.grey.shade600,
                                    size: 16,
                                  ),
                                ),
                              ),
                            ),
                          )
                        : const SizedBox.shrink(key: ValueKey('empty')),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(width: 12),

          // Checkbox para seleccionar todas las facturas
          Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: () {
                setState(() {
                  _seleccionarTodas = !_todasSeleccionadas;
                  _toggleSeleccionarTodas();
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                decoration: BoxDecoration(
                  color: _todasSeleccionadas || _algunasSeleccionadas
                      ? Colors.blue.shade50
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: _todasSeleccionadas || _algunasSeleccionadas
                        ? Colors.blue.shade300
                        : Colors.grey.shade300,
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Transform.scale(
                      scale: 0.85,
                      child: Checkbox(
                        value: _todasSeleccionadas,
                        tristate: true,
                        onChanged: (value) {
                          setState(() {
                            if (value == true) {
                              // Seleccionar todas
                              _facturasSeleccionadas = List.from(
                                _facturasFiltradas,
                              );
                            } else {
                              // Deseleccionar todas
                              _facturasSeleccionadas.clear();
                            }
                          });
                        },
                        activeColor: Colors.blue.shade600,
                        checkColor: Colors.white,
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        visualDensity: VisualDensity.compact,
                      ),
                    ),
                    const SizedBox(width: 2),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Seleccionar todas',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: _todasSeleccionadas || _algunasSeleccionadas
                                ? Colors.blue.shade700
                                : Colors.grey.shade700,
                          ),
                        ),
                        if (_facturasSeleccionadas.isNotEmpty)
                          Text(
                            '${_facturasSeleccionadas.length} seleccionadas',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w400,
                              color: Colors.blue.shade600,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAgregarGastosStep() {
    return Container(
      color: Colors.grey.shade50,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSearchAndFilterBar(),
          Expanded(child: _buildFacturasContent()),
        ],
      ),
    );
  }

  Widget _buildFacturasContent() {
    if (_isLoadingFacturas) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text(
              'Cargando facturas...',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    if (_errorFacturas != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red.shade400),
            const SizedBox(height: 16),
            Text(
              'Error al cargar facturas',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.red.shade700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _errorFacturas!,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.red.shade600),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _loadFacturas,
              icon: const Icon(Icons.refresh),
              label: const Text('Reintentar'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      );
    }

    if (_facturasDisponibles.isEmpty) {
      return _buildEmptyFacturasState();
    }

    return _buildFacturasList();
  }

  Widget _buildEmptyFacturasState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Ilustración de estado vacío
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              shape: BoxShape.circle,
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Icono de factura
                Container(
                  width: 60,
                  height: 70,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade400,
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                // Icono de interrogación
                Container(
                  width: 30,
                  height: 30,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.help_outline,
                    color: Colors.grey,
                    size: 20,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Sin facturas disponibles 👀',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'No hay facturas disponibles para la política "${widget.politicaSeleccionada.value}".',
            style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: _loadFacturas,
            icon: const Icon(Icons.refresh),
            label: const Text('Recargar'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFacturasList() {
    final totalSeleccionado = _facturasSeleccionadas.fold<double>(
      0.0,
      (sum, factura) => sum + (factura.total ?? 0.0),
    );

    return Column(
      children: [
        // Header con información de selección
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            gradient: _searchQuery.isNotEmpty
                ? LinearGradient(
                    colors: [Colors.blue.shade50, Colors.blue.shade100],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  )
                : LinearGradient(
                    colors: [Colors.blue.shade50, Colors.blue.shade50],
                  ),
            border: Border(
              bottom: BorderSide(
                color: _searchQuery.isNotEmpty
                    ? Colors.blue.shade200
                    : Colors.blue.shade100,
                width: 1,
              ),
            ),
          ),
          child: Row(
            children: [
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: Icon(
                  _searchQuery.isNotEmpty
                      ? Icons.filter_list
                      : Icons.info_outline,
                  key: ValueKey(_searchQuery.isNotEmpty),
                  color: Colors.blue.shade600,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: _searchQuery.isNotEmpty
                      ? Column(
                          key: const ValueKey('search_info'),
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Resultados de búsqueda: "${_searchQuery}"',
                              style: TextStyle(
                                color: Colors.blue.shade800,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${_facturasFiltradas.length} de ${_facturasDisponibles.length} facturas • ${_facturasSeleccionadas.length} seleccionadas',
                              style: TextStyle(
                                color: Colors.blue.shade600,
                                fontSize: 12,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                          ],
                        )
                      : Text(
                          key: const ValueKey('default_info'),
                          'Selecciona las facturas (${_facturasSeleccionadas.length} )',
                          style: TextStyle(
                            color: Colors.blue.shade700,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                ),
              ),
              if (_searchQuery.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade200,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${_facturasFiltradas.length}',
                    style: TextStyle(
                      color: Colors.blue.shade800,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
        ),
        // Lista de facturas
        Expanded(
          child: _facturasFiltradas.isEmpty && _searchQuery.isNotEmpty
              ? _buildNoResultsFound()
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _facturasFiltradas.length,
                  itemBuilder: (context, index) {
                    final factura = _facturasFiltradas[index];
                    final isSelected = _facturasSeleccionadas.contains(factura);

                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      elevation: isSelected ? 4 : 1,
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
                          '${factura.proveedor ?? factura.ruc ?? 'SIN RUC'} ',
                          style: TextStyle(
                            fontWeight: FontWeight.w500,
                            color: isSelected
                                ? Colors.blue.shade700
                                : Colors.black87,
                            fontSize: 12,
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${factura.categoria ?? 'Sin categoría'}',
                              style: TextStyle(
                                color: isSelected
                                    ? Colors.blue.shade600
                                    : Colors.grey.shade600,
                                fontSize: 12,
                              ),
                            ),

                            Text(
                              _formatFechaISO(factura.fecha),
                              style: TextStyle(
                                color: isSelected
                                    ? Colors.blue.shade600
                                    : Colors.grey.shade600,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                        secondary: Container(
                          width: 80,
                          height: 20,
                          decoration: BoxDecoration(
                            color: isSelected
                                ? Colors.blue.shade100
                                : Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(3),
                          ),
                          child: Center(
                            child: Text(
                              '${factura.total?.toStringAsFixed(2) ?? '0.0'}'
                              ' ${factura.moneda ?? 'PEN'}',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: isSelected
                                    ? Colors.blue.shade700
                                    : Colors.grey.shade700,
                              ),
                              textAlign: TextAlign.center,
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

        // Total y botones
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border(top: BorderSide(color: Colors.grey.shade300)),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.shade200,
                blurRadius: 4,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: Column(
            children: [
              // Total
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Total seleccionado:',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w500,
                            color: Colors.black,
                          ),
                        ),
                        Text(
                          'S/. ${totalSeleccionado.toStringAsFixed(2)}',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: _facturasSeleccionadas.isNotEmpty
                                ? Colors.green.shade700
                                : Colors.grey.shade500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Botones
              Padding(
                padding: const EdgeInsets.all(10),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          side: BorderSide(color: Colors.grey.shade400),
                          foregroundColor: Colors.grey.shade700,
                        ),
                        child: const Text(
                          'Cancelar',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _facturasSeleccionadas.isEmpty
                            ? null
                            : _crearInforme,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _facturasSeleccionadas.isNotEmpty
                              ? Colors.green
                              : Colors.grey,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          disabledBackgroundColor: Colors.grey[300],
                          disabledForegroundColor: Colors.grey[600],
                        ),
                        child: const Text(
                          'Crear Informe',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
