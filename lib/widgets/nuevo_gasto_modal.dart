import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flu2/controllers/edit_reporte_controller.dart';
import 'package:flu2/models/apiruc_model.dart';
import 'package:flu2/models/user_company.dart';
import 'package:flu2/utils/navigation_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'package:open_filex/open_filex.dart';
import 'package:printing/printing.dart';
import '../models/dropdown_option.dart';
import '../services/api_service.dart';
import '../services/user_service.dart';
import '../services/company_service.dart';
import '../screens/home_screen.dart';
import 'nuevo_gasto_logic.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Modal para crear un nuevo gasto con todos los campos personalizados
class NuevoGastoModal extends StatefulWidget {
  final DropdownOption politicaSeleccionada;
  final VoidCallback onCancel;
  final Function(Map<String, dynamic>) onSave;

  //FOCUS NODES

  const NuevoGastoModal({
    super.key,
    required this.politicaSeleccionada,
    required this.onCancel,
    required this.onSave,
  });

  @override
  State<NuevoGastoModal> createState() => _NuevoGastoModalState();
}

class _NuevoGastoModalState extends State<NuevoGastoModal>
    with WidgetsBindingObserver {
  final _formKey = GlobalKey<FormState>();
  final ApiService _apiService = ApiService();
  final NuevoGastoLogic _logic = NuevoGastoLogic();

  final FocusNode _categoriaFocusNode = FocusNode();
  final FocusNode _tipoGastoFocusNode = FocusNode();
  final FocusNode _centroCostoFocusNode = FocusNode();
  final FocusNode _rucProveedorFocusNode = FocusNode();
  final FocusNode _razonSocialFocusNode = FocusNode();
  final FocusNode _tipoComprobanteFocusNode = FocusNode();
  final FocusNode _fechaFocusNode = FocusNode();
  final FocusNode _serieFacturaFocusNode = FocusNode();
  final FocusNode _numeroFacturaFocusNode = FocusNode();
  final FocusNode _igvFocusNode = FocusNode();
  final FocusNode _totalFocusNode = FocusNode();
  final FocusNode _origenFocusNode = FocusNode();
  final FocusNode _destinoFocusNode = FocusNode();
  final FocusNode _motivoViajeFocusNode = FocusNode();
  final FocusNode _movilidadFocusNode = FocusNode();
  final FocusNode _placaFocusNode = FocusNode();
  final FocusNode _notaFocusNode = FocusNode();

  // Controladores para todos los campos
  late TextEditingController _politicaController;
  late TextEditingController _categoriaController;
  late TextEditingController _tipoGastoController;
  //centro de costo
  late TextEditingController _centroCostoController;
  late TextEditingController _razonSocialController;
  late TextEditingController _rucProveedorController;
  late TextEditingController _rucClienteController;
  late TextEditingController _tipoComprobanteController;
  late TextEditingController _fechaController;
  late TextEditingController _serieFacturaController;
  late TextEditingController _numeroFacturaController;
  late TextEditingController _igvController;
  late TextEditingController _totalController;
  late TextEditingController _monedaController;

  late TextEditingController _origenController;
  late TextEditingController _destinoController;
  late TextEditingController _motivoViajeController;
  late TextEditingController _movilidadController;
  late TextEditingController _placaController;
  late TextEditingController _notaController;

  late final EditReporteController _controller;

  // Variables para archivos
  File? _selectedFile;
  String? _selectedFileType; // 'image' o 'pdf'
  String? _selectedFileName;
  final ImagePicker _picker = ImagePicker();

  // Variables para el lector SUNAT
  bool _isScanning = false;
  bool _hasScannedData = false;
  bool _isFormValid = false;

  // Variables para dropdowns
  List<DropdownOption> _categorias = [];
  List<DropdownOption> _tiposGasto = [];
  //dropdown centro de costo
  List<DropdownOption> _centroCosto = [];
  List<DropdownOption> _tiposMovilidad = [];
  DropdownOption? _selectedCategoria;
  DropdownOption? _selectedTipoGasto;
  DropdownOption? _selectedCentroCosto;
  DropdownOption? _selectedTipoMovilidad;
  String? _selectedComprobante;

  //bool _boolMostrar = true; // controla si se muestran los campos
  bool _validar = true; // controla si deben validarse

  ///ApiRuc
  bool _isLoadingApiRuc = false;
  String? _errorApiRuc;
  ApiRuc? _apiRucData;

  // Estados de carga
  bool _isLoading = false;
  bool _isLoadingCategorias = false;
  bool _isLoadingTiposGasto = false;

  bool _isLoadingCentrosCosto = false;
  bool _isLoadingTipoMovilidad = false;
  String? _error;

  // Opciones para moneda
  String? _selectedMoneda;
  final List<String> _monedas = ['PEN', 'USD', 'EUR'];

  final List<String> tipocomprobante = [
    'FACTURA ELECTRONICA',
    'BOLETA DE VENTA',
    'NOTA DE CREDITO',
    'NOTA DE DEBITO',
    'GUÍA DE REMISION',
    'RECIBO POR HONORARIOS',
  ];

  /*   String get fechaSQL =>
      DateFormat('yyyy-MM-dd').format(DateTime.parse(_fechaController.text));
 */
  /// Validar si el RUC del cliente (escaneado) coincide con la empresa seleccionada
  bool _isRucValid() {
    final rucClienteEscaneado = _rucClienteController.text.trim();
    final rucEmpresaSeleccionada = CompanyService().companyRuc;

    // Si no hay empresa seleccionada, no es válido
    if (rucEmpresaSeleccionada.isEmpty) {
      return false;
    }

    // Si no hay RUC del cliente escaneado, consideramos válido (para casos sin QR)
    if (rucClienteEscaneado.isEmpty) {
      return true;
    }

    // Si ambos existen, deben coincidir
    return rucClienteEscaneado == rucEmpresaSeleccionada;
  }

  bool get _boolMostrar {
    // Botón habilitado solo si RUC es válido y hay empresa seleccionada
    final empresaSeleccionada =
        CompanyService().companyRuc?.isNotEmpty ?? false;
    return _isRucValid() && empresaSeleccionada;
  }

  /// Obtener mensaje de estado del RUC del cliente
  String _getRucStatusMessage() {
    final rucClienteEscaneado = _rucClienteController.text.trim();
    final rucEmpresaSeleccionada = CompanyService().companyRuc;
    final empresaSeleccionada = CompanyService().currentUserCompany;

    if (rucClienteEscaneado.isEmpty) {
      return '❌ RUC cliente no coincide con $empresaSeleccionada';
    }

    if (rucEmpresaSeleccionada.isEmpty) {
      return '⚠️ No hay empresa seleccionada';
    }

    if (rucClienteEscaneado == rucEmpresaSeleccionada) {
      return '✅ RUC cliente coincide con $empresaSeleccionada';
    } else {
      return '❌ RUC cliente no coincide con $empresaSeleccionada';
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeControllers();
    _loadCategorias();
    _loadTiposGasto();
    _loadTipoMovilidad();
    _loadCentrosCosto();
    //_loadApiRuc(_rucController.toString());
    _addValidationListeners();
    _loadDraft(); // ✅ Cargar borrador al iniciar
  }

  void _initializeControllers() {
    // Controladores adicionales que faltaban
    _politicaController = TextEditingController(
      text: widget.politicaSeleccionada.value,
    );
    _categoriaController = TextEditingController();
    _tipoGastoController = TextEditingController(
      text: CompanyService().companyTipogasto,
    );
    _centroCostoController = TextEditingController();
    _rucProveedorController = TextEditingController();
    _razonSocialController = TextEditingController();
    _rucClienteController = TextEditingController();
    _tipoComprobanteController = TextEditingController(
      text: 'FACTURA ELECTRONICA', // Valor por defecto
    );
    _fechaController = TextEditingController();
    _serieFacturaController = TextEditingController();
    _numeroFacturaController = TextEditingController();
    _igvController = TextEditingController();
    _totalController = TextEditingController();
    _monedaController = TextEditingController(text: 'PEN'); // PEN

    _origenController = TextEditingController();
    _destinoController = TextEditingController();
    _motivoViajeController = TextEditingController();
    _movilidadController = TextEditingController(text: 'TAXI');

    _notaController = TextEditingController();
    _placaController = TextEditingController(
      text: CompanyService().companyPlaca,
    );

    // Inicializar RUC Cliente con el RUC de la empresa actual (no editable)
    // El RUC Cliente siempre debe ser el de la empresa que registra el gasto
    final companyService = CompanyService();
    final currentCompany = companyService.currentCompany;
    _rucClienteController = TextEditingController(
      text: currentCompany?.ruc ?? '',
    );

    // Configurar valores por defecto
    _selectedMoneda = 'PEN';
    _selectedComprobante = 'FACTURA ELECTRONICA';

    final isGastoMovilidad =
        widget.politicaSeleccionada.value != "GASTO DE MOVILIDAD";
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _politicaController.dispose();
    _categoriaController.dispose();
    _tipoGastoController.dispose();
    _centroCostoController.dispose();
    _rucProveedorController.dispose();
    _razonSocialController.dispose();
    _rucClienteController.dispose();
    _tipoComprobanteController.dispose();
    _fechaController.dispose();
    _serieFacturaController.dispose();
    _numeroFacturaController.dispose();

    _igvController.dispose();
    _totalController.dispose();
    _monedaController.dispose();
    _notaController.dispose();

    //movilidad
    _origenController.dispose();
    _destinoController.dispose();
    _motivoViajeController.dispose();
    _movilidadController.dispose();
    _placaController.dispose();

    super.dispose();
  }

  void _addValidationListeners() {
    _tipoComprobanteController.addListener(_validateForm);
    _fechaController.addListener(_validateForm);
    _totalController.addListener(_validateForm);
    _categoriaController.addListener(_validateForm);
    _tipoGastoController.addListener(_validateForm);
    _centroCostoController.addListener(_validateForm);
  }

  /// 🔄 Detectar cuando la app va a segundo plano y guardar borrador
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      _saveDraft(); // Guardar borrador automáticamente
    }
  }

  /// 💾 Guardar borrador en SharedPreferences
  Future<void> _saveDraft() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // ⏰ Guardar timestamp actual (marca de tiempo)
      await prefs.setInt(
        'draft_timestamp',
        DateTime.now().millisecondsSinceEpoch,
      );

      await prefs.setString('draft_categoria', _categoriaController.text);
      await prefs.setString('draft_tipoGasto', _tipoGastoController.text);
      await prefs.setString('draft_centroCosto', _centroCostoController.text);
      await prefs.setString('draft_rucProveedor', _rucProveedorController.text);
      await prefs.setString('draft_razonSocial', _razonSocialController.text);
      await prefs.setString('draft_rucCliente', _rucClienteController.text);
      await prefs.setString(
        'draft_tipoComprobante',
        _tipoComprobanteController.text,
      );
      await prefs.setString('draft_fecha', _fechaController.text);
      await prefs.setString('draft_serieFactura', _serieFacturaController.text);
      await prefs.setString(
        'draft_numeroFactura',
        _numeroFacturaController.text,
      );
      await prefs.setString('draft_igv', _igvController.text);
      await prefs.setString('draft_total', _totalController.text);
      await prefs.setString('draft_moneda', _monedaController.text);
      await prefs.setString('draft_origen', _origenController.text);
      await prefs.setString('draft_destino', _destinoController.text);
      await prefs.setString('draft_motivoViaje', _motivoViajeController.text);
      await prefs.setString('draft_movilidad', _movilidadController.text);
      await prefs.setString('draft_placa', _placaController.text);
      await prefs.setString('draft_nota', _notaController.text);
    } catch (e) {
      // Silencioso, no afecta la experiencia del usuario
    }
  }

  /// 📂 Cargar borrador desde SharedPreferences
  Future<void> _loadDraft() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Solo cargar si existe al menos un campo guardado
      final hasData = prefs.containsKey('draft_categoria');
      if (!hasData) return;

      // ⏰ Verificar si el borrador tiene menos de 30 minutos
      final timestamp = prefs.getInt('draft_timestamp');
      if (timestamp != null) {
        final savedTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
        final now = DateTime.now();
        final difference = now.difference(savedTime);

        // Si pasaron más de 30 minutos, limpiar, cerrar modal y notificar
        if (difference.inMinutes > 30) {
          await _clearDraft();

          if (mounted) {
            // Mostrar mensaje de expiración
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text(
                  '⏰ El borrador expiró (más de 30 minutos). Por favor, vuelva a llenar el formulario.',
                ),
                backgroundColor: Colors.orange,
                duration: const Duration(seconds: 4),
              ),
            );

            // Cerrar el modal automáticamente
            Navigator.of(context).pop();
          }
          return;
        }
      }

      setState(() {
        _categoriaController.text = prefs.getString('draft_categoria') ?? '';
        _tipoGastoController.text = prefs.getString('draft_tipoGasto') ?? '';
        _centroCostoController.text =
            prefs.getString('draft_centroCosto') ?? '';
        _rucProveedorController.text =
            prefs.getString('draft_rucProveedor') ?? '';
        _razonSocialController.text =
            prefs.getString('draft_razonSocial') ?? '';
        _rucClienteController.text = prefs.getString('draft_rucCliente') ?? '';
        _tipoComprobanteController.text =
            prefs.getString('draft_tipoComprobante') ?? '';
        _fechaController.text = prefs.getString('draft_fecha') ?? '';
        _serieFacturaController.text =
            prefs.getString('draft_serieFactura') ?? '';
        _numeroFacturaController.text =
            prefs.getString('draft_numeroFactura') ?? '';
        _igvController.text = prefs.getString('draft_igv') ?? '';
        _totalController.text = prefs.getString('draft_total') ?? '';
        _monedaController.text = prefs.getString('draft_moneda') ?? '';
        _origenController.text = prefs.getString('draft_origen') ?? '';
        _destinoController.text = prefs.getString('draft_destino') ?? '';
        _motivoViajeController.text =
            prefs.getString('draft_motivoViaje') ?? '';
        _movilidadController.text = prefs.getString('draft_movilidad') ?? '';
        _placaController.text = prefs.getString('draft_placa') ?? '';
        _notaController.text = prefs.getString('draft_nota') ?? '';
      });

      // Mostrar mensaje de recuperación
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('📝 Datos recuperados del borrador'),
            backgroundColor: Colors.blue,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      // Silencioso, no afecta la experiencia del usuario
    }
  }

  /// 🗑️ Limpiar borrador de SharedPreferences
  Future<void> _clearDraft() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('draft_timestamp'); // ⏰ Limpiar timestamp
      await prefs.remove('draft_categoria');
      await prefs.remove('draft_tipoGasto');
      await prefs.remove('draft_centroCosto');
      await prefs.remove('draft_rucProveedor');
      await prefs.remove('draft_razonSocial');
      await prefs.remove('draft_rucCliente');
      await prefs.remove('draft_tipoComprobante');
      await prefs.remove('draft_fecha');
      await prefs.remove('draft_serieFactura');
      await prefs.remove('draft_numeroFactura');
      await prefs.remove('draft_igv');
      await prefs.remove('draft_total');
      await prefs.remove('draft_moneda');
      await prefs.remove('draft_origen');
      await prefs.remove('draft_destino');
      await prefs.remove('draft_motivoViaje');
      await prefs.remove('draft_movilidad');
      await prefs.remove('draft_placa');
      await prefs.remove('draft_nota');
    } catch (e) {
      // Silencioso
    }
  }

  /// Validar si todos los campos obligatorios están llenos
  void _validateForm() {
    final isValid =
        _tipoComprobanteController.text.trim().isNotEmpty &&
        _fechaController.text.trim().isNotEmpty &&
        _totalController.text.trim().isNotEmpty &&
        _categoriaController.text.trim().isNotEmpty &&
        _tipoGastoController.text.trim().isNotEmpty &&
        _centroCostoController.text.trim().isNotEmpty &&
        _origenController.text.trim().isNotEmpty &&
        _destinoController.text.trim().isNotEmpty &&
        _motivoViajeController.text
            .trim()
            .isNotEmpty; // ✅ Añadida validación de RUC

    if (_isFormValid != isValid) {
      setState(() {
        _isFormValid = isValid;
      });
    }
  }

  Future<void> _loadCentrosCosto() async {
    if (mounted) {
      setState(() {
        _isLoadingCentrosCosto = true;
        _error = null;
      });
    }
    try {
      final centroCosto = await _logic.fetchCentrosCosto(
        _apiService,
        UserService().currentUserCode,
        CompanyService().currentUserCompany,
      );
      if (mounted) {
        setState(() {
          _centroCosto = centroCosto;
          _isLoadingCentrosCosto = false;
          // Seleccionar automáticamente el primer centro de costo
          if (_centroCosto.isNotEmpty && _selectedCentroCosto == null) {
            _selectedCentroCosto = _centroCosto.first;
            _centroCostoController.text = _centroCosto.first.value;

            // 🔄 Cargar automáticamente el tipo de gasto y placa desde la metadata del primer centro de costo
            final value = _centroCosto.first;
            if (value.metadata != null) {
              debugPrint('========================================');
              debugPrint('🔍 CENTRO DE COSTO SELECCIONADO AUTOMÁTICAMENTE');
              debugPrint('📌 Valor: ${value.value}');
              debugPrint('📌 ID: ${value.id}');
              debugPrint('📦 Metadata completa: ${value.metadata}');
              debugPrint('========================================');

              // Cargar tipo de gasto
              final tipogasto =
                  value.metadata!['tipogasto']?.toString() ??
                  value.metadata!['tipoGasto']?.toString();

              debugPrint('📊 Tipo gasto extraído de metadata: "$tipogasto"');

              if (tipogasto != null && tipogasto.isNotEmpty) {
                // Buscar el tipo de gasto en la lista
                final tipoGastoEncontrado = _tiposGasto.firstWhere(
                  (tipo) => tipo.value.toUpperCase() == tipogasto.toUpperCase(),
                  orElse: () => DropdownOption.empty,
                );

                if (tipoGastoEncontrado.id.isNotEmpty) {
                  _selectedTipoGasto = tipoGastoEncontrado;
                  _tipoGastoController.text = tipoGastoEncontrado.value;
                  debugPrint(
                    '✅ Tipo de gasto asignado automáticamente: ${tipoGastoEncontrado.value}',
                  );
                } else {
                  debugPrint(
                    '⚠️ Tipo de gasto "$tipogasto" no encontrado en la lista',
                  );
                }
              } else {
                debugPrint('❌ Tipo de gasto no encontrado en metadata');
              }

              // Cargar placa
              final placa = value.metadata!['placa']?.toString();
              debugPrint('🚗 Placa extraída de metadata: "$placa"');

              if (placa != null && placa.isNotEmpty) {
                _placaController.text = placa;
                debugPrint('✅ Placa asignada automáticamente: $placa');
              } else {
                _placaController.text = '';
                debugPrint(
                  'ℹ️ Placa vacía en metadata, asignando valor por defecto: N',
                );
              }
            } else {
              debugPrint(
                '❌ NO HAY METADATA EN EL CENTRO DE COSTO SELECCIONADO',
              );
            }
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoadingCentrosCosto = false;
        });
      }
    }
  }

  /// Cargar categorías desde la API filtradas por la política seleccionada
  Future<void> _loadCategorias() async {
    if (mounted) {
      setState(() {
        _isLoadingCategorias = true;
        _error = null;
      });
    }

    try {
      final categorias = await _logic.fetchCategorias(
        _apiService,
        widget.politicaSeleccionada.value,
      );

      if (mounted) {
        setState(() {
          _categorias = categorias;
          _isLoadingCategorias = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoadingCategorias = false;
        });
      }
    }
  }

  /// Cargar tipos de gasto desde la API
  Future<void> _loadTiposGasto() async {
    if (mounted) {
      setState(() {
        _isLoadingTiposGasto = true;
        _error = null;
      });
    }

    try {
      final tiposGasto = await _logic.fetchTiposGasto(_apiService);

      if (mounted) {
        setState(() {
          _tiposGasto = tiposGasto;
          _isLoadingTiposGasto = false;

          // 🔹 Buscar y asignar 'TAXI' como valor por defecto
          _selectedTipoGasto = _tiposGasto.firstWhere(
            (tipo) =>
                tipo.value.toUpperCase() ==
                CompanyService().companyTipogasto.toUpperCase(),
            orElse: () => _tiposGasto.first,
          );

          // 🔹 Actualizar el TextEditingController
          _tipoGastoController.text = _selectedTipoGasto?.value ?? '';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoadingTiposGasto = false;
        });
      }
    }
  }

  /// Cargar tipos de movilidad desde la API
  Future<void> _loadTipoMovilidad() async {
    if (mounted) {
      setState(() {
        _isLoadingTipoMovilidad = true;
        _error = null;
      });
    }

    try {
      final tiposMovilidad = await _logic.fetchTipoMovilidad(_apiService);

      if (mounted) {
        setState(() {
          _tiposMovilidad = tiposMovilidad;
          _isLoadingTipoMovilidad = false;

          // 🔹 Buscar y asignar 'TAXI' como valor por defecto
          _selectedTipoMovilidad = _tiposMovilidad.firstWhere(
            (tipo) => tipo.value.toUpperCase() == 'TAXI',
            orElse: () => _tiposMovilidad.first,
          );

          // 🔹 Actualizar el TextEditingController
          _movilidadController.text = _selectedTipoMovilidad?.value ?? '';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoadingTipoMovilidad = false;
        });
      }
    }
  }

  /// Cargar información del RUC desde la API
  Future<void> _loadApiRuc(String ruc) async {
    if (mounted) {
      setState(() {
        _isLoadingApiRuc = true;
        _errorApiRuc = null;
      });
    }

    try {
      // ✅ Aquí la llamada correcta al método de la API
      final apiRuc = await _apiService.getApiRuc(ruc: ruc);

      if (mounted) {
        setState(() {
          _apiRucData = apiRuc;
          _isLoadingApiRuc = false;

          // 👇 Aquí actualizas el TextEditingController después de obtener los datos
          _razonSocialController.text = apiRuc.nombreRazonSocial ?? 'S/N';
        });
      }

      debugPrint('✅ RUC cargado correctamente: ${apiRuc.ruc}');
    } catch (e) {
      debugPrint('❌ Error al cargar RUC: $e');
      if (mounted) {
        setState(() {
          _errorApiRuc = e.toString();
          _isLoadingApiRuc = false;
        });
      }
    }
  }

  /// Comprimir imagen si es mayor a 1MB
  Future<File?> _compressImage(File file) async {
    return await _logic.compressImage(file);
  }

  /// Convertir imagen a PDF
  Future<File?> _convertImageToPdf(File imageFile) async {
    return await _logic.convertImageToPdf(imageFile);
  }

  /// Seleccionar archivo (imagen o PDF)
  Future<void> _pickImage() async {
    try {
      setState(() => _isLoading = true); // Mostrar indicador de carga

      // Mostrar opciones para seleccionar tipo de archivo
      final selectedOption = await showDialog<String>(
        context: context,
        builder: (BuildContext context) {
          final isDark = Theme.of(context).brightness == Brightness.dark;

          return AlertDialog(
            backgroundColor: isDark ? Colors.grey[900] : Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
            titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
            contentPadding: const EdgeInsets.fromLTRB(24, 16, 24, 10),

            title: Row(
              children: [
                const Icon(Icons.attach_file, color: Colors.blue, size: 26),
                const SizedBox(width: 10),
                Text(
                  'Seleccionar evidencia',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                ),
              ],
            ),

            content: Text(
              '¿Qué tipo de archivo deseas agregar?',
              style: TextStyle(
                fontSize: 15,
                height: 1.4,
                color: isDark ? Colors.grey[300] : Colors.black87,
              ),
            ),

            actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            actionsAlignment: MainAxisAlignment.spaceBetween,

            actions: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Tomar foto
                  TextButton.icon(
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.blue,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    onPressed: () => Navigator.pop(context, 'camera'),
                    icon: const Icon(Icons.camera_alt_rounded),
                    label: Text(
                      'Tomar Foto',
                      style: TextStyle(
                        fontSize: 16,
                        color: isDark ? Colors.blue[300] : Colors.blue,
                      ),
                    ),
                  ),

                  // Galería
                  TextButton.icon(
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.purple,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    onPressed: () => Navigator.pop(context, 'gallery'),
                    icon: const Icon(Icons.photo_library_rounded),
                    label: Text(
                      'Galería',
                      style: TextStyle(
                        fontSize: 16,
                        color: isDark ? Colors.purple[300] : Colors.purple,
                      ),
                    ),
                  ),

                  // PDF
                  TextButton.icon(
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.red,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    onPressed: () => Navigator.pop(context, 'pdf'),
                    icon: const Icon(Icons.picture_as_pdf_rounded),
                    label: Text(
                      'Archivo PDF',
                      style: TextStyle(
                        fontSize: 16,
                        color: isDark ? Colors.red[300] : Colors.red,
                      ),
                    ),
                  ),

                  const SizedBox(height: 6),

                  // Cancelar
                  TextButton(
                    style: TextButton.styleFrom(
                      foregroundColor: isDark
                          ? Colors.grey[400]
                          : Colors.grey[700],
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    onPressed: () => Navigator.pop(context),
                    child: Text(
                      'Cancelar',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.grey[400] : Colors.grey[700],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      );

      if (selectedOption != null) {
        if (selectedOption == 'camera' || selectedOption == 'gallery') {
          // Tomar foto con la cámara o galería
          final XFile? image = await _picker.pickImage(
            source: selectedOption == 'camera'
                ? ImageSource.camera
                : ImageSource.gallery,
            imageQuality: 85, // Calidad de la imagen
          );

          if (image != null) {
            File file = File(image.path);

            // Aquí recortamos la imagen
            _cropImage(file);
          }
        } else if (selectedOption == 'pdf') {
          // Seleccionar archivo PDF
          final result = await FilePicker.platform.pickFiles(
            type: FileType.custom,
            allowedExtensions: ['pdf'],
            allowMultiple: false,
          );

          if (result != null && result.files.isNotEmpty) {
            final file = File(result.files.first.path!);
            if (mounted) {
              setState(() {
                _selectedFile = file;
                _selectedFileType = 'pdf';
                _selectedFileName = result.files.first.name;
              });
            }
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al seleccionar archivo: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false); // Ocultar indicador de carga
      }
    }
  }

  /// Recortar imagen seleccionada
  Future<void> _cropImage(File imageFile) async {
    try {
      // Usamos el paquete image_cropper para permitir recortar la imagen
      final croppedFile = await ImageCropper().cropImage(
        sourcePath: imageFile.path,
        aspectRatio: CropAspectRatio(
          ratioX: 1.0,
          ratioY: 1.0,
        ), // Relación de aspecto cuadrada (1:1)
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: 'Recortar Comprobante',
            toolbarColor: Colors.green,
            toolbarWidgetColor: Colors.white,
            initAspectRatio:
                CropAspectRatioPreset.square, // Relación cuadrada inicial
            lockAspectRatio: false, // No bloquear la relación de aspecto
          ),
          IOSUiSettings(
            minimumAspectRatio: 1.0, // Relación mínima de aspecto
          ),
        ],
      );

      if (croppedFile != null) {
        if (mounted) {
          setState(() {
            _selectedFile = File(
              croppedFile.path,
            ); // Convertimos CroppedFile a File
            _selectedFileType = 'image'; // Indicamos que es una imagen
            _selectedFileName = croppedFile.path
                .split('/')
                .last; // Nombre del archivo
          });
        }
      }
    } on PlatformException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al recortar la imagen: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Mostrar selector de fecha
  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        _fechaController.text = picked.toString().split(' ')[0];
      });
    }
  }

  void _guardarValidar() {
    // Validar que la nota no esté vacía
    if (_notaController.text.trim().isEmpty) {
      _showMensaggeDialog("FALTA COMPLETAR NOTA O GLOSA");
      return;
    }

    if (_categoriaController.text.trim() == "") {
      _showMensaggeDialog("SELECCIONA CATEGORIA");
    } else if (_categoriaController.text == "PLANILLA DE MOVILIDAD") {
      if (_totalController.text.trim() == "") {
        _showMensaggeDialog("INGRESE MONTO");
      } else if (_centroCostoController.text.trim() == "") {
        _showMensaggeDialog("SELECCIONA CENTRO DE COSTO");
      } else if (_origenController.text.trim() == "") {
        _showMensaggeDialog("FALTA ORIGEN");
      } else if (_destinoController.text.trim() == "") {
        _showMensaggeDialog("FALTA DESTINO");
      } else if (_motivoViajeController.text.trim() == "") {
        _showMensaggeDialog("FALTA MOTIVO");
      } else {
        _guardarGasto();
      }
    } else if (_categoriaController.text == "VIAJES CON COMPROBANTE") {
      // Validar razón social para VIAJES CON COMPROBANTE
      if (_razonSocialController.text.trim().isEmpty) {
        _showMensaggeDialog("FALTA RAZÓN SOCIAL");
        return;
      }
      if (CompanyService().companyRuc.toString() !=
          _rucClienteController.text) {
        _showMensaggeDialog(
          "Ruc del cliente no coincide con ruc en el comprobante",
        );
      } else if (_totalController.text.trim() == "") {
        _showMensaggeDialog("INGRESE MONTO");
      } else if (_centroCostoController.text.trim() == "") {
        _showMensaggeDialog("SELECCIONA CENTRO DE COSTO");
      } else if (_selectedFile == null) {
        _showMensaggeDialog("ADJUNTE EVIDENCIA 📷");
      } else if (_origenController.text.trim() == "") {
        _showMensaggeDialog("FALTA ORIGEN");
      } else if (_destinoController.text.trim() == "") {
        _showMensaggeDialog("FALTA DESTINO");
      } else if (_motivoViajeController.text.trim() == "") {
        _showMensaggeDialog("FALTA MOTIVO");
      } else {
        _guardarGasto();
      }
    } else {
      // Validar razón social para cualquier otra categoría (excepto PLANILLA DE MOVILIDAD)
      if (_razonSocialController.text.trim().isEmpty) {
        _showMensaggeDialog("FALTA RAZÓN SOCIAL");
        return;
      }
      if (_selectedFile == null) {
        _showMensaggeDialog("ADJUNTE EVIDENCIA 📷");
      } else if (CompanyService().companyRuc.toString() !=
          _rucClienteController.text) {
        _showMensaggeDialog(
          "Ruc del cliente no coincide con ruc del comprobante",
        );
      } else if (_totalController.text.trim() == "") {
        _showMensaggeDialog("INGRESE MONTO");
      } else if (_centroCostoController.text.trim() == "") {
        _showMensaggeDialog("SELECCIONA CENTRO DE COSTO");
      } else {
        _guardarGasto();
      }
    }
  }

  /// Guarda el gasto utilizando la API
  Future<void> _guardarGasto() async {
    // Antes
    // if (_selectedFile == null && _categoriaController.text == "PLANILLA DE MOVILIDAD")

    // Si el centro de costo está vacío, usar el primero de la lista
    if (_centroCostoController.text.trim().isEmpty && _centroCosto.isNotEmpty) {
      setState(() {
        _selectedCentroCosto = _centroCosto.first;
        _centroCostoController.text = _centroCosto.first.value;
      });
    }

    try {
      // Mostrar indicador de carga
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return const Dialog(
            child: Padding(
              padding: EdgeInsets.all(20.0),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(width: 20),
                  Text("Guardando gasto..."),
                ],
              ),
            ),
          );
        },
      );

      // Obtener datos del usuario y empresa
      final userService = UserService();
      final companyService = CompanyService();

      final currentUser = userService.currentUser;
      final currentCompany = companyService.currentCompany;

      if (currentUser == null || currentCompany == null) {
        throw Exception('Error: Usuario o empresa no seleccionados');
      }

      // ✅ Asegurar que el tipo de comprobante tenga un valor por defecto si está vacío
      if (_tipoComprobanteController.text.trim().isEmpty) {
        _tipoComprobanteController.text = 'FACTURA ELECTRONICA';
        _selectedComprobante = 'FACTURA ELECTRONICA';
      }

      // Preparar datos del gasto usando la lógica separada
      final gastoData = _logic.prepareGastoData(
        politica: _politicaController.text,
        categoria: _categoriaController.text,
        tipoGasto: _tipoGastoController.text,
        centroCosto: _centroCostoController.text,
        ruc: _rucProveedorController.text,
        tipoComprobante: _tipoComprobanteController.text,
        serie: _serieFacturaController.text,
        numero: _numeroFacturaController.text,
        igv: _igvController.text,
        fecha: _fechaController.text,
        total: _totalController.text,
        moneda: _monedaController.text,
        nota: _notaController.text,
        motivoviaje: _motivoViajeController.text,
        origen: _origenController.text,
        destino: _destinoController.text,
        movilidad: _movilidadController.text,
        placa: _placaController.text,
        razonSocial: _razonSocialController.text,
      );

      // Enviar a la API y guardar evidencia si existe (la lógica interna maneja la evidencia)

      final idRend = await _logic.saveGastoWithEvidencia(
        _apiService,
        gastoData,
        _selectedFile,
      );

      if (idRend == null) {
        debugPrint(
          'No se pudo guardar la factura principal o no se obtuvo el ID autogenerado',
        );
      }

      // Cerrar diálogo de carga
      Navigator.of(context).pop();

      // Mostrar mensaje de éxito
      /* ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Factura guardada exitosamente'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      ); */

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.transparent,
          elevation: 0,
          duration: const Duration(seconds: 2),
          content: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              gradient: const LinearGradient(
                colors: [Color(0xFF4CAF50), Color(0xFF2E7D32)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 8,
                  offset: Offset(0, 3),
                ),
              ],
            ),
            child: Row(
              children: [
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.7, end: 1.0),
                  duration: const Duration(milliseconds: 500),
                  curve: Curves.easeOutBack,
                  builder: (context, scale, child) {
                    return Transform.scale(scale: scale, child: child);
                  },
                  child: const Icon(
                    Icons.check_circle,
                    color: Colors.white,
                    size: 26,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Factura guardada exitosamente',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                      height: 1.2,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );

      // 🗑️ Limpiar borrador después de guardar exitosamente
      await _clearDraft();

      // Cerrar el modal y navegar a la pantalla de gastos
      Navigator.of(context).pop(); // Cerrar modal
      Navigator.of(context).pop(); // Cerrar pantalla QR si existe

      // Navegar a HomeScreen con índice 0 (pestaña de Gastos)
      // Nota: Asegúrate de importar HomeScreen si no está importado

      // Navegar a HomeScreen con índice 0 (pestaña de Gastos)
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const HomeScreen()),
        (route) => false, // Remover todas las rutas anteriores
      );
    } catch (e) {
      // Cerrar diálogo de carga si está abierto
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }

      // Extraer mensaje del servidor para mostrar en alerta
      final serverMessage = _logic.extractServerMessage(e.toString());
      _showServerAlert(serverMessage);
    } finally {
      debugPrint('🔄 Finalizando proceso...');
    }
  }

  /// Extrae el mensaje del servidor de un error
  // Delegado a NuevoGastoLogic.extractServerMessage

  /// Verifica si el mensaje indica que la factura ya está registrada
  /// Muestra una alerta con el mensaje del servidor
  void _showServerAlert(String message) {
    final isDuplicate = _logic.isFacturaDuplicada(message);
    final isDuplicatemonto = _logic.isFacturaDuplicadaMonto(message);

    if (isDuplicate) {
      _showFacturaDuplicadaDialog(message);
    } else if (isDuplicatemonto) {
      _showFacturaDuplicadaDialogMonto(message);
    } else {
      _showErrorDialog(message);
    }
  }

  /// Muestra un diálogo específico para facturas duplicadas
  void _showFacturaDuplicadaDialogMonto(String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.receipt_long,
                  color: Colors.red,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'MONTO MOVILIDAD',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color.fromARGB(255, 255, 0, 0),
                  ),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline, color: Colors.red, size: 20),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'SE REGISTRO CORRECTAMENTE, PERO SUPERASTE EL LIMITE DE 44 SOLES AL DIA',
                        style: TextStyle(fontSize: 14, color: Colors.black87),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Cerrar diálogo de error
                // Usar un Future.delayed para asegurar que el contexto esté disponible
                if (mounted && Navigator.of(context).canPop()) {
                  Navigator.of(context).pop(true);
                }
              },
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
              child: const Text(
                'Entendido',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        );
      },
    );
  }

  /// Muestra un diálogo específico para facturas duplicadas
  void _showFacturaDuplicadaDialog(String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.receipt_long,
                  color: Colors.red,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'FACTURA YA EXISTE',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.red,
                  ),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.withOpacity(0.2)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline, color: Colors.red, size: 20),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'Esta factura ya ha sido registrada anteriormente en el sistema, revise su documento',
                        style: TextStyle(fontSize: 14, color: Colors.black87),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              if (message.isNotEmpty)
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.grey.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Cerrar diálogo de error
                // Usar un Future.delayed para asegurar que el contexto esté disponible
                Future.delayed(const Duration(milliseconds: 100), () {
                  // Cerrar el modal principal
                  if (mounted && Navigator.of(context).canPop()) {
                    Navigator.of(context).pop();
                  }
                });
              },
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
              child: const Text(
                'Entendido',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showMensaggeDialog(String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.receipt_long,
                  color: Colors.red,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'ADVERTENCIA',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.red,
                  ),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.withOpacity(0.2)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.info_outline, color: Colors.red, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        message, // ✅ aquí se usa el mensaje recibido
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.black87,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Cerrar diálogo de advertencia
                FocusScope.of(
                  context,
                ).unfocus(); // Quitar el focus de cualquier campo
              },
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
              child: const Text(
                'Entendido',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        );
      },
    );
  }

  /// Muestra un diálogo de error general
  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.error_outline,
                  color: Colors.red,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Mensaje Error',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.red,
                  ),
                ),
              ),
            ],
          ),
          content: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.05),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.red.withOpacity(0.2)),
            ),
            child: Text(
              message,
              style: const TextStyle(fontSize: 14, color: Colors.black87),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Cerrar diálogo de error
                // Para errores generales, no cerramos automáticamente el modal
                // para permitir al usuario corregir el problema
              },
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
              child: const Text(
                'Entendido',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final double maxHeight = MediaQuery.of(context).size.height * 0.93;
    final double minHeight = MediaQuery.of(context).size.height * 0.55;

    return Container(
      constraints: BoxConstraints(minHeight: minHeight, maxHeight: maxHeight),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[900] : Colors.white,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(22),
          topRight: Radius.circular(22),
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,

        // Para que no agregue paddings automáticos
        resizeToAvoidBottomInset: true,

        body: SafeArea(
          top: false,
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                // HEADER
                Padding(
                  padding: const EdgeInsets.only(top: 8, bottom: 8),
                  child: _buildHeader(),
                ),

                // CONTENIDO SCROLLEABLE
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildImageSection(),
                        const SizedBox(height: 10),

                        if (_categoriaController.text !=
                            "PLANILLA DE MOVILIDAD")
                          _buildLectorSunatSection(),

                        const SizedBox(height: 10),
                        _buildDatosGeneralesSection(),
                        const SizedBox(height: 10),
                        _buildDatosFacturaSection(),
                        const SizedBox(height: 10),

                        if (_politicaController.text.contains(
                          'GASTOS DE MOVILIDAD',
                        ))
                          _buildDatosMovilidadSection(),

                        const SizedBox(height: 10),
                        _buildNotasSection(),

                        /*                         const SizedBox(height: 80), // Para separar del botón
 */
                      ],
                    ),
                  ),
                ),

                // BOTONES ABAJO
                /* SafeArea(
                  top: false,
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: _buildActionButtons(),
                  ),
                ), */
                SafeArea(
                  top: false,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 0.0), // ← MÁS PEGADO
                    child: _buildActionButtons(),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Construir el header del modal
  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.green.shade700, Colors.green.shade400],
        ),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.add_business, color: Colors.white, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Nuevo Gasto',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  'Política: ${widget.politicaSeleccionada.value}',
                  style: const TextStyle(fontSize: 12, color: Colors.white70),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: widget.onCancel,
            icon: const Icon(Icons.close, color: Colors.white),
          ),
        ],
      ),
    );
  }

  /// Construir la seción de imagen
  Widget _buildImageSection() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Card(
      color: isDark ? Colors.grey[800] : Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(1),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.attach_file, color: Colors.red),
                const SizedBox(width: 1),
                Text(
                  'Adjuntar Evidencia',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                ),
                const Text(
                  ' *',
                  style: TextStyle(color: Colors.red, fontSize: 16),
                ),
                const Spacer(),
                if (_isLoading)
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                else
                  ElevatedButton.icon(
                    onPressed: _pickImage,
                    icon: Icon(
                      (widget.politicaSeleccionada.value !=
                                  "GASTOS DE MOVILIDAD" &&
                              _selectedFile == null)
                          ? Icons.add
                          : Icons.edit,
                    ),
                    label: Text(
                      (widget.politicaSeleccionada.value !=
                                  "GASTOS DE MOVILIDAD" &&
                              _selectedFile == null)
                          ? 'Agregar'
                          : 'Cambiar',
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),

            // Mostrar archivo seleccionado
            if (_selectedFile != null)
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: _selectedFileType == 'image'
                    ? GestureDetector(
                        onTap: _handleTapEvidencia, // 👈 agregado aquí
                        child: Container(
                          height: 200,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.file(
                              _selectedFile!,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                      )
                    : GestureDetector(
                        onTap: _handleTapEvidencia, // 👈 agregado aquí también
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.picture_as_pdf,
                                color: Colors.red,
                                size: 40,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Archivo PDF seleccionado',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      _selectedFileName ?? 'archivo.pdf',
                                      style: TextStyle(
                                        color: Colors.grey.shade700,
                                        fontSize: 12,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                              const Icon(
                                Icons.check_circle,
                                color: Colors.green,
                                size: 24,
                              ),
                            ],
                          ),
                        ),
                      ),
              )
            else
              Container(
                height: 100,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: isDark ? Colors.grey[700] : Colors.grey.shade100,
                  border: Border.all(
                    color:
                        (widget.politicaSeleccionada.value !=
                                "GASTOS DE MOVILIDAD" &&
                            _selectedFile == null)
                        ? Colors.red.shade300
                        : (isDark ? Colors.grey[600]! : Colors.grey.shade300),
                    width:
                        (widget.politicaSeleccionada.value !=
                                "GASTOS DE MOVILIDAD" &&
                            _selectedFile == null)
                        ? 2
                        : 1,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.attach_file,
                      color:
                          (widget.politicaSeleccionada.value !=
                                  "GASTOS DE MOVILIDAD" &&
                              _selectedFile == null)
                          ? Colors.red
                          : (isDark ? Colors.grey[400] : Colors.grey),
                      size: 40,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      (widget.politicaSeleccionada.value !=
                              "GASTOS DE MOVILIDAD")
                          ? 'Agregar evidencia (Obligatorio)'
                          : 'Agregar evidencia (Opcional)',
                      style: TextStyle(
                        color:
                            (widget.politicaSeleccionada.value !=
                                    "GASTOS DE MOVILIDAD" &&
                                _selectedFile == null)
                            ? Colors.red
                            : (isDark ? Colors.grey[400] : Colors.grey),
                        fontWeight:
                            (widget.politicaSeleccionada.value !=
                                    "GASTOS DE MOVILIDAD" &&
                                _selectedFile == null)
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Imagen o PDF',
                      style: TextStyle(
                        color: isDark ? Colors.grey[400] : Colors.grey.shade600,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleTapEvidencia() async {
    try {
      String nombreArchivo =
          '${_rucClienteController.text}_${_serieFacturaController.text}_${_numeroFacturaController.text}';

      // 1️⃣ Si hay un archivo local seleccionado
      if (_selectedFile != null) {
        final path = _selectedFile!.path;
        final bytes = await _selectedFile!.readAsBytes();

        if (_isPdfFile(path)) {
          await _abrirPdfExterno(bytes, path.split('/').last);
          return;
        } else {
          await _showEvidenciaDialogFromBytes(bytes);
          return;
        }
      }

      // 2️⃣ Si tenemos evidencia almacenada en `_apiEvidencia`
      if (_selectedFile != null) {
        final evidencia = _selectedFile!.path;

        // 👉 Si es base64
        if (_controller.isBase64(evidencia)) {
          final bytes = base64Decode(evidencia);

          // Detectar si es PDF por cabecera '%PDF'
          final isPdf =
              bytes.length >= 4 &&
              bytes[0] == 0x25 &&
              bytes[1] == 0x50 &&
              bytes[2] == 0x44 &&
              bytes[3] == 0x46;

          if (isPdf) {
            await _abrirPdfExterno(bytes, nombreArchivo + '.pdf');
            return;
          }

          await _showEvidenciaDialogFromBytes(bytes);
          return;
        }

        // 👉 Si es una URL válida
        if (_controller.isValidUrl(evidencia)) {
          try {
            final uri = Uri.tryParse(evidencia);
            String? fileName;
            if (uri != null && uri.pathSegments.isNotEmpty) {
              fileName = uri.pathSegments.last;
            }

            if (fileName != null) {
              final bytes = await _apiService.obtenerImagenBytes(fileName);
              if (bytes != null) {
                if (fileName.toLowerCase().endsWith('.pdf')) {
                  await _abrirPdfExterno(bytes, fileName);
                } else {
                  await _showEvidenciaDialogFromBytes(bytes);
                }
                return;
              }
            }

            // Fallback: mostrar imagen por URL directamente
            if (!mounted) return;
            showDialog(
              context: context,
              builder: (_) => AlertDialog(
                title: const Text('Evidencia'),
                content: SizedBox(
                  width: MediaQuery.of(context).size.width * 0.8,
                  height: MediaQuery.of(context).size.height * 0.6,
                  child: InteractiveViewer(
                    panEnabled: true,
                    boundaryMargin: const EdgeInsets.all(20),
                    minScale: 1.0,
                    maxScale: 5.0,
                    child: Image.network(evidencia, fit: BoxFit.contain),
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cerrar'),
                  ),
                ],
              ),
            );
            return;
          } catch (e) {
            debugPrint('⚠️ Error descargando evidencia: $e');
          }
        }
      }

      // 3️⃣ Si no hay evidencia o es inválida
      if (!mounted) return;
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Evidencia'),
          content: const Text('No hay imagen disponible para previsualizar.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cerrar'),
            ),
          ],
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error mostrando evidencia: ${e.toString()}')),
      );
    }
  }

  /// Mostrar un diálogo con los bytes de la imagen
  Future<void> _showEvidenciaDialogFromBytes(Uint8List bytes) async {
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Colors.black, // Fondo negro para el AlertDialog
        title: Center(
          child: const Text(
            'Evidencia',
            style: TextStyle(
              color: Colors.white,
            ), // Título en blanco para que sea visible en el fondo negro
          ),
        ),
        content: SizedBox(
          width: MediaQuery.of(context).size.width * 0.9,
          height: MediaQuery.of(context).size.height * 0.6,
          child: InteractiveViewer(
            panEnabled: true,
            boundaryMargin: const EdgeInsets.all(2),
            minScale: 1.0,
            maxScale: 6.0,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(
                12,
              ), // Bordes redondeados para la imagen
              child: Image.memory(
                bytes,
                fit: BoxFit
                    .contain, // Asegurarse de que la imagen no se distorsione
              ),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Cerrar',
              style: TextStyle(
                color: Colors.white,
              ), // Texto de cerrar en blanco
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _abrirPdfExterno(Uint8List pdfBytes, String fileName) async {
    try {
      // Crea un archivo temporal en el almacenamiento del dispositivo
      final tempDir = await getTemporaryDirectory();
      final tempPath = '${tempDir.path}/$fileName';

      final file = File(tempPath);
      await file.writeAsBytes(pdfBytes, flush: true);

      // Abre el archivo con una app externa instalada en el teléfono
      final result = await OpenFilex.open(tempPath);

      if (result.type != ResultType.done) {
        debugPrint('⚠️ No se pudo abrir el PDF: ${result.message}');
      }
    } catch (e, st) {
      debugPrint('🔥 Error al abrir PDF externo: $e\n$st');
    }
  }

  /// Verificar si un archivo es PDF basado en su extensión
  bool _isPdfFile(String filePath) {
    return filePath.toLowerCase().endsWith('.pdf');
  }

  /// Construir la sección de datos generales
  Widget _buildDatosGeneralesSection() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Datos Generales',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.green,
          ),
        ),
        const SizedBox(height: 4),

        // Politica
        TextFormField(
          controller: _politicaController,
          decoration: InputDecoration(
            labelText: 'Politica',
            enabled: false,
            floatingLabelBehavior:
                FloatingLabelBehavior.always, // Label siempre arriba
            border: UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.grey.shade400, width: 1),
            ),
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.grey.shade400, width: 1),
            ),
            focusedBorder: const UnderlineInputBorder(
              borderSide: BorderSide(
                color: Colors.green,
                width: 2,
              ), // Línea verde al focus
            ),
            errorBorder: const UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.red, width: 2),
            ),
            prefixIcon: const Icon(Icons.business, color: Colors.grey),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'El proveedor es obligatorio';
            }
            return null;
          },
        ),
        const SizedBox(height: 12),

        _buildCategoriaSection(),
        const SizedBox(height: 12),
        _buildCentroCostoSection(),

        _buildTipoGastoSection(),
      ],
    );
  }

  /// Construir la sección de datos personalizados
  Widget _buildDatosFacturaSection() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bool esPlanillaMovilidad =
        _selectedCategoria == 'PLANILLA DE MOVILIDAD';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Datos de comprobante',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.green,
          ),
        ),
        // Campos que se muestran solo si NO es planilla de movilidad
        if (!esPlanillaMovilidad) ...[
          if (_categoriaController.text != "PLANILLA DE MOVILIDAD")
            TextFormField(
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              controller: _rucProveedorController,
              readOnly: _hasScannedData,
              /* _hasScannedData ||
                  _categoriaController.text !=
                      "VIAJES CON COMPROBANTE", // 🔒 Bloqueado después de escanear o si es VIAJES CON COMPROBANTE */
              decoration: InputDecoration(
                labelText: 'RUC Emisor',
                border: UnderlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: Colors.transparent,
                    width: 0,
                  ),
                ),
                enabledBorder: UnderlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Colors.grey, width: 1),
                ),
                focusedBorder: const UnderlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(12)),
                  borderSide: BorderSide(color: Colors.green, width: 2),
                ),
                disabledBorder: UnderlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Colors.white, width: 1),
                ),
                prefixIcon: const Icon(Icons.badge),
              ),
              textInputAction: TextInputAction.done,
              onFieldSubmitted: (value) {
                if (value.length == 11) {
                  _loadApiRuc(value);
                } else {
                  showMessageError(context, 'El RUC debe tener 11 dígitos');
                }
              },
              validator: (value) {
                if (value != null && value.isNotEmpty && value.length != 11) {
                  return 'El RUC debe tener 11 dígitos';
                }
                return null;
              },
            ),

          // Razón Social
          if (_categoriaController.text != "PLANILLA DE MOVILIDAD")
            TextFormField(
              focusNode: _razonSocialFocusNode,
              textInputAction: TextInputAction.next,
              controller: _razonSocialController,
              validator: (value) {
                // Obligatorio excepto en PLANILLA DE MOVILIDAD
                if (_categoriaController.text != "PLANILLA DE MOVILIDAD") {
                  if (value == null || value.trim().isEmpty) {
                    return 'La Razón Social es obligatoria';
                  }
                }
                return null;
              },
              readOnly: _hasScannedData,
              /* _hasScannedData ||
                  _categoriaController.text !=
                      "VIAJES CON COMPROBANTE", // 🔒 Bloqueado después de escanear o si es VIAJES CON COMPROBANTE */
              decoration: InputDecoration(
                labelText: 'Razón Social',
                hintText: 'Ingresa Razón Social',
                floatingLabelBehavior: FloatingLabelBehavior.always,
                border: UnderlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: Colors.transparent,
                    width: 0,
                  ),
                ),
                enabledBorder: UnderlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Colors.grey, width: 1),
                ),
                focusedBorder: const UnderlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(12)),
                  borderSide: BorderSide(color: Colors.green, width: 2),
                ),
                disabledBorder: UnderlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Colors.white, width: 1),
                ),
                prefixIcon: const Icon(Icons.business, color: Colors.grey),
              ),
            ),

          const SizedBox(height: 12),

          // RUC Cliente
          /*           if (_categoriaController.text != "PLANILLA DE MOVILIDAD")
 */
          TextFormField(
            controller: _rucClienteController,
            decoration: const InputDecoration(
              labelText: 'RUC Cliente',
              border: UnderlineInputBorder(),
              prefixIcon: Icon(Icons.business),
              suffixIcon: Icon(Icons.lock, color: Colors.grey),
            ),
            enabled: false,
            style: const TextStyle(
              color: Colors.grey,
              fontWeight: FontWeight.w500,
            ),
          ),

          // 🔍 Mensaje de validación del RUC Cliente
          if (_rucClienteController.text.trim().isEmpty)
            Padding(
              padding: const EdgeInsets.only(left: 12, top: 4, bottom: 8),
              child: Row(
                children: [
                  Icon(
                    _isRucValid() ? Icons.check_circle : Icons.error,
                    size: 16,
                    color: _isRucValid() ? Colors.green : Colors.red,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      _getRucStatusMessage(),
                      style: TextStyle(
                        fontSize: 12,
                        color: _isRucValid() ? Colors.red : Colors.red,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),

          // 🔍 Mensaje de validación del RUC Cliente
          if (_rucClienteController.text.trim().isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(left: 12, top: 4, bottom: 8),
              child: Row(
                children: [
                  Icon(
                    _isRucValid() ? Icons.check_circle : Icons.error,
                    size: 16,
                    color: _isRucValid() ? Colors.green : Colors.red,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      _getRucStatusMessage(),
                      style: TextStyle(
                        fontSize: 12,
                        color: _isRucValid() ? Colors.green : Colors.red,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),

          const SizedBox(height: 8),

          // Tipo de Comprobante
          if (_categoriaController.text != "PLANILLA DE MOVILIDAD")
            DropdownButtonFormField<String>(
              value: _selectedComprobante,
              decoration: InputDecoration(
                labelText: 'Tipo Comprobante',
                border: UnderlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: Colors.transparent,
                    width: 0,
                  ),
                ),
                enabledBorder: UnderlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Colors.grey, width: 1),
                ),
                focusedBorder: const UnderlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(12)),
                  borderSide: BorderSide(color: Colors.green, width: 2),
                ),
                disabledBorder: UnderlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Colors.white, width: 1),
                ),
                prefixIcon: const Icon(Icons.edit_document),
              ),
              items: tipocomprobante.map((comprobante) {
                return DropdownMenuItem<String>(
                  value: comprobante,
                  child: Text(comprobante),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedComprobante = value;
                  _tipoComprobanteController.text = value ?? '';
                });
              },
              validator: (value) {
                if (value == null || value.isEmpty) {
                  // Si no hay selección, tomar el primero de la lista
                  setState(() {
                    _selectedComprobante = tipocomprobante.first;
                    _tipoComprobanteController.text = tipocomprobante.first;
                  });
                  return null; // Ya no es error, se asignó automáticamente
                }
                return null;
              },
            ),
          const SizedBox(height: 4),

          // Fecha
          TextFormField(
            controller: _fechaController,
            decoration: InputDecoration(
              labelText: 'Fecha Emisión',
              hintText: 'DD/MM/AAAA',
              floatingLabelBehavior: FloatingLabelBehavior.always,
              floatingLabelStyle: const TextStyle(
                color: Colors.green,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
              border: UnderlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: Colors.transparent,
                  width: 0,
                ),
              ),
              enabledBorder: UnderlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: isDark ? Colors.grey[600]! : Colors.grey,
                  width: 1,
                ),
              ),
              focusedBorder: const UnderlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(12)),
                borderSide: BorderSide(color: Colors.green, width: 2),
              ),
              disabledBorder: UnderlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: isDark ? Colors.grey[700]! : Colors.white,
                  width: 1,
                ),
              ),
              prefixIcon: Container(
                margin: const EdgeInsets.only(right: 8),
                child: const Icon(Icons.calendar_month, color: Colors.green),
              ),
              /* suffixIcon: _validar
                  ? IconButton(
                      icon: const Icon(Icons.expand_more, color: Colors.green),
                      onPressed: _selectDate,
                      tooltip: 'Seleccionar fecha',
                    )
                  : null,
              filled: true, */
              suffixIcon: IconButton(
                icon: const Icon(Icons.expand_more, color: Colors.green),
                onPressed: () {
                  // Solo abrir calendario si NO ha escaneado QR
                  if (!_hasScannedData) {
                    _selectDate();
                  }
                },
                tooltip: 'Seleccionar fecha',
              ),

              fillColor: _fechaController.text.isEmpty
                  ? (isDark ? Colors.grey[800] : Colors.white)
                  : (isDark ? Colors.grey[800] : Colors.white),
            ),
            readOnly:
                true, // ✅ Siempre true para evitar teclado, solo se usa el calendario
            /*  onTap:
                (_validar &&
                    _categoriaController.text != "VIAJES CON COMPROBANTE")
                ? _selectDate
                : null, // ✅ Permite seleccionar fecha excepto en VIAJES CON COMPROBANTE */
            /*  onTap: () {
              // Abrir calendario al tocar el campo (excepto en VIAJES CON COMPROBANTE)
              if (_categoriaController.text == "VIAJES CON COMPROBANTE") {
                _selectDate();
              }
            }, */
            onTap: () {
              // ✅ Permitir abrir calendario solo si NO ha escaneado QR
              if (!_hasScannedData) {
                _selectDate();
              }
            },
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: _fechaController.text.isEmpty
                  ? (isDark ? Colors.grey[400] : Colors.grey.shade600)
                  : (isDark ? Colors.white : Colors.black87),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Por favor, selecciona una fecha';
              }
              return null;
            },
          ),
          const SizedBox(height: 4),

          // Serie y Número de Factura
          if (_categoriaController.text != "PLANILLA DE MOVILIDAD")
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    focusNode: _serieFacturaFocusNode,
                    textInputAction: TextInputAction.next,
                    controller: _serieFacturaController,
                    readOnly: _hasScannedData,
                    /* !_validar ||
                        _categoriaController.text !=
                            "VIAJES CON COMPROBANTE", // 🔒 Bloqueado después de escanear QR o si es VIAJES CON COMPROBANTE */
                    decoration: InputDecoration(
                      labelText: 'Serie *',
                      border: UnderlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: Colors.transparent,
                          width: 0,
                        ),
                      ),
                      enabledBorder: UnderlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: Colors.grey,
                          width: 1,
                        ),
                      ),
                      focusedBorder: const UnderlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(12)),
                        borderSide: BorderSide(color: Colors.green, width: 2),
                      ),
                      disabledBorder: UnderlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: Colors.white,
                          width: 1,
                        ),
                      ),
                      prefixIcon: const Icon(Icons.receipt_long),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    focusNode: _numeroFacturaFocusNode,
                    textInputAction: TextInputAction.next,
                    keyboardType: TextInputType.number,
                    controller: _numeroFacturaController,
                    readOnly: _hasScannedData,

                    /*                         !_validar ||
                        _categoriaController.text !=
                            "VIAJES CON COMPROBANTE", // 🔒 Bloqueado después de escanear QR o si es VIAJES CON COMPROBANTE */
                    decoration: InputDecoration(
                      labelText: 'Número *',
                      border: UnderlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: Colors.transparent,
                          width: 0,
                        ),
                      ),
                      enabledBorder: UnderlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: Colors.grey,
                          width: 1,
                        ),
                      ),
                      focusedBorder: const UnderlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(12)),
                        borderSide: BorderSide(color: Colors.green, width: 2),
                      ),
                      disabledBorder: UnderlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: Colors.white,
                          width: 1,
                        ),
                      ),
                      prefixIcon: const Icon(Icons.confirmation_number),
                    ),
                  ),
                ),
              ],
            ),
          const SizedBox(height: 4),

          // Serie y Número de Factura
          if (_categoriaController.text != "PLANILLA DE MOVILIDAD")
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    focusNode: _igvFocusNode,
                    textInputAction: TextInputAction.next,
                    keyboardType: TextInputType.number,
                    controller: _igvController,
                    /*  readOnly: true, // 🔒 Bloqueado solo después de escanear QR */
                    readOnly: _hasScannedData,

                    /*   _categoriaController.text != "VIAJES CON COMPROBANTE" ||
                        _hasScannedData, // ✅ Solo bloqueado en VIAJES CON COMPROBANTE */
                    decoration: InputDecoration(
                      labelText: 'Igv *',
                      border: UnderlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: Colors.transparent,
                          width: 0,
                        ),
                      ),
                      enabledBorder: UnderlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: Colors.grey,
                          width: 1,
                        ),
                      ),
                      focusedBorder: const UnderlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(12)),
                        borderSide: BorderSide(color: Colors.green, width: 2),
                      ),
                      disabledBorder: UnderlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: Colors.white,
                          width: 1,
                        ),
                      ),
                      prefixIcon: const Icon(Icons.receipt_long),
                    ),
                  ),
                ),
              ],
            ),
          const SizedBox(height: 4),
        ],

        // Total y Moneda (siempre visibles)
        Row(
          children: [
            Expanded(
              flex: 1,
              child: TextFormField(
                focusNode: _totalFocusNode,
                textInputAction: TextInputAction.next,
                controller: _totalController,

                /*   readOnly:
                    (_categoriaController.text !=
                    "PLANILLA DE MOVILIDAD"), // ✅ Solo editable en planilla de movilidad
 */
                /*   readOnly:
                    _categoriaController.text != "VIAJES CON COMPROBANTE" ||
                    _hasScannedData, // ✅ Solo bloqueado en VIAJES CON COMPROBANTE */
                /*   readOnly: (_categoriaController.text == "PLANILLA DE MOVILIDAD")
                    ? false
                    : (_hasScannedData ||
                          _categoriaController.text !=
                              "VIAJES CON COMPROBANTE"), */
                /* readOnly: (_categoriaController.text == "PLANILLA DE MOVILIDAD")
                    ? _hasScannedData // Si escaneó QR, bloquear también en planilla
                    : (_hasScannedData ||
                          _categoriaController.text !=
                              "VIAJES CON COMPROBANTE"), */
                readOnly: _hasScannedData,
                decoration: InputDecoration(
                  labelText: 'Total',
                  border: UnderlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                      color: Colors.transparent,
                      width: 0,
                    ),
                  ),
                  enabledBorder: UnderlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Colors.grey, width: 1),
                  ),
                  focusedBorder: const UnderlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(12)),
                    borderSide: BorderSide(color: Colors.green, width: 2),
                  ),
                  disabledBorder: UnderlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Colors.white, width: 1),
                  ),
                  prefixIcon: const Icon(Icons.attach_money),
                ),
                keyboardType: TextInputType.numberWithOptions(decimal: true),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: DropdownButtonFormField<String>(
                value: _selectedMoneda,
                decoration: InputDecoration(
                  labelText: 'Moneda',
                  border: UnderlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                      color: Colors.transparent,
                      width: 0,
                    ),
                  ),
                  enabledBorder: UnderlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Colors.grey, width: 1),
                  ),
                  focusedBorder: const UnderlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(12)),
                    borderSide: BorderSide(color: Colors.green, width: 2),
                  ),
                  disabledBorder: UnderlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Colors.white, width: 1),
                  ),
                  prefixIcon: const Icon(Icons.monetization_on),
                ),
                items: _monedas.map((moneda) {
                  return DropdownMenuItem<String>(
                    value: moneda,
                    child: Text(moneda),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedMoneda = value;
                    _monedaController.text = value ?? '';
                  });
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Seleccione una moneda';
                  }
                  return null;
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
      ],
    );
  }

  /// Construir la sección de categoría
  Widget _buildCategoriaSection() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (_isLoadingCategorias) {
      return const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Categoría',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
          ),
          SizedBox(height: 8),
          Center(child: CircularProgressIndicator()),
        ],
      );
    }

    if (_error != null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Categoría',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.red.shade900.withOpacity(0.3)
                  : Colors.red.shade50,
              border: Border.all(
                color: isDark ? Colors.red.shade700 : Colors.red.shade300,
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.error,
                  color: isDark ? Colors.red.shade400 : Colors.red.shade700,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Error cargando categorías: $_error',
                    style: TextStyle(
                      color: isDark ? Colors.red.shade400 : Colors.red.shade700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    }

    return DropdownButtonFormField<DropdownOption>(
      value: _selectedCategoria,
      dropdownColor: isDark ? Colors.grey[800] : Colors.white,
      decoration: InputDecoration(
        labelText: 'Categoría',
        labelStyle: TextStyle(color: isDark ? Colors.grey[400] : null),
        border: UnderlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.transparent, width: 0),
        ),
        enabledBorder: UnderlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: isDark ? Colors.grey[600]! : Colors.grey,
            width: 1,
          ),
        ),
        focusedBorder: const UnderlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
          borderSide: BorderSide(color: Colors.green, width: 2),
        ),
        disabledBorder: UnderlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.white, width: 1),
        ),
        prefixIcon: Icon(
          Icons.category,
          color: isDark ? Colors.grey[400] : Colors.grey,
        ),
      ),
      isExpanded: true,
      style: TextStyle(color: isDark ? Colors.white : Colors.black),
      items: _categorias.map((categoria) {
        return DropdownMenuItem<DropdownOption>(
          value: categoria,
          child: Text(
            categoria.value,
            style: TextStyle(color: isDark ? Colors.white : Colors.black),
          ),
        );
      }).toList(),
      onChanged: (value) {
        setState(() {
          _selectedCategoria = value;
          _categoriaController.text = value?.value ?? '';
          // Cambia visibilidad según categoría
        });
      },
      validator: (value) {
        if (value == null) {
          return 'Seleccione una categoría';
        }
        return null;
      },
    );
  }

  /// Construir la sección de tipo de gasto
  Widget _buildTipoGastoSection() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (_isLoadingTiposGasto) {
      return const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Tipo de Gasto',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
          ),
          SizedBox(height: 8),
          Center(child: CircularProgressIndicator()),
        ],
      );
    }

    if (_error != null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Tipo de Gasto',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.red.shade900.withOpacity(0.3)
                  : Colors.red.shade50,
              border: Border.all(
                color: isDark ? Colors.red.shade700 : Colors.red.shade300,
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.error,
                  color: isDark ? Colors.red.shade400 : Colors.red.shade700,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Error cargando tipos de gasto: $_error',
                    style: TextStyle(
                      color: isDark ? Colors.red.shade400 : Colors.red.shade700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    }

    return DropdownButtonFormField<DropdownOption>(
      dropdownColor: isDark ? Colors.grey[800] : Colors.white,
      value: _selectedTipoGasto,
      decoration: InputDecoration(
        labelText: 'Tipo de Gasto (Automático)',
        labelStyle: TextStyle(
          color: isDark ? Colors.grey[500] : Colors.grey[700],
        ),
        prefixIcon: Icon(
          Icons.lock_outline,
          color: isDark ? Colors.grey[400] : Colors.grey,
        ),
        suffixIcon: Tooltip(
          message:
              'El tipo de gasto se asigna automáticamente según el centro de costo',
          child: Icon(Icons.info_outline, size: 20, color: Colors.grey),
        ),
        border: UnderlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.transparent, width: 0),
        ),
        enabledBorder: UnderlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: isDark ? Colors.grey[600]! : Colors.grey,
            width: 1,
          ),
        ),
        focusedBorder: UnderlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
          borderSide: BorderSide(
            color: isDark ? Colors.grey[600]! : Colors.grey,
            width: 2,
          ),
        ),
        disabledBorder: UnderlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: isDark ? Colors.grey[700]! : Colors.grey[300]!,
            width: 1,
          ),
        ),
        filled: true,
        fillColor: isDark ? Colors.grey[850] : Colors.grey[100],
      ),
      isExpanded: true,
      style: TextStyle(color: isDark ? Colors.grey[400] : Colors.grey[700]),
      items: _tiposGasto.map((tipoGasto) {
        return DropdownMenuItem<DropdownOption>(
          value: tipoGasto,
          child: Text(
            tipoGasto.value,
            style: TextStyle(
              color: isDark ? Colors.grey[400] : Colors.grey[700],
            ),
          ),
        );
      }).toList(),
      onChanged: null, // 🔒 Deshabilitado - se asigna automáticamente

      validator: (value) {
        if (value == null) {
          return 'Seleccione un tipo de gasto';
        }
        return null;
      },
    );
  }

  Widget _buildCentroCostoSection() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (_isLoadingCentrosCosto) {
      return const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Centro de Costo',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
          ),
          SizedBox(height: 8),
          Center(child: CircularProgressIndicator()),
        ],
      );
    }

    if (_error != null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Centro de Costo',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.red.shade900.withOpacity(0.3)
                  : Colors.red.shade50,
              border: Border.all(
                color: isDark ? Colors.red.shade700 : Colors.red.shade300,
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.error,
                  color: isDark ? Colors.red.shade400 : Colors.red.shade700,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Error cargando centros de costo: $_error',
                    style: TextStyle(
                      color: isDark ? Colors.red.shade400 : Colors.red.shade700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    }

    // Mostrar mensaje si la lista está vacía
    if (_centroCosto.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Centro de Costo',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.orange.shade900.withOpacity(0.3)
                  : Colors.orange.shade50,
              border: Border.all(
                color: isDark ? Colors.orange.shade700 : Colors.orange.shade300,
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info,
                  color: isDark
                      ? Colors.orange.shade400
                      : Colors.orange.shade700,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'No hay centros de costo disponibles',
                    style: TextStyle(
                      color: isDark
                          ? Colors.orange.shade400
                          : Colors.orange.shade700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    }

    return DropdownButtonFormField<DropdownOption>(
      dropdownColor: isDark ? Colors.grey[800] : Colors.white,
      value: _selectedCentroCosto,
      decoration: InputDecoration(
        labelText: 'Centro de Costo',
        labelStyle: TextStyle(color: isDark ? Colors.grey[400] : null),
        border: UnderlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.transparent, width: 0),
        ),
        enabledBorder: UnderlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: isDark ? Colors.grey[600]! : Colors.grey,
            width: 1,
          ),
        ),
        focusedBorder: const UnderlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
          borderSide: BorderSide(color: Colors.green, width: 2),
        ),
        disabledBorder: UnderlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.white, width: 1),
        ),
        prefixIcon: Icon(
          Icons.account_box,
          color: isDark ? Colors.grey[400] : Colors.grey,
        ),
      ),
      isExpanded: true,
      style: TextStyle(color: isDark ? Colors.white : Colors.black),
      items: _centroCosto.map((centroCosto) {
        return DropdownMenuItem<DropdownOption>(
          value: centroCosto,
          child: Text(
            centroCosto.value,
            style: TextStyle(color: isDark ? Colors.white : Colors.black),
          ),
        );
      }).toList(),
      onChanged: (value) {
        setState(() {
          _selectedCentroCosto = value;
          _centroCostoController.text = value?.value ?? '';

          // 🔄 Cargar automáticamente el tipo de gasto y placa desde la metadata del centro de costo
          if (value?.metadata != null) {
            // Cargar tipo de gasto
            final tipogasto =
                value!.metadata!['tipogasto']?.toString() ??
                value.metadata!['tipoGasto']?.toString();

            if (tipogasto != null && tipogasto.isNotEmpty) {
              // Buscar el tipo de gasto en la lista
              final tipoGastoEncontrado = _tiposGasto.firstWhere(
                (tipo) => tipo.value.toUpperCase() == tipogasto.toUpperCase(),
                orElse: () => DropdownOption.empty,
              );

              if (tipoGastoEncontrado.id.isNotEmpty) {
                _selectedTipoGasto = tipoGastoEncontrado;
                _tipoGastoController.text = tipoGastoEncontrado.value;
                debugPrint(
                  '✅ Tipo de gasto asignado automáticamente: ${tipoGastoEncontrado.value}',
                );
              } else {
                debugPrint(
                  '⚠️ Tipo de gasto "$tipogasto" no encontrado en la lista',
                );
              }
            }

            // Cargar placa
            final placa = value.metadata!['placa']?.toString();
            if (placa != null && placa.isNotEmpty) {
              _placaController.text = placa;
              debugPrint('✅ Placa asignada automáticamente: $placa');
            } else {
              _placaController.text = ''; // Valor por defecto
              debugPrint('ℹ️ Placa por defecto: N');
            }
          }
        });
      },
      validator: (value) {
        if (value == null) {
          return 'Seleccione un centro de costo';
        }
        return null;
      },
    );
  }

  /// Construir la sección de tipo de gasto
  Widget _buildTipoMovilidadSection() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (_isLoadingTipoMovilidad) {
      return const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Tipo de Movilidad',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
          ),
          SizedBox(height: 8),
          Center(child: CircularProgressIndicator()),
        ],
      );
    }

    if (_error != null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Tipo de Movilidad',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.red.shade900.withOpacity(0.3)
                  : Colors.red.shade50,
              border: Border.all(
                color: isDark ? Colors.red.shade700 : Colors.red.shade300,
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.error,
                  color: isDark ? Colors.red.shade400 : Colors.red.shade700,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Error cargando: $_error',
                    style: TextStyle(
                      color: isDark ? Colors.red.shade400 : Colors.red.shade700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    }

    return DropdownButtonFormField<DropdownOption>(
      value: _selectedTipoMovilidad,
      dropdownColor: isDark ? Colors.grey[800] : Colors.white,
      decoration: InputDecoration(
        labelText: 'Tipo de Movilidad',
        labelStyle: TextStyle(color: isDark ? Colors.grey[400] : null),
        border: UnderlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.transparent, width: 0),
        ),
        enabledBorder: UnderlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: isDark ? Colors.grey[600]! : Colors.grey,
            width: 1,
          ),
        ),
        focusedBorder: const UnderlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
          borderSide: BorderSide(color: Colors.green, width: 2),
        ),
        disabledBorder: UnderlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.white, width: 1),
        ),
        prefixIcon: Icon(
          Icons.account_balance_wallet,
          color: isDark ? Colors.grey[400] : Colors.grey,
        ),
      ),
      isExpanded: true,
      style: TextStyle(color: isDark ? Colors.white : Colors.black),
      items: _tiposMovilidad.map((tiposMovilidad) {
        return DropdownMenuItem<DropdownOption>(
          value: tiposMovilidad,
          child: Text(
            tiposMovilidad.value,
            style: TextStyle(color: isDark ? Colors.white : Colors.black),
          ),
        );
      }).toList(),
      onChanged: (value) {
        setState(() {
          _selectedTipoMovilidad = value;
          _movilidadController.text = value?.value ?? '';
        });
      },
      validator: (value) {
        if (value == null) {
          return 'Seleccione movilidad';
        }
        return null;
      },
    );
  }

  /// Construir la sección de datos personalizados
  Widget _buildDatosMovilidadSection() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Datos de la Movilidad',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.green,
          ),
        ),
        const SizedBox(height: 8),

        // ORIGEN VIAJE
        TextFormField(
          focusNode: _origenFocusNode,
          textInputAction: TextInputAction.next,
          controller: _origenController,
          style: TextStyle(color: isDark ? Colors.white : Colors.black),
          decoration: InputDecoration(
            labelText: 'Origen',
            labelStyle: TextStyle(color: isDark ? Colors.grey[400] : null),
            border: UnderlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.transparent, width: 0),
            ),
            enabledBorder: UnderlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: isDark ? Colors.grey[600]! : Colors.grey,
                width: 1,
              ),
            ),
            focusedBorder: const UnderlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(12)),
              borderSide: BorderSide(color: Colors.green, width: 2),
            ),
            disabledBorder: UnderlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.white, width: 1),
            ),
            prefixIcon: Icon(
              Icons.badge,
              color: isDark ? Colors.grey[400] : Colors.grey,
            ),
          ),
          keyboardType: TextInputType.text,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Origen Obligatorio';
            }

            return null;
          },
        ),
        const SizedBox(height: 12),

        // DESTINO VIAJE
        TextFormField(
          focusNode: _destinoFocusNode,
          textInputAction: TextInputAction.next,
          controller: _destinoController,
          style: TextStyle(color: isDark ? Colors.white : Colors.black),
          decoration: InputDecoration(
            labelText: 'Destino',
            labelStyle: TextStyle(color: isDark ? Colors.grey[400] : null),
            border: UnderlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.transparent, width: 0),
            ),
            enabledBorder: UnderlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: isDark ? Colors.grey[600]! : Colors.grey,
                width: 1,
              ),
            ),
            focusedBorder: const UnderlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(12)),
              borderSide: BorderSide(color: Colors.green, width: 2),
            ),
            disabledBorder: UnderlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.white, width: 1),
            ),
            prefixIcon: Icon(
              Icons.badge,
              color: isDark ? Colors.grey[400] : Colors.grey,
            ),
          ),
          keyboardType: TextInputType.text,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Destino Obligatorio';
            }
            return null;
          },
        ),
        const SizedBox(height: 12),

        // MOTIVo VIAJE
        TextFormField(
          focusNode: _motivoViajeFocusNode,
          textInputAction: TextInputAction.next,
          controller: _motivoViajeController,
          style: TextStyle(color: isDark ? Colors.white : Colors.black),
          decoration: InputDecoration(
            labelText: 'Motivo Viaje',
            labelStyle: TextStyle(color: isDark ? Colors.grey[400] : null),
            border: UnderlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.transparent, width: 0),
            ),
            enabledBorder: UnderlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: isDark ? Colors.grey[600]! : Colors.grey,
                width: 1,
              ),
            ),
            focusedBorder: const UnderlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(12)),
              borderSide: BorderSide(color: Colors.green, width: 2),
            ),
            disabledBorder: UnderlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.white, width: 1),
            ),
            prefixIcon: Icon(
              Icons.badge,
              color: isDark ? Colors.grey[400] : Colors.grey,
            ),
          ),
          keyboardType: TextInputType.text,
          validator: (value) {
            if (widget.politicaSeleccionada.value == "GASTOS DE MOVILIDAD") {
              if (value == null || value.isEmpty) {
                return 'Motivo Viaje Obligatorio';
              }
            }
            return null;
          },
        ),
        const SizedBox(height: 12),

        // MOVILIDAD
        _buildTipoMovilidadSection(),
        const SizedBox(height: 12),

        // PLACA (Se carga automáticamente pero es editable)
        TextFormField(
          focusNode: _placaFocusNode,
          textInputAction: TextInputAction.next,
          controller: _placaController,
          style: TextStyle(color: isDark ? Colors.white : Colors.black),
          decoration: InputDecoration(
            labelText: 'Placa',
            labelStyle: TextStyle(color: isDark ? Colors.grey[400] : null),
            suffixIcon: Tooltip(
              message: 'La placa se carga automáticamente pero puede editarse',
              child: Icon(Icons.info_outline, size: 20, color: Colors.grey),
            ),
            border: UnderlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.transparent, width: 0),
            ),
            enabledBorder: UnderlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: isDark ? Colors.grey[600]! : Colors.grey,
                width: 1,
              ),
            ),
            focusedBorder: const UnderlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(12)),
              borderSide: BorderSide(color: Colors.green, width: 2),
            ),
            disabledBorder: UnderlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.white, width: 1),
            ),
            prefixIcon: Icon(
              Icons.badge,
              color: isDark ? Colors.grey[400] : Colors.grey,
            ),
          ),
          keyboardType: TextInputType.text,
        ),
        const SizedBox(height: 12),
      ],
    );
  }

  /// Construir la sección de notas
  Widget _buildNotasSection() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          focusNode: _notaFocusNode,
          textInputAction: TextInputAction.next,
          controller: _notaController,
          style: TextStyle(color: isDark ? Colors.white : Colors.black),
          decoration: InputDecoration(
            labelText: 'Nota o Glosa:',
            labelStyle: TextStyle(color: isDark ? Colors.grey[400] : null),
            border: OutlineInputBorder(
              borderSide: BorderSide(
                color: isDark ? Colors.grey[600]! : Colors.grey,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderSide: BorderSide(
                color: isDark ? Colors.grey[600]! : Colors.grey,
              ),
            ),
            focusedBorder: const OutlineInputBorder(
              borderSide: BorderSide(color: Colors.green, width: 2),
            ),
            prefixIcon: Icon(
              Icons.note,
              color: isDark ? Colors.grey[400] : Colors.grey,
            ),
          ),
          maxLines: 2,
          maxLength: 500,
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'La nota es obligatoria';
            }
            return null;
          },
        ),
      ],
    );
  }

  /// Construir los botones de acción
  Widget _buildActionButtons() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(8),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: () async {
                await _clearDraft(); // 🗑️ Limpiar borrador al cancelar
                widget.onCancel();
              },
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 8),
                side: BorderSide(
                  color: isDark ? Colors.grey[600]! : Colors.grey,
                ),
                foregroundColor: isDark ? Colors.grey[400] : Colors.grey,
              ),
              child: Text(
                'Cancelar',
                style: TextStyle(
                  fontSize: 16,
                  color: isDark ? Colors.grey[400] : Colors.grey,
                ),
              ),
            ),
          ),
          const SizedBox(width: 18),
          Expanded(
            child: ElevatedButton(
              onPressed: _boolMostrar ? _guardarValidar : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: _boolMostrar ? Colors.green : Colors.grey,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 8),
              ),
              child: const Text(
                'Guardar',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Construir la sección del lector de código SUNAT
  Widget _buildLectorSunatSection() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Card(
      color: isDark ? Colors.grey[800] : Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.qr_code_scanner, color: Colors.green),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Lector de Código QR',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black,
                    ),
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: _isScanning ? null : _scanQRCode,
                  icon: Icon(
                    _isScanning ? Icons.hourglass_empty : Icons.qr_code_scanner,
                    size: 16,
                  ),
                  label: Text(_isScanning ? 'Escaneando...' : 'Escanear QR'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    textStyle: const TextStyle(fontSize: 12),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 1),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _hasScannedData
                    ? (isDark
                          ? Colors.green.shade800.withOpacity(0.3)
                          : Colors.green.shade50)
                    : (isDark ? Colors.grey.shade800 : Colors.grey.shade50),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: _hasScannedData
                      ? (isDark ? Colors.green.shade600 : Colors.green.shade200)
                      : (isDark ? Colors.grey.shade600 : Colors.grey.shade300),
                ),
              ),
              child: _hasScannedData
                  ? Column(
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.check_circle,
                              color: Colors.green.shade600,
                              size: 20,
                            ),
                            const SizedBox(width: 1),
                            const Text(
                              'Código QR procesado correctamente',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: Colors.green,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 2),
                        TextButton.icon(
                          onPressed: _clearScannedData,
                          icon: const Icon(Icons.clear, size: 16),
                          label: const Text('Limpiar Datos'),
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.red,
                            textStyle: const TextStyle(fontSize: 12),
                          ),
                        ),
                      ],
                    )
                  : Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: Colors.grey.shade600,
                          size: 15,
                        ),
                        const SizedBox(width: 2),
                        Expanded(
                          child: Text(
                            'Escanee el código QR de la factura',
                            style: TextStyle(
                              color: isDark
                                  ? Colors.grey[400]
                                  : Colors.grey.shade600,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  /// Método para escanear código QR
  Future<void> _scanQRCode() async {
    if (mounted) {
      setState(() {
        _isScanning = true;
      });
    }

    try {
      // Navegar a la pantalla de escáner
      final qrData = await Navigator.push<String>(
        context,
        MaterialPageRoute(builder: (context) => _QRScannerScreen()),
      );

      if (qrData != null && qrData.isNotEmpty) {
        _processQRData(qrData);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al escanear QR: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isScanning = false;
        });
      }
    }
  }

  /// Procesar los datos del QR y llenar los campos
  void _processQRData(String qrData) {
    try {
      if (mounted) {
        setState(() {
          _hasScannedData = true;
          _validar = false; // ✅ Bloquear edición de campos después de escanear
        });
      }

      // Parsear el QR de SUNAT (formato típico separado por |)
      final parts = qrData.split('|');

      if (parts.length >= 6) {
        // Formato típico de QR SUNAT:
        // RUC|Tipo|Serie|Número|IGV|Total|Fecha|TipoDoc|DocReceptor

        // Envolver las asignaciones en setState y escribir en ambos controladores
        if (mounted) {
          setState(() {
            // RUC del emisor (proveedor)
            if (parts[0].isNotEmpty) {
              _rucProveedorController.text = parts[0];
              _loadApiRuc(_rucProveedorController.text);
            }

            // Tipo de comprobante (texto) -> actualizar controlador UI y el usado en guardado
            if (parts[1].isNotEmpty) {
              String tipoDoc = parts[1];
              String tipoTexto;
              switch (tipoDoc) {
                case '01':
                  tipoTexto = 'FACTURA ELECTRONICA';
                  break;
                case '03':
                  tipoTexto = 'BOLETA DE VENTA';
                  break;
                case '07':
                  tipoTexto = 'NOTA DE CREDITO';
                  break;
                case '08':
                  tipoTexto = 'NOTA DE DEBITO';
                  break;
                case '09':
                  tipoTexto = 'GUIA DE REMISION';
                  break;
                case '10':
                  tipoTexto = 'RECIBO POR HONORARIOS';
                default:
                  tipoTexto = 'COMPROBANTE';
              }
              _tipoComprobanteController.text = tipoTexto;
            }

            // Serie
            if (parts[2].isNotEmpty) {
              _serieFacturaController.text = parts[2];
            }

            // Número de factura
            if (parts[3].isNotEmpty) {
              _numeroFacturaController.text = parts[3];
            }

            // Igv
            if (parts[4].isNotEmpty) {
              _igvController.text = parts[4];
            }

            // Total
            if (parts[5].isNotEmpty) {
              _totalController.text = parts[5];
            }

            // Fecha (si está disponible)
            if (parts.length > 6 && parts[6].isNotEmpty) {
              final fechaNormalizada = _logic.normalizarFecha(parts[6]);
              _fechaController.text = fechaNormalizada;
            }

            // RUC del cliente/receptor (si está disponible)
            // Formato QR SUNAT típico: RUC_Emisor|Tipo|Serie|Número|IGV|Total|Fecha|TipoDoc_Receptor|Doc_Receptor
            if (parts.length > 8 && parts[8].isNotEmpty) {
              _rucClienteController.text = parts[8];
            }
          });
        }

        if (mounted) {
          /*  ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Datos del QR aplicados correctamente'),
              backgroundColor: Colors.green,
            ),
          ); */
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              behavior: SnackBarBehavior.floating,
              margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              backgroundColor: Colors.green.shade700.withOpacity(0.95),
              elevation: 8,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
              content: Row(
                children: const [
                  Icon(Icons.verified, color: Colors.white, size: 26),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Datos del QR aplicados correctamente',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }
      } else {
        throw Exception('Formato de QR no válido');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al procesar QR: $e'),
            backgroundColor: Colors.red,
          ),
        );
        setState(() {
          _hasScannedData = false;
        });
      }
    }
  }

  /// Normaliza diferentes formatos de fecha al formato ISO (YYYY-MM-DD)
  // Normalización delegada a NuevoGastoLogic.normalizarFecha

  /// Limpiar los datos escaneados
  void _clearScannedData() {
    if (mounted) {
      setState(() {
        _hasScannedData = false;
        _validar = true; // ✅ Reactivar edición cuando se limpian datos

        // Limpiar los campos que se llenaron automáticamente
        _rucProveedorController.clear();
        _rucClienteController.clear(); // ✅ Limpiar RUC del cliente
        _razonSocialController.clear();
        _serieFacturaController.clear();
        _tipoComprobanteController.text =
            'FACTURA ELECTRONICA'; // ✅ Restaurar valor por defecto
        _selectedComprobante =
            'FACTURA ELECTRONICA'; // ✅ Restaurar también la variable de selección
        _numeroFacturaController.clear();
        _totalController.clear();
        _igvController.clear();
        _fechaController.text = DateTime.now().toString().split(' ')[0];
      });

      ScaffoldMessenger.of(context).showSnackBar(
        /*    const SnackBar(
          content: Text('Datos del QR limpiados'),
          backgroundColor: Colors.orange,
        ), */
        SnackBar(
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(20),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          backgroundColor: Colors.orange.shade700,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          content: Row(
            children: const [
              Icon(Icons.cleaning_services, color: Colors.white, size: 26),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Datos del QR limpiados',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }
}

/// Pantalla del escáner QR para códigos SUNAT
class _QRScannerScreen extends StatefulWidget {
  @override
  State<_QRScannerScreen> createState() => _QRScannerScreenState();
}

class _QRScannerScreenState extends State<_QRScannerScreen> {
  MobileScannerController cameraController = MobileScannerController();
  bool _isProcessing = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      resizeToAvoidBottomInset:
          true, //Esto hace que la pantalla se ajuste al teclado
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: const Text('Escanear Código QR'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.flash_on),
            onPressed: () => cameraController.toggleTorch(),
          ),
        ],
      ),
      body: Stack(
        children: [
          // Cámara escáner
          MobileScanner(controller: cameraController, onDetect: _onQRDetected),

          // Overlay con marco de escaneo
          Container(
            decoration: ShapeDecoration(
              shape: QrScannerOverlayShape(
                borderColor: Colors.blue,
                borderRadius: 10,
                borderLength: 30,
                borderWidth: 10,
                cutOutSize: 250,
              ),
            ),
          ),

          // Instrucciones
          Positioned(
            bottom: 100,
            left: 0,
            right: 0,
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 32),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'Enfoque el código QR de la factura SUNAT\npara extraer los datos automáticamente',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),

          // Indicador de procesamiento
          if (_isProcessing)
            Container(
              color: Colors.black54,
              child: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: Colors.blue),
                    SizedBox(height: 16),
                    Text(
                      'Procesando código QR...',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _onQRDetected(BarcodeCapture capture) {
    if (_isProcessing) return;

    final List<Barcode> barcodes = capture.barcodes;
    if (barcodes.isNotEmpty) {
      final String? qrData = barcodes.first.rawValue;
      if (qrData != null && qrData.isNotEmpty) {
        setState(() {
          _isProcessing = true;
        });

        // Pequeño delay para mostrar el indicador de procesamiento
        Future.delayed(const Duration(milliseconds: 500), () {
          Navigator.pop(context, qrData);
        });
      }
    }
  }

  @override
  void dispose() {
    cameraController.dispose();
    super.dispose();
  }
}

/// Shape personalizado para el overlay del escáner QR
class QrScannerOverlayShape extends ShapeBorder {
  const QrScannerOverlayShape({
    this.borderColor = Colors.blue,
    this.borderWidth = 3.0,
    this.overlayColor = const Color.fromRGBO(0, 0, 0, 80),
    this.borderRadius = 0,
    this.borderLength = 40,
    double? cutOutSize,
  }) : cutOutSize = cutOutSize ?? 250;

  final Color borderColor;
  final double borderWidth;
  final Color overlayColor;
  final double borderRadius;
  final double borderLength;
  final double cutOutSize;

  @override
  EdgeInsetsGeometry get dimensions => const EdgeInsets.all(10);

  @override
  Path getInnerPath(Rect rect, {TextDirection? textDirection}) {
    return Path()
      ..fillType = PathFillType.evenOdd
      ..addPath(getOuterPath(rect), Offset.zero);
  }

  @override
  Path getOuterPath(Rect rect, {TextDirection? textDirection}) {
    Path getLeftTopPath(Rect rect) {
      return Path()
        ..moveTo(rect.left, rect.bottom)
        ..lineTo(rect.left, rect.top + borderRadius)
        ..quadraticBezierTo(
          rect.left,
          rect.top,
          rect.left + borderRadius,
          rect.top,
        )
        ..lineTo(rect.right, rect.top);
    }

    return getLeftTopPath(rect)
      ..lineTo(rect.right, rect.bottom)
      ..lineTo(rect.left, rect.bottom)
      ..lineTo(rect.left, rect.top);
  }

  @override
  void paint(Canvas canvas, Rect rect, {TextDirection? textDirection}) {
    final width = rect.width;
    final height = rect.height;
    final cutOutWidth = cutOutSize < width ? cutOutSize : width - borderWidth;
    final cutOutHeight = cutOutSize < height
        ? cutOutSize
        : height - borderWidth;

    final backgroundPath = Path()
      ..addRect(rect)
      ..addOval(
        Rect.fromCenter(
          center: rect.center,
          width: cutOutWidth,
          height: cutOutHeight,
        ),
      )
      ..fillType = PathFillType.evenOdd;

    final backgroundPaint = Paint()
      ..color = overlayColor
      ..style = PaintingStyle.fill;

    canvas.drawPath(backgroundPath, backgroundPaint);

    // Dibujar las esquinas del marco
    final borderPaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = borderWidth;

    final path = Path();

    // Esquina superior izquierda
    path.moveTo(
      rect.center.dx - cutOutWidth / 2,
      rect.center.dy - cutOutHeight / 2 + borderLength,
    );
    path.lineTo(
      rect.center.dx - cutOutWidth / 2,
      rect.center.dy - cutOutHeight / 2,
    );
    path.lineTo(
      rect.center.dx - cutOutWidth / 2 + borderLength,
      rect.center.dy - cutOutHeight / 2,
    );

    // Esquina superior derecha
    path.moveTo(
      rect.center.dx + cutOutWidth / 2 - borderLength,
      rect.center.dy - cutOutHeight / 2,
    );
    path.lineTo(
      rect.center.dx + cutOutWidth / 2,
      rect.center.dy - cutOutHeight / 2,
    );
    path.lineTo(
      rect.center.dx + cutOutWidth / 2,
      rect.center.dy - cutOutHeight / 2 + borderLength,
    );

    // Esquina inferior derecha
    path.moveTo(
      rect.center.dx + cutOutWidth / 2,
      rect.center.dy + cutOutHeight / 2 - borderLength,
    );
    path.lineTo(
      rect.center.dx + cutOutWidth / 2,
      rect.center.dy + cutOutHeight / 2,
    );
    path.lineTo(
      rect.center.dx + cutOutWidth / 2 - borderLength,
      rect.center.dy + cutOutHeight / 2,
    );

    // Esquina inferior izquierda
    path.moveTo(
      rect.center.dx - cutOutWidth / 2 + borderLength,
      rect.center.dy + cutOutHeight / 2,
    );
    path.lineTo(
      rect.center.dx - cutOutWidth / 2,
      rect.center.dy + cutOutHeight / 2,
    );
    path.lineTo(
      rect.center.dx - cutOutWidth / 2,
      rect.center.dy + cutOutHeight / 2 - borderLength,
    );

    canvas.drawPath(path, borderPaint);
  }

  @override
  ShapeBorder scale(double t) {
    return QrScannerOverlayShape(
      borderColor: borderColor,
      borderWidth: borderWidth,
      overlayColor: overlayColor,
    );
  }
}
