import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:printing/printing.dart';
import 'package:file_picker/file_picker.dart';
import '../models/reporte_model.dart';
import '../models/categoria_model.dart';
import '../models/dropdown_option.dart';
import '../services/api_service.dart';
import '../services/company_service.dart';
import '../controllers/edit_reporte_controller.dart';
import '../screens/home_screen.dart';
import 'package:path/path.dart' as p;
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';

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
  late TextEditingController _proveedorController;
  late TextEditingController _tipoComprobanteController;
  late TextEditingController _serieController;
  late TextEditingController _numeroController;
  late TextEditingController _fechaController;
  late TextEditingController _totalController;
  late TextEditingController _monedaController;
  late TextEditingController _rucClienteController;
  late TextEditingController _glosaController;
  late TextEditingController _obsController;
  // Campos de movilidad
  late TextEditingController _origenController;
  late TextEditingController _destinoController;
  late TextEditingController _motivoViajeController;
  late TextEditingController _tipoMovilidadController;

  // Campos adicionales usados en el formulario
  late TextEditingController _igvController;
  late TextEditingController _fechaEmisionController;
  late TextEditingController _notaController;

  // Estado
  bool _isLoading = false;
  bool _isEditMode = false;
  bool _isFormValid = false;

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  // Servicios y controlador
  final ApiService _apiService = ApiService();
  late final EditReporteController _controller;

  // Image / file picker
  final ImagePicker _picker = ImagePicker();
  File? _selectedImage;
  String? _apiEvidencia;

  List<CategoriaModel> _categoriasGeneral = [];
  List<DropdownOption> _tiposGasto = [];
  bool _isLoadingCategorias = false;
  bool _isLoadingTiposGasto = false;
  String? _errorCategorias;
  String? _errorTiposGasto;

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
    // Añadir listeners para validar formulario en tiempo real
    _addValidationListeners();
    // Intentar cargar la evidencia que ya exista en el servidor para este reporte
    // de modo que el campo de 'Agregar evidencia' muestre la imagen/PDF si existe.
    _cargarImagenServidor();
  }

  /// Determina si el reporte está en estado 'EN INFORME'.
  /// Como `Reporte` no tiene un campo `estado`, comprobamos varios campos
  /// que en el proyecto se usan en distintos contextos para representar el estado.
  bool _isEnInforme() {
    final candidates = [
      widget.reporte.categoria,
      widget.reporte.destino,
      widget.reporte.tipogasto,
      widget.reporte.obs,
      widget.reporte.glosa,
    ];
    for (final v in candidates) {
      if (v != null) {
        final value = v.trim().toUpperCase();
        if (value.contains('EN INFORME') ||
            value == 'EN AUDITORIA' ||
            value == 'EN REVISION' ||
            value == 'APROBADO' ||
            value == 'DESAPROBADO' ) {
          return true;
        }
      }
    }
    return false;

    return false;
  }

  // (El helper de error de imagen fue removido; la UI muestra placeholders simples)

  /// Agregar listeners para validación en tiempo real
  void _addValidationListeners() {
    _rucController.addListener(_validateForm);
    _rucClienteController.addListener(_validateForm);
    _tipoComprobanteController.addListener(_validateForm);
    _serieController.addListener(_validateForm);
    _numeroController.addListener(_validateForm);
    _fechaEmisionController.addListener(_validateForm);
    _totalController.addListener(_validateForm);
    _categoriaController.addListener(_validateForm);
    _tipoGastoController.addListener(_validateForm);
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
      return '';
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
        (_selectedImage != null ||
            (_apiEvidencia != null && _apiEvidencia!.isNotEmpty)) &&
        _isRucValid();

    if (_isFormValid != isValid) {
      setState(() {
        _isFormValid = isValid;
      });
    }
  }

  void _initializeSelectedValues() {
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

  void _initializeControllers() {
    _politicaController = TextEditingController(
      text: widget.reporte.politica ?? '',
    );
    _categoriaController = TextEditingController(
      text: widget.reporte.categoria ?? '',
    );
    _tipoGastoController = TextEditingController(
      text: widget.reporte.tipogasto ?? '',
    );
    _rucController = TextEditingController(text: widget.reporte.ruc ?? '');
    _proveedorController = TextEditingController(
      text: widget.reporte.proveedor ?? '',
    );
    _tipoComprobanteController = TextEditingController(
      text: widget.reporte.tipocomprobante ?? '',
    );
    _serieController = TextEditingController(text: widget.reporte.serie ?? '');
    _numeroController = TextEditingController(
      text: widget.reporte.numero ?? '',
    );
    _fechaController = TextEditingController(text: widget.reporte.fecha ?? '');
    _totalController = TextEditingController(
      text: widget.reporte.total?.toString() ?? '',
    );
    _monedaController = TextEditingController(
      text: widget.reporte.moneda ?? 'PEN',
    );
    _rucClienteController = TextEditingController(
      text: widget.reporte.ruccliente ?? '',
    );
    _glosaController = TextEditingController(text: widget.reporte.glosa ?? '');
    _obsController = TextEditingController(text: widget.reporte.obs ?? '');

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

    // Nuevos controladores
    _igvController = TextEditingController(
      text: widget.reporte.igv?.toString() ?? '',
    );
    // Mostrar fecha de emisión en formato ISO (yyyy-MM-dd) cuando sea posible
    final formattedFecha = _formatToIsoDate(widget.reporte.fecha);
    _fechaEmisionController = TextEditingController(text: formattedFecha);
    _notaController = TextEditingController(text: widget.reporte.obs ?? '');
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
    _rucController.dispose();
    _proveedorController.dispose();
    _tipoComprobanteController.dispose();
    _serieController.dispose();
    _numeroController.dispose();
    _fechaController.dispose();
    _totalController.dispose();
    _monedaController.dispose();
    _rucClienteController.dispose();
    _glosaController.dispose();
    _obsController.dispose();
    _igvController.dispose();
    _fechaEmisionController.dispose();
    _notaController.dispose();
    _origenController.dispose();
    _destinoController.dispose();
    _motivoViajeController.dispose();
    _tipoMovilidadController.dispose();

    _controller.dispose();
    super.dispose();
  }

  // Nota: conversión a base64 está en el controller (`_controller.convertImageToBase64`).

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
                const SizedBox(height: 12),
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

  /// Intentar convertir varias representaciones de fecha a formato ISO (yyyy-MM-dd)
  String _formatToIsoDate(String? input) {
    if (input == null) return '';
    final trimmed = input.trim();
    if (trimmed.isEmpty) return '';

    try {
      // Si ya está en formato ISO aproximado (yyyy-MM-dd o yyyy/MM/dd), normalizar
      final isoLike = RegExp(r'^(\d{4})[-/](\d{1,2})[-/](\d{1,2})');
      final match = isoLike.firstMatch(trimmed);
      if (match != null) {
        final y = match.group(1)!;
        final m = match.group(2)!.padLeft(2, '0');
        final d = match.group(3)!.padLeft(2, '0');
        return '$y-$m-$d';
      }

      // Intentar formatos comunes: dd/MM/yyyy, dd-MM-yyyy
      final dmy = RegExp(r'^(\d{1,2})[\/-](\d{1,2})[\/-](\d{4})');
      final matchDmy = dmy.firstMatch(trimmed);
      if (matchDmy != null) {
        final d = matchDmy.group(1)!.padLeft(2, '0');
        final m = matchDmy.group(2)!.padLeft(2, '0');
        final y = matchDmy.group(3)!;
        return '$y-$m-$d';
      }

      // Intentar parsear con DateTime.parse como último recurso
      final dt = DateTime.tryParse(trimmed);
      if (dt != null) {
        final y = dt.year.toString().padLeft(4, '0');
        final m = dt.month.toString().padLeft(2, '0');
        final d = dt.day.toString().padLeft(2, '0');
        return '$y-$m-$d';
      }
    } catch (_) {
      // ignore
    }

    // Si no se pudo parsear, devolver el original tal cual (o vacío si no se desea)
    return trimmed;
  }

  /// Verificar si un archivo es PDF basado en su extensión
  bool _isPdfFile(String filePath) {
    return filePath.toLowerCase().endsWith('.pdf');
  }

  /// Construir la sección de imagen/evidencia
  Widget _buildImageSection() {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Card(
        elevation: 2,
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.receipt, color: Colors.red),
                  const SizedBox(width: 8),
                  const Text(
                    'Adjuntar Factura',
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
                        (_selectedImage == null &&
                                (_apiEvidencia == null ||
                                    _apiEvidencia!.isEmpty))
                            ? Icons.add_a_photo
                            : Icons.edit,
                      ),
                      label: Text(
                        (_selectedImage == null &&
                                (_apiEvidencia == null ||
                                    _apiEvidencia!.isEmpty))
                            ? 'Seleccionar'
                            : 'Cambiar ',
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _isEditMode ? Colors.red : Colors.grey,
                        foregroundColor: Colors.white,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              // Mostrar archivo: puede ser imagen o PDF
              if (_selectedImage != null)
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
                      child: _isPdfFile(_selectedImage!.path)
                          ? Container(
                              color: Colors.grey.shade100,
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
                                      color: Colors.grey,
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
              else if (_apiEvidencia != null && _apiEvidencia!.isNotEmpty)
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
                      child: _buildEvidenciaImage(_apiEvidencia!),
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
                          (_selectedImage == null &&
                              (_apiEvidencia == null || _apiEvidencia!.isEmpty))
                          ? Colors.red.shade300
                          : Colors.grey.shade300,
                      width:
                          (_selectedImage == null &&
                              (_apiEvidencia == null || _apiEvidencia!.isEmpty))
                          ? 2
                          : 1,
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.receipt_outlined,
                        color:
                            (_selectedImage == null &&
                                (_apiEvidencia == null ||
                                    _apiEvidencia!.isEmpty))
                            ? Colors.red
                            : Colors.grey,
                        size: 40,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Agregar evidencia (Obligatorio)',
                        style: TextStyle(
                          color:
                              (_selectedImage == null &&
                                  (_apiEvidencia == null ||
                                      _apiEvidencia!.isEmpty))
                              ? Colors.red
                              : Colors.grey,
                          fontWeight:
                              (_selectedImage == null &&
                                  (_apiEvidencia == null ||
                                      _apiEvidencia!.isEmpty))
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
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
    // Determinar las categorías disponibles según la política
    List<DropdownMenuItem<String>> items = [];
    // Valor seleccionado calculado de forma robusta (se determina más abajo)
    String? selectedValue;
    final savedCategoriaGlobal = _categoriaController.text.trim();
    String normalizeGlobal(String s) => s.trim().toLowerCase();

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

    return AbsorbPointer(
      absorbing: !_isEditMode,
      child: DropdownButtonFormField<String>(
        decoration: InputDecoration(
          labelText: 'Categoría *',
          prefixIcon: Icon(Icons.category),
          border: OutlineInputBorder(),
          filled: true,
          fillColor: _isEditMode ? Colors.white : Colors.grey[100],
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
          if (value != null) {
            setState(() {
              _categoriaController.text = value;
            });
            _validateForm(); // Validar cuando cambie la categoría
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
          AbsorbPointer(
            absorbing: !_isEditMode,
            child: DropdownButtonFormField<String>(
              decoration: InputDecoration(
                labelText: 'Tipo de Gasto *',
                prefixIcon: Icon(Icons.abc),
                border: OutlineInputBorder(),
                filled: true,
                fillColor: _isEditMode ? Colors.white : Colors.grey[100],
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
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _tipoGastoController.text = value;
                  });
                  _validateForm(); // Validar cuando cambie el tipo de gasto
                }
              },
            ),
          ),
      ],
    );
  }

  /// Construir la sección de datos raw
  /* Widget _buildRawDataSection() {
    return ExpansionTile(
      title: const Text('Datos Originales del Reporte'),
      leading: const Icon(Icons.receipt_long),
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(8),
          ),
          child: SelectableText(
            'ID: ${widget.reporte.idrend}\n'
            'Política: ${widget.reporte.politica}\n'
            'Categoría: ${widget.reporte.categoria}\n'
            'RUC: ${widget.reporte.ruc}\n'
            'Proveedor: ${widget.reporte.proveedor}\n'
            'Serie: ${widget.reporte.serie}\n'
            'Número: ${widget.reporte.numero}\n'
            'Total: ${widget.reporte.total}\n'
            'Fecha: ${widget.reporte.fecha}\n'
            'Estado: ${widget.reporte.categoria}',
            style: const TextStyle(fontFamily: 'monospace', fontSize: 10),
          ),
        ),
      ],
    );
  } */

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

  /// Mostrar un diálogo con los bytes de la imagen
  Future<void> _showEvidenciaDialogFromBytes(Uint8List bytes) async {
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
            child: Image.memory(bytes, fit: BoxFit.contain),
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
      if (_apiEvidencia != null && _apiEvidencia!.isNotEmpty) {
        final evidencia = _apiEvidencia!;

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

  /// Guardar factura mediante API
  Future<void> _updateFacturaAPI() async {
    // Validar campos obligatorios antes de continuar
    if (!_isFormValid) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('❌ Por favor complete todos los campos obligatorios'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final success = await _controller.saveReporte(
        reporte: widget.reporte,
        politica: _politicaController.text,
        categoria: _categoriaController.text,
        tipoGasto: _tipoGastoController.text,
        ruc: _rucController.text,
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
        selectedImage: _selectedImage,
        apiEvidencia: _apiEvidencia,
      );

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ FACTURA ACTUALIZADA'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );

        if (widget.onSave != null) widget.onSave!(widget.reporte);

        // Cerrar modal
        Navigator.of(context).pop();

        // Cerrar pantalla QR si existe y navegar a HomeScreen para forzar refresco
        try {
          Navigator.of(context).pop();
        } catch (_) {}

        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const HomeScreen()),
          (route) => false,
        );
      }
    } catch (e) {
      final serverMessage = _extractServerMessage(e.toString());
      _showServerAlert(serverMessage);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // Removed unused success snackbar helper; success feedback is shown inline after save.

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.9,
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
                padding: const EdgeInsets.all(15),
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
                    _buildInvoiceDataSection(),
                    const SizedBox(height: 10),
                    _buildNotesSection(),
                    const SizedBox(height: 10),
                    // Sección Movilidad (solo visible para políticas de movilidad)
                    _buildMovilidadSection(),
                    const SizedBox(height: 10),
                    /*                     _buildRawDataSection(),
 */
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

  /// Construir el header del modal
  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.red.shade700, Colors.red.shade400],
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
                  'Editar Reporte',
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
          // Botón editar (solo icono) - ocultar si el reporte está en 'EN INFORME'
          if (!_isEditMode && !_isEnInforme())
            IconButton(
              onPressed: () {
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
          decoration: const InputDecoration(
            labelText: 'Política Seleccionada',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.policy),
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
          Icons.confirmation_number,
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
          Icons.calendar_today,
          TextInputType.datetime,
          isRequired: true,
          readOnly: true,
        ),
        const SizedBox(height: 16),

        // Cuarta fila: Total y Moneda
        _buildTextField(
          _totalController,
          'Total ',
          Icons.money_rounded,
          TextInputType.numberWithOptions(decimal: true),
          isRequired: true,
          readOnly: true,
        ),
        const SizedBox(height: 16),
        _buildTextField(
          _monedaController,
          'Moneda *',
          Icons.house,
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
    return _buildTextField(
      _notaController,
      'Nota',
      Icons.comment,
      TextInputType.text,
    );
  }

  /// Construir la sección específica de Movilidad (origen, destino, motivo, tipo transporte)
  Widget _buildMovilidadSection() {
    final politica = _politicaController.text.toLowerCase();
    if (!politica.contains('movilidad')) return const SizedBox.shrink();
    // Fondo y estilos para la sección de Movilidad
    final Color sectionBg = Colors.white; // color de fondo de la sección

    return Card(
      color: sectionBg,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
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
                        color: sectionBg.withOpacity(0.25),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: const Text(
                        'Solo lectura',
                        style: TextStyle(fontSize: 12, color: Colors.black54),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _origenController,
                readOnly: !_isEditMode,
                decoration: InputDecoration(
                  labelText: 'Lugar Origen',
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.place),
                  filled: true,
                  fillColor: _isEditMode
                      ? Colors.white
                      : sectionBg.withOpacity(0.12),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _destinoController,
                readOnly: !_isEditMode,
                decoration: InputDecoration(
                  labelText: 'Lugar Destino',
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.flag),
                  filled: true,
                  fillColor: _isEditMode
                      ? Colors.white
                      : sectionBg.withOpacity(0.12),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _motivoViajeController,
                readOnly: !_isEditMode,
                decoration: InputDecoration(
                  labelText: 'Motivo de Viaje',
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.event_note),
                  filled: true,
                  fillColor: _isEditMode
                      ? Colors.white
                      : sectionBg.withOpacity(0.12),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _tipoMovilidadController,
                readOnly: !_isEditMode,
                decoration: InputDecoration(
                  labelText: 'Tipo Transporte',
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.directions_transit),
                  filled: true,
                  fillColor: _isEditMode
                      ? Colors.white
                      : sectionBg.withOpacity(0.12),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  /* 
  /// Construir un campo de texto personalizado
  Widget _buildTextField(
    TextEditingController controller,
    String label,
    IconData icon,
    TextInputType keyboardType, {
    bool isRequired = false,
    bool readOnly = false,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      readOnly: readOnly,
      decoration: InputDecoration(
        labelText: isRequired ? '$label *' : label,
        prefixIcon: Icon(icon),
        border: const UnderlineInputBorder(),
        filled: true,
        fillColor: readOnly ? Colors.grey.shade100 : Colors.grey.shade50,
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
 */

  /// Construir un campo de texto personalizado
  Widget _buildTextField(
    TextEditingController controller,
    String label,
    IconData icon,
    TextInputType keyboardType, {
    bool isRequired = false,
    bool readOnly = false,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      readOnly: readOnly,
      decoration: InputDecoration(
        labelText: isRequired ? '$label *' : label,
        prefixIcon: Icon(icon),
        filled: true,
        fillColor: readOnly ? Colors.white : Colors.white,

        // 👇 aquí cambiamos a underline y personalizamos bordes
        border: const UnderlineInputBorder(),
        enabledBorder: UnderlineInputBorder(
          borderSide: BorderSide(color: Colors.grey.shade400), // color normal
          borderRadius: BorderRadius.circular(16),
        ),
        focusedBorder: const UnderlineInputBorder(
          /* borderSide: BorderSide(
            color: Colors.orange,
            width: 2,
          ), */
          // color al enfocar
        ),
        disabledBorder: UnderlineInputBorder(
          borderSide: BorderSide(
            color: Colors.white,
          ), // color cuando es readOnly
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

  /// Construir los botones de acción
  Widget _buildActionButtons() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 50),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        border: Border(top: BorderSide(color: Colors.grey.shade300)),
      ),
      child: Column(
        children: [
          // Mensaje de campos obligatorios
          if (!_isFormValid)
            Container(
              padding: const EdgeInsets.all(6),
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.warning, color: Colors.orange.shade600),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Text(
                      'Por favor complete todos los campos ',
                      style: TextStyle(
                        color: Colors.orange,
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
              const SizedBox(width: 4),
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
                        ? 'Guardando...'
                        : _isFormValid
                        ? 'Guardar Reporte'
                        : 'Completar ',
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
