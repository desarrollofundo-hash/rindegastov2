import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
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
import '../models/dropdown_option.dart';
import '../services/api_service.dart';
import '../services/user_service.dart';
import '../services/company_service.dart';
import '../screens/home_screen.dart';
import 'nuevo_gasto_logic.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Modal para crear un nuevo gasto con todos los campos personalizados
class NuevoGastoModal extends StatefulWidget {
  final DropdownOption politicaSeleccionada;
  final VoidCallback onCancel;
  final Function(Map<String, dynamic>) onSave;

  const NuevoGastoModal({
    super.key,
    required this.politicaSeleccionada,
    required this.onCancel,
    required this.onSave,
  });

  @override
  State<NuevoGastoModal> createState() => _NuevoGastoModalState();
}

class _NuevoGastoModalState extends State<NuevoGastoModal> {
  final _formKey = GlobalKey<FormState>();
  final ApiService _apiService = ApiService();
  final NuevoGastoLogic _logic = NuevoGastoLogic();

  // Controladores para todos los campos
  late TextEditingController _politicaController;
  late TextEditingController _categoriaController;
  late TextEditingController _tipoGastoController;
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
  List<DropdownOption> _tiposMovilidad = [];
  DropdownOption? _selectedCategoria;
  DropdownOption? _selectedTipoGasto;
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
  ];

  String get fechaSQL =>
      DateFormat('yyyy-MM-dd').format(DateTime.parse(_fechaController.text));

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
    _initializeControllers();
    _loadCategorias();
    _loadTiposGasto();
    _loadTipoMovilidad();
    //_loadApiRuc(_rucController.toString());
    _addValidationListeners();
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
    _rucProveedorController = TextEditingController();
    _razonSocialController = TextEditingController();
    _rucClienteController = TextEditingController();
    _tipoComprobanteController = TextEditingController();
    _fechaController = TextEditingController(
      text: DateTime.now().toString().split(' ')[0], // Fecha actual por defecto
    );
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
    _politicaController.dispose();
    _categoriaController.dispose();
    _tipoGastoController.dispose();
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
  }

  /// Validar si todos los campos obligatorios están llenos
  void _validateForm() {
    final isValid =
        _tipoComprobanteController.text.trim().isNotEmpty &&
        _fechaController.text.trim().isNotEmpty &&
        _totalController.text.trim().isNotEmpty &&
        _categoriaController.text.trim().isNotEmpty &&
        _tipoGastoController.text.trim().isNotEmpty &&
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
          return AlertDialog(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
            titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
            contentPadding: const EdgeInsets.fromLTRB(24, 16, 24, 10),

            title: Row(
              children: const [
                Icon(Icons.attach_file, color: Colors.blue, size: 26),
                SizedBox(width: 10),
                Text(
                  'Seleccionar evidencia',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
                ),
              ],
            ),

            content: const Text(
              '¿Qué tipo de archivo deseas agregar?',
              style: TextStyle(
                fontSize: 15,
                height: 1.4,
                color: Colors.black87,
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
                    label: const Text(
                      'Tomar Foto',
                      style: TextStyle(fontSize: 16),
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
                    label: const Text(
                      'Galería',
                      style: TextStyle(fontSize: 16),
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
                    label: const Text(
                      'Archivo PDF',
                      style: TextStyle(fontSize: 16),
                    ),
                  ),

                  const SizedBox(height: 6),

                  // Cancelar
                  TextButton(
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.grey[700],
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
      if (CompanyService().companyRuc.toString() !=
          _rucClienteController.text) {
        _showMensaggeDialog(
          "Ruc del cliente no coincide con ruc en el comprobante",
        );
      } else if (_totalController.text.trim() == "") {
        _showMensaggeDialog("INGRESE MONTO");
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
      if (_selectedFile == null) {
        _showMensaggeDialog("ADJUNTE EVIDENCIA 📷");
      } else if (CompanyService().companyRuc.toString() !=
          _rucClienteController.text) {
        _showMensaggeDialog(
          "Ruc del cliente no coincide con ruc del comprobante",
        );
      } else if (_totalController.text.trim() == "") {
        _showMensaggeDialog("INGRESE MONTO");
      } else {
        _guardarGasto();
      }
    }
  }

  /// Guarda el gasto utilizando la API
  Future<void> _guardarGasto() async {
    // Antes
    // if (_selectedFile == null && _categoriaController.text == "PLANILLA DE MOVILIDAD")

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

      // Preparar datos del gasto usando la lógica separada
      final gastoData = _logic.prepareGastoData(
        politica: _politicaController.text,
        categoria: _categoriaController.text,
        tipoGasto: _tipoGastoController.text,
        ruc: _rucProveedorController.text,
        tipoComprobante: _tipoComprobanteController.text,
        serie: _serieFacturaController.text,
        numero: _numeroFacturaController.text,
        igv: _igvController.text,
        fecha: fechaSQL,
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
                    if (_categoriaController.text != "PLANILLA DE MOVILIDAD")
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
                  ],
                ),
              ),
            ),
            // Evitar que los botones queden pegados al borde inferior del modal
            SafeArea(
              top: false,
              left: false,
              right: false,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 1.0),
                child: _buildActionButtons(),
              ),
            ),
          ],
        ),
      ),
    );
  }
 */

  /* @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(60),
        child: SafeArea(
          child: _buildHeader(), // Tu encabezado original
        ),
      ),

      body: Form(
        key: _formKey,
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildImageSection(),
                    const SizedBox(height: 10),

                    if (_categoriaController.text != "PLANILLA DE MOVILIDAD")
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
                  ],
                ),
              ),
            ),

            // Zona inferior segura para evitar que se tape con el teclado
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: _buildActionButtons(),
              ),
            ),
          ],
        ),
      ),
    );
  }
 */

  @override
  Widget build(BuildContext context) {
    final double maxHeight = MediaQuery.of(context).size.height * 0.93;
    final double minHeight = MediaQuery.of(context).size.height * 0.55;

    return Container(
      constraints: BoxConstraints(minHeight: minHeight, maxHeight: maxHeight),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
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

  /// Construir la sección de imagen
  Widget _buildImageSection() {
    return Card(
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(1),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.attach_file, color: Colors.red),
                const SizedBox(width: 1),
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
                  color: Colors.grey.shade100,
                  border: Border.all(
                    color:
                        (widget.politicaSeleccionada.value !=
                                "GASTOS DE MOVILIDAD" &&
                            _selectedFile == null)
                        ? Colors.red.shade300
                        : Colors.grey.shade300,
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
                          : Colors.grey,
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
                            : Colors.grey,
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

        _buildTipoGastoSection(),
      ],
    );
  }

  /// Construir la sección de datos personalizados
  Widget _buildDatosFacturaSection() {
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
          // RUC Emisor
          /* TextFormField(
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
          ), */
          if (_categoriaController.text != "PLANILLA DE MOVILIDAD")
            TextFormField(
              controller: _rucProveedorController,
              readOnly: true, // 🔒 No editable
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
              keyboardType: TextInputType.number,
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
              controller: _razonSocialController,
              readOnly: true, // 🔒 No editable
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
                  return 'Seleccione';
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
              prefixIcon: Container(
                margin: const EdgeInsets.only(right: 8),
                child: const Icon(Icons.calendar_month, color: Colors.green),
              ),
              suffixIcon: _validar
                  ? IconButton(
                      icon: const Icon(Icons.expand_more, color: Colors.green),
                      onPressed: _selectDate,
                      tooltip: 'Seleccionar fecha',
                    )
                  : null,
              filled: true,
              fillColor: _fechaController.text.isEmpty
                  ? Colors.white
                  : Colors.white,
            ),
            readOnly:
                true, // ✅ Siempre true para evitar teclado, solo se usa el calendario
            onTap:
                (_validar &&
                    _categoriaController.text != "VIAJES CON COMPROBANTE")
                ? _selectDate
                : null, // ✅ Permite seleccionar fecha excepto en VIAJES CON COMPROBANTE

            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: _fechaController.text.isEmpty
                  ? Colors.grey.shade600
                  : Colors.black87,
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
                    controller: _serieFacturaController,
                    readOnly:
                        !_validar ||
                        _categoriaController.text ==
                            "VIAJES CON COMPROBANTE", // 🔒 Bloqueado después de escanear QR o si es VIAJES CON COMPROBANTE
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
                    controller: _numeroFacturaController,
                    readOnly:
                        !_validar ||
                        _categoriaController.text ==
                            "VIAJES CON COMPROBANTE", // 🔒 Bloqueado después de escanear QR o si es VIAJES CON COMPROBANTE

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
                    controller: _igvController,
                    /*  readOnly: true, // 🔒 Bloqueado solo después de escanear QR */
                    readOnly:
                        _categoriaController.text == "VIAJES CON COMPROBANTE" ||
                        _hasScannedData, // ✅ Solo bloqueado en VIAJES CON COMPROBANTE

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
                controller: _totalController,

                /*   readOnly:
                    (_categoriaController.text !=
                    "PLANILLA DE MOVILIDAD"), // ✅ Solo editable en planilla de movilidad
 */
                readOnly:
                    _categoriaController.text == "VIAJES CON COMPROBANTE" ||
                    _hasScannedData, // ✅ Solo bloqueado en VIAJES CON COMPROBANTE

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
              color: Colors.red.shade50,
              border: Border.all(color: Colors.red.shade300),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(Icons.error, color: Colors.red.shade700),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Error cargando categorías: $_error',
                    style: TextStyle(color: Colors.red.shade700),
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
      dropdownColor: Colors.white, // 👈 Cambia aquí el color de fondo del menú
      decoration: InputDecoration(
        labelText: 'Categoría',
        border: UnderlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.transparent, width: 0),
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
        prefixIcon: const Icon(Icons.category),
      ),
      isExpanded: true,
      items: _categorias.map((categoria) {
        return DropdownMenuItem<DropdownOption>(
          value: categoria,
          child: Text(categoria.value),
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
              color: Colors.red.shade50,
              border: Border.all(color: Colors.red.shade300),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(Icons.error, color: Colors.red.shade700),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Error cargando tipos de gasto: $_error',
                    style: TextStyle(color: Colors.red.shade700),
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    }

    return DropdownButtonFormField<DropdownOption>(
      dropdownColor: Colors.white,
      value: _selectedTipoGasto,
      decoration: InputDecoration(
        labelText: 'Tipo de Gasto',
        border: UnderlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.transparent, width: 0),
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
        prefixIcon: const Icon(Icons.account_balance_wallet),
      ),
      isExpanded: true,
      items: _tiposGasto.map((tipoGasto) {
        return DropdownMenuItem<DropdownOption>(
          value: tipoGasto,
          child: Text(tipoGasto.value),
        );
      }).toList(),
      onChanged: (value) {
        setState(() {
          _selectedTipoGasto = value;
          _tipoGastoController.text = value?.value ?? '';
        });
      },
      validator: (value) {
        if (value == null) {
          return 'Seleccione un tipo de gasto';
        }
        return null;
      },
    );
  }

  /// Construir la sección de tipo de gasto
  Widget _buildTipoMovilidadSection() {
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
              color: Colors.red.shade50,
              border: Border.all(color: Colors.red.shade300),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(Icons.error, color: Colors.red.shade700),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Error cargando: $_error',
                    style: TextStyle(color: Colors.red.shade700),
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
      decoration: InputDecoration(
        labelText: 'Tipo de Movilidad',
        border: UnderlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.transparent, width: 0),
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
        prefixIcon: const Icon(Icons.account_balance_wallet),
      ),
      isExpanded: true,
      items: _tiposMovilidad.map((tiposMovilidad) {
        return DropdownMenuItem<DropdownOption>(
          value: tiposMovilidad,
          child: Text(tiposMovilidad.value),
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
          controller: _origenController,
          decoration: InputDecoration(
            labelText: 'Origen',
            border: UnderlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.transparent, width: 0),
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
          controller: _destinoController,
          decoration: InputDecoration(
            labelText: 'Destino',
            border: UnderlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.transparent, width: 0),
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
          controller: _motivoViajeController,
          decoration: InputDecoration(
            labelText: 'Motivo Viaje',
            border: UnderlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.transparent, width: 0),
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

        // PLACA
        TextFormField(
          controller: _placaController,
          decoration: InputDecoration(
            labelText: 'Placa',
            border: UnderlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.transparent, width: 0),
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
          keyboardType: TextInputType.text,
        ),
        const SizedBox(height: 12),
      ],
    );
  }

  /// Construir la sección de notas
  Widget _buildNotasSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: _notaController,
          decoration: const InputDecoration(
            labelText: 'Nota o Glosa:',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.note),
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
    return Container(
      padding: const EdgeInsets.all(8),

      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: widget.onCancel,
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 8),
                side: const BorderSide(color: Colors.grey),
              ),
              child: const Text(
                'Cancelar',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            ),
          ),
          const SizedBox(width: 18),
          Expanded(
            child: ElevatedButton(
              onPressed: _guardarValidar,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
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
    return Card(
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.qr_code_scanner, color: Colors.green),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Lector de Código QR',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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
                    ? Colors.green.shade50
                    : Colors.grey.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: _hasScannedData
                      ? Colors.green.shade200
                      : Colors.grey.shade300,
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
                              color: Colors.grey.shade600,
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
            // RUC del emisor
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
          });
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Datos del QR aplicados correctamente'),
              backgroundColor: Colors.green,
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
        _razonSocialController.clear();
        _serieFacturaController.clear();
        _tipoComprobanteController.clear();
        _numeroFacturaController.clear();
        _totalController.clear();
        _igvController.clear();
        _fechaController.text = DateTime.now().toString().split(' ')[0];
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Datos del QR limpiados'),
          backgroundColor: Colors.orange,
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
