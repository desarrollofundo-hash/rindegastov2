//factura_modal_movilidad.dart
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flu2/controllers/edit_reporte_controller.dart';
// import 'package:flu2/models/apiruc_model.dart';
import 'package:flu2/models/dropdown_option.dart';
import 'package:flu2/services/user_service.dart';
import 'package:flu2/widgets/nuevo_gasto_logic.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:open_filex/open_filex.dart';
import 'package:printing/printing.dart';
import 'package:path/path.dart' as p;
import '../models/factura_data.dart';
import '../models/categoria_model.dart';
import '../services/categoria_service.dart';
import '../services/company_service.dart';
import '../services/api_service.dart';
import '../screens/home_screen.dart';
import '../themes/app_theme.dart';
import 'package:path_provider/path_provider.dart';

/// Widget modal personalizado para gastos de movilidad
class FacturaModalMovilidad extends StatefulWidget {
  final FacturaData facturaData;
  final String politicaSeleccionada;
  final Function(FacturaData, String?) onSave;
  final VoidCallback onCancel;

  const FacturaModalMovilidad({
    super.key,
    required this.facturaData,
    required this.politicaSeleccionada,
    required this.onSave,
    required this.onCancel,
  });

  @override
  State<FacturaModalMovilidad> createState() => _FacturaModalMovilidadState();
}

class _FacturaModalMovilidadState extends State<FacturaModalMovilidad> {
  // Para tipos de gasto
  bool _isLoadingTiposGasto = false;
  bool _isEditMode = true;
  bool _isDisposed =
      false; // Variable para trackear si el widget ha sido disposed

  String? _errorTiposGasto;
  List<String> _tiposGasto = [];
  // Controladores para cada campo específico de movilidad
  final FocusNode _origenFocusNode = FocusNode();
  final FocusNode _destinoFocusNode = FocusNode();
  final FocusNode _motivoViajeFocusNode = FocusNode();
  final FocusNode _placaFocusNode = FocusNode();
  final FocusNode _notaFocusNode = FocusNode();

  late TextEditingController _politicaController;
  late TextEditingController _rucController;
  late TextEditingController _razonSocialController;
  late TextEditingController _tipoComprobanteController;
  late TextEditingController _serieController;
  late TextEditingController _numeroController;
  late TextEditingController _igvController;
  late TextEditingController _fechaEmisionController;
  late TextEditingController _totalController;
  late TextEditingController _monedaController;
  late TextEditingController _rucClienteController;
  late TextEditingController _notaController;
  late TextEditingController _centroCostoController;

  // Campos específicos para movilidad
  late TextEditingController _origenController;
  late TextEditingController _destinoController;
  late TextEditingController _motivoViajeController;
  late TextEditingController _tipoTransporteController;
  late TextEditingController _categoriaController;
  late TextEditingController _tipoGastoController;
  late TextEditingController _placaController;

  late final EditReporteController _controller;

  File? _selectedFile;
  String? _selectedFileType; // 'image' o 'pdf'
  String? _selectedFileName;
  final ImagePicker _picker = ImagePicker();
  final ApiService _apiService = ApiService();
  final NuevoGastoLogic _logic = NuevoGastoLogic();

  bool _isLoading = false;
  bool _isLoadingCategorias = false;
  List<CategoriaModel> _categoriasMovilidad = [];
  List<DropdownOption> _tiposMovilidad = [];
  List<DropdownOption> _centroCosto = [];
  DropdownOption? _selectedCentroCosto;

  String? _errorCategorias;
  String? _errorTiposMovilidad;
  bool _isLoadingCentrosCosto = false;
  String? _error;

  ///ApiRuc
  // bool _isLoadingApiRuc = false;
  // String? _errorApiRuc;
  // ApiRuc? _apiRucData;

  bool _isLoadingTipoMovilidad = false;

  // Opciones para moneda
  String? _selectedMoneda;
  final List<String> _monedas = ['PEN', 'USD', 'EUR'];

  // Variables para validación de campos obligatorios
  bool _isFormValid = false;
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _initializeControllers();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!_canSetState) return;

      await Future.wait([
        _loadCategorias(),
        _loadTiposGasto(),
        _loadCentrosCosto(),

        _loadTipoMovilidad(),
        _loadApiRuc(widget.facturaData.ruc.toString()),
      ]);
    });
    _addValidationListeners();
  }

  /// Helper method para verificar si es seguro hacer setState
  bool get _canSetState => mounted && !_isDisposed;

  /// Cargar tipos de gasto desde la API
  Future<void> _loadTiposGasto() async {
    if (!mounted) return;
    setState(() {
      _isLoadingTiposGasto = true;
      _errorTiposGasto = null;
    });
    try {
      final tipos = await _apiService.getTiposGasto();
      if (!mounted) return;
      setState(() {
        _tiposGasto = tipos.map((e) => e.toString()).toList();
        _isLoadingTiposGasto = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorTiposGasto = e.toString();
        _isLoadingTiposGasto = false;
      });
    }
  }

  /// Cargar tipos de gasto desde la API
  Future<void> _loadTipoMovilidad() async {
    if (mounted) {
      setState(() {
        _isLoadingTipoMovilidad = true;
        _errorTiposMovilidad = null;
      });
    }

    try {
      final tiposMovilidad = await _apiService.getTiposMovilidad();
      if (mounted) {
        setState(() {
          _tiposMovilidad = tiposMovilidad;
          _isLoadingTipoMovilidad = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorTiposMovilidad = e.toString();
          _isLoadingTipoMovilidad = false;
        });
      }
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
                // Buscar el tipo de gasto en la lista (String)
                final tipoGastoEncontrado = _tiposGasto.firstWhere(
                  (tipo) => tipo.toUpperCase() == tipogasto.toUpperCase(),
                  orElse: () => '',
                );

                if (tipoGastoEncontrado.isNotEmpty) {
                  _tipoGastoController.text = tipoGastoEncontrado;
                  debugPrint(
                    '✅ Tipo de gasto asignado automáticamente: $tipoGastoEncontrado',
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

  /// Cargar información del RUC desde la API
  Future<void> _loadApiRuc(String ruc) async {
    /* if (mounted) {
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
    } */

    // Simulación para completar el campo de razón social
    if (mounted) {
      setState(() {
        _razonSocialController.text = 'Razón Social Simulada';
      });
    }
  }

  /// Agregar listeners para validación en tiempo real
  void _addValidationListeners() {
    _rucController.addListener(_validateForm);
    _rucClienteController.addListener(
      _validateForm,
    ); // ✅ Añadido listener para RUC cliente
    _tipoComprobanteController.addListener(_validateForm);
    _serieController.addListener(_validateForm);
    _numeroController.addListener(_validateForm);
    _fechaEmisionController.addListener(_validateForm);
    _totalController.addListener(_validateForm);
    _origenController.addListener(_validateForm);
    _destinoController.addListener(_validateForm);
    _motivoViajeController.addListener(_validateForm);
    _categoriaController.addListener(_validateForm);
    _notaController.addListener(_validateForm);
  }

  /// Validar si el RUC del cliente (escaneado) coincide con la empresa seleccionada
  bool _isRucValid() {
    final rucClienteEscaneado = _rucClienteController.text.trim();
    final rucEmpresaSeleccionada = CompanyService().companyRuc;

    // Si no hay RUC del cliente escaneado o no hay empresa seleccionada, consideramos válido
    if (rucClienteEscaneado.isEmpty || rucEmpresaSeleccionada.isEmpty) {
      return true;
    }

    return rucClienteEscaneado == rucEmpresaSeleccionada;
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

  /// Validar si todos los campos obligatorios están llenos
  void _validateForm() {
    final isValid =
        _rucController.text.trim().isNotEmpty &&
        _tipoComprobanteController.text.trim().isNotEmpty &&
        _serieController.text.trim().isNotEmpty &&
        _numeroController.text.trim().isNotEmpty &&
        _fechaEmisionController.text.trim().isNotEmpty &&
        _totalController.text.trim().isNotEmpty &&
        _origenController.text.trim().isNotEmpty &&
        _destinoController.text.trim().isNotEmpty &&
        _motivoViajeController.text.trim().isNotEmpty &&
        _categoriaController.text.trim().isNotEmpty &&
        (_centroCostoController.text
            .trim()
            .isNotEmpty) && // ✅ Validación segura de centro de costo
        _rucClienteController.text.trim().isNotEmpty &&
        _notaController.text.trim().isNotEmpty &&
        (_selectedFile !=
            null) && // ✅ Actualizado para aceptar archivos o imágenes
        _isRucValid(); // ✅ Añadida validación de RUC

    if (_isFormValid != isValid && _canSetState) {
      setState(() {
        _isFormValid = isValid;
      });
    }
  }

  /// Cargar categorías desde la API para GASTOS DE MOVILIDAD
  Future<void> _loadCategorias() async {
    if (!mounted) return;
    setState(() {
      _isLoadingCategorias = true;
      _errorCategorias = null;
    });

    try {
      final categorias = await CategoriaService.getCategoriasMovilidad();

      // 🔍 Filtrar: excluir las que contengan "PLANILLA DE MOVILIDAD"
      final categoriasFiltradas = categorias
          .where(
            (c) =>
                !c.toString().toUpperCase().contains('PLANILLA DE MOVILIDAD'),
          )
          .toList();

      if (!mounted) return;
      setState(() {
        _categoriasMovilidad = categoriasFiltradas;
        _isLoadingCategorias = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorCategorias = e.toString();
        _isLoadingCategorias = false;
      });
    }
  }

  /// Inicializar todos los controladores con los datos parseados del QR
  void _initializeControllers() {
    _politicaController = TextEditingController(
      text: widget.politicaSeleccionada,
    );
    _tipoGastoController = TextEditingController(
      text: CompanyService().companyTipogasto,
    );
    _rucController = TextEditingController(text: widget.facturaData.ruc ?? '');

    _centroCostoController = TextEditingController();
    _razonSocialController = TextEditingController();
    _tipoComprobanteController = TextEditingController(
      text: widget.facturaData.tipoComprobante ?? '',
    );
    _serieController = TextEditingController(
      text: widget.facturaData.serie ?? '',
    );
    _numeroController = TextEditingController(
      text: widget.facturaData.numero ?? '',
    );
    _igvController = TextEditingController(
      text: widget.facturaData.codigo ?? '',
    );
    _fechaEmisionController = TextEditingController(
      text: widget.facturaData.fechaEmision ?? '',
    );
    _totalController = TextEditingController(
      text: widget.facturaData.total?.toString() ?? '',
    );
    _monedaController = TextEditingController(
      text: widget.facturaData.moneda ?? 'PEN',
    );
    _rucClienteController = TextEditingController(
      text: widget.facturaData.rucCliente ?? '',
    );
    _notaController = TextEditingController(text: '');

    // Campos específicos para movilidad
    _origenController = TextEditingController(text: '');
    _destinoController = TextEditingController(text: '');
    _motivoViajeController = TextEditingController(text: '');
    _tipoTransporteController = TextEditingController(text: 'TAXI');
    _placaController = TextEditingController(
      text: CompanyService().companyPlaca,
    );
    _categoriaController = TextEditingController(text: '');

    //INICIALIZAR MONEDA
    _selectedMoneda = 'PEN';
  }

  @override
  void dispose() {
    _isDisposed = true;
    _disposeControllers();
    _apiService.dispose();
    super.dispose();
  }

  void _disposeControllers() {
    // Remover listeners antes de dispose
    _rucController.removeListener(_validateForm);
    _rucClienteController.removeListener(
      _validateForm,
    ); // ✅ Añadido removal para RUC cliente
    _tipoComprobanteController.removeListener(_validateForm);
    _serieController.removeListener(_validateForm);
    _numeroController.removeListener(_validateForm);
    _fechaEmisionController.removeListener(_validateForm);
    _totalController.removeListener(_validateForm);
    _origenController.removeListener(_validateForm);
    _destinoController.removeListener(_validateForm);
    _motivoViajeController.removeListener(_validateForm);
    _categoriaController.removeListener(_validateForm);
    _centroCostoController.removeListener(_validateForm);

    // Dispose de los controladores
    _politicaController.dispose();
    _rucController.dispose();
    _razonSocialController.dispose();
    _tipoComprobanteController.dispose();
    _serieController.dispose();
    _numeroController.dispose();
    _igvController.dispose();
    _fechaEmisionController.dispose();
    _totalController.dispose();
    _monedaController.dispose();
    _rucClienteController.dispose();
    _notaController.dispose();
    _origenController.dispose();
    _destinoController.dispose();
    _motivoViajeController.dispose();
    _tipoTransporteController.dispose();
    _categoriaController.dispose();
    _placaController.dispose();
  }

  /// Seleccionar archivo (imagen o PDF)
  Future<void> _pickImage() async {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    try {
      if (!mounted) return;
      setState(() => _isLoading = true);

      // Mostrar opciones para seleccionar tipo de archivo
      final selectedOption = await showDialog<String>(
        context: context,
        builder: (BuildContext context) {
          final bool isDark = Theme.of(context).brightness == Brightness.dark;

          /*   return AlertDialog(
            title: const Text('Seleccionar evidencia'),
            content: const Text('¿Qué tipo de archivo desea agregar?'),
            backgroundColor: Colors.white,
            actions: [
              TextButton.icon(
                onPressed: () => Navigator.pop(context, 'camera'),
                icon: const Icon(Icons.camera_alt),
                label: const Text('Tomar Foto'),
              ),
              TextButton.icon(
                onPressed: () => Navigator.pop(context, 'gallery'),
                icon: const Icon(Icons.photo_library),
                label: const Text('Galería'),
              ),
              TextButton.icon(
                onPressed: () => Navigator.pop(context, 'pdf'),
                icon: const Icon(Icons.picture_as_pdf),
                label: const Text('Archivo PDF'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancelar'),
              ),
            ],
          ); */
          return AlertDialog(
            backgroundColor: isDark ? AppTheme.surfaceDark : Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
            titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
            contentPadding: const EdgeInsets.fromLTRB(24, 16, 24, 10),

            title: Row(
              children: [
                Icon(
                  Icons.attach_file,
                  color: isDark ? AppTheme.primaryDark : Colors.blue,
                  size: 26,
                ),
                const SizedBox(width: 10),
                Text(
                  'Seleccionar evidencia',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                    color: isDark ? AppTheme.textPrimaryDark : Colors.black,
                  ),
                ),
              ],
            ),

            content: Text(
              '¿Qué tipo de archivo deseas agregar?',
              style: TextStyle(
                fontSize: 15,
                height: 1.4,
                color: isDark ? AppTheme.textSecondaryDark : Colors.black87,
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
                      foregroundColor: isDark
                          ? AppTheme.primaryDark
                          : Colors.blue,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    onPressed: () => Navigator.pop(context, 'camera'),
                    icon: const Icon(Icons.camera_alt_rounded),
                    label: const Text(
                      'Tomar Foto',
                      style: TextStyle(fontSize: 16),
                    ),
                  ),

                  // Galería
                  TextButton.icon(
                    style: TextButton.styleFrom(
                      foregroundColor: isDark
                          ? Colors.purple.shade300
                          : Colors.purple,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    onPressed: () => Navigator.pop(context, 'gallery'),
                    icon: const Icon(Icons.photo_library_rounded),
                    label: const Text(
                      'Galería',
                      style: TextStyle(fontSize: 16),
                    ),
                  ),

                  // PDF
                  TextButton.icon(
                    style: TextButton.styleFrom(
                      foregroundColor: isDark
                          ? Colors.red.shade300
                          : Colors.red,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    onPressed: () => Navigator.pop(context, 'pdf'),
                    icon: const Icon(Icons.picture_as_pdf_rounded),
                    label: const Text(
                      'Archivo PDF',
                      style: TextStyle(fontSize: 16),
                    ),
                  ),

                  const SizedBox(height: 6),

                  // Cancelar
                  TextButton(
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.red,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    onPressed: () => Navigator.pop(context),
                    child: const Text(
                      'Cancelar',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
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
            backgroundColor: isDark ? Colors.red.shade400 : Colors.red,
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
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

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
            toolbarTitle: 'Recortar Imagen',
            toolbarColor: isDark ? AppTheme.primaryDark : Colors.green,
            toolbarWidgetColor: isDark ? AppTheme.backgroundDark : Colors.white,
            initAspectRatio:
                CropAspectRatioPreset.square, // Relación cuadrada inicial
            lockAspectRatio: false, // No bloquear la relación de aspecto
          ),
          IOSUiSettings(
            minimumAspectRatio: 1.0, // Relación mínima de aspecto
          ),
        ],
      );

      if (croppedFile != null && mounted) {
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
    } on PlatformException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al recortar la imagen: $e'),
            backgroundColor: isDark ? Colors.red.shade400 : Colors.red,
          ),
        );
      }
    }
  }

  /// Mostrar alerta en medio de la pantalla con mensaje del servidor
  void _showServerAlert(String message) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        final bool isDark = Theme.of(context).brightness == Brightness.dark;

        return Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.all(20),
            margin: const EdgeInsets.symmetric(horizontal: 40),
            decoration: BoxDecoration(
              color: isDark ? Colors.red.shade400 : Colors.red,
              borderRadius: BorderRadius.circular(15),
              boxShadow: [
                BoxShadow(
                  color: isDark
                      ? Colors.black.withOpacity(0.5)
                      : Colors.black.withOpacity(0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.warning_rounded,
                  color: isDark ? Colors.white : Colors.white,
                  size: 50,
                ),
                const SizedBox(height: 16),
                Text(
                  'Mensaje del Servidor',
                  style: TextStyle(
                    color: isDark ? Colors.white : Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  message,
                  style: TextStyle(
                    color: isDark ? Colors.white : Colors.white,
                    fontSize: 16,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isDark
                        ? AppTheme.backgroundDark
                        : Colors.white,
                    foregroundColor: isDark
                        ? AppTheme.textPrimaryDark
                        : Colors.red,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 30,
                      vertical: 12,
                    ),
                  ),
                  child: const Text(
                    'Entendido',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Extraer mensaje del error del servidor
  String _extractServerMessage(String errorString) {
    try {
      // Buscar si el error contiene JSON con mensaje
      final regex = RegExp(r'\{.*"message".*?:.*?"([^"]+)".*\}');
      final match = regex.firstMatch(errorString);

      if (match != null && match.group(1) != null) {
        return match.group(1)!;
      }

      // Si no encuentra JSON, usar el mensaje completo pero limitado
      if (errorString.length > 200) {
        return errorString.substring(0, 200) + '...';
      }

      return errorString;
    } catch (e) {
      return 'Error al procesar la respuesta del servidor';
    }
  }

  /// Convertir PDF a imagen PNG con múltiples estrategias de fallback
  Future<File?> convertirPdfAImagen(File pdfFile) async {
    try {
      debugPrint('🔄 Iniciando conversión de PDF a imagen...');

      // 1️⃣ Validar que el archivo existe
      if (!await pdfFile.exists()) {
        debugPrint('❌ El archivo PDF no existe');
        return null;
      }

      // 2️⃣ Leer los bytes del PDF
      final pdfBytes = await pdfFile.readAsBytes();

      // 3️⃣ Validar que no está vacío
      if (pdfBytes.isEmpty) {
        debugPrint('❌ El archivo PDF está vacío');
        return null;
      }

      // 4️⃣ Validar firma del PDF (debe empezar con %PDF)
      final header = String.fromCharCodes(pdfBytes.take(4));
      if (!header.startsWith('%PDF')) {
        debugPrint('❌ El archivo no es un PDF válido (header: $header)');
        return null;
      }

      debugPrint('✅ PDF válido detectado (${pdfBytes.lengthInBytes} bytes)');

      // 5️⃣ Verificar tamaño del PDF (limitar a 10MB para evitar problemas de memoria)
      const int maxSizeForConversion = 10 * 1024 * 1024; // 10 MB
      if (pdfBytes.lengthInBytes > maxSizeForConversion) {
        debugPrint(
          '⚠️ PDF demasiado grande (${pdfBytes.lengthInBytes} bytes), omitiendo conversión',
        );
        return null;
      }

      // 6️⃣ Intentar conversión con diferentes calidades (fallback automático)
      final List<double> dpis = [
        150.0,
        100.0,
        72.0,
      ]; // Calidad alta, media, baja

      for (double dpi in dpis) {
        try {
          debugPrint('📄 Intentando rasterizar con $dpi DPI...');

          final stream = Printing.raster(pdfBytes, pages: [0], dpi: dpi);
          final raster = await stream.first.timeout(
            const Duration(seconds: 30),
            onTimeout: () {
              throw TimeoutException('Timeout al rasterizar PDF');
            },
          );

          final uiImage = await raster.toImage();
          debugPrint(
            '✅ Imagen rasterizada: ${uiImage.width}x${uiImage.height}',
          );

          // 7️⃣ Convertir la imagen UI a bytes PNG
          final byteData = await uiImage.toByteData(
            format: ui.ImageByteFormat.png,
          );
          if (byteData == null) {
            debugPrint(
              '⚠️ No se pudo convertir a bytes con DPI $dpi, probando siguiente...',
            );
            continue;
          }

          // 8️⃣ Validar que los bytes no están vacíos
          final imageBytes = byteData.buffer.asUint8List();
          if (imageBytes.isEmpty) {
            debugPrint('⚠️ Bytes vacíos con DPI $dpi, probando siguiente...');
            continue;
          }

          // 9️⃣ Guardar la imagen como archivo temporal
          final tempDir = await getTemporaryDirectory();
          final timestamp = DateTime.now().millisecondsSinceEpoch;
          final imagePath = '${tempDir.path}/pdf_converted_$timestamp.png';
          final imageFile = File(imagePath);
          await imageFile.writeAsBytes(imageBytes);

          // 🔟 Validar que el archivo se guardó correctamente
          if (!await imageFile.exists()) {
            debugPrint('⚠️ Archivo no se guardó correctamente con DPI $dpi');
            continue;
          }

          final fileSize = await imageFile.length();
          if (fileSize == 0) {
            debugPrint('⚠️ Archivo guardado está vacío con DPI $dpi');
            await imageFile.delete();
            continue;
          }

          debugPrint('✅ Conversión exitosa con $dpi DPI');
          debugPrint('✅ Imagen guardada en: $imagePath');
          debugPrint('📊 Dimensiones: ${uiImage.width}x${uiImage.height}');
          debugPrint('📊 Tamaño del archivo: $fileSize bytes');

          return imageFile;
        } catch (e) {
          debugPrint('⚠️ Error con DPI $dpi: $e');
          if (dpi == dpis.last) {
            // Si es el último intento, propagar el error
            rethrow;
          }
          // Continuar con el siguiente DPI
          continue;
        }
      }

      debugPrint('❌ No se pudo convertir con ningún nivel de calidad');
      return null;
    } on TimeoutException catch (e) {
      debugPrint('❌ Timeout al convertir PDF: $e');
      return null;
    } catch (e, stackTrace) {
      debugPrint('❌ Error al convertir PDF a imagen: $e');
      debugPrint('Stack trace: $stackTrace');
      return null;
    }
  }

  /// Guardar factura mediante API
  Future<void> _saveFacturaAPI() async {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    print('🚀 Iniciando guardado de factura...');

    // Validar campos obligatorios antes de continuar
    if (!_isFormValid) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              '❌ Por favor complete todos los campos obligatorios',
            ),
            backgroundColor: isDark ? Colors.red.shade400 : Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
      return;
    }

    // 🔍 VALIDACIÓN: RUC del cliente escaneado debe coincidir con empresa seleccionada
    final rucClienteEscaneado = _rucClienteController.text.trim();
    final rucEmpresaSeleccionada = CompanyService().companyRuc;

    if (rucClienteEscaneado.isNotEmpty && rucEmpresaSeleccionada.isNotEmpty) {
      if (rucClienteEscaneado != rucEmpresaSeleccionada) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '❌ RUC del cliente no coincide con la empresa seleccionada',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text('RUC cliente escaneado: $rucClienteEscaneado'),
                  Text('RUC empresa: $rucEmpresaSeleccionada'),
                  Text('Empresa: ${CompanyService().currentUserCompany}'),
                ],
              ),
              backgroundColor: isDark ? Colors.red.shade400 : Colors.red,
              duration: const Duration(seconds: 6),
              action: SnackBarAction(
                label: 'OK',
                textColor: isDark ? Colors.white : Colors.white,
                onPressed: () {},
              ),
            ),
          );
        }
        return;
      }
    }

    try {
      if (!mounted) return;
      setState(() => _isLoading = true);

      // Formatear fecha para SQL Server (solo fecha, sin hora)
      String fechaSQL = "";
      if (_fechaEmisionController.text.isNotEmpty) {
        try {
          // Intentar parsear la fecha del QR
          final fecha = DateTime.parse(_fechaEmisionController.text);
          fechaSQL =
              "${fecha.year}-${fecha.month.toString().padLeft(2, '0')}-${fecha.day.toString().padLeft(2, '0')}";
        } catch (e) {
          // Si falla, usar fecha actual
          final fecha = DateTime.now();
          fechaSQL =
              "${fecha.year}-${fecha.month.toString().padLeft(2, '0')}-${fecha.day.toString().padLeft(2, '0')}";
        }
      } else {
        final fecha = DateTime.now();
        fechaSQL =
            "${fecha.year}-${fecha.month.toString().padLeft(2, '0')}-${fecha.day.toString().padLeft(2, '0')}";
      }

      final body = {
        "idUser": UserService().currentUserCode,
        "dni": UserService().currentUserDni,
        "politica": _politicaController.text.length > 80
            ? _politicaController.text.substring(0, 80)
            : _politicaController.text,
        "categoria": _categoriaController.text.isEmpty
            ? "MOVILIDAD"
            : (_categoriaController.text.length > 80
                  ? _categoriaController.text.substring(0, 80)
                  : _categoriaController.text),
        "tipoGasto": _tipoGastoController.text.isEmpty
            ? "GASTO DE MOVILIDAD"
            : (_tipoGastoController.text.length > 80
                  ? _tipoGastoController.text.substring(0, 80)
                  : _tipoGastoController.text),
        "ruc": _rucController.text.isEmpty
            ? ""
            : (_rucController.text.length > 80
                  ? _rucController.text.substring(0, 80)
                  : _rucController.text),
        "proveedor": _razonSocialController.text,
        "tipoCombrobante": _tipoComprobanteController.text.isEmpty
            ? ""
            : (_tipoComprobanteController.text.length > 180
                  ? _tipoComprobanteController.text.substring(0, 180)
                  : _tipoComprobanteController.text),
        "serie": _serieController.text.isEmpty
            ? ""
            : (_serieController.text.length > 80
                  ? _serieController.text.substring(0, 80)
                  : _serieController.text),
        "numero": _numeroController.text.isEmpty
            ? ""
            : (_numeroController.text.length > 80
                  ? _numeroController.text.substring(0, 80)
                  : _numeroController.text),
        "igv": double.tryParse(_igvController.text) ?? 0.0,
        "fecha": fechaSQL,
        "total": double.tryParse(_totalController.text) ?? 0.0,
        "moneda": _monedaController.text.isEmpty
            ? "PEN"
            : (_monedaController.text.length > 80
                  ? _monedaController.text.substring(0, 80)
                  : _monedaController.text),
        "rucCliente": _rucClienteController.text.isEmpty
            ? ""
            : (_rucClienteController.text.length > 80
                  ? _rucClienteController.text.substring(0, 80)
                  : _rucClienteController.text),
        "desEmp": CompanyService().currentCompany?.empresa ?? '',
        "desSed": "",
        "gerencia": CompanyService().currentCompany?.gerencia ?? '',
        "area": CompanyService().currentCompany?.area ?? '',
        "idCuenta": "",
        /* "consumidor": CompanyService().currentCompany?.consumidor ?? '', */
        "consumidor": _centroCostoController.text,
        "placa": _placaController.text,
        "estadoActual": "BORRADOR",
        "glosa": "ESCANER IA",
        "motivoViaje": _motivoViajeController.text.length > 50
            ? _motivoViajeController.text.substring(0, 50)
            : _motivoViajeController.text,
        "lugarOrigen": _origenController.text.length > 50
            ? _origenController.text.substring(0, 50)
            : _origenController.text,
        "lugarDestino": _destinoController.text.length > 50
            ? _destinoController.text.substring(0, 50)
            : _destinoController.text,
        "tipoMovilidad": _tipoTransporteController.text.length > 50
            ? _tipoTransporteController.text.substring(0, 50)
            : _tipoTransporteController.text,
        "obs": _notaController.text.length > 1000
            ? _notaController.text.substring(0, 1000)
            : _notaController.text,
        "estado": "S", // Solo 1 carácter como requiere la BD
        "fecCre": DateTime.now().toIso8601String(),
        "useReg": UserService().currentUserCode, // Campo obligatorio
        "hostname": "FLUTTER", // Campo obligatorio, máximo 50 caracteres
        "fecEdit": DateTime.now().toIso8601String(),
        "useEdit": 0,
        "useElim": 0,
      };

      // ✅ Proceder con el guardado
      print('✅ Procediendo a guardar...');
      final idRend = await _apiService.saveRendicionGasto(body);

      if (idRend == null) {
        throw Exception(
          'No se pudo guardar la factura principal o no se obtuvo el ID autogenerado',
        );
      }

      debugPrint('🆔 ID autogenerado obtenido: $idRend');
      debugPrint('📋 Preparando datos de evidencia con el ID generado...');

      // 🔄 Si es un PDF, convertirlo a imagen
      File archivoASubir = _selectedFile!;
      String extensionFinal = p.extension(_selectedFile!.path);

      if (_selectedFile!.path.toLowerCase().endsWith('.pdf')) {
        debugPrint('📄 Detectado PDF, convirtiendo a imagen...');
        try {
          final imagenConvertida = await convertirPdfAImagen(_selectedFile!);
          if (imagenConvertida != null) {
            archivoASubir = imagenConvertida;
            extensionFinal = '.png';
            debugPrint('✅ PDF convertido a imagen exitosamente');
          } else {
            debugPrint('⚠️ No se pudo convertir PDF, subiendo PDF original');
          }
        } catch (e) {
          debugPrint('❌ Error al convertir PDF: $e');
          debugPrint('⚠️ Subiendo PDF original');
        }
      }

      String nombreArchivo =
          '${idRend.toString()}_${_rucController.text}_${_serieController.text}_${_numeroController.text}$extensionFinal';

      final driveId = await _apiService.subirArchivo(
        archivoASubir.path,
        nombreArchivo: nombreArchivo,
      );

      final facturaDataEvidencia = {
        "idRend": idRend, // ✅ Usar el ID autogenerado del API principal
        "evidencia": null,
        "obs": driveId,
        "estado": "S", // Solo 1 carácter como requiere la BD
        "fecCre": DateTime.now().toIso8601String(),
        "useReg": UserService().currentUserCode, // Campo obligatorio
        "hostname": "FLUTTER", // Campo obligatorio, máximo 50 caracteres
        "fecEdit": DateTime.now().toIso8601String(),
        "useEdit": 0,
        "useElim": 0,
      };

      final successEvidencia = await _apiService.saveRendicionGastoEvidencia(
        facturaDataEvidencia,
      );

      if (successEvidencia && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  height: 80,
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F9D58),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Row(
                    children: [
                      const SizedBox(width: 48),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '¡Éxito!',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: isDark ? Colors.white : Colors.white,
                              ),
                            ),
                            const Spacer(),
                            Text(
                              'Factura guardada correctamente',
                              style: TextStyle(
                                fontSize: 14,
                                color: isDark
                                    ? Colors.white.withOpacity(0.8)
                                    : Colors.white.withOpacity(0.8),
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Positioned(
                  bottom: -10,
                  left: 15,
                  child: ClipRRect(
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(10),
                    ),
                    child: Icon(
                      Icons.check_circle,
                      size: 40,
                      color: Colors.green[900],
                    ),
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.transparent,
            elevation: 0,
            duration: const Duration(seconds: 3),
            behavior: SnackBarBehavior.floating,
          ),
        );

        // Cerrar el modal y navegar a la pantalla de gastos
        Navigator.of(context).pop(); // Cerrar modal
        Navigator.of(context).pop(); // Cerrar pantalla QR si existe

        // Navegar a HomeScreen con índice 0 (pestaña de Gastos)
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const HomeScreen()),
          (route) => false, // Remover todas las rutas anteriores
        );
      }
    } catch (e) {
      print('💥 Error capturado: $e');
      if (mounted) {
        // Extraer mensaje del servidor para mostrar en alerta
        final serverMessage = _extractServerMessage(e.toString());
        _showServerAlert(serverMessage);
      }
    } finally {
      print('🔄 Finalizando proceso...');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
  /* 
  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildImageSection(),
                    const SizedBox(height: 10),
                    _buildPolicySection(),
                    const SizedBox(height: 10),
                    _buildCategorySection(),
                    const SizedBox(height: 10),
                    _buildTipoGastoSection(),
                    const SizedBox(height: 10),
                    _buildFacturaDataSection(),
                    const SizedBox(height: 10),
                    _buildMovilidadSection(),
                    const SizedBox(height: 10),
                    _buildNotesSection(),
                  ],
                ),
              ),
            ),
            _buildActionButtons(),
          ],
        ),
      ),
    );
  }
 */

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final double maxHeight = MediaQuery.of(context).size.height * 0.93;
    final double minHeight = MediaQuery.of(context).size.height * 0.55;

    return Container(
      constraints: BoxConstraints(minHeight: minHeight, maxHeight: maxHeight),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.surfaceDark : Colors.white,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(22),
          topRight: Radius.circular(22),
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        resizeToAvoidBottomInset: true, // evita que el teclado tape los campos

        body: SafeArea(
          top: false,
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                // HEADER SUPERIOR
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: _buildHeader(),
                ),

                // CONTENIDO SCROLLEABLE
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildImageSection(),
                        const SizedBox(height: 10),

                        _buildPolicySection(),
                        const SizedBox(height: 10),

                        _buildCategorySection(),
                        const SizedBox(height: 10),

                        _buildCentroCostoSection(),
                        const SizedBox(height: 10),

                        _buildTipoGastoSection(),
                        const SizedBox(height: 10),

                        _buildFacturaDataSection(),
                        const SizedBox(height: 10),

                        _buildMovilidadSection(),
                        const SizedBox(height: 10),

                        _buildNotesSection(),
                      ],
                    ),
                  ),
                ),
                SafeArea(
                  top: false,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 1.0), // ← MÁS PEGADO
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
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color(0xFF1976D2),
            Color(0xFF42A5F5),
          ], // Azul/celeste original
        ),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.directions_car, color: Colors.white, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Gasto de Movilidad - Perú',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const Text(
                  'Datos extraídos del QR',
                  style: TextStyle(fontSize: 12, color: Colors.white70),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.close, color: Colors.white),
          ),
        ],
      ),
    );
  }

  /// Construir la sección de imagen
  Widget _buildImageSection() {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Card(
      color: isDark ? AppTheme.surfaceDark : Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.attach_file, color: Colors.red),
                const SizedBox(width: 8),
                Text(
                  'Adjuntar Evidencia',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isDark ? AppTheme.textPrimaryDark : Colors.black,
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
                      (_selectedFile == null) ? Icons.add : Icons.edit,
                    ),
                    label: Text(
                      (_selectedFile == null) ? 'Agregar' : 'Cambiar',
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isDark
                          ? AppTheme.primaryDark
                          : Colors.blue,
                      foregroundColor: isDark ? Colors.black87 : Colors.white,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),

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
                  color: isDark ? AppTheme.backgroundDark : Colors.white,
                  border: Border.all(
                    color: (_selectedFile == null)
                        ? Colors.red.shade300
                        : (isDark
                              ? Colors.grey.shade600
                              : Colors.grey.shade300),
                    width: (_selectedFile == null) ? 2 : 1,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.attach_file,
                      color: (_selectedFile == null) ? Colors.red : Colors.grey,
                      size: 40,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Agregar evidencia (Obligatorio)',
                      style: TextStyle(
                        color: (_selectedFile == null)
                            ? Colors.red
                            : (isDark
                                  ? AppTheme.textSecondaryDark
                                  : Colors.grey),
                        fontWeight: (_selectedFile == null)
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Imagen o PDF',
                      style: TextStyle(
                        color: isDark
                            ? AppTheme.textSecondaryDark
                            : Colors.grey.shade600,
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

  /*
  /// Construir la sección de imagen
  Widget _buildImageSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.attach_file, color: Colors.blue),
                const SizedBox(width: 8),
                const Text(
                  'Adjuntar Evidencia',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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
                      (_selectedImage == null && _selectedFile == null)
                          ? Icons.add
                          : Icons.edit,
                    ),
                    label: Text(
                      (_selectedImage == null && _selectedFile == null)
                          ? 'Agregar'
                          : 'Cambiar',
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
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
                    ? Container(
                        height: 200,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.file(_selectedFile!, fit: BoxFit.cover),
                        ),
                      )
                    : Container(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.picture_as_pdf,
                              color: Colors.blue,
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
              )
            else
              Container(
                height: 100,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  border: Border.all(
                    color: (_selectedImage == null && _selectedFile == null)
                        ? Colors.red.shade300
                        : Colors.grey.shade300,
                    width: (_selectedImage == null && _selectedFile == null)
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
                      color: (_selectedImage == null && _selectedFile == null)
                          ? Colors.red
                          : Colors.grey,
                      size: 40,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Agregar evidencia (Obligatorio)',
                      style: TextStyle(
                        color: (_selectedImage == null && _selectedFile == null)
                            ? Colors.red
                            : Colors.grey,
                        fontWeight:
                            (_selectedImage == null && _selectedFile == null)
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Imagen o PDF',
                      style: TextStyle(
                        color: Colors.grey.shade600,
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
*/

  Future<void> _handleTapEvidencia() async {
    try {
      String nombreArchivo =
          '${_rucController.text}_${_serieController.text}_${_numeroController.text}';

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

  /// Construir la sección de política
  Widget _buildPolicySection() {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Card(
      elevation: 0,
      color: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(0),
        side: BorderSide.none,
      ),
      child: Padding(
        padding: const EdgeInsets.all(2),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.policy,
                  color: isDark ? AppTheme.primaryDark : Colors.blue,
                ),
                const SizedBox(width: 8),
                Text(
                  'Política',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isDark ? AppTheme.textPrimaryDark : Colors.black,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _politicaController,
              enabled: false,
              style: TextStyle(
                color: isDark ? AppTheme.textPrimaryDark : Colors.black87,
              ),
              decoration: InputDecoration(
                labelText: 'Política Seleccionada',
                labelStyle: TextStyle(
                  color: isDark
                      ? AppTheme.textSecondaryDark
                      : Colors.grey.shade700,
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
                    color: isDark ? Colors.grey.shade600 : Colors.grey,
                    width: 1,
                  ),
                ),
                focusedBorder: UnderlineInputBorder(
                  borderRadius: const BorderRadius.all(Radius.circular(12)),
                  borderSide: BorderSide(
                    color: isDark ? AppTheme.primaryDark : Colors.blue,
                    width: 2,
                  ),
                ),
                disabledBorder: UnderlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: isDark ? Colors.grey.shade700 : Colors.grey,
                    width: 1,
                  ),
                ),
                prefixIcon: Icon(
                  Icons.policy,
                  color: isDark ? AppTheme.textSecondaryDark : Colors.grey,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Construir la sección de categoría para movilidad
  Widget _buildCategorySection() {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Card(
      elevation: 0,
      color: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(0),
        side: BorderSide.none,
      ),
      child: Padding(
        padding: const EdgeInsets.all(2),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.category,
                  color: isDark ? AppTheme.primaryDark : Colors.blue,
                ),
                const SizedBox(width: 8),
                Text(
                  'Categoría',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isDark ? AppTheme.textPrimaryDark : Colors.black,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (_isLoadingCategorias)
              const Center(
                child: Column(
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 8),
                    Text(
                      'Cargando categorías...',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              )
            else if (_errorCategorias != null)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error, color: Colors.red.shade600),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Error al cargar categorías: $_errorCategorias',
                        style: TextStyle(color: Colors.red.shade700),
                      ),
                    ),
                    TextButton(
                      onPressed: _loadCategorias,
                      child: const Text('Reintentar'),
                    ),
                  ],
                ),
              )
            else if (_categoriasMovilidad.isEmpty)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange.shade200),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.warning, color: Colors.orange),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'No hay categorías disponibles para esta política',
                        style: TextStyle(color: Colors.orange),
                      ),
                    ),
                  ],
                ),
              )
            else
              DropdownButtonFormField<String>(
                dropdownColor: isDark ? AppTheme.surfaceDark : Colors.white,
                style: TextStyle(
                  color: isDark ? AppTheme.textPrimaryDark : Colors.black87,
                ),
                decoration: InputDecoration(
                  labelText: 'Seleccionar Categoría *',
                  labelStyle: TextStyle(
                    color: isDark
                        ? AppTheme.textSecondaryDark
                        : Colors.grey.shade700,
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
                      color: isDark ? Colors.grey.shade600 : Colors.grey,
                      width: 1,
                    ),
                  ),
                  focusedBorder: UnderlineInputBorder(
                    borderRadius: const BorderRadius.all(Radius.circular(12)),
                    borderSide: BorderSide(
                      color: isDark ? AppTheme.primaryDark : Colors.blue,
                      width: 2,
                    ),
                  ),
                  disabledBorder: UnderlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: isDark ? Colors.grey.shade700 : Colors.grey,
                      width: 1,
                    ),
                  ),
                  prefixIcon: Icon(
                    Icons.category,
                    color: isDark ? AppTheme.textSecondaryDark : Colors.grey,
                  ),
                ),
                initialValue:
                    _categoriaController.text.isNotEmpty &&
                        _categoriasMovilidad.any(
                          (cat) => cat.categoria == _categoriaController.text,
                        )
                    ? _categoriaController.text
                    : null,
                items: _categoriasMovilidad
                    .map(
                      (categoria) => DropdownMenuItem<String>(
                        value: categoria.categoria,
                        child: Text(
                          _formatCategoriaName(categoria.categoria),
                          style: TextStyle(
                            color: isDark
                                ? AppTheme.textPrimaryDark
                                : Colors.black87,
                          ),
                        ),
                      ),
                    )
                    .toList(),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Categoría es obligatoria';
                  }
                  return null;
                },
                onChanged: (value) {
                  if (value != null && _canSetState) {
                    setState(() {
                      _categoriaController.text = value;
                    });
                    _validateForm(); // Validar cuando cambie la categoría
                  }
                },
              ),
          ],
        ),
      ),
    );
  }

  /// Formatear el nombre de la categoría para mostrar
  String _formatCategoriaName(String categoria) {
    return categoria
        .toLowerCase()
        .split(' ')
        .map(
          (word) => word.isNotEmpty
              ? '${word[0].toUpperCase()}${word.substring(1).toLowerCase()}'
              : word,
        )
        .join(' ');
  }

  /// Sección separada para Tipo de Gasto
  Widget _buildTipoGastoSection() {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Card(
      elevation: 0,
      color: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(0),
        side: BorderSide.none,
      ),
      child: Padding(
        padding: const EdgeInsets.all(2),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              /*  children: [
                Icon(
                  Icons.local_offer,
                  color: isDark ? AppTheme.primaryDark : Colors.blue,
                ),
                const SizedBox(width: 8),
                Text(
                  'Tipo de Gasto',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isDark ? AppTheme.textPrimaryDark : Colors.black,
                  ),
                ),
              ], */
            ),
            if (_isLoadingTiposGasto)
              const Center(
                child: Column(
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 8),
                    Text(
                      'Cargando tipos de gasto...',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              )
            else if (_errorTiposGasto != null)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error, color: Colors.red.shade600),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Error al cargar tipos de gasto: $_errorTiposGasto',
                        style: TextStyle(color: Colors.red.shade700),
                      ),
                    ),
                    TextButton(
                      onPressed: _loadTiposGasto,
                      child: const Text('Reintentar'),
                    ),
                  ],
                ),
              )
            else
              DropdownButtonFormField<String>(
                dropdownColor: isDark ? AppTheme.surfaceDark : Colors.white,

                style: TextStyle(
                  color: isDark ? AppTheme.textPrimaryDark : Colors.black87,
                ),
                decoration: InputDecoration(
                  labelText: 'Tipo de Gasto (Automático)',
                  labelStyle: TextStyle(
                    color: isDark
                        ? AppTheme.textSecondaryDark
                        : Colors.grey.shade700,
                  ),
                  prefixIcon: Icon(
                    Icons.lock_outline,
                    color: isDark ? Colors.grey[400] : Colors.grey,
                  ),
                  suffixIcon: Tooltip(
                    message:
                        'El tipo de gasto se asigna automáticamente según el centro de costo',
                    child: Icon(
                      Icons.info_outline,
                      size: 20,
                      color: Colors.grey,
                    ),
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
                      color: isDark ? Colors.grey.shade600 : Colors.grey,
                      width: 1,
                    ),
                  ),
                  focusedBorder: UnderlineInputBorder(
                    borderRadius: const BorderRadius.all(Radius.circular(12)),
                    borderSide: BorderSide(
                      color: isDark ? AppTheme.primaryDark : Colors.blue,
                      width: 2,
                    ),
                  ),
                  disabledBorder: UnderlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: isDark ? Colors.grey.shade700 : Colors.grey,
                      width: 1,
                    ),
                  ),
                ),
                value:
                    _tipoGastoController.text.isNotEmpty &&
                        _tiposGasto.contains(_tipoGastoController.text)
                    ? _tipoGastoController.text
                    : null,
                items: _tiposGasto
                    .map(
                      (tipo) => DropdownMenuItem<String>(
                        value: tipo,
                        child: Text(
                          tipo,
                          style: TextStyle(
                            color: isDark
                                ? AppTheme.textPrimaryDark
                                : Colors.black87,
                          ),
                        ),
                      ),
                    )
                    .toList(),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Tipo de gasto es obligatorio';
                  }
                  return null;
                },
                /*  onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _tipoGastoController.text = value;
                    });
                    _validateForm();
                  }
                }, */
                onChanged: null, // Campo deshabilitado
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildFacturaDataSection() {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Card(
      elevation: 0,
      color: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(0),
        side: BorderSide.none,
      ),
      child: Padding(
        padding: const EdgeInsets.all(2),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.receipt_long,
                  color: isDark ? AppTheme.primaryDark : Colors.blue,
                ),
                const SizedBox(width: 8),
                Text(
                  'Datos de la Factura',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isDark ? AppTheme.textPrimaryDark : Colors.black,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildTextField(
                    _rucController,
                    'RUC Emisor',
                    Icons.business_center,
                    TextInputType.number,
                    isRequired: true,
                    readOnly: true,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildTextField(
                    _razonSocialController,
                    'Razon Social...',
                    Icons.business,
                    TextInputType.text,
                    isRequired: true,
                    readOnly: true,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildTextField(
                    _tipoComprobanteController,
                    'Tipo Comprobante',
                    Icons.description,
                    TextInputType.text,
                    isRequired: true,
                    readOnly: true,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildTextField(
                    _rucClienteController,
                    'RUC Cliente',
                    Icons.person_outline_rounded,
                    TextInputType.number,
                    readOnly: true,
                  ),
                ),
              ],
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

            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildTextField(
                    _fechaEmisionController,
                    'Fecha Emisión',
                    Icons.calendar_today,
                    TextInputType.datetime,
                    isRequired: true,
                    readOnly: true,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildTextField(
                    _serieController,
                    'Serie',
                    Icons.tag,
                    TextInputType.text,
                    isRequired: true,
                    readOnly: true,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildTextField(
                    _numeroController,
                    'Número',
                    Icons.numbers,
                    TextInputType.number,
                    isRequired: true,
                    readOnly: true,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Total y Moneda en la misma fila
            Row(
              children: [
                Expanded(
                  flex: 1,
                  child: TextFormField(
                    controller: _totalController,
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
                        borderSide: const BorderSide(
                          color: Colors.grey,
                          width: 1,
                        ),
                      ),
                      focusedBorder: const UnderlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(12)),
                        borderSide: BorderSide(color: Colors.blue, width: 2),
                      ),
                      disabledBorder: UnderlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: Colors.grey,
                          width: 1,
                        ),
                      ),
                      prefixIcon: const Icon(Icons.attach_money),
                    ),
                    keyboardType: TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    readOnly: true,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'El total es obligatorio';
                      }
                      if (double.tryParse(value) == null) {
                        return 'Ingrese un valor válido';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    dropdownColor: Colors.white,
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
                        borderSide: const BorderSide(
                          color: Colors.grey,
                          width: 1,
                        ),
                      ),
                      focusedBorder: const UnderlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(12)),
                        borderSide: BorderSide(color: Colors.blue, width: 2),
                      ),
                      disabledBorder: UnderlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: Colors.grey,
                          width: 1,
                        ),
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

            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildTextField(
                    _igvController,
                    'IGV',
                    Icons.attach_money,
                    TextInputType.text,
                    readOnly: true,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTipoMovilidad() {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Tipo de movilidad',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: isDark ? AppTheme.textPrimaryDark : Colors.black87,
          ),
        ),
        const SizedBox(height: 8),

        // Si está cargando, mostrar indicador
        if (_isLoadingTipoMovilidad)
          Column(
            children: [
              const Center(child: CircularProgressIndicator()),
              const SizedBox(height: 8),
              Text(
                'Cargando tipos movilidad...',
                style: TextStyle(
                  color: isDark ? AppTheme.textSecondaryDark : Colors.grey,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          )
        else if (_errorTiposMovilidad != null)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.red.shade900.withOpacity(0.3)
                  : Colors.red.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isDark ? Colors.red.shade600 : Colors.red.shade200,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.error,
                  color: isDark ? Colors.red.shade400 : Colors.red.shade600,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Error al cargar tipos movilidad: $_errorTiposMovilidad',
                    style: TextStyle(
                      color: isDark ? Colors.red.shade300 : Colors.red.shade700,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: _loadTiposGasto,
                  child: const Text('Reintentar'),
                ),
              ],
            ),
          )
        else
          AbsorbPointer(
            absorbing: !_isEditMode,
            child: DropdownButtonFormField<String>(
              style: TextStyle(
                color: isDark ? AppTheme.textPrimaryDark : Colors.black87,
                fontSize: 16,
              ),
              dropdownColor: isDark ? AppTheme.surfaceDark : Colors.white,
              decoration: InputDecoration(
                labelText: 'Tipo de Movilidad *',
                labelStyle: TextStyle(
                  color: isDark ? AppTheme.textSecondaryDark : Colors.grey[600],
                ),
                prefixIcon: Icon(
                  Icons.attach_money,
                  color: isDark ? AppTheme.primaryDark : Colors.grey[600],
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
                    color: isDark ? AppTheme.textSecondaryDark : Colors.grey,
                    width: 1,
                  ),
                ),
                focusedBorder: UnderlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(12)),
                  borderSide: BorderSide(
                    color: isDark ? AppTheme.primaryDark : Colors.blue,
                    width: 2,
                  ),
                ),
                disabledBorder: UnderlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: isDark ? AppTheme.textSecondaryDark : Colors.grey,
                    width: 1,
                  ),
                ),
                filled: true,
                fillColor: _isEditMode
                    ? (isDark ? AppTheme.surfaceDark : Colors.white)
                    : (isDark ? Colors.grey[800] : Colors.grey[100]),
              ),
              value:
                  _tipoTransporteController.text.isNotEmpty &&
                      _tiposMovilidad.any(
                        (tipo) => tipo.value == _tipoTransporteController.text,
                      )
                  ? _tipoTransporteController.text
                  : null,
              items: _tiposMovilidad
                  .map(
                    (tipo) => DropdownMenuItem<String>(
                      value: tipo.value,
                      child: Text(
                        tipo.value,
                        style: TextStyle(
                          color: isDark
                              ? AppTheme.textPrimaryDark
                              : Colors.black87,
                        ),
                      ),
                    ),
                  )
                  .toList(),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Tipo movilidad es obligatorio';
                }
                return null;
              },
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _tipoTransporteController.text = value;
                  });
                  _validateForm(); // Validar cuando cambie el tipo de gasto
                }
              },
            ),
          ),
      ],
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
                  ? Colors.blue.shade900.withOpacity(0.3)
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
              // Buscar el tipo de gasto en la lista (String)
              final tipoGastoEncontrado = _tiposGasto.firstWhere(
                (tipo) => tipo.toUpperCase() == tipogasto.toUpperCase(),
                orElse: () => '',
              );

              if (tipoGastoEncontrado.isNotEmpty) {
                _tipoGastoController.text = tipoGastoEncontrado;
                debugPrint(
                  '✅ Tipo de gasto asignado automáticamente: $tipoGastoEncontrado',
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

  /// Construir la sección específica de movilidad
  Widget _buildMovilidadSection() {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Card(
      elevation: 0,
      color: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(0),
        side: BorderSide.none,
      ),
      child: Padding(
        padding: const EdgeInsets.all(2),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.directions_car,
                  color: isDark ? AppTheme.primaryDark : Colors.blue,
                ),
                const SizedBox(width: 8),
                Text(
                  'Detalles de Movilidad',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isDark ? AppTheme.textPrimaryDark : Colors.black,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _origenController,
                    focusNode: _origenFocusNode,
                    textInputAction: TextInputAction.next,
                    style: TextStyle(
                      color: isDark ? AppTheme.textPrimaryDark : Colors.black87,
                    ),
                    decoration: InputDecoration(
                      labelText: 'Origen *',
                      labelStyle: TextStyle(
                        color: isDark
                            ? AppTheme.textSecondaryDark
                            : Colors.grey.shade700,
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
                          color: isDark ? Colors.grey.shade600 : Colors.grey,
                          width: 1,
                        ),
                      ),
                      focusedBorder: UnderlineInputBorder(
                        borderRadius: const BorderRadius.all(
                          Radius.circular(12),
                        ),
                        borderSide: BorderSide(
                          color: isDark ? AppTheme.primaryDark : Colors.blue,
                          width: 2,
                        ),
                      ),
                      disabledBorder: UnderlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: isDark ? Colors.grey.shade700 : Colors.grey,
                          width: 1,
                        ),
                      ),
                      prefixIcon: Icon(
                        Icons.my_location,
                        color: isDark
                            ? AppTheme.textSecondaryDark
                            : Colors.grey,
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Origen es obligatorio';
                      }
                      return null;
                    },
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    focusNode: _destinoFocusNode,
                    textInputAction: TextInputAction.next,
                    controller: _destinoController,
                    style: TextStyle(
                      color: isDark ? AppTheme.textPrimaryDark : Colors.black87,
                    ),
                    decoration: InputDecoration(
                      labelText: 'Destino *',
                      labelStyle: TextStyle(
                        color: isDark
                            ? AppTheme.textSecondaryDark
                            : Colors.grey.shade700,
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
                          color: isDark ? Colors.grey.shade600 : Colors.grey,
                          width: 1,
                        ),
                      ),
                      focusedBorder: UnderlineInputBorder(
                        borderRadius: const BorderRadius.all(
                          Radius.circular(12),
                        ),
                        borderSide: BorderSide(
                          color: isDark ? AppTheme.primaryDark : Colors.blue,
                          width: 2,
                        ),
                      ),
                      disabledBorder: UnderlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: isDark ? Colors.grey.shade700 : Colors.grey,
                          width: 1,
                        ),
                      ),
                      prefixIcon: Icon(
                        Icons.location_on,
                        color: isDark
                            ? AppTheme.textSecondaryDark
                            : Colors.grey,
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Destino es obligatorio';
                      }
                      return null;
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextFormField(
              focusNode: _motivoViajeFocusNode,
              textInputAction: TextInputAction.next,
              controller: _motivoViajeController,
              style: TextStyle(
                color: isDark ? AppTheme.textPrimaryDark : Colors.black87,
              ),
              decoration: InputDecoration(
                labelText: 'Motivo del Viaje *',
                labelStyle: TextStyle(
                  color: isDark
                      ? AppTheme.textSecondaryDark
                      : Colors.grey.shade700,
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
                    color: isDark ? Colors.grey.shade600 : Colors.grey,
                    width: 1,
                  ),
                ),
                focusedBorder: UnderlineInputBorder(
                  borderRadius: const BorderRadius.all(Radius.circular(12)),
                  borderSide: BorderSide(
                    color: isDark ? AppTheme.primaryDark : Colors.blue,
                    width: 2,
                  ),
                ),
                disabledBorder: UnderlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: isDark ? Colors.grey.shade700 : Colors.grey,
                    width: 1,
                  ),
                ),
                prefixIcon: Icon(
                  Icons.description,
                  color: isDark ? AppTheme.textSecondaryDark : Colors.grey,
                ),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Motivo del Viaje es obligatorio';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),

            _buildTipoMovilidad(),

            const SizedBox(height: 12),

            // PLACA
            TextFormField(
              focusNode: _placaFocusNode,
              textInputAction: TextInputAction.next,
              controller: _placaController,
              decoration: InputDecoration(
                labelText: 'Placa',
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
                  borderSide: BorderSide(color: Colors.blue, width: 2),
                ),
                disabledBorder: UnderlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Colors.grey, width: 1),
                ),
                prefixIcon: const Icon(Icons.badge),
              ),
              keyboardType: TextInputType.text,
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  /// Construir la sección de datos de factura

  /// Construir la sección de notas
  Widget _buildNotesSection() {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Card(
      elevation: 0,
      color: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(0),
        side: BorderSide.none,
      ),
      child: Padding(
        padding: const EdgeInsets.all(2),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.note_add,
                  color: isDark ? AppTheme.primaryDark : Colors.blue,
                ),
                const SizedBox(width: 8),
                Text(
                  'Notas Adicionales',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isDark ? AppTheme.textPrimaryDark : Colors.black,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _notaController,
              style: TextStyle(
                color: isDark ? AppTheme.textPrimaryDark : Colors.black87,
              ),
              decoration: InputDecoration(
                labelText: 'Nota o Glosa:',
                labelStyle: TextStyle(
                  color: isDark
                      ? AppTheme.textSecondaryDark
                      : Colors.grey.shade700,
                ),
                border: OutlineInputBorder(
                  borderSide: BorderSide(
                    color: isDark ? Colors.grey.shade600 : Colors.grey,
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(
                    color: isDark ? Colors.grey.shade600 : Colors.grey,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(
                    color: isDark ? AppTheme.primaryDark : Colors.blue,
                    width: 2,
                  ),
                ),
                prefixIcon: Icon(
                  Icons.note,
                  color: isDark ? AppTheme.textSecondaryDark : Colors.grey,
                ),
                filled: true,
                fillColor: isDark
                    ? AppTheme.backgroundDark
                    : Colors.grey.shade50,
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
        ),
      ),
    );
  }

  /// Construir los botones de acción
  Widget _buildActionButtons() {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.fromLTRB(
        20,
        8,
        20,
        8,
      ), // ← Reducido el padding superior
      child: Column(
        children: [
          // Mensaje de campos obligatorios
          if (!_isFormValid)
            Container(
              padding: const EdgeInsets.all(2),
              margin: const EdgeInsets.only(bottom: 6),
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.orange.withOpacity(0.2)
                    : Colors.orange.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isDark
                      ? Colors.orange.withOpacity(0.5)
                      : Colors.orange.shade200,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.warning,
                    color: isDark
                        ? Colors.orange.shade300
                        : Colors.orange.shade600,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Por favor complete todos los campos ',
                      style: TextStyle(
                        color: isDark ? Colors.orange.shade300 : Colors.orange,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: widget.onCancel,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    side: const BorderSide(color: Colors.red, width: 1.5),
                    backgroundColor: Colors.transparent,
                  ),
                  child: const Text(
                    'Cancelar',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.red,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: _isLoading || !_isFormValid
                      ? null
                      : _saveFacturaAPI,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    backgroundColor: _isFormValid ? Colors.green : Colors.grey,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: Colors.grey[400],
                    disabledForegroundColor: Colors.grey[600],
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        )
                      : Text(
                          _isFormValid ? 'Guardar Gasto' : 'Complete ',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Construir un campo de texto personalizado
  Widget _buildTextField(
    TextEditingController controller,
    String label,
    IconData icon,
    TextInputType keyboardType, {
    bool isRequired = false,
    bool readOnly = false,
  }) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      readOnly: readOnly,
      style: TextStyle(
        color: isDark ? AppTheme.textPrimaryDark : Colors.black87,
      ),
      decoration: InputDecoration(
        labelText: isRequired ? '$label *' : label,
        labelStyle: TextStyle(
          color: isDark ? AppTheme.textSecondaryDark : Colors.grey.shade700,
        ),
        prefixIcon: Icon(
          icon,
          color: isDark ? AppTheme.textSecondaryDark : Colors.grey,
        ),
        border: UnderlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.transparent, width: 0),
        ),
        enabledBorder: UnderlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: isDark ? Colors.grey.shade600 : Colors.grey,
            width: 1,
          ),
        ),
        focusedBorder: UnderlineInputBorder(
          borderRadius: const BorderRadius.all(Radius.circular(12)),
          borderSide: BorderSide(
            color: isDark ? AppTheme.primaryDark : Colors.blue,
            width: 2,
          ),
        ),
        disabledBorder: UnderlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: isDark ? Colors.grey.shade700 : Colors.grey,
            width: 1,
          ),
        ),
        filled: true,
        fillColor: readOnly
            ? (isDark ? Colors.grey.shade800 : Colors.grey.shade100)
            : (isDark ? AppTheme.backgroundDark : Colors.grey.shade50),
      ),
      validator: isRequired
          ? (value) {
              if (value == null || value.trim().isEmpty) {
                return '$label es obligatorio';
              }
              if (label == 'Total' && double.tryParse(value) == null) {
                return 'Ingrese un número válido';
              }
              return null;
            }
          : null,
    );
  }
}
