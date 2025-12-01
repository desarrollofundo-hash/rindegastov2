//factura_modal_peru.dart
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flu2/controllers/edit_reporte_controller.dart';
// import 'package:flu2/models/apiruc_model.dart'; // No utilizado actualmente
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:file_picker/file_picker.dart';
import 'package:open_filex/open_filex.dart';
import '../models/factura_data.dart';
import '../models/categoria_model.dart';
import '../models/dropdown_option.dart';
import '../services/categoria_service.dart';
import '../services/api_service.dart';
import '../screens/home_screen.dart';
import '../services/user_service.dart';
import '../services/company_service.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Widget modal personalizado para mostrar y editar datos de factura peruana
class FacturaModalPeru extends StatefulWidget {
  final FacturaData facturaData;
  final String politicaSeleccionada;
  final Function(FacturaData, String?) onSave;
  final VoidCallback onCancel;

  const FacturaModalPeru({
    super.key,
    required this.facturaData,
    required this.politicaSeleccionada,
    required this.onSave,
    required this.onCancel,
  });

  @override
  State<FacturaModalPeru> createState() => _FacturaModalPeruState();
}

class _FacturaModalPeruState extends State<FacturaModalPeru> {
  // Controladores para cada campo
  late TextEditingController _politicaController;
  late TextEditingController _categoriaController;
  late TextEditingController _tipoGastoController;
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

  // Campos específicos para movilidad - comentados porque no se usan actualmente
  // late TextEditingController _origenController;
  // late TextEditingController _destinoController;
  // late TextEditingController _motivoViajeController;
  // late TextEditingController _tipoTransporteController;
  late TextEditingController _placaController;

  late final EditReporteController _controller;

  File? _selectedFile;
  String? _selectedFileType; // 'image' o 'pdf'
  String? _selectedFileName;
  final ImagePicker _picker = ImagePicker();
  final ApiService _apiService = ApiService();
  bool _isLoading = false;
  bool _isLoadingCategorias = false;
  bool _isLoadingTiposGasto = false;
  List<CategoriaModel> _categoriasGeneral = [];
  List<DropdownOption> _tiposGasto = [];
  // List<DropdownOption> _tiposMovilidad = []; // No utilizado actualmente
  String? _errorCategorias;
  String? _errorTiposGasto;
  // String? _errorTiposMovilidad; // No utilizado

  ///ApiRuc - campos comentados porque no se usan actualmente
  // bool _isLoadingApiRuc = false;
  // String? _errorApiRuc;
  // ApiRuc? _apiRucData;

  // bool _isLoadingTipoMovilidad = false; // No utilizado

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
    _loadCategorias();
    _loadTiposGasto(); // Cargar gasto
    _loadTipoMovilidad();
    _loadApiRuc(
      widget.facturaData.ruc.toString(),
    ); //widget.facturaData.rucEmisor

    _addValidationListeners();
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
    _categoriaController.addListener(_validateForm);
    _tipoGastoController.addListener(_validateForm);
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
        _categoriaController.text.trim().isNotEmpty &&
        _tipoGastoController.text.trim().isNotEmpty &&
        _rucClienteController.text.trim().isNotEmpty &&
        _notaController.text.trim().isNotEmpty &&
        (_selectedFile !=
            null) && // ✅ Actualizado para aceptar archivos o imágenes
        _isRucValid(); // ✅ Añadida validación de RUC

    if (_isFormValid != isValid) {
      setState(() {
        _isFormValid = isValid;
      });
    }
  }

  /// Cargar categorías desde la API
  Future<void> _loadCategorias() async {
    if (!_politicaController.text.toLowerCase().contains('general')) {
      return; // Solo cargar para política GENERAL
    }

    if (mounted) {
      setState(() {
        _isLoadingCategorias = true;
        _errorCategorias = null;
      });
    }

    try {
      final categorias = await CategoriaService.getCategoriasGeneral();
      if (mounted) {
        setState(() {
          _categoriasGeneral = categorias;
          _isLoadingCategorias = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorCategorias = e.toString();
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
        _errorTiposGasto = null;
      });
    }

    try {
      final tiposGasto = await _apiService.getTiposGasto();
      if (mounted) {
        setState(() {
          _tiposGasto = tiposGasto;
          _isLoadingTiposGasto = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorTiposGasto = e.toString();
          _isLoadingTiposGasto = false;
        });
      }
    }
  }

  /// Cargar tipos de gasto desde la API
  Future<void> _loadTipoMovilidad() async {
    if (mounted) {
      setState(() {
        // _isLoadingTipoMovilidad = true;
        // _errorTiposMovilidad = null; // No utilizado
      });
    }

    try {
      // final tiposMovilidad = await _apiService.getTiposMovilidad(); // No utilizado
      if (mounted) {
        setState(() {
          // _tiposMovilidad = tiposMovilidad; // No utilizado
          // _isLoadingTipoMovilidad = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          // _errorTiposMovilidad = e.toString(); // No utilizado
          // _isLoadingTipoMovilidad = false;
        });
      }
    }
  }

  /// Cargar información del RUC desde la API
  Future<void> _loadApiRuc(String ruc) async {
    if (mounted) {
      setState(() {
        // _isLoadingApiRuc = true;
        // _errorApiRuc = null;
      });
    }

    try {
      // ✅ Aquí la llamada correcta al método de la API
      final apiRuc = await _apiService.getApiRuc(ruc: ruc);

      if (mounted) {
        setState(() {
          // _apiRucData = apiRuc;
          // _isLoadingApiRuc = false;

          // 👇 Aquí actualizas el TextEditingController después de obtener los datos
          _razonSocialController.text = apiRuc.nombreRazonSocial ?? 'S/N';
        });
      }

      debugPrint('✅ RUC cargado correctamente: ${apiRuc.ruc}');
    } catch (e) {
      debugPrint('❌ Error al cargar RUC: $e');
      if (mounted) {
        setState(() {
          // _errorApiRuc = e.toString();
          // _isLoadingApiRuc = false;
        });
      }
    }
  }

  /// Inicializar todos los controladores con los datos parseados del QR
  void _initializeControllers() {
    _politicaController = TextEditingController(
      text: widget.politicaSeleccionada,
    );
    _categoriaController = TextEditingController(text: '');
    _tipoGastoController = TextEditingController(
      text: CompanyService().companyTipogasto,
    );
    _rucController = TextEditingController(text: widget.facturaData.ruc ?? '');
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
      text: widget.facturaData.total?.toStringAsFixed(2) ?? '',
    );
    _monedaController = TextEditingController(
      text: widget.facturaData.moneda ?? 'PEN',
    );
    _rucClienteController = TextEditingController(
      text: widget.facturaData.rucCliente ?? '',
    );
    _notaController = TextEditingController(text: '');
    // _tipoTransporteController = TextEditingController(text: 'TAXI');
    _placaController = TextEditingController(
      text: CompanyService().companyPlaca,
    );

    // Configurar valores por defecto
    _selectedMoneda = 'PEN';
  }

  @override
  void dispose() {
    _disposeControllers();
    _apiService.dispose();
    super.dispose();
  }

  /// Dispose de todos los controladores
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
    _categoriaController.removeListener(_validateForm);
    _tipoGastoController.removeListener(_validateForm);
    _notaController.removeListener(_validateForm);

    // Dispose de los controladores
    _politicaController.dispose();
    _categoriaController.dispose();
    _tipoGastoController.dispose();
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
    _placaController.dispose();
  }

  /// Seleccionar archivo (imagen o PDF)
  Future<void> _pickImage() async {
    try {
      if (mounted) setState(() => _isLoading = true);

      // Mostrar opciones para seleccionar tipo de archivo
      final selectedOption = await showDialog<String>(
        context: context,
        builder: (BuildContext context) {
          final bool isDark = Theme.of(context).brightness == Brightness.dark;
          /*  return AlertDialog(
            title: const Text('Seleccionar evidencia'),
            content: const Text('¿Qué tipo de archivo desea agregar?'),
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
            backgroundColor: isDark
                ? Theme.of(context).dialogBackgroundColor
                : Colors.white,
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

            content: Text(
              '¿Qué tipo de archivo deseas agregar?',
              style: TextStyle(
                fontSize: 15,
                height: 1.4,
                color: isDark
                    ? Theme.of(context).textTheme.bodyMedium?.color
                    : Colors.black87,
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

  /// Mostrar alerta en medio de la pantalla con mensaje del servidor
  void _showServerAlert(String message) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.all(20),
            margin: const EdgeInsets.symmetric(horizontal: 40),
            decoration: BoxDecoration(
              color: Colors.red,
              borderRadius: BorderRadius.circular(15),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.warning_rounded,
                  color: Colors.white,
                  size: 50,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Mensaje del Servidor',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  message,
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.red,
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

  /// Guardar factura mediante API
  Future<void> _saveFacturaAPI() async {
    // Validar campos obligatorios antes de continuar

    if (!_isFormValid) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('❌ Por favor complete todos los campos '),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
        ),
      );
      return;
    }

    // 🔍 VALIDACIÓN: RUC del cliente escaneado debe coincidir con empresa seleccionada
    final rucClienteEscaneado = _rucClienteController.text.trim();
    final rucEmpresaSeleccionada = CompanyService().companyRuc;

    if (rucClienteEscaneado != rucEmpresaSeleccionada ||
        rucClienteEscaneado.isEmpty) {
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
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 6),
          action: SnackBarAction(
            label: 'OK',
            textColor: Colors.white,
            onPressed: () {},
          ),
        ),
      );
      return;
    }

    try {
      if (mounted) setState(() => _isLoading = true);

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

      // 📋 DATOS PRINCIPALES DE LA FACTURA
      // Este objeto contiene toda la información principal de la factura
      // que será enviada al API que debe generar el idRend automáticamente
      final facturaData = {
        "idUser": UserService().currentUserCode,
        "dni": UserService().currentUserDni,
        "politica": _politicaController.text.length > 80
            ? _politicaController.text.substring(0, 80)
            : _politicaController.text,
        "categoria": _categoriaController.text.isEmpty
            ? "GENERAL"
            : (_categoriaController.text.length > 80
                  ? _categoriaController.text.substring(0, 80)
                  : _categoriaController.text),

        "tipoGasto": _tipoGastoController.text.isEmpty
            ? "GASTO GENERAL"
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
        "consumidor": CompanyService().currentCompany?.consumidor ?? '',
        "placa": _placaController.text,
        "estadoActual": "BORRADOR",
        "glosa": "CODIGO QR",
        "motivoViaje": "",
        "lugarOrigen": "",
        "lugarDestino": "",
        "tipoMovilidad": "",
        "obs": _notaController.text,
        "estado": "S", // Solo 1 carácter como requiere la BD
        "fecCre": DateTime.now().toIso8601String(),
        "useReg": UserService().currentUserCode, // Campo obligatorio
        "hostname": "FLUTTER", // Campo obligatorio, máximo 50 caracteres
        "fecEdit": DateTime.now().toIso8601String(),
        "useEdit": 0,
        "useElim": 0,
      };

      // 🚨 IMPORTANTE: Si saverendiciongastoevidencia es el que GENERA el idRend,
      // entonces necesitamos cambiar el orden de los APIs

      // ✅ PRIMER API: Guardar datos principales de la factura (genera idRend automáticamente)
      // Nota: Verificar cuál endpoint realmente genera el idRend autoincrementable
      final idRend = await _apiService.saveRendicionGasto(facturaData);

      if (idRend == null) {
        throw Exception(
          'No se pudo guardar la factura principal o no se obtuvo el ID autogenerado',
        );
      }

      debugPrint('🆔 ID autogenerado obtenido: $idRend');
      debugPrint('📋 Preparando datos de evidencia con el ID generado...');

      final extension = p.extension(
        _selectedFile!.path,
      ); // obtiene la extensión, e.g. ".pdf", ".png", ".jpg"

      String nombreArchivo =
          '${idRend}_${_rucController.text}_${_serieController.text}_${_numeroController.text}$extension';

      final driveId = await _apiService.subirArchivo(
        _selectedFile!.path,
        nombreArchivo: nombreArchivo,
      );
      // ✅ SEGUNDO API: Guardar evidencia/archivo usando el idRend del primer API
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

      // Usar el nuevo servicio API para guardar la evidencia

      final successEvidencia = await _apiService.saveRendicionGastoEvidencia(
        facturaDataEvidencia,
      );

      /*   if (successEvidencia && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Factura guardada exitosamente'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        ); */

      if (successEvidencia && mounted) {
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
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  /*   @override
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
                    const SizedBox(height: 20),
                    _buildPolicySection(),
                    const SizedBox(height: 12),
                    _buildCategorySection(),
                    const SizedBox(height: 12),
                    _buildTipoGastoSection(),
                    const SizedBox(height: 12),
                    _buildFacturaDataSection(),
                    const SizedBox(height: 20),
                    _buildNotesSection(),
                    //const SizedBox(height: 12),
                    //_buildRawDataSection(),
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
    final double maxHeight = MediaQuery.of(context).size.height * 0.93;
    final double minHeight = MediaQuery.of(context).size.height * 0.55;
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      constraints: BoxConstraints(minHeight: minHeight, maxHeight: maxHeight),
      decoration: BoxDecoration(
        color: isDark
            ? Theme.of(context).scaffoldBackgroundColor
            : Colors.white,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(22),
          topRight: Radius.circular(22),
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        resizeToAvoidBottomInset: true,

        body: SafeArea(
          top: false,
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                // HEADER
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: _buildHeader(),
                ),

                // CONTENIDO SCROLLEABLE
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildImageSection(),
                        const SizedBox(height: 20),
                        _buildPolicySection(),
                        const SizedBox(height: 12),
                        _buildCategorySection(),
                        const SizedBox(height: 12),
                        _buildTipoGastoSection(),
                        const SizedBox(height: 12),
                        _buildFacturaDataSection(),
                        const SizedBox(height: 20),
                        _buildNotesSection(),

                        /*  const SizedBox(
                          height: 80,
                        ), // Espacio para evitar que se tape */
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
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [Colors.red.shade800, Colors.red.shade600]
              : [Colors.red.shade700, Colors.red.shade400],
        ),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.receipt_long, color: Colors.white, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Factura Electrónica - Perú',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
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
      color: isDark ? Theme.of(context).cardColor : Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.attach_file, color: Colors.red),
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
                      (_selectedFile == null) ? Icons.add : Icons.edit,
                    ),
                    label: Text(
                      (_selectedFile == null) ? 'Agregar' : 'Cambiar',
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
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
                  border: Border.all(color: Colors.white),
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
                  color: Colors.white,
                  border: Border.all(
                    color: (_selectedFile == null)
                        ? Colors.red.shade300
                        : Colors.grey.shade300,
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
                            : Colors.grey,
                        fontWeight: (_selectedFile == null)
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
                const Icon(Icons.attach_file, color: Colors.red),
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
                      (_selectedFile == null) ? Icons.add : Icons.edit,
                    ),
                    label: Text(
                      (_selectedFile == null) ? 'Agregar' : 'Cambiar',
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
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
              )
            else
              Container(
                height: 100,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  border: Border.all(
                    color: (_selectedFile == null)
                        ? Colors.red.shade300
                        : Colors.grey.shade300,
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
                            : Colors.grey,
                        fontWeight: (_selectedFile == null)
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Datos Generales',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.red.shade400 : Colors.red,
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: _politicaController,
          enabled: false,
          decoration: InputDecoration(
            labelText: 'Política Seleccionada',
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
              borderSide: BorderSide(color: Colors.red, width: 2),
            ),
            disabledBorder: UnderlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.grey, width: 1),
            ),
            prefixIcon: const Icon(Icons.policy),
          ),
        ),
      ],
    );
  }

  /// Construir la sección de categoría
  Widget _buildCategorySection() {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    // Determinar las categorías disponibles según la política
    List<DropdownMenuItem<String>> items = [];

    if (_politicaController.text.toLowerCase().contains('movilidad')) {
      // Para política de movilidad, mantener las opciones hardcodeadas
      items = const [];
    } else if (_politicaController.text.toLowerCase().contains('general')) {
      // Para política GENERAL, usar datos de la API
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
            SizedBox(height: 8),
            Text(
              'Cargando categorías...',
              style: TextStyle(color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        );
      }

      if (_errorCategorias != null) {
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
            ),
          ],
        );
      }

      // Convertir categorías de la API a DropdownMenuItems
      items = _categoriasGeneral
          .map(
            (categoria) => DropdownMenuItem<String>(
              value: categoria.categoria,
              child: Text(_formatCategoriaName(categoria.categoria)),
            ),
          )
          .toList();

      // Si no hay categorías, mostrar mensaje
      if (items.isEmpty) {
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
            ),
          ],
        );
      }
    } else {
      // Para otras políticas, usar categorías por defecto
      items = const [];
    }

    return DropdownButtonFormField<String>(
      dropdownColor: isDark ? Theme.of(context).cardColor : Colors.white,
      decoration: InputDecoration(
        labelText: 'Categoría *',
        prefixIcon: const Icon(Icons.category),
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
          borderSide: BorderSide(color: Colors.red, width: 2),
        ),
        disabledBorder: UnderlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.grey, width: 1),
        ),
      ),
      initialValue:
          _categoriaController.text.isNotEmpty &&
              items.any((item) => item.value == _categoriaController.text)
          ? _categoriaController.text
          : null,
      items: items,
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Categoría es obligatoria';
        }
        return null;
      },
      onChanged: (value) {
        if (value != null) {
          setState(() {
            _categoriaController.text = value;
          });
          _validateForm(); // Validar cuando cambie la categoría
        }
      },
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

  /// Construir la sección de tipo de gasto
  Widget _buildTipoGastoSection() {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Tipo de Gasto',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 8),

        // Si está cargando, mostrar indicador
        if (_isLoadingTiposGasto)
          const Column(
            children: [
              Center(child: CircularProgressIndicator()),
              SizedBox(height: 8),
              Text(
                'Cargando tipos de gasto...',
                style: TextStyle(color: Colors.grey),
                textAlign: TextAlign.center,
              ),
            ],
          )
        // Si hay error, mostrar mensaje
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
                Icon(Icons.error_outline, color: Colors.red.shade600),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Error al cargar tipos de gasto: $_errorTiposGasto',
                    style: TextStyle(color: Colors.red.shade700),
                  ),
                ),
              ],
            ),
          )
        // Dropdown normal
        else
          DropdownButtonFormField<String>(
            dropdownColor: isDark ? Theme.of(context).cardColor : Colors.white,
            decoration: InputDecoration(
              labelText: 'Tipo de Gasto *',
              prefixIcon: const Icon(Icons.payment),
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
                borderSide: BorderSide(color: Colors.red, width: 2),
              ),
              disabledBorder: UnderlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Colors.grey, width: 1),
              ),
            ),
            initialValue:
                _tipoGastoController.text.isNotEmpty &&
                    _tiposGasto.any(
                      (tipo) => tipo.value == _tipoGastoController.text,
                    )
                ? _tipoGastoController.text
                : null,
            items: _tiposGasto
                .map(
                  (tipo) => DropdownMenuItem<String>(
                    value: tipo.value,
                    child: Text(tipo.value),
                  ),
                )
                .toList(),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Tipo de gasto es obligatorio';
              }
              return null;
            },
            onChanged: (value) {
              if (value != null) {
                if (mounted) {
                  setState(() {
                    _tipoGastoController.text = value;
                  });
                }
                _validateForm(); // Validar cuando cambie el tipo de gasto
              }
            },
          ),
      ],
    );
  }

  /// Construir la sección de datos de la factura

  Widget _buildFacturaDataSection() {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Datos de la Factura',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.red.shade400 : Colors.red,
          ),
        ),
        const SizedBox(height: 16),

        // Primera fila: RUC y Tipo Comprobante (solo lectura)
        Row(
          children: [
            Expanded(
              child: _buildTextField(
                _rucController,
                'RUC Emisor',
                Icons.business,
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
                'Razon Social',
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
        // Segunda fila: Serie y Número (solo lectura)
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
                Icons.confirmation_number,
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
                readOnly: true,
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
                    borderSide: BorderSide(color: Colors.red, width: 2),
                  ),
                  disabledBorder: UnderlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Colors.grey, width: 1),
                  ),
                  prefixIcon: const Icon(Icons.attach_money),
                ),
                keyboardType: TextInputType.numberWithOptions(decimal: true),
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
                dropdownColor: isDark
                    ? Theme.of(context).cardColor
                    : Colors.white,
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
                    borderSide: BorderSide(color: Colors.red, width: 2),
                  ),
                  disabledBorder: UnderlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Colors.grey, width: 1),
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

        // Tercera fila: IGV (solo lectura)
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

        const SizedBox(height: 12),

        // Quinta fila: RUC Cliente (solo lectura)
        _buildTextField(
          _rucClienteController,
          'RUC Cliente',
          Icons.person,
          TextInputType.number,
          readOnly: true,
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
                const SizedBox(width: 6),
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
      ],
    );
  }

  /// Construir la sección de notas
  Widget _buildNotesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: _notaController,
          decoration: const InputDecoration(
            labelText: 'Nota o Glosa: * ',
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

  /// Construir la sección de notas

  /// Construir los botones de acción
  Widget _buildActionButtons() {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: isDark
            ? Theme.of(context).cardColor.withOpacity(0.5)
            : Colors.grey.shade50,
        border: Border(
          top: BorderSide(
            color: isDark
                ? Theme.of(context).dividerColor
                : Colors.grey.shade300,
          ),
        ),
      ),
      child: Column(
        children: [
          // Mensaje de campos obligatorios
          if (!_isFormValid)
            Container(
              padding: const EdgeInsets.all(2),
              margin: const EdgeInsets.only(bottom: 4),
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.orange.shade900.withOpacity(0.2)
                    : Colors.orange.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isDark
                      ? Colors.orange.shade700
                      : Colors.orange.shade200,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.warning,
                    color: isDark
                        ? Colors.orange.shade400
                        : Colors.orange.shade600,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Por favor complete todos los campos ',
                      style: TextStyle(
                        color: isDark ? Colors.orange.shade400 : Colors.orange,
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
                child: ElevatedButton.icon(
                  onPressed: widget.onCancel,
                  icon: const Icon(Icons.cancel),
                  label: const Text('Cancelar'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isDark
                        ? Colors.red.shade700
                        : const Color.fromARGB(255, 244, 54, 54),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _isLoading || !_isFormValid
                      ? null
                      : _saveFacturaAPI,
                  icon: _isLoading
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        )
                      : const Icon(Icons.save),
                  label: Text(
                    _isLoading
                        ? 'Guardando...'
                        : _isFormValid
                        ? 'Guardar Factura'
                        : 'Complete ',
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isFormValid
                        ? (isDark
                              ? const Color.fromARGB(255, 34, 155, 54)
                              : const Color.fromARGB(255, 19, 126, 32))
                        : (isDark ? Colors.grey.shade700 : Colors.grey),
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: isDark
                        ? Colors.grey[700]
                        : Colors.grey[300],
                    disabledForegroundColor: isDark
                        ? Colors.grey[400]
                        : Colors.grey[600],
                    padding: const EdgeInsets.symmetric(vertical: 12),
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
      decoration: InputDecoration(
        labelText: isRequired ? '$label *' : label,
        prefixIcon: Icon(icon),
        border: UnderlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.transparent, width: 0),
        ),
        enabledBorder: UnderlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: isDark ? Theme.of(context).dividerColor : Colors.grey,
            width: 1,
          ),
        ),
        focusedBorder: UnderlineInputBorder(
          borderRadius: const BorderRadius.all(Radius.circular(12)),
          borderSide: BorderSide(
            color: isDark ? Colors.red.shade400 : Colors.red,
            width: 2,
          ),
        ),
        disabledBorder: UnderlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: isDark ? Theme.of(context).disabledColor : Colors.grey,
            width: 1,
          ),
        ),
        filled: true,
        fillColor: readOnly
            ? (isDark
                  ? Theme.of(context).disabledColor.withOpacity(0.1)
                  : Colors.grey.shade100)
            : (isDark ? Theme.of(context).cardColor : Colors.white),
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
