import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';
import '../models/dropdown_option.dart';
import '../services/api_service.dart';
import '../services/user_service.dart';
import '../services/company_service.dart';

class NuevoGastoMovilidadController extends ChangeNotifier {
  final DropdownOption politicaSeleccionada;

  NuevoGastoMovilidadController({required this.politicaSeleccionada});

  final ApiService _apiService = ApiService();
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();

  // Track whether dispose() was called to avoid calling notifyListeners afterwards
  bool _isDisposed = false;

  // Text controllers
  final TextEditingController proveedorController = TextEditingController();
  final TextEditingController fechaController = TextEditingController();
  final TextEditingController totalController = TextEditingController();
  final TextEditingController monedaController = TextEditingController(
    text: 'PEN',
  );
  final TextEditingController rucController = TextEditingController();
  final TextEditingController serieFacturaController = TextEditingController();
  final TextEditingController numeroFacturaController = TextEditingController();
  final TextEditingController tipoDocumentoController = TextEditingController();
  final TextEditingController numeroDocumentoController =
      TextEditingController();
  final TextEditingController notaController = TextEditingController();
  final TextEditingController rucClienteController = TextEditingController();

  // Movilidad
  final TextEditingController origenController = TextEditingController();
  final TextEditingController destinoController = TextEditingController();
  final TextEditingController motivoViajeController = TextEditingController();
  final TextEditingController tipoTransporteController = TextEditingController(
    text: 'Taxi',
  );

  // Estado
  bool _isLoading = false;
  bool _isLoadingCategorias = false;
  bool _isLoadingTiposGasto = false;
  bool _isScanning = false;
  bool _hasScannedData = false;

  // Data
  List<DropdownOption> categoriasMovilidad = [];
  List<DropdownOption> tiposGasto = [];

  // Selecciones
  DropdownOption? selectedCategoria;
  DropdownOption? selectedTipoGasto;

  // Archivo
  File? selectedImage;
  File? selectedFile;
  String? selectedFileType;
  String? selectedFileName;
  final ImagePicker _picker = ImagePicker();

  String? error;

  // Helper methods to update selections and scanning state from the UI
  void updateSelectedCategoria(DropdownOption? v) {
    selectedCategoria = v;
    _safeNotify();
  }

  void updateSelectedTipoGasto(DropdownOption? v) {
    selectedTipoGasto = v;
    _safeNotify();
  }

  void setScanning(bool v) {
    _isScanning = v;
    _safeNotify();
  }

  // Getters
  bool get isLoading => _isLoading;
  bool get isLoadingCategorias => _isLoadingCategorias;
  bool get isLoadingTiposGasto => _isLoadingTiposGasto;
  bool get isScanning => _isScanning;
  bool get hasScannedData => _hasScannedData;

  Future<void> initialize() async {
    // fecha inicial
    fechaController.text = DateTime.now().toLocal().toString().split(' ')[0];
    rucClienteController.text = CompanyService().currentCompany?.ruc ?? '';
    tipoTransporteController.text = 'Taxi';
    await loadCategorias();
    await loadTiposGasto();
    _safeNotify();
  }

  Future<void> loadCategorias() async {
    _isLoadingCategorias = true;
    error = null;
    _safeNotify();
    try {
      final categorias = await _apiService.getRendicionCategorias(
        politica: politicaSeleccionada.value,
      );
      categoriasMovilidad = categorias;
    } catch (e) {
      error = e.toString();
    } finally {
      _isLoadingCategorias = false;
      _safeNotify();
    }
  }

  Future<void> loadTiposGasto() async {
    _isLoadingTiposGasto = true;
    error = null;
    _safeNotify();
    try {
      final tipos = await _apiService.getTiposGasto();
      tiposGasto = tipos;
    } catch (e) {
      error = e.toString();
    } finally {
      _isLoadingTiposGasto = false;
      _safeNotify();
    }
  }

  /// Mostrar diálogo para elegir método de selección de archivo
  Future<void> pickFile(BuildContext context) async {
    final selectedOption = await showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
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
              onPressed: () => Navigator.pop(context, 'file'),
              icon: const Icon(Icons.attach_file),
              label: const Text('Archivo'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
          ],
        );
      },
    );

    if (selectedOption != null) {
      _isLoading = true;
      _safeNotify();
      try {
        if (selectedOption == 'camera') {
          final XFile? image = await _picker.pickImage(
            source: ImageSource.camera,
          );
          if (image != null) {
            selectedImage = File(image.path);
            selectedFile = null;
            selectedFileType = 'image';
            selectedFileName = image.name;
          }
        } else if (selectedOption == 'gallery') {
          final XFile? image = await _picker.pickImage(
            source: ImageSource.gallery,
          );
          if (image != null) {
            selectedImage = File(image.path);
            selectedFile = null;
            selectedFileType = 'image';
            selectedFileName = image.name;
          }
        } else if (selectedOption == 'file') {
          final result = await FilePicker.platform.pickFiles(
            type: FileType.custom,
            allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
          );
          if (result != null && result.files.single.path != null) {
            selectedFile = File(result.files.single.path!);
            selectedImage = null;
            selectedFileType = result.files.single.extension;
            selectedFileName = result.files.single.name;
          }
        }
      } finally {
        _isLoading = false;
        _safeNotify();
      }
    }
  }

  /// Procesar datos del QR y llenar campos
  void processQRData(String qrData) {
    _hasScannedData = true;
    final parts = qrData.split('|');
    if (parts.length >= 6) {
      if (parts[0].isNotEmpty) rucController.text = parts[0];
      if (parts[1].isNotEmpty) {
        String tipoDoc = parts[1];
        switch (tipoDoc) {
          case '01':
            tipoDocumentoController.text = 'Factura';
            break;
          case '03':
            tipoDocumentoController.text = 'Boleta';
            break;
          case '08':
            tipoDocumentoController.text = 'Nota de Débito';
            break;
          default:
            tipoDocumentoController.text = 'Otro';
        }
      }
      if (parts[2].isNotEmpty) serieFacturaController.text = parts[2];
      if (parts[3].isNotEmpty) numeroFacturaController.text = parts[3];
      if (parts[2].isNotEmpty && parts[3].isNotEmpty) {
        numeroDocumentoController.text = '${parts[2]}-${parts[3]}';
      }
      if (parts[5].isNotEmpty) totalController.text = parts[5];
      if (parts.length > 6 && parts[6].isNotEmpty) {
        fechaController.text = normalizarFecha(parts[6]);
      }
      _safeNotify();
    } else {
      _hasScannedData = false;
      _safeNotify();
      throw Exception('Formato de QR no válido');
    }
  }

  void clearScannedData() {
    _hasScannedData = false;
    rucController.clear();
    serieFacturaController.clear();
    numeroFacturaController.clear();
    tipoDocumentoController.clear();
    numeroDocumentoController.clear();
    totalController.clear();
    fechaController.text = DateTime.now().toLocal().toString().split(' ')[0];
    _safeNotify();
  }

  String normalizarFecha(String fechaOriginal) {
    try {
      String fechaLimpia = fechaOriginal.trim();
      final formatosPosibles = [
        'yyyy-MM-dd',
        'dd/MM/yyyy',
        'dd-MM-yyyy',
        'yyyy/MM/dd',
        'MM/dd/yyyy',
        'dd.MM.yyyy',
        'yyyyMMdd',
        'dd/MM/yy',
        'yyyy-M-d',
        'dd/M/yyyy',
        'd/MM/yyyy',
        'd/M/yyyy',
      ];
      DateTime? fechaParseada;
      for (String formato in formatosPosibles) {
        try {
          fechaParseada = DateFormat(formato).parseStrict(fechaLimpia);
          break;
        } catch (e) {
          continue;
        }
      }
      if (fechaParseada == null) {
        try {
          fechaParseada = DateTime.parse(fechaLimpia);
        } catch (e) {
          try {
            String soloNumeros = fechaLimpia.replaceAll(RegExp(r'[^0-9]'), '');
            if (soloNumeros.length == 8) {
              String year = soloNumeros.substring(0, 4);
              String month = soloNumeros.substring(4, 6);
              String day = soloNumeros.substring(6, 8);
              fechaParseada = DateTime.parse('$year-$month-$day');
            }
          } catch (_) {}
        }
      }
      if (fechaParseada != null) {
        final ahora = DateTime.now();
        final hace5Anos = ahora.subtract(const Duration(days: 365 * 5));
        final en1Ano = ahora.add(const Duration(days: 365));
        if (fechaParseada.isBefore(hace5Anos) ||
            fechaParseada.isAfter(en1Ano)) {
          return DateFormat('yyyy-MM-dd').format(ahora);
        }
        return DateFormat('yyyy-MM-dd').format(fechaParseada);
      }
      return DateFormat('yyyy-MM-dd').format(DateTime.now());
    } catch (e) {
      return DateFormat('yyyy-MM-dd').format(DateTime.now());
    }
  }

  String extractServerMessage(String errorString) {
    try {
      final regex = RegExp(r'\{.*"message".*?:.*?"([^\"]+)".*\}');
      final match = regex.firstMatch(errorString);
      if (match != null && match.group(1) != null) {
        return match.group(1)!;
      }
      if (errorString.length > 200)
        return errorString.substring(0, 200) + '...';
      return errorString;
    } catch (e) {
      return 'Error al procesar la respuesta del servidor';
    }
  }

  /// Guarda la rendición y la evidencia. Retorna el id generado o lanza excepción.
  Future<int?> save() async {
    if (!formKey.currentState!.validate()) {
      throw Exception('Formulario inválido');
    }

    _isLoading = true;
    _safeNotify();

    try {
      String fechaSQL = '';
      if (fechaController.text.isNotEmpty) {
        try {
          final fecha = DateTime.parse(fechaController.text);
          fechaSQL =
              "${fecha.year}-${fecha.month.toString().padLeft(2, '0')}-${fecha.day.toString().padLeft(2, '0')}";
        } catch (e) {
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
        "politica": politicaSeleccionada.value.length > 80
            ? politicaSeleccionada.value.substring(0, 80)
            : politicaSeleccionada.value,
        "categoria": (() {
          // Preferir la categoría seleccionada por el usuario si existe
          if (selectedCategoria != null &&
              selectedCategoria!.value.isNotEmpty) {
            return selectedCategoria!.value.length > 80
                ? selectedCategoria!.value.substring(0, 80)
                : selectedCategoria!.value;
          }

          // Si no hay selección, intentar usar una categoría disponible desde la API
          if (categoriasMovilidad.isNotEmpty) {
            // Si la política es de movilidad, preferir categorías obvias
            if (politicaSeleccionada.value.toLowerCase().contains(
              'movilidad',
            )) {
              final preferida = categoriasMovilidad.firstWhere((c) {
                final v = c.value.toLowerCase();
                return v.contains('moviliz') || v.contains('viaj');
              }, orElse: () => categoriasMovilidad.first);
              return preferida.value.length > 80
                  ? preferida.value.substring(0, 80)
                  : preferida.value;
            }

            // Para otras políticas, usar la primera categoría disponible
            final primera = categoriasMovilidad.first;
            return primera.value.length > 80
                ? primera.value.substring(0, 80)
                : primera.value;
          }

          // Último recurso: valores por defecto historic/compatible
          return politicaSeleccionada.value.toLowerCase().contains('movilidad')
              ? 'MOVILIZACION'
              : 'MOVILIDAD';
        })(),
        "tipoGasto":
            selectedTipoGasto?.value == null || selectedTipoGasto!.value.isEmpty
            ? "GASTO DE MOVILIDAD"
            : (selectedTipoGasto!.value.length > 80
                  ? selectedTipoGasto!.value.substring(0, 80)
                  : selectedTipoGasto!.value),
        "ruc": rucController.text.isEmpty
            ? ""
            : (rucController.text.length > 80
                  ? rucController.text.substring(0, 80)
                  : rucController.text),
        "proveedor": proveedorController.text.isEmpty
            ? "PROVEEDOR DE EJEMPLO"
            : (proveedorController.text.length > 80
                  ? proveedorController.text.substring(0, 80)
                  : proveedorController.text),
        "tipoCombrobante": tipoDocumentoController.text.isEmpty
            ? ""
            : (tipoDocumentoController.text.length > 180
                  ? tipoDocumentoController.text.substring(0, 180)
                  : tipoDocumentoController.text),
        "serie": serieFacturaController.text.isEmpty
            ? ""
            : (serieFacturaController.text.length > 80
                  ? serieFacturaController.text.substring(0, 80)
                  : serieFacturaController.text),
        "numero": numeroFacturaController.text.isEmpty
            ? ""
            : (numeroFacturaController.text.length > 80
                  ? numeroFacturaController.text.substring(0, 80)
                  : numeroFacturaController.text),
        "igv": 0.0,
        "fecha": fechaSQL,
        "total": double.tryParse(totalController.text) ?? 0.0,
        "moneda": monedaController.text.isEmpty
            ? "PEN"
            : (monedaController.text.length > 80
                  ? monedaController.text.substring(0, 80)
                  : monedaController.text),
        "rucCliente": rucClienteController.text.isNotEmpty
            ? rucClienteController.text
            : (CompanyService().currentCompany?.ruc ?? ''),
        "desEmp": CompanyService().currentCompany?.empresa ?? '',
        "desSed": "",
        "idCuenta": "",
        "consumidor": "",
        "regimen": "",
        "destino": "BORRADOR",
        "glosa": notaController.text.length > 480
            ? notaController.text.substring(0, 480)
            : notaController.text,
        "motivoViaje": motivoViajeController.text.length > 50
            ? motivoViajeController.text.substring(0, 50)
            : motivoViajeController.text,
        "lugarOrigen": origenController.text.length > 50
            ? origenController.text.substring(0, 50)
            : origenController.text,
        "lugarDestino": destinoController.text.length > 50
            ? destinoController.text.substring(0, 50)
            : destinoController.text,
        "tipoMovilidad": tipoTransporteController.text.length > 50
            ? tipoTransporteController.text.substring(0, 50)
            : tipoTransporteController.text,
        "obs": notaController.text.length > 1000
            ? notaController.text.substring(0, 1000)
            : notaController.text,
        "estado": "S",
        "fecCre": DateTime.now().toIso8601String(),
        "useReg": UserService().currentUserCode,
        "hostname": "FLUTTER",
        "fecEdit": DateTime.now().toIso8601String(),
        "useEdit": 0,
        "useElim": 0,
      };

      final idRend = await _apiService.saveRendicionGasto(body);
      if (idRend == null)
        throw Exception(
          'No se pudo guardar la factura principal o no se obtuvo el ID autogenerado',
        );

      final facturaDataEvidencia = {
        "idRend": idRend,
        "evidencia": selectedFile != null
            ? base64Encode(selectedFile!.readAsBytesSync())
            : (selectedImage != null
                  ? base64Encode(selectedImage!.readAsBytesSync())
                  : ""),
        "obs": notaController.text.length > 1000
            ? notaController.text.substring(0, 1000)
            : notaController.text,
        "estado": "S",
        "fecCre": DateTime.now().toIso8601String(),
        "useReg": UserService().currentUserCode,
        "hostname": "FLUTTER",
        "fecEdit": DateTime.now().toIso8601String(),
        "useEdit": 0,
        "useElim": 0,
      };

      final successEvidencia = await _apiService.saveRendicionGastoEvidencia(
        facturaDataEvidencia,
      );
      if (!successEvidencia) throw Exception('No se pudo guardar evidencia');

      return idRend;
    } catch (e) {
      rethrow;
    } finally {
      _isLoading = false;
      _safeNotify();
    }
  }

  @override
  void dispose() {
    proveedorController.dispose();
    fechaController.dispose();
    totalController.dispose();
    monedaController.dispose();
    rucController.dispose();
    serieFacturaController.dispose();
    numeroFacturaController.dispose();
    tipoDocumentoController.dispose();
    numeroDocumentoController.dispose();
    notaController.dispose();
    rucClienteController.dispose();
    origenController.dispose();
    destinoController.dispose();
    motivoViajeController.dispose();
    tipoTransporteController.dispose();
    _apiService.dispose();
    _isDisposed = true;
    super.dispose();
  }

  // Safe notify to avoid calling notifyListeners after dispose
  void _safeNotify() {
    if (!_isDisposed) {
      try {
        notifyListeners();
      } catch (_) {
        // Ignore any errors during notify
      }
    }
  }
}
