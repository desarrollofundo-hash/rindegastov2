import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flu2/models/apiruc_model.dart';
import 'package:flu2/services/user_service.dart';
import 'package:flu2/utils/navigation_utils.dart';
import 'package:flu2/widgets/nuevo_gasto_logic.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:printing/printing.dart';
import 'package:file_picker/file_picker.dart';
import '../models/reporte_model.dart';
import '../models/categoria_model.dart';
import '../models/dropdown_option.dart';
import '../services/api_service.dart';
import '../services/company_service.dart';
import '../controllers/edit_reporte_controller.dart';
import '../screens/home_screen.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

class EditReporteModal extends StatefulWidget {
  final Reporte reporte;
  final Function(Reporte)? onSave;

  const EditReporteModal({super.key, required this.reporte, this.onSave});

  @override
  State<EditReporteModal> createState() => _EditReporteModalState();
}

class _EditReporteModalState extends State<EditReporteModal> {
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
  late TextEditingController _totalController;
  late TextEditingController _fechaEmisionController;
  late TextEditingController _monedaController;
  late TextEditingController _rucClienteController;
  late TextEditingController _notaController;
  late TextEditingController _centroCostoController;
  // Campos de movilidad
  late TextEditingController _origenController;
  late TextEditingController _destinoController;
  late TextEditingController _motivoViajeController;
  late TextEditingController _tipoMovilidadController;
  late TextEditingController _placaController;
  late TextEditingController _motivorechazoController;

  // Campos adicionales usados en el formulario

  // Estado
  bool _isLoading = false;
  bool _isEditMode = false;

  bool _isFormValid = false;

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  // Servicios y controlador
  final ApiService _apiService = ApiService();
  late final EditReporteController _controller;

  ///ApiRuc
  bool _isLoadingApiRuc = false;
  String? _errorApiRuc;
  ApiRuc? _apiRucData;

  // Variables para el lector SUNAT
  bool _isScanning = false;
  bool _hasScannedData = false;
  final NuevoGastoLogic _logic = NuevoGastoLogic();

  // Image / file picker
  final ImagePicker _picker = ImagePicker();
  File? _selectedImage;
  String? _selectedFileType; // 'image' o 'pdf'
  String? _selectedFileName;
  bool _isLoadingCentrosCosto = false;

  List<CategoriaModel> _categoriasGeneral = [];
  List<DropdownOption> _centroCosto = [];
  List<DropdownOption> _tiposGasto = [];
  final bool _isloadingCentrosCosto = false;
  bool _isLoadingCategorias = false;
  bool _isLoadingTiposGasto = false;
  String? _errorCategorias;
  String? _errorTiposGasto;
  String? _numeroGasto;
  String? _errorCentroCosto;
  String? _error;

  // Cerca de donde declaran las otras variables de estado
  List<DropdownOption> _tiposMovilidad = [];
  DropdownOption? _selectedTipoMovilidad;
  bool _isLoadingTipoMovilidad = false;
  // Opciones para moneda
  String? _selectedMoneda;
  final List<String> _monedas = ['PEN', 'USD', 'EUR'];

  // Almacenar la categoría original del reporte para detectar si fue guardada anteriormente
  String? _originalCategoria;

  // Selecciones

  // _selectedCategoria and _selectedTipoGasto were previously declared but
  // not used after refactor. Keep controllers instead (_categoriaController,
  // _tipoGastoController) to track values.

  @override
  void initState() {
    super.initState();
    _controller = EditReporteController(apiService: _apiService);
    _initializeControllers();
    _initializeSelectedValues();
    _loadPoliticas();
    // Cargar las categorías filtrando por la política del reporte para
    // asegurarnos de que la categoría guardada esté disponible.
    _loadCategorias(politicaFiltro: widget.reporte.politica);
    _loadTiposGasto();
    _loadCentrosCosto();
    _loadTiposMovilidad();

    // Añadir listeners para validar formulario en tiempo real
    _addValidationListeners();
    // Intentar cargar la evidencia que ya exista en el servidor para este reporte
    // de modo que el campo de 'Agregar evidencia' muestre la imagen/PDF si existe.
    _cargarImagenServidor();
  }

  /// Cargar tipos de movilidad desde la API
  Future<void> _loadTiposMovilidad() async {
    if (!mounted) return;
    setState(() {
      _isLoadingTipoMovilidad = true;
    });

    try {
      final tiposMovilidad = await _apiService.getTiposMovilidad();
      if (!mounted) return;
      setState(() {
        _tiposMovilidad = tiposMovilidad;
        _isLoadingTipoMovilidad = false;

        // Seleccionar el tipo guardado si existe
        if (_tipoMovilidadController.text.isNotEmpty) {
          try {
            _selectedTipoMovilidad = tiposMovilidad.firstWhere(
              (tipo) =>
                  tipo.value.toLowerCase() ==
                  _tipoMovilidadController.text.toLowerCase(),
            );
          } catch (_) {
            _selectedTipoMovilidad = tiposMovilidad.isNotEmpty
                ? tiposMovilidad.first
                : null;
          }
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoadingTipoMovilidad = false;
      });
      debugPrint('❌ Error cargando tipos de movilidad: $e');
    }
  }

  /// Determina si el reporte está en estado 'EN INFORME'.
  /// Como `Reporte` no tiene un campo `estado`, comprobamos varios campos
  /// que en el proyecto se usan en distintos contextos para representar el estado.
  bool _isEnInforme() {
    final companyValue = CompanyService().currentUserArea;
    final estadoValue = widget.reporte.estadoActual;

    // 🔹 Verificar primero si el área es CONTABILIDAD
    if (companyValue != null) {
      final area = companyValue.trim().toUpperCase();

      // ✅ Nueva condición especial:
      // Si el área es CONTABILIDAD y el estado está en revisión o aprobado → TRUE
      if (area == 'CONTABILIDAD' &&
          (estadoValue?.trim().toUpperCase() == 'EN REVISION' ||
              estadoValue?.trim().toUpperCase() == 'APROBADO')) {
        return true;
      }

      // En cualquier otro caso, si es contabilidad → sigue siendo FALSE
      if (area == 'CONTABILIDAD') {
        return false;
      }
    }

    // 🔹 Verificar estados que bloquean (independientemente del área)
    if (estadoValue != null) {
      final value = estadoValue.trim().toUpperCase();
      if (value == 'EN AUDITORIA' ||
          value == 'CONTABILIDAD' ||
          value == 'EN REVISION' ||
          value == 'APROBADO' ||
          value == 'RECHAZADO' ||
          value == 'DESAPROBADO') {
        return true;
      }
    }

    return false;
  }

  // (El helper de error de imagen fue removido; la UI muestra placeholders simples)
  /// Detectar si la categoría seleccionada es "PLANILLA DE MOVILIDAD"
  bool _isPlanillaDeMovilidad() {
    final categoria = _categoriaController.text.trim().toUpperCase();
    return categoria.contains('PLANILLA') && categoria.contains('MOVILIDAD');
  }

  /// Agregar listeners para validación en tiempo real
  void _addValidationListeners() {
    if (_categoriaController.text == "PLANILLA DE MOVILIDAD") {
      _fechaEmisionController.addListener(_validateForm);
      _totalController.addListener(_validateForm);
      _categoriaController.addListener(_validateForm);
      _tipoGastoController.addListener(_validateForm);
      _centroCostoController.addListener(_validateForm);
      _notaController.addListener(_validateForm);

      // ✅ Agregar listeners para campos de movilidad
      _origenController.addListener(_validateForm);
      _destinoController.addListener(_validateForm);
      _motivoViajeController.addListener(_validateForm);
      _tipoMovilidadController.addListener(_validateForm);
      _placaController.addListener(_validateForm);
    }
    //else if (_categoriaController.text == "PLANILLA DE MOVILIDAD") {}
    else {
      _rucController.addListener(_validateForm);
      _rucClienteController.addListener(_validateForm);
      _tipoComprobanteController.addListener(_validateForm);
      _serieController.addListener(_validateForm);
      _numeroController.addListener(_validateForm);
      _fechaEmisionController.addListener(_validateForm);
      _totalController.addListener(_validateForm);
      _categoriaController.addListener(_validateForm);
      _tipoGastoController.addListener(_validateForm);
      _centroCostoController.addListener(_validateForm);
      _notaController.addListener(_validateForm);
    }
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
    // ✅ Solo validar si está en modo edición
    if (!_isEditMode) {
      setState(() {
        _isFormValid = false;
      });
      return;
    }
    final isMovilidad = _isPlanillaDeMovilidad();

    final isValid = isMovilidad
        ? // Validación para PLANILLA DE MOVILIDAD
          _fechaEmisionController.text.trim().isNotEmpty &&
              _totalController.text.trim().isNotEmpty &&
              (_selectedMoneda != null && _selectedMoneda!.isNotEmpty) &&
              _categoriaController.text.trim().isNotEmpty &&
              _tipoGastoController.text.trim().isNotEmpty &&
              _origenController.text.trim().isNotEmpty &&
              _destinoController.text.trim().isNotEmpty &&
              _motivoViajeController.text.trim().isNotEmpty &&
              _tipoMovilidadController.text.trim().isNotEmpty &&
              _placaController.text.trim().isNotEmpty
        : // Validación para formulario completo
          _rucController.text.trim().isNotEmpty &&
              _tipoComprobanteController.text.trim().isNotEmpty &&
              _serieController.text.trim().isNotEmpty &&
              _numeroController.text.trim().isNotEmpty &&
              _fechaEmisionController.text.trim().isNotEmpty &&
              _totalController.text.trim().isNotEmpty &&
              _categoriaController.text.trim().isNotEmpty &&
              _tipoGastoController.text.trim().isNotEmpty &&
              _isRucValid();

    if (_isFormValid != isValid) {
      setState(() {
        _isFormValid = isValid;
      });
    }
  }

  void _initializeSelectedValues() {
    _selectedImage = null;
    _selectedMoneda = widget.reporte.moneda ?? 'PEN';
    // Para política se validará después de cargar desde API
    // Para categoría y tipo de gasto, se validarán después de cargar desde API
    // Las variables se inicializan en los métodos correspondientes
  }

  /// Cargar políticas desde la API
  Future<void> _loadPoliticas() async {
    // Placeholder to load políticas if needed. Currently no indicator is used.
    if (!mounted) return;
  }

  /// Cargar categorías desde la API
  Future<void> _loadCategorias({String? politicaFiltro}) async {
    if (!_politicaController.text.toLowerCase().contains('general') &&
        politicaFiltro == null) {
      return; // Solo cargar para política GENERAL
    }

    if (!mounted) return;
    setState(() {
      _isLoadingCategorias = true;
      _errorCategorias = null;
    });

    try {
      // Si hay una política específica, filtrar por ella; sino, obtener todas
      final categorias = await _apiService.getRendicionCategorias(
        politica: politicaFiltro ?? 'todos',
      );
      print(
        '🚀 Categorías cargadas: ${categorias.length} para política: ${politicaFiltro ?? "todas"}',
      );

      // Convertir DropdownOption a CategoriaModel para mantener compatibilidad
      final categoriasModelo = categorias
          .map(
            (cat) => CategoriaModel(
              id: cat.id,
              politica: politicaFiltro ?? '',
              categoria: cat.value,
              estado: 'S',
            ),
          )
          .toList();

      if (!mounted) return;
      setState(() {
        _categoriasGeneral = categoriasModelo;
        _isLoadingCategorias = false;
        // Mantener el valor original para mostrarlo
      });
    } catch (e) {
      print('❌ Error cargando categorías: $e');
      if (!mounted) return;
      setState(() {
        _errorCategorias = e.toString();
        _isLoadingCategorias = false;
        // Mantener el valor original incluso si hay error
      });
    }
  }

  /// Cargar tipos de gasto desde la API
  Future<void> _loadTiposGasto() async {
    if (!mounted) return;
    setState(() {
      _isLoadingTiposGasto = true;
      _errorTiposGasto = null;
    });

    try {
      final tiposGasto = await _apiService.getTiposGasto();
      if (!mounted) return;
      setState(() {
        _tiposGasto = tiposGasto;
        _isLoadingTiposGasto = false;
        // No cambiar _selectedTipoGasto aquí, mantener el valor original para mostrarlo
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorTiposGasto = e.toString();
        _isLoadingTiposGasto = false;
        // Mantener el valor original incluso si hay error
      });
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

  void _initializeControllers() {
    _politicaController = TextEditingController(
      text: widget.reporte.politica ?? '',
    );
    _categoriaController = TextEditingController(
      text: widget.reporte.categoria ?? '',
    );
    // Guardar la categoría original para detectar si fue creada antes
    _originalCategoria = widget.reporte.categoria ?? '';
    _tipoGastoController = TextEditingController(
      text: widget.reporte.tipogasto ?? '',
    );
    _centroCostoController = TextEditingController(
      text: widget.reporte.consumidor ?? '',
    );
    print('========================================');
    print('🏁 INICIALIZANDO EDIT REPORTE MODAL');
    print('📌 Centro de Costo inicial: "${widget.reporte.consumidor ?? ''}"');
    print('========================================');
    _rucController = TextEditingController(text: widget.reporte.ruc ?? '');
    _razonSocialController = TextEditingController(
      text: widget.reporte.proveedor ?? '',
    );
    _tipoComprobanteController = TextEditingController(
      text: widget.reporte.tipocomprobante ?? '',
    );
    debugPrint(
      '📝 Tipo Comprobante cargado: "${widget.reporte.tipocomprobante}"',
    );
    _serieController = TextEditingController(text: widget.reporte.serie ?? '');
    _numeroController = TextEditingController(
      text: widget.reporte.numero ?? '',
    );
    _fechaEmisionController = TextEditingController(
      text: formatDate(widget.reporte.fecha),
    );
    _totalController = TextEditingController(
      text: widget.reporte.total?.toString() ?? '',
    );
    _monedaController = TextEditingController(
      text: widget.reporte.moneda ?? 'PEN',
    );
    _rucClienteController = TextEditingController(
      text: widget.reporte.ruccliente ?? '',
    );

    // Movilidad
    _origenController = TextEditingController(
      text: widget.reporte.lugarorigen ?? '',
    );
    _destinoController = TextEditingController(
      text: widget.reporte.lugardestino ?? '',
    );
    _motivoViajeController = TextEditingController(
      text: widget.reporte.motivoviaje ?? '',
    );
    _tipoMovilidadController = TextEditingController(
      text: widget.reporte.tipomovilidad ?? '',
    );
    _placaController = TextEditingController(text: widget.reporte.placa ?? '');

    // Nuevos controladores
    _igvController = TextEditingController(
      text: widget.reporte.igv?.toString() ?? '',
    );
    // Mostrar fecha de emisión en formato ISO (yyyy-MM-dd) cuando sea posible
    _notaController = TextEditingController(text: widget.reporte.obs ?? '');
    _motivorechazoController = TextEditingController(
      text: widget.reporte.motivorechazo ?? '',
    );
    _numeroGasto = widget.reporte.idrend.toString();
  }

  @override
  void dispose() {
    // Remover listeners antes de dispose
    _rucController.removeListener(_validateForm);
    _rucClienteController.removeListener(_validateForm);
    _tipoComprobanteController.removeListener(_validateForm);
    _serieController.removeListener(_validateForm);
    _numeroController.removeListener(_validateForm);
    _fechaEmisionController.removeListener(_validateForm);
    _totalController.removeListener(_validateForm);
    _categoriaController.removeListener(_validateForm);
    _tipoGastoController.removeListener(_validateForm);

    // Dispose de los controladores
    _politicaController.dispose();
    _categoriaController.dispose();
    _tipoGastoController.dispose();
    _centroCostoController.dispose();
    _rucController.dispose();
    _razonSocialController.dispose();
    _tipoComprobanteController.dispose();
    _serieController.dispose();
    _numeroController.dispose();
    _totalController.dispose();
    _monedaController.dispose();
    _rucClienteController.dispose();
    _igvController.dispose();
    _fechaEmisionController.dispose();
    _notaController.dispose();
    _origenController.dispose();
    _destinoController.dispose();
    _motivoViajeController.dispose();
    _tipoMovilidadController.dispose();
    _placaController.dispose();
    _motivorechazoController.dispose();

    _controller.dispose();
    super.dispose();
  }

  // Nota: conversión a base64 está en el controller (`_controller.convertImageToBase64`).

  /*
  /// Seleccionar imagen desde la cámara
  Future<void> _pickImage() async {
    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Seleccionar'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Tomar foto'),
                onTap: () {
                  Navigator.pop(context);
                  _pickFromCamera();
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Galería'),
                onTap: () {
                  Navigator.pop(context);
                  _pickFromGallery();
                },
              ),
              ListTile(
                leading: const Icon(Icons.picture_as_pdf),
                title: const Text('PDF'),
                onTap: () {
                  Navigator.pop(context);
                  _pickPDFFile();
                },
              ),
            ],
          ),
        );
      },
    );
  }
*/

  /// Seleccionar archivo (imagen o PDF)
  Future<void> _pickImage() async {
    try {
      setState(() => _isLoading = true); // Mostrar indicador de carga

      // Mostrar opciones para seleccionar tipo de archivo
      final selectedOption = await showDialog<String>(
        context: context,
        builder: (BuildContext context) {
          final isDark = Theme.of(context).brightness == Brightness.dark;
          /* return AlertDialog(
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
          );
        }, */
          return AlertDialog(
            backgroundColor: isDark
                ? Theme.of(context).cardColor
                : Colors.white,
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
                    color: isDark
                        ? Theme.of(context).textTheme.headlineSmall?.color
                        : Colors.black,
                  ),
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
            setState(() {
              _selectedImage = file;
              _selectedFileType = 'pdf';
              _selectedFileName = result.files.first.name;
            });
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
            toolbarTitle: 'Recortar Combrobante',
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
        setState(() {
          _selectedImage = File(
            croppedFile.path,
          ); // Convertimos CroppedFile a File
          _selectedFileType = 'image'; // Indicamos que es una imagen
          _selectedFileName = croppedFile.path
              .split('/')
              .last; // Nombre del archivo
        });
        _validateForm();
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

  Future<void> _pickFromCamera() async {
    try {
      setState(() => _isLoading = true);

      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
        maxWidth: 1920,
        maxHeight: 1080,
      );

      if (image != null && mounted) {
        final file = File(image.path);
        if (await file.exists()) {
          setState(() => _selectedImage = file);
          _validateForm();
        } else {
          throw Exception('El archivo de imagen no se pudo crear');
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al capturar imagen: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _pickFromGallery() async {
    try {
      setState(() => _isLoading = true);

      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
        maxWidth: 1920,
        maxHeight: 1080,
      );

      if (image != null && mounted) {
        final file = File(image.path);
        if (await file.exists()) {
          setState(() => _selectedImage = file);
          _validateForm();
        } else {
          throw Exception('El archivo de imagen no se pudo crear');
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al seleccionar imagen: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _pickPDFFile() async {
    try {
      setState(() => _isLoading = true);

      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
      );

      if (result != null && mounted) {
        final file = File(result.files.single.path!);
        if (await file.exists()) {
          setState(
            () => _selectedImage = file,
          ); // Usamos _selectedImage para mantener compatibilidad
          _validateForm();
          print('📄 PDF seleccionado: ${file.path}');
        } else {
          throw Exception('El archivo PDF no se pudo acceder');
        }
      }
    } catch (e) {
      print('🔴 Error al seleccionar PDF: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al seleccionar PDF: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
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
            padding: const EdgeInsets.all(24),
            margin: const EdgeInsets.symmetric(horizontal: 40),
            decoration: BoxDecoration(
              color: Colors.red,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, color: Colors.white, size: 48),
                const SizedBox(height: 16),
                const Text(
                  'Error del Servidor',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  message,
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.red,
                  ),
                  child: const Text('OK'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Extraer mensaje del servidor desde el error
  String _extractServerMessage(String error) {
    try {
      // Buscar patrones comunes de mensajes de error del servidor
      if (error.contains('Exception:')) {
        return error.split('Exception:').last.trim();
      }
      if (error.contains('Error:')) {
        return error.split('Error:').last.trim();
      }
      return error.length > 100 ? '${error.substring(0, 100)}...' : error;
    } catch (e) {
      return 'Error interno del servidor';
    }
  }

  /// Verificar si un archivo es PDF basado en su extensión
  bool _isPdfFile(String filePath) {
    return filePath.toLowerCase().endsWith('.pdf');
  }

  /// Construir la sección de imagen/evidencia
  Widget _buildImageSection() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Card(
        color: isDark ? Theme.of(context).cardColor : Colors.white,
        elevation: 2,
        child: Padding(
          padding: const EdgeInsets.all(5),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.receipt, color: Colors.red),
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
                      onPressed: _isEditMode ? _pickImage : null,
                      icon: Icon(
                        (_selectedImage == null)
                            ? Icons.add_a_photo
                            : Icons.edit,
                      ),
                      label: Text(
                        (_selectedImage == null) ? 'Seleccionar' : 'Cambiar ',
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _isEditMode ? Colors.red : Colors.grey,
                        foregroundColor: Colors.white,
                      ),
                    ),
                ],
              ),

              /// Mostrar archivo: puede ser imagen o PDF
              if (_selectedImage != null)
                Container(
                  height: 200,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.white),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: GestureDetector(
                      onTap: _handleTapEvidencia,
                      child: _isPdfFile(_selectedImage!.path)
                          ? Container(
                              color: Colors.white,
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(
                                    Icons.picture_as_pdf,
                                    size: 48,
                                    color: Colors.red,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'PDF: ${_selectedImage!.path.split('/').last}',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Colors.white,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            )
                          : Image.file(_selectedImage!, fit: BoxFit.cover),
                    ),
                  ),
                )
              else if (_selectedImage != null)
                // Si la evidencia está en base64
                Container(
                  height: 200,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: GestureDetector(
                      onTap: _handleTapEvidencia,
                      child: _buildEvidenciaImage(_selectedImage!.path),
                    ),
                  ),
                )
              else
                Container(
                  height: 100,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: isDark
                        ? Theme.of(context).cardColor.withOpacity(0.3)
                        : Colors.grey.shade100,
                    border: Border.all(
                      color: (_selectedImage == null)
                          ? Colors.red.shade300
                          : (isDark
                                ? Theme.of(context).dividerColor
                                : Colors.grey.shade300),
                      width: (_selectedImage == null) ? 2 : 1,
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.receipt_outlined,
                        color: (_selectedImage == null)
                            ? Colors.red
                            : Colors.grey,
                        size: 40,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Agregar evidencia (Obligatorio)',
                        style: TextStyle(
                          color: (_selectedImage == null)
                              ? Colors.red
                              : Colors.grey,
                          fontWeight: (_selectedImage == null)
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                ),

              /*  Row(
                children: [
                  const Icon(Icons.qr_code_scanner, color: Colors.red),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Lector de Código QR',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: _isScanning ? null : _scanQRCode,
                    icon: Icon(
                      _isScanning
                          ? Icons.hourglass_empty
                          : Icons.qr_code_scanner,
                      size: 16,
                    ),
                    label: Text(_isScanning ? 'Escaneando...' : 'Escanear QR'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      textStyle: const TextStyle(fontSize: 12),
                    ),
                  ),
                ],
              ), */
              const SizedBox(height: 1),
            ],
          ),
        ),
      ),
    );
  }

  /// Método para escanear código QR
  Future<void> _scanQRCode() async {
    setState(() {
      _isScanning = true;
    });

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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al escanear QR: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isScanning = false;
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

  /// Procesar los datos del QR y llenar los campos
  void _processQRData(String qrData) {
    try {
      setState(() {
        _hasScannedData = true;
        _isEditMode = false; // Permitir edición después de escanear
      });

      // Parsear el QR de SUNAT (formato típico separado por |)
      final parts = qrData.split('|');

      if (parts.length >= 6) {
        // Formato típico de QR SUNAT:
        // RUC|Tipo|Serie|Número|IGV|Total|Fecha|TipoDoc|DocReceptor

        // Envolver las asignaciones en setState y escribir en ambos controladores
        setState(() {
          // RUC del emisor
          if (parts[0].isNotEmpty) {
            _rucController.text = parts[0];
            _loadApiRuc(_rucController.text);
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
            _serieController.text = parts[2];
          }

          // Número de factura
          if (parts[3].isNotEmpty) {
            _numeroController.text = parts[3];
          }

          // Igv de factura
          if (parts[4].isNotEmpty) {
            _igvController.text = parts[4];
          }
          /*
          // Número de documento (combinado para compatibilidad)
          if (parts[2].isNotEmpty && parts[3].isNotEmpty) {
            _numeroDocumentoController.text = '${parts[2]}-${parts[3]}';
          }
          */

          // Total
          if (parts[5].isNotEmpty) {
            _totalController.text = parts[5];
          }

          // Fecha (si está disponible)
          if (parts.length > 6 && parts[6].isNotEmpty) {
            final fechaNormalizada = formatDate(parts[6]);
            _fechaEmisionController.text = fechaNormalizada;
          }

          // Ruc
          if (parts[8].isNotEmpty) {
            _rucClienteController.text = parts[8];
          }
        });

        ScaffoldMessenger.of(context).showSnackBar(
          /* const SnackBar(
            content: Text('Datos del QR aplicados correctamente'),
            backgroundColor: Colors.green,
          ), */
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
      } else {
        throw Exception('Formato de QR no válido');
      }
    } catch (e) {
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

  /// Renderizar evidencia cuando llega en base64 o como URL
  Widget _buildEvidenciaImage(String evidenciaBase64OrUrl) {
    try {
      // 1) Si parece una URL válida
      if (_controller.isValidUrl(evidenciaBase64OrUrl)) {
        final uri = Uri.tryParse(evidenciaBase64OrUrl);
        final isPdf = uri != null && uri.path.toLowerCase().endsWith('.pdf');
        if (isPdf) {
          // Mostrar placeholder de PDF (clicable por el GestureDetector externo)
          final fileName = uri.pathSegments.isNotEmpty
              ? uri.pathSegments.last
              : 'PDF';
          return Container(
            color: Colors.grey.shade100,
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.picture_as_pdf,
                    size: 48,
                    color: Colors.red.shade700,
                  ),
                  const SizedBox(height: 8),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 160),
                    child: Text(
                      fileName,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 12),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 2,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        // No es PDF -> intentar mostrar como imagen de red
        return Image.network(
          evidenciaBase64OrUrl,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) {
            return Center(child: Text('No se pudo cargar la imagen'));
          },
        );
      }

      // 2) Si parece base64, decodificar y validar tipo
      if (_controller.isBase64(evidenciaBase64OrUrl)) {
        Uint8List bytes;
        try {
          bytes = base64Decode(evidenciaBase64OrUrl);
        } catch (e) {
          return Center(child: Text('Evidencia inválida'));
        }

        // Detectar PDF por cabecera '%PDF'
        final isPdf =
            bytes.length >= 4 &&
            bytes[0] == 0x25 &&
            bytes[1] == 0x50 &&
            bytes[2] == 0x44 &&
            bytes[3] == 0x46;

        if (isPdf) {
          // Mostrar placeholder PDF en lugar de intentar Image.memory
          return Container(
            color: Colors.grey.shade100,
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.picture_as_pdf,
                    size: 48,
                    color: Colors.red.shade700,
                  ),
                  const SizedBox(height: 8),
                  const Text('PDF', style: TextStyle(fontSize: 12)),
                ],
              ),
            ),
          );
        }

        // No es PDF -> mostrar imagen en memoria
        return Image.memory(bytes, fit: BoxFit.cover);
      }

      // 3) Si no es ninguno de los anteriores, mostrar placeholder
      return Center(child: Text('Evidencia no disponible'));
    } catch (e) {
      return Center(child: Text('Evidencia inválida'));
    }
  }

  /// Construir la sección de categoría
  Widget _buildCategorySection() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    // Determinar las categorías disponibles según la política
    List<DropdownMenuItem<String>> items = [];
    // Valor seleccionado calculado de forma robusta (se determina más abajo)
    String? selectedValue;
    final savedCategoriaGlobal = _categoriaController.text.trim();
    String normalizeGlobal(String s) => s.trim().toLowerCase();

    // ✅ Detectar si la categoría es "PLANILLA DE MOVILIDAD"
    final isPlanillaMovilidad =
        savedCategoriaGlobal.toLowerCase().contains('planilla') &&
        savedCategoriaGlobal.toLowerCase().contains('movilidad');

    if (_politicaController.text.toLowerCase().contains('movilidad') ||
        _politicaController.text.toLowerCase().contains('general')) {
      // Para políticas 'movilidad' y 'general', usar datos de la API
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
                color: isDark
                    ? Colors.red.shade900.withOpacity(0.2)
                    : Colors.red.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isDark ? Colors.red.shade700 : Colors.red.shade200,
                ),
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

      // Normalizar y determinar el valor seleccionado de forma robusta.
      final savedCategoria = savedCategoriaGlobal;

      // Buscar coincidencia insensible a mayúsculas/espacios en los items.
      final match = items.firstWhere(
        (it) =>
            normalizeGlobal(it.value ?? '') == normalizeGlobal(savedCategoria),
        orElse: () =>
            DropdownMenuItem<String>(value: '', child: const SizedBox.shrink()),
      );

      if (savedCategoria.isNotEmpty) {
        if (match.value != null && match.value!.isNotEmpty) {
          // Usar el valor tal como viene en la lista (mantener capitalización API)
          selectedValue = match.value;
        } else {
          // No se encontró en la lista: insertar fallback para que el usuario lo vea
          items.insert(
            0,
            DropdownMenuItem<String>(
              value: savedCategoria,
              child: Text(_formatCategoriaName(savedCategoria) + ' (guardada)'),
            ),
          );
          selectedValue = savedCategoria;
        }
      }

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

    // Verificar si la categoría ORIGINAL (guardada) es "Planilla de Movilidad"
    // ✅ Bloquear edición si es "PLANILLA DE MOVILIDAD"
    // También bloquear si la categoría ORIGINAL (guardada) es "Planilla de Movilidad"
    final isMovilidadCategoriaOriginal =
        _originalCategoria != null &&
        (_originalCategoria!.toLowerCase().contains('planilla de movilidad') ||
            _originalCategoria!.toLowerCase().contains('movilidad'));

    return AbsorbPointer(
      absorbing: !_isEditMode || isMovilidadCategoriaOriginal,
      child: DropdownButtonFormField<String>(
        decoration: InputDecoration(
          labelText: 'Categoría *',
          prefixIcon: Icon(Icons.category),
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
            borderSide: const BorderSide(color: Colors.white, width: 1),
          ),
          filled: true,
          fillColor: isPlanillaMovilidad
              ? (isDark
                    ? Theme.of(context).disabledColor.withOpacity(0.1)
                    : Colors.grey.shade200)
              : (_isEditMode
                    ? (isDark ? Theme.of(context).cardColor : Colors.white)
                    : (isDark ? Theme.of(context).cardColor : Colors.white)),
          // ✅ Agregar sufijo para indicar que está bloqueada
          suffixIcon: isPlanillaMovilidad
              ? Icon(Icons.lock, color: Colors.grey.shade600, size: 20)
              : null,
        ),

        value: selectedValue,
        items: items,
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Categoría es obligatoria';
          }
          return null;
        },
        onChanged: (value) {
          // ✅ Solo permitir cambios si NO es planilla de movilidad
          if (value != null && !isPlanillaMovilidad) {
            setState(() {
              _categoriaController.text = value;
            });
            // ✅ Llamar directamente después del setState
            Future.microtask(() => _validateForm());
          }
        },
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

  /// Construir la sección de tipo de gasto
  Widget _buildTipoGastoSection() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
        else if (_errorTiposGasto != null)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.red.shade900.withOpacity(0.2)
                  : Colors.red.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isDark ? Colors.red.shade700 : Colors.red.shade200,
              ),
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
          AbsorbPointer(
            absorbing: true, // 🔒 Siempre bloqueado - no editable
            child: DropdownButtonFormField<String>(
              decoration: InputDecoration(
                labelText: 'Tipo de Gasto * (Automático)',
                prefixIcon: Icon(Icons.lock_outline, color: Colors.grey),
                suffixIcon: Tooltip(
                  message:
                      'El tipo de gasto se asigna automáticamente según el centro de costo',
                  child: Icon(Icons.info_outline, size: 20, color: Colors.grey),
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
                  borderSide: BorderSide(color: Colors.grey, width: 2),
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
              value:
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
              onChanged:
                  null, // 🔒 Deshabilitado - no se puede cambiar manualmente
            ),
          ),
      ],
    );
  }
  /* 
  Widget _buildCentroCostoSection() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Si está cargando, mostrar indicador
        if (_isLoadingCentrosCosto)
          const Column(
            children: [
              Center(child: CircularProgressIndicator()),
              SizedBox(height: 8),
              Text(
                'Cargando centro de costo ...',
                style: TextStyle(color: Colors.grey),
                textAlign: TextAlign.center,
              ),
            ],
          )
        else if (_errorCentroCosto != null)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.red.shade900.withOpacity(0.2)
                  : Colors.red.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isDark ? Colors.red.shade700 : Colors.red.shade200,
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.error, color: Colors.red.shade600),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Error al cargar centro de costo: $_errorCentroCosto',
                    style: TextStyle(color: Colors.red.shade700),
                  ),
                ),
                TextButton(
                  onPressed: _loadCentrosCosto,
                  child: const Text('Reintentar'),
                ),
              ],
            ),
          )
        else
          AbsorbPointer(
            absorbing: !_isEditMode,
            child: DropdownButtonFormField<String>(
              decoration: InputDecoration(
                labelText: 'Centro de Costo *',
                prefixIcon: Icon(Icons.abc),
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
                  borderSide: const BorderSide(color: Colors.white, width: 1),
                ),
                filled: true,
                fillColor: _isEditMode
                    ? (isDark ? Theme.of(context).cardColor : Colors.white)
                    : (isDark ? Theme.of(context).cardColor : Colors.white),
              ),
              value:
                  _centroCostoController.text.isNotEmpty &&
                      _centroCosto.any(
                        (centro) => centro.value == _centroCostoController.text,
                      )
                  ? _centroCostoController.text
                  : null,
              items: _centroCosto
                  .map(
                    (centro) => DropdownMenuItem<String>(
                      value: centro.value,
                      child: Text(centro.value),
                    ),
                  )
                  .toList(),

              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Centro de costo es obligatorio';
                }
                return null;
              },
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _centroCostoController.text = value;
                  });
                  // ✅ Llamar directamente después del setState
                  Future.microtask(() => _validateForm());
                }
              },
            ),
          ),
      ],
    );
  }
 */

  Widget _buildCentroCostoSection() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_isLoadingCentrosCosto)
          const Column(
            children: [
              Center(child: CircularProgressIndicator()),
              SizedBox(height: 8),
              Text(
                'Cargando centro de costo ...',
                style: TextStyle(color: Colors.grey),
                textAlign: TextAlign.center,
              ),
            ],
          )
        else if (_errorCentroCosto != null)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.red.shade900.withOpacity(0.2)
                  : Colors.red.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isDark ? Colors.red.shade700 : Colors.red.shade200,
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.error, color: Colors.red.shade600),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Error al cargar centro de costo: $_errorCentroCosto',
                    style: TextStyle(color: Colors.red.shade700),
                  ),
                ),
                TextButton(
                  onPressed: _loadCentrosCosto,
                  child: const Text('Reintentar'),
                ),
              ],
            ),
          )
        else
          AbsorbPointer(
            absorbing: !_isEditMode,
            child: DropdownButtonFormField<String>(
              decoration: InputDecoration(
                labelText: 'Centro de Costo *',
                prefixIcon: Icon(Icons.abc),
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
                  borderSide: const BorderSide(color: Colors.white, width: 1),
                ),
                filled: true,
                fillColor: _isEditMode
                    ? (isDark ? Theme.of(context).cardColor : Colors.white)
                    : (isDark ? Theme.of(context).cardColor : Colors.white),
              ),
              value:
                  _centroCostoController.text.isNotEmpty &&
                      _centroCosto.any(
                        (centro) => centro.value == _centroCostoController.text,
                      )
                  ? _centroCostoController.text
                  : null,
              items: _centroCosto
                  .map(
                    (centro) => DropdownMenuItem<String>(
                      value: centro.value,
                      child: Text(centro.value),
                    ),
                  )
                  .toList(),

              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Centro de costo es obligatorio';
                }
                return null;
              },
              onChanged: (value) {
                if (value != null) {
                  print('========================================');
                  print('🔄 DROPDOWN CENTRO DE COSTO CAMBIADO');
                  print('📌 Valor seleccionado: "$value"');
                  print('📌 _isEditMode: $_isEditMode');

                  setState(() {
                    _centroCostoController.text = value;

                    // 🔄 Cargar automáticamente el tipo de gasto y placa desde la metadata del centro de costo
                    final centroSeleccionado = _centroCosto.firstWhere(
                      (c) => c.value == value,
                      orElse: () => DropdownOption.empty,
                    );

                    if (centroSeleccionado.metadata != null) {
                      // Cargar tipo de gasto
                      final tipogasto =
                          centroSeleccionado.metadata!['tipogasto']
                              ?.toString() ??
                          centroSeleccionado.metadata!['tipoGasto']?.toString();

                      if (tipogasto != null && tipogasto.isNotEmpty) {
                        // Buscar el tipo de gasto en la lista
                        final tipoGastoEncontrado = _tiposGasto.firstWhere(
                          (tipo) =>
                              tipo.value.toUpperCase() ==
                              tipogasto.toUpperCase(),
                          orElse: () => DropdownOption.empty,
                        );

                        if (tipoGastoEncontrado.id.isNotEmpty) {
                          _tipoGastoController.text = tipoGastoEncontrado.value;
                          print(
                            '✅ Tipo de gasto asignado automáticamente: ${tipoGastoEncontrado.value}',
                          );
                        } else {
                          print(
                            '⚠️ Tipo de gasto "$tipogasto" no encontrado en la lista',
                          );
                        }
                      }

                      // Cargar placa
                      final placa = centroSeleccionado.metadata!['placa']
                          ?.toString();
                      if (placa != null && placa.isNotEmpty) {
                        _placaController.text = placa;
                        print('✅ Placa asignada automáticamente: $placa');
                      } else {
                        _placaController.text = 'N'; // Valor por defecto
                        print('ℹ️ Placa por defecto: N');
                      }
                    }
                  });

                  print(
                    '✅ Controlador actualizado: "${_centroCostoController.text}"',
                  );
                  print('========================================');
                  // ✅ Llamar directamente después del setState
                  Future.microtask(() => _validateForm());
                }
              },
            ),
          ),
      ],
    );
  }

  Future<void> _cargarImagenServidor() async {
    debugPrint('🔄 Iniciando carga de evidencia desde servidor...');

    try {
      if (!mounted) return;

      final baseName =
          '${widget.reporte.idrend}_${_rucController.text}_${_serieController.text}_${_numeroController.text}';

      // Construir lista de extensiones candidatas
      final List<String> candidates = [];

      // Añadir extensiones comunes y un intento sin extensión
      candidates.addAll(['.png', '.jpg', '.jpeg', '.pdf', '.gif', '']);

      Uint8List? bytes;
      String? triedName;

      // Intentar obtener la imagen desde el servidor con las extensiones candidatas
      for (final ext in candidates) {
        final name = ext.isNotEmpty ? '$baseName$ext' : baseName;
        debugPrint('🔎 Intentando obtener: $name');
        try {
          bytes = await _apiService.obtenerImagenBytes(name);
        } catch (_) {
          bytes = null;
        }
        if (bytes != null) {
          triedName = name;
          break;
        }
      }

      // Si encontramos la imagen
      if (bytes != null && mounted) {
        // Guardar la imagen en el dispositivo
        final tempDir =
            await getTemporaryDirectory(); // Obtén el directorio temporal
        final tempFile = File(
          '${tempDir.path}/$triedName',
        ); // Crear un archivo temporal

        // Escribir los bytes en el archivo
        await tempFile.writeAsBytes(bytes);

        setState(() {
          _selectedImage =
              tempFile; // Asignar el archivo a la variable _selectedImage
        });

        debugPrint('✅ Evidencia cargada desde servidor: $triedName');
        return;
      }

      // Si no se encuentra la imagen
      /*     debugPrint(
        '⚠️ No se encontró la evidencia en el servidor (probadas: ${candidates.join(', ')})',
      ); */
      if (mounted) {
        /*  ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No se encontró la evidencia en el servidor'),
          ),
        ); */
      }
    } catch (e) {
      debugPrint('🔥 Error cargando imagen del servidor: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error cargando evidencia: ${e.toString()}')),
        );
      }
    }
  }

  /*
  Future<void> _cargarImagenServidor() async {
    try {
      if (!mounted) return;

      // Base para el nombre de archivo en el servidor
      final baseName =
          '${widget.reporte.idrend}_${_rucController.text}_${_serieController.text}_${_numeroController.text}';

      debugPrint('🧩 Buscando evidencia en servidor (base): $baseName');

      // Si ya tenemos algo en _apiEvidencia y es base64, no hace falta descargar
      if (_apiEvidencia != null && _apiEvidencia!.isNotEmpty) {
        final api = _apiEvidencia!;
        if (_controller.isBase64(api)) {
          debugPrint(
            'ℹ️ _apiEvidencia ya contiene base64, no se descargará del servidor',
          );
          return;
        }
      }

      // Construir lista de extensiones candidatas. Si _apiEvidencia contiene
      // una URL o filename con extensión, probar esa extensión primero.
      final List<String> candidates = [];
      if (_apiEvidencia != null && _apiEvidencia!.isNotEmpty) {
        final api = _apiEvidencia!;
        try {
          final ext = p.extension(api);
          if (ext.isNotEmpty) candidates.add(ext);
        } catch (_) {}
      }

      // Añadir extensiones comunes y un intento sin extensión
      candidates.addAll(['.png', '.jpg', '.jpeg', '.pdf', '.gif', '']);

      Uint8List? bytes;
      String? triedName;
      for (final ext in candidates) {
        final name = ext.isNotEmpty ? '$baseName$ext' : baseName;
        debugPrint('🔎 Intentando obtener: $name');
        try {
          bytes = await _apiService.obtenerImagenBytes(name);
        } catch (e) {
          bytes = null;
        }
        if (bytes != null) {
          triedName = name;
          break;
        }
      }

      if (bytes != null && mounted) {
        final b64 = base64Encode(bytes);
        setState(() {
          _selectedImage = null; // por si hay una imagen local
          _apiEvidencia =
              b64; // ahora _buildEvidenciaImage la detectará como base64
        });
        debugPrint('✅ Evidencia cargada desde servidor: $triedName');
        return;
      }

      debugPrint(
        '⚠️ No se encontró la evidencia en el servidor (probadas: ${candidates.join(', ')})',
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No se encontró la evidencia en el servidor'),
          ),
        );
      }
    } catch (e) {
      debugPrint('🔥 Error cargando imagen del servidor: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error cargando evidencia: ${e.toString()}')),
        );
      }
    }
  }
*/

  /// Mostrar un PDF en un diálogo usando PdfPreview (paquete `printing` está en pubspec)
  Future<void> _showPdfDialogFromBytes(Uint8List bytes, {String? title}) async {
    if (!mounted) return;
    await showDialog(
      context: context,
      builder: (context) => Dialog(
        insetPadding: const EdgeInsets.all(12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              color: Colors.grey.shade200,
              width: double.infinity,
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      title ?? 'PDF',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),
            SizedBox(
              width: MediaQuery.of(context).size.width * 0.9,
              height: MediaQuery.of(context).size.height * 0.8,
              child: PdfPreview(
                allowPrinting: true,
                canChangePageFormat: false,
                build: (format) async => bytes,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Handler cuando el usuario toca la evidencia en la UI.
  /// Intenta obtener bytes desde la selección local, desde base64 en
  /// `_apiEvidencia` o (si es una URL) intenta descargar bytes vía API.
  Future<void> _handleTapEvidencia() async {
    try {
      String nombreArchivo =
          '${_rucController.text}_${_serieController.text}_${_numeroController.text}';

      // 1️⃣ Si hay un archivo local seleccionado
      if (_selectedImage != null) {
        final path = _selectedImage!.path;
        final bytes = await _selectedImage!.readAsBytes();

        if (_isPdfFile(path)) {
          await _abrirPdfExterno(bytes, path.split('/').last);
          return;
        } else {
          await _showEvidenciaDialogFromBytes(bytes);
          return;
        }
      }

      // 2️⃣ Si tenemos evidencia almacenada en `_apiEvidencia`
      if (_selectedImage != null) {
        final evidencia = _selectedImage!.path;

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

  /*
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
*/
  Future<void> _showEvidenciaDialogFromBytes(
    Uint8List bytes, {
    String? nombreArchivo,
  }) async {
    if (!mounted) return;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    // Supongamos que tienes estos valores
    final ruc = widget.reporte.ruc;
    final serie = widget.reporte.serie;
    final numero = widget.reporte.numero;

    // Concatenar para formar el nombre del archivo
    final nombreArchivo = '${ruc}_${serie}_${numero}.png';

    // Si no se pasa un nombre, usar un default
    final fileName = nombreArchivo;
    // Guardar temporalmente los bytes en un archivo para compartir
    final tempDir = await getTemporaryDirectory();
    final tempFile = File('${tempDir.path}/$fileName');
    await tempFile.writeAsBytes(bytes);

    /* showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Colors.black,
        title: Center(
          child: const Text('Evidencia', style: TextStyle(color: Colors.white)),
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
              borderRadius: BorderRadius.circular(12),
              child: Image.memory(bytes, fit: BoxFit.contain),
            ),
          ),
        ),
        actions: [
          // Botón de compartir
          TextButton.icon(
            onPressed: () async {
              try {
                await Share.shareXFiles([
                  XFile(tempFile.path, name: fileName),
                ], text: fileName);
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error compartiendo: $e')),
                );
              }
            },
            icon: const Icon(Icons.share, color: Colors.white),
            label: const Text(
              'Compartir',
              style: TextStyle(color: Colors.white),
            ),
          ),

          // Botón de cerrar
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
     */
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.7),
      builder: (_) => Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 24),
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xff1e1e1e) : const Color(0xff121212),
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: Colors.blue.withOpacity(0.4),
                blurRadius: 20,
                spreadRadius: 0,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                '📎 Evidencia',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),

              const SizedBox(height: 14),

              SizedBox(
                width: MediaQuery.of(context).size.width * .85,
                height: MediaQuery.of(context).size.height * .55,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: InteractiveViewer(
                    minScale: 1,
                    maxScale: 6,
                    child: Image.memory(bytes, fit: BoxFit.contain),
                  ),
                ),
              ),

              const SizedBox(height: 18),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // compartir
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueAccent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () async {
                      try {
                        await Share.shareXFiles([
                          XFile(tempFile.path, name: fileName),
                        ], text: fileName);
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Error compartiendo: $e')),
                        );
                      }
                    },
                    icon: const Icon(Icons.share, color: Colors.white),
                    label: const Text(
                      "Compartir",
                      style: TextStyle(color: Colors.white),
                    ),
                  ),

                  // cerrar
                  TextButton(
                    style: TextButton.styleFrom(overlayColor: Colors.white12),
                    onPressed: () => Navigator.pop(context),
                    child: const Text(
                      "Cerrar",
                      style: TextStyle(color: Colors.white70),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
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

  /// Guardar factura mediante API
  Future<void> _updateFacturaAPI() async {
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

    setState(() => _isLoading = true);
    try {
      // 🔍 DEBUG: Verificar valor del centro de costo antes de enviar
      print('========================================');
      print('📤 ENVIANDO DATOS AL SERVIDOR');
      print('🔍 Centro de Costo: "${_centroCostoController.text}"');
      print('🔍 Categoría: "${_categoriaController.text}"');
      print('🔍 Tipo Gasto: "${_tipoGastoController.text}"');
      print(
        '🔍 Imagen seleccionada: ${_selectedImage != null ? "Sí (${_selectedImage!.path})" : "No (null)"}',
      );
      print('========================================');

      final success = await _controller.saveReporte(
        reporte: widget.reporte,
        politica: _politicaController.text,
        categoria: _categoriaController.text,
        tipoGasto: _tipoGastoController.text,
        centroCosto: _centroCostoController.text,
        ruc: _rucController.text,
        razonsocial: _razonSocialController.text,
        tipoComprobante: _tipoComprobanteController.text,
        serie: _serieController.text,
        numero: _numeroController.text,
        igv: _igvController.text,
        fechaEmision: _fechaEmisionController.text,
        total: _totalController.text,
        moneda: _monedaController.text,
        rucCliente: _rucClienteController.text,
        nota: _notaController.text,

        // Movilidad
        motivoViaje: _motivoViajeController.text,
        lugarOrigen: _origenController.text,
        lugarDestino: _destinoController.text,
        tipoMovilidad: _tipoMovilidadController.text,
        placa: _placaController.text,
        selectedImage: _selectedImage, // ✅ Si es null, se envía null
        apiEvidencia: null,
      );
      /* 
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ GASTO ACTUALIZADA'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        ); */

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white, size: 22),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Gasto actualizado correctamente',
                    style: TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.green.shade600,
            duration: const Duration(seconds: 3),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            margin: const EdgeInsets.all(16),
            elevation: 6,
            showCloseIcon: true,
            closeIconColor: Colors.white,
          ),
        );

        // Actualizar el objeto reporte con los nuevos valores
        final updatedReporte = Reporte(
          idrend: widget.reporte.idrend,
          iduser: widget.reporte.iduser,
          dni: widget.reporte.dni,
          politica: _politicaController.text,
          categoria: _categoriaController.text,
          tipogasto: _tipoGastoController.text,
          ruc: _rucController.text,
          proveedor: _razonSocialController.text,
          tipocomprobante: _tipoComprobanteController.text,
          serie: _serieController.text,
          numero: _numeroController.text,
          igv: double.tryParse(_igvController.text),
          fecha: _fechaEmisionController.text,
          total: double.tryParse(_totalController.text),
          moneda: _monedaController.text,
          ruccliente: _rucClienteController.text,
          desempr: widget.reporte.desempr,
          dessed: widget.reporte.dessed,
          gerencia: widget.reporte.gerencia,
          area: widget.reporte.area,
          idcuenta: widget.reporte.idcuenta,
          consumidor:
              _centroCostoController.text, // ✅ ACTUALIZAR CENTRO DE COSTO
          placa: _placaController.text,
          estadoActual: widget.reporte.estadoActual,
          glosa: widget.reporte.glosa,
          motivoviaje: _motivoViajeController.text,
          lugarorigen: _origenController.text,
          lugardestino: _destinoController.text,
          tipomovilidad: _tipoMovilidadController.text,
          feccre: widget.reporte.feccre,
          obs: _notaController.text,
          evidencia: widget.reporte.evidencia,
          motivorechazo: widget.reporte.motivorechazo,
        );

        if (widget.onSave != null) widget.onSave!(updatedReporte);

        // Cerrar modal
        Navigator.of(context).pop();
      }
    } catch (e) {
      final serverMessage = _extractServerMessage(e.toString());
      _showServerAlert(serverMessage);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // Removed unused success snackbar helper; success feedback is shown inline after save.
  /* 
  @override
  Widget build(BuildContext context) {
    final isMovilidad = _isPlanillaDeMovilidad();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      height: MediaQuery.of(context).size.height * 0.90,
      decoration: BoxDecoration(
        color: isDark
            ? Theme.of(context).scaffoldBackgroundColor
            : Colors.white,
        borderRadius: const BorderRadius.only(
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
                padding: const EdgeInsets.all(15),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: isMovilidad
                      ? [
                          // Campos simplificados para PLANILLA DE MOVILIDAD
                          _buildImageSection(),
                          const SizedBox(height: 4),
                          //POLITICA
                          _buildPolicySection(),
                          const SizedBox(height: 4),
                          _buildCategorySection(),
                          const SizedBox(height: 4),
                          _buildCentroCostoSection(),
                          const SizedBox(height: 4),

                          // Fecha Emisión
                          _buildDateField(
                            _fechaEmisionController,
                            'Fecha Emisión ',
                            Icons.calendar_month_sharp,
                            isRequired: true,
                            readOnly: !_isEditMode,
                          ),
                          const SizedBox(height: 4),
                          // Total
                          _buildTextField(
                            _totalController,
                            'Total ',
                            Icons.price_change,
                            TextInputType.numberWithOptions(decimal: true),
                            isRequired: true,
                            readOnly: !_isEditMode,
                          ),
                          const SizedBox(height: 4),
                          // Moneda
                          _buildMonedaDropdown(),
                          const SizedBox(height: 4),
                          // Sección Movilidad completa
                          _buildMovilidadSection(),
                          const SizedBox(height: 4),
                          // Nota
                          _buildTextField(
                            _notaController,
                            'Nota o Glosa:',
                            Icons.comment,
                            TextInputType.text,
                            readOnly: !_isEditMode,
                          ),
                        ]
                      : [
                          // Campos normales (formulario completo)
                          _buildImageSection(),
                          const SizedBox(height: 10),
                          _buildPolicySection(),
                          const SizedBox(height: 10),
                          _buildCategorySection(),
                          const SizedBox(height: 10),
                          _buildTipoGastoSection(),
                          const SizedBox(height: 10),
                          _buildCentroCostoSection(),
                          const SizedBox(height: 10),
                          _buildInvoiceDataSection(),
                          const SizedBox(height: 10),
                          _buildNotesSection(),
                          const SizedBox(height: 10),
                          // Sección Movilidad (solo visible para políticas de movilidad)
                          _buildMovilidadSection(),
                          const SizedBox(height: 10),
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
    final isMovilidad = _isPlanillaDeMovilidad();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final double maxHeight = MediaQuery.of(context).size.height * 0.90;
    final double minHeight = MediaQuery.of(context).size.height * 0.55;

    return Container(
      constraints: BoxConstraints(minHeight: minHeight, maxHeight: maxHeight),
      decoration: BoxDecoration(
        color: isDark
            ? Theme.of(context).scaffoldBackgroundColor
            : Colors.white,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        resizeToAvoidBottomInset: true, // ✅ Permite ajuste al teclado

        body: SafeArea(
          top: false,
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                // Header fijo
                _buildHeader(),

                // Contenido scrolleable
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(), // ✅ Scroll suave
                    padding: const EdgeInsets.symmetric(horizontal: 15),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: isMovilidad
                          ? [
                              // Campos simplificados para PLANILLA DE MOVILIDAD
                              _buildImageSection(),
                              const SizedBox(height: 4),
                              _buildPolicySection(),
                              const SizedBox(height: 4),
                              _buildCategorySection(),
                              const SizedBox(height: 4),
                              _buildCentroCostoSection(),
                              const SizedBox(height: 4),
                              //tipo de gasto para planilla de movilidad
                              _buildTipoGastoSection(),
                              const SizedBox(height: 4),
                              _buildDateField(
                                _fechaEmisionController,
                                'Fecha Emisión ',
                                Icons.calendar_month_sharp,
                                isRequired: true,
                                readOnly: !_isEditMode,
                              ),
                              const SizedBox(height: 4),
                              _buildTextField(
                                _totalController,
                                'Total ',
                                Icons.price_change,
                                TextInputType.numberWithOptions(decimal: true),
                                isRequired: true,
                                readOnly: !_isEditMode,
                              ),
                              const SizedBox(height: 4),
                              _buildMonedaDropdown(),
                              const SizedBox(height: 4),
                              _buildMovilidadSection(),
                              const SizedBox(height: 4),
                              _buildTextField(
                                _notaController,
                                'Nota o Glosa:',
                                Icons.comment,
                                TextInputType.text,
                                readOnly: !_isEditMode,
                              ),
                              /*        const SizedBox(
                                height: 80,
                              ), // ✅ Espacio extra para scroll */
                            ]
                          : [
                              // Campos normales (formulario completo)
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
                              _buildInvoiceDataSection(),
                              const SizedBox(height: 10),
                              _buildNotesSection(),
                              const SizedBox(height: 10),
                              _buildMovilidadSection(),
                              /*   const SizedBox(
                                height: 80,
                              ), */
                              // ✅ Espacio extra para scroll
                            ],
                    ),
                  ),
                ),

                // Botones fijos abajo
                SafeArea(top: false, child: _buildActionButtons()),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /* 
  @override
  Widget build(BuildContext context) {
    final isMovilidad = _isPlanillaDeMovilidad();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Colors.transparent,
      resizeToAvoidBottomInset: true, // ✔️ como pediste
      body: Align(
        alignment: Alignment.bottomCenter,
        child: Container(
          height: MediaQuery.of(context).size.height * 0.90, // ✔️ altura fija
          decoration: BoxDecoration(
            color: isDark
                ? Theme.of(context).scaffoldBackgroundColor
                : Colors.white,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),

          /// 🔥 ESTO ES LO MÁS IMPORTANTE 🔥
          /// Mantiene altura fija aunque el teclado aparezca.
          child: LayoutBuilder(
            builder: (context, constraints) {
              return ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: constraints.maxHeight, // ✔️ NO permite que crezca
                ),

                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      _buildHeader(),

                      /// 🔥 AQUÍ EL SCROLL INTERNO SIN CAMBIAR ALTURA EXTERNA
                      Expanded(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.all(15),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: isMovilidad
                                ? [
                                    _buildImageSection(),
                                    const SizedBox(height: 4),
                                    _buildPolicySection(),
                                    const SizedBox(height: 4),
                                    _buildCategorySection(),
                                    const SizedBox(height: 4),

                                    _buildDateField(
                                      _fechaEmisionController,
                                      'Fecha Emisión ',
                                      Icons.calendar_month_sharp,
                                      isRequired: true,
                                      readOnly: !_isEditMode,
                                    ),
                                    const SizedBox(height: 4),

                                    _buildTextField(
                                      _totalController,
                                      'Total ',
                                      Icons.price_change,
                                      const TextInputType.numberWithOptions(
                                        decimal: true,
                                      ),
                                      isRequired: true,
                                      readOnly: !_isEditMode,
                                    ),
                                    const SizedBox(height: 4),

                                    _buildMonedaDropdown(),
                                    const SizedBox(height: 4),

                                    _buildMovilidadSection(),
                                    const SizedBox(height: 4),

                                    _buildTextField(
                                      _notaController,
                                      'Nota o Glosa:',
                                      Icons.comment,
                                      TextInputType.text,
                                      readOnly: !_isEditMode,
                                    ),
                                    const SizedBox(height: 10),
                                  ]
                                : [
                                    _buildImageSection(),
                                    const SizedBox(height: 10),
                                    _buildPolicySection(),
                                    const SizedBox(height: 10),
                                    _buildCategorySection(),
                                    const SizedBox(height: 10),
                                    _buildTipoGastoSection(),
                                    const SizedBox(height: 10),
                                    _buildInvoiceDataSection(),
                                    const SizedBox(height: 10),
                                    _buildNotesSection(),
                                    const SizedBox(height: 10),
                                    _buildMovilidadSection(),
                                    const SizedBox(height: 10),
                                  ],
                          ),
                        ),
                      ),

                      _buildActionButtons(),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
 */
  /// Construir el header del modal
  Widget _buildHeader() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(14),
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
          Icon(Icons.fact_check_rounded, color: Colors.white, size: 28),
          /*           const Icon(Icons.receipt_long, color: Colors.white, size: 28),
 */
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Editar Gasto # $_numeroGasto',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  'Modifica los datos del reporte',
                  style: TextStyle(fontSize: 12, color: Colors.white70),
                ),
              ],
            ),
          ),
          // Botón editar (solo icono)
          if (!_isEditMode)
            IconButton(
              onPressed: () {
                print('========================================');
                print('🔓 MODO EDICIÓN ACTIVADO');
                print('========================================');
                setState(() {
                  _isEditMode = true;
                });
              },
              icon: const Icon(Icons.edit, color: Colors.white, size: 24),
              tooltip: 'Editar campos',
            ),
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.close, color: Colors.white),
          ),
        ],
      ),
    );
  }

  /// Construir la sección de política
  Widget _buildPolicySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Datos Generales',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.red,
          ),
        ),
        const SizedBox(height: 16),
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
            prefixIcon: const Icon(Icons.security_outlined),
          ),
        ),
      ],
    );
  }

  /// Construir la sección de datos de la factura
  Widget _buildInvoiceDataSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Datos Factura',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.red,
          ),
        ),
        const SizedBox(height: 8),
        // Primera fila: RUC y Tipo de Comprobante
        _buildTextField(
          _rucController,
          'RUC ',
          Icons.business,
          TextInputType.number,
          isRequired: true,
          readOnly: true,
        ),
        const SizedBox(height: 16),

        _buildTextField(
          _razonSocialController,
          'Razon social',
          Icons.house,
          TextInputType.text,
          readOnly: true,
        ),
        const SizedBox(height: 16),

        _buildTextField(
          _tipoComprobanteController,
          'Tipo Comprobante ',
          Icons.receipt_long,
          TextInputType.text,
          isRequired: true,
          readOnly: true,
        ),
        const SizedBox(height: 16),

        // Segunda fila: Serie y Número
        _buildTextField(
          _serieController,
          'Serie ',
          Icons.tag,
          TextInputType.text,
          isRequired: true,
          readOnly: true,
        ),
        const SizedBox(height: 16),
        _buildTextField(
          _numeroController,
          'Número ',
          Icons.numbers,
          TextInputType.number,
          isRequired: true,
          readOnly: true,
        ),
        const SizedBox(height: 16),

        // Tercera fila: IGV/Código y Fecha de Emisión
        _buildTextField(
          _igvController,
          'IGV',
          Icons.percent,
          TextInputType.text,
          readOnly: true,
        ),
        const SizedBox(height: 16),
        _buildTextField(
          _fechaEmisionController,
          'Fecha Emisión ',
          Icons.calendar_month_sharp,
          TextInputType.datetime,
          isRequired: true,
          readOnly: true,
        ),
        const SizedBox(height: 16),

        // Cuarta fila: Total y Moneda
        _buildTextField(
          _totalController,
          'Total ',
          Icons.price_change,
          TextInputType.numberWithOptions(decimal: true),
          isRequired: true,
          readOnly: true,
        ),
        const SizedBox(height: 16),
        _buildTextField(
          _monedaController,
          'Moneda *',
          Icons.monetization_on,
          TextInputType.text,
          readOnly: true,
        ),
        const SizedBox(height: 16),

        // Quinta fila: RUC Cliente (solo lectura)
        _buildTextField(
          _rucClienteController,
          'RUC Cliente * ',
          Icons.person,
          TextInputType.number,
          readOnly: true,
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

  /// Sección de notas
  Widget _buildNotesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildTextField(
          _notaController,
          'Nota',
          Icons.comment,
          TextInputType.text,
          readOnly: !_isEditMode,
        ),
        Text(
          _motivorechazoController.text,
          style: const TextStyle(fontSize: 16),
        ),
      ],
    );
  }

  /// Construir la sección específica de Movilidad (origen, destino, motivo, tipo transporte)
  Widget _buildMovilidadSection() {
    final politica = _politicaController.text.toLowerCase();
    if (!politica.contains('movilidad')) return const SizedBox.shrink();
    // Fondo y estilos para la sección de Movilidad
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final Color sectionBg = isDark ? Theme.of(context).cardColor : Colors.white;

    return Card(
      color: sectionBg,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(1),
        child: AbsorbPointer(
          absorbing: !_isEditMode,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.directions_car, color: Colors.orange),
                  const SizedBox(width: 14),
                  const Text(
                    'Detalles de Movilidad',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const Spacer(),
                  // Mostrar indicador de solo lectura cuando NO está en modo edición
                  if (!_isEditMode)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.grey.shade800.withOpacity(0.5)
                            : sectionBg.withOpacity(0.25),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isDark
                              ? Colors.grey.shade700
                              : Colors.grey.shade300,
                        ),
                      ),
                      child: Text(
                        'Solo lectura',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? Colors.grey.shade400 : Colors.black54,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _origenController,
                readOnly: !_isEditMode,
                decoration: InputDecoration(
                  labelText: 'Lugar Origen',
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
                      color: isDark ? Colors.grey.shade700 : Colors.grey,
                      width: 1,
                    ),
                  ),
                  focusedBorder: const UnderlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(12)),
                    borderSide: BorderSide(color: Colors.red, width: 2),
                  ),
                  disabledBorder: UnderlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: isDark ? Colors.grey.shade800 : Colors.white,
                      width: 1,
                    ),
                  ),
                  prefixIcon: const Icon(Icons.place),
                  filled: true,
                  fillColor: _isEditMode
                      ? (isDark ? Theme.of(context).cardColor : Colors.white)
                      : sectionBg.withOpacity(0.12),
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _destinoController,
                readOnly: !_isEditMode,
                decoration: InputDecoration(
                  labelText: 'Lugar Destino',
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
                      color: isDark ? Colors.grey.shade700 : Colors.grey,
                      width: 1,
                    ),
                  ),
                  focusedBorder: const UnderlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(12)),
                    borderSide: BorderSide(color: Colors.red, width: 2),
                  ),
                  disabledBorder: UnderlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: isDark ? Colors.grey.shade800 : Colors.white,
                      width: 1,
                    ),
                  ),
                  prefixIcon: const Icon(Icons.flag),
                  filled: true,
                  fillColor: _isEditMode
                      ? (isDark ? Theme.of(context).cardColor : Colors.white)
                      : sectionBg.withOpacity(0.12),
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _motivoViajeController,
                readOnly: !_isEditMode,
                decoration: InputDecoration(
                  labelText: 'Motivo de Viaje',
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
                      color: isDark ? Colors.grey.shade700 : Colors.grey,
                      width: 1,
                    ),
                  ),
                  focusedBorder: const UnderlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(12)),
                    borderSide: BorderSide(color: Colors.red, width: 2),
                  ),
                  disabledBorder: UnderlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: isDark ? Colors.grey.shade800 : Colors.white,
                      width: 1,
                    ),
                  ),
                  prefixIcon: const Icon(Icons.event_note),
                  filled: true,
                  fillColor: _isEditMode
                      ? (isDark ? Theme.of(context).cardColor : Colors.white)
                      : sectionBg.withOpacity(0.12),
                ),
              ),
              /*  TextFormField(
                controller: _tipoMovilidadController,
                readOnly: !_isEditMode,
                decoration: InputDecoration(
                  labelText: 'Tipo Transporte',
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
                    borderSide: const BorderSide(color: Colors.white, width: 1),
                  ),
                  prefixIcon: const Icon(Icons.directions_transit),
                  filled: true,
                  fillColor: _isEditMode
                      ? Colors.white
                      : sectionBg.withOpacity(0.12),
                ),
              ),
 */
              AbsorbPointer(
                absorbing: !_isEditMode,
                child: DropdownButtonFormField<DropdownOption>(
                  value: _selectedTipoMovilidad,
                  decoration: InputDecoration(
                    labelText: 'Tipo Transporte',
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
                      borderSide: BorderSide(color: Colors.red, width: 2),
                    ),
                    disabledBorder: UnderlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: Colors.white,
                        width: 1,
                      ),
                    ),
                    prefixIcon: const Icon(Icons.directions_transit),
                    filled: true,
                    fillColor: _isEditMode
                        ? (isDark ? Theme.of(context).cardColor : Colors.white)
                        : (isDark
                              ? Theme.of(
                                  context,
                                ).disabledColor.withOpacity(0.05)
                              : Colors.grey.shade50),
                  ),
                  isExpanded: true,
                  items: _tiposMovilidad.map((tipo) {
                    return DropdownMenuItem<DropdownOption>(
                      value: tipo,
                      child: Text(tipo.value),
                    );
                  }).toList(),
                  onChanged: _isEditMode
                      ? (value) {
                          setState(() {
                            _selectedTipoMovilidad = value;
                            _tipoMovilidadController.text = value?.value ?? '';
                          });
                        }
                      : null,
                  validator: (value) {
                    if (value == null) {
                      return 'Seleccione tipo transporte';
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _placaController,
                readOnly: !_isEditMode,
                decoration: InputDecoration(
                  labelText: 'Placa',
                  suffixIcon: Tooltip(
                    message:
                        'La placa se carga automáticamente pero puede editarse',
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
                      color: isDark ? Colors.grey.shade700 : Colors.grey,
                      width: 1,
                    ),
                  ),
                  focusedBorder: const UnderlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(12)),
                    borderSide: BorderSide(color: Colors.red, width: 2),
                  ),
                  disabledBorder: UnderlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: isDark ? Colors.grey.shade800 : Colors.white,
                      width: 1,
                    ),
                  ),
                  prefixIcon: const Icon(Icons.directions_transit),
                  filled: true,
                  fillColor: _isEditMode
                      ? (isDark ? Theme.of(context).cardColor : Colors.white)
                      : sectionBg.withOpacity(0.12),
                ),
              ),
            ],
          ),
        ),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      readOnly: readOnly,
      decoration: InputDecoration(
        labelText: isRequired ? '$label *' : label,
        prefixIcon: Icon(icon),
        filled: true,
        fillColor: readOnly
            ? (isDark
                  ? Theme.of(context).disabledColor.withOpacity(0.1)
                  : Colors.grey.shade100)
            : (isDark ? Theme.of(context).cardColor : Colors.white),

        // 👇 aquí cambiamos a underline y personalizamos bordes
        border: const UnderlineInputBorder(),
        enabledBorder: UnderlineInputBorder(
          borderSide: BorderSide(
            color: isDark ? Colors.grey.shade700 : Colors.grey.shade400,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        focusedBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: Colors.red, width: 1),
        ),
        disabledBorder: UnderlineInputBorder(
          borderSide: BorderSide(
            color: isDark ? Colors.grey.shade800 : Colors.grey.shade300,
          ),
        ),
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

  /// Construir un campo de fecha con DatePicker
  Widget _buildDateField(
    TextEditingController controller,
    String label,
    IconData icon, {
    bool isRequired = false,
    bool readOnly = false,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return TextFormField(
      controller: controller,
      readOnly: true,
      onTap: _isEditMode && !readOnly
          ? () async {
              final pickedDate = await showDatePicker(
                context: context,
                initialDate: _parseDate(controller.text) ?? DateTime.now(),
                firstDate: DateTime(2020),
                lastDate: DateTime(2050),
              );

              if (pickedDate != null) {
                setState(() {
                  controller.text =
                      '${pickedDate.day.toString().padLeft(2, '0')}/${pickedDate.month.toString().padLeft(2, '0')}/${pickedDate.year}';
                  _validateForm();
                });
              }
            }
          : null,
      decoration: InputDecoration(
        labelText: isRequired ? '$label *' : label,
        prefixIcon: Icon(icon),
        filled: true,
        fillColor: readOnly
            ? (isDark
                  ? Theme.of(context).disabledColor.withOpacity(0.1)
                  : Colors.grey.shade100)
            : (isDark ? Theme.of(context).cardColor : Colors.white),
        border: const UnderlineInputBorder(),
        enabledBorder: UnderlineInputBorder(
          borderSide: BorderSide(
            color: isDark ? Colors.grey.shade700 : Colors.grey.shade400,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        focusedBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: Colors.red, width: 1),
        ),
        disabledBorder: UnderlineInputBorder(
          borderSide: BorderSide(
            color: isDark ? Colors.grey.shade800 : Colors.grey.shade300,
          ),
        ),
      ),
      validator: isRequired
          ? (value) {
              if (value == null || value.trim().isEmpty) {
                return '$label es obligatorio';
              }
              return null;
            }
          : null,
    );
  }

  /// Parsear fecha desde string en formato DD/MM/YYYY
  DateTime? _parseDate(String dateString) {
    try {
      final parts = dateString.split('/');
      if (parts.length == 3) {
        final day = int.parse(parts[0]);
        final month = int.parse(parts[1]);
        final year = int.parse(parts[2]);
        return DateTime(year, month, day);
      }
    } catch (e) {
      debugPrint('Error parseando fecha: $e');
    }
    return null;
  }

  /// Construir dropdown para moneda
  Widget _buildMonedaDropdown() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return AbsorbPointer(
      absorbing: !_isEditMode,
      child: DropdownButtonFormField<String>(
        value: _selectedMoneda,
        decoration: InputDecoration(
          labelText: 'Moneda *',
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
            borderSide: const BorderSide(color: Colors.white, width: 1),
          ),
          prefixIcon: const Icon(Icons.monetization_on),
          filled: true,
          fillColor: _isEditMode
              ? (isDark ? Theme.of(context).cardColor : Colors.white)
              : (isDark ? Theme.of(context).cardColor : Colors.white),
        ),
        items: _monedas.map((moneda) {
          return DropdownMenuItem<String>(value: moneda, child: Text(moneda));
        }).toList(),
        onChanged: _isEditMode
            ? (value) {
                setState(() {
                  _selectedMoneda = value;
                  _monedaController.text = value ?? '';
                  _validateForm();
                });
              }
            : null,
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Moneda es obligatoria';
          }
          return null;
        },
      ),
    );
  }

  /// Construir los botones de acción
  Widget _buildActionButtons() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      /*  decoration: BoxDecoration(
        color: Colors.grey.shade50,
        border: Border(top: BorderSide(color: Colors.grey.shade300)),
      ), */
      child: Column(
        children: [
          // Mensaje de campos obligatorios
          if (_isEditMode && !_isFormValid)
            Container(
              padding: const EdgeInsets.all(2),
              margin: const EdgeInsets.only(bottom: 8),
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
                  Icon(Icons.warning, color: Colors.orange.shade800),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Text(
                      'Por favor complete los campos ',
                      style: TextStyle(
                        color: Colors.orange,
                        fontWeight: FontWeight.w700,
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
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.cancel),
                  label: const Text('Cancelar'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color.fromARGB(255, 244, 54, 54),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 6),
                  ),
                ),
              ),
              /*               const SizedBox(width: 4),
 */
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _isLoading || !_isFormValid
                      ? null
                      : _updateFacturaAPI,
                  icon: _isLoading
                      ? const SizedBox(
                          child: CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        )
                      : const Icon(Icons.save_rounded),
                  label: Text(
                    _isLoading
                        ? 'Actualizando...'
                        : _isFormValid
                        ? 'Actualizar Gasto'
                        : 'Editar Gasto',
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isFormValid
                        ? const Color.fromARGB(255, 19, 126, 32)
                        : Colors.grey,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: Colors.grey[300],
                    disabledForegroundColor: Colors.grey[600],
                    padding: const EdgeInsets.symmetric(vertical: 6),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
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
      resizeToAvoidBottomInset: true,
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
                borderColor: Colors.red,
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
