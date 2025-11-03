import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flu2/controllers/edit_reporte_controller.dart';
import 'package:flu2/services/api_service.dart';
import 'package:flu2/services/company_service.dart';
import 'package:flu2/services/user_service.dart';
import 'package:flu2/utils/navigation_utils.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:open_filex/open_filex.dart';
import '../models/reporte_model.dart'; // Modelo de Reporte
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:flutter/scheduler.dart';
import 'package:share_plus/share_plus.dart';

class DetalleModalGasto extends StatefulWidget {
  final String id;

  const DetalleModalGasto({required this.id});

  @override
  _DetalleModalGastoState createState() => _DetalleModalGastoState();
}

class _DetalleModalGastoState extends State<DetalleModalGasto> {
  // Estado
  bool _isLoading = false;
  bool _isEditMode = false;
  bool _isFormValid = false;

  final ApiService _apiService = ApiService();
  Reporte? _reporte;

  // Image / file picker
  final ImagePicker _picker = ImagePicker();
  File? _selectedImage;
  String? _apiEvidencia;
  late final EditReporteController _controller;

  @override
  void initState() {
    super.initState();
    _controller = EditReporteController(apiService: _apiService);
    _loadReporte();
  }

  Future<void> _loadReporte() async {
    setState(() {
      _isLoading = true;
    });

    try {
      debugPrint('📡 Solicitando reporte desde API para id: ${widget.id}');

      final reporte = await _apiService.getReportesRendicionGasto(
        id: '2', // Ajusta según tu API
        idrend: widget.id,
        user: UserService().currentUserCode,
        ruc: CompanyService().companyRuc,
      );

      if (!mounted) return;

      setState(() {
        _reporte = reporte.isNotEmpty ? reporte[0] : null;
        _isLoading = false;
      });

      if (_reporte != null) {
        debugPrint('✅ Reporte cargado correctamente: ${_reporte!.idrend}');
        // 🔹 Ahora que tenemos reporte, cargamos la evidencia
        _cargarImagenServidor();
      } else {
        debugPrint('⚠️ No se encontró reporte con id ${widget.id}');
        SchedulerBinding.instance.addPostFrameCallback((_) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No se encontró el reporte solicitado.'),
            ),
          );
        });
      }
    } catch (e) {
      debugPrint('🔥 Error al cargar reporte: $e');

      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      SchedulerBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cargar reporte: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      });
    }
  }

  Future<void> _cargarImagenServidor() async {
    debugPrint('🔄 Iniciando carga de evidencia desde servidor...');

    try {
      if (!mounted) return;

      final baseName =
          '${_reporte!.idrend}_${_reporte!.ruc}_${_reporte!.serie}_${_reporte!.numero}';
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

      // Construir lista de extensiones candidatas
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
        } catch (_) {
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

      // ⚠️ Si no se encontró la imagen
      debugPrint(
        '⚠️ No se encontró la evidencia en el servidor (probadas: ${candidates.join(', ')})',
      );
      if (mounted) {
        SchedulerBinding.instance.addPostFrameCallback((_) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No se encontró la evidencia en el servidor'),
            ),
          );
        });
      }
    } catch (e) {
      debugPrint('🔥 Error cargando imagen del servidor: $e');
      if (mounted) {
        SchedulerBinding.instance.addPostFrameCallback((_) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error cargando evidencia: ${e.toString()}'),
            ),
          );
        });
      }
    }
  }

  /// Verificar si un archivo es PDF basado en su extensión
  bool _isPdfFile(String filePath) {
    return filePath.toLowerCase().endsWith('.pdf');
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
    // Supongamos que tienes estos valores
    final ruc = _reporte!.ruc;
    final serie = _reporte!.serie;
    final numero = _reporte!.numero;

    // Concatenar para formar el nombre del archivo
    final nombreArchivo = '${ruc}_${serie}_${numero}.png';

    // Si no se pasa un nombre, usar un default
    final fileName = nombreArchivo;
    // Guardar temporalmente los bytes en un archivo para compartir
    final tempDir = await getTemporaryDirectory();
    final tempFile = File('${tempDir.path}/$fileName');
    await tempFile.writeAsBytes(bytes);

    showDialog(
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

  Future<void> _handleTapEvidencia() async {
    try {
      String nombreArchivo =
          '${_reporte?.ruc}_${_reporte?.serie}_${_reporte?.numero}';

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

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.only(top: 100), // Solo margen superior
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(20)),
      ),
      child: SizedBox(
        width: double.maxFinite,
        height: double
            .maxFinite, // Usa toda la altura disponible desde el margen superior
        child: Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 0.5,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.green),
              onPressed: () => Navigator.of(context).pop(),
            ),
            title: Column(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Text(
                  'DETALLE DEL GASTO',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
            centerTitle: true,
            actions: [
              IconButton(
                icon: const Icon(Icons.close, color: Colors.red),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _reporte != null
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeaderSection(),
                      const SizedBox(height: 16),
                      _buildImageSection(),
                      const SizedBox(height: 16),
                      _buildGeneralDataSection(),
                      const SizedBox(height: 16),
                      //_buildStatusSection(),
                      //const SizedBox(height: 16),
                      _buildAmountSection(),
                      const SizedBox(height: 16),
                      _buildFacturaDataSection(),
                      const SizedBox(height: 8),
                      if (_reporte!.politica?.toUpperCase() ==
                          'GASTOS DE MOVILIDAD')
                        _buildMovilidadSection(),
                      const SizedBox(height: 8),
                      _buildFacturaNotaSection(),
                    ],
                  )
                : const Center(child: Text('No se encontraron datos.')),
          ),
        ),
      ),
    );
  }

  // Sección de encabezado con ID y fecha del gasto
  Widget _buildHeaderSection() {
    if (_reporte == null) return Container();

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue[800],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Gasto ID: #${_reporte!.idrend}', // Usamos el id de reporte
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Fecha: ${formatDate(_reporte!.fecha)}',
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${_reporte!.estadoActual}', // Usamos el id de reporte
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Construir la sección de imagen/evidencia
  Widget _buildImageSection() {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Card(
        color: Colors.white,
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
                    'Evidencia',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const Spacer(),
                  if (_isLoading)
                    const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                ],
              ),
              // Mostrar archivo: puede ser imagen o PDF
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
              else if (_apiEvidencia != null && _apiEvidencia!.isNotEmpty)
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
                        'Sin evidencia',
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

  // Sección de datos generales del gasto
  Widget _buildGeneralDataSection() {
    if (_reporte == null) return Container();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Datos Generales del Gasto',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        _buildReadOnlyField('Politica', _reporte!.politica ?? 'N/A'),
        _buildReadOnlyField('Tipo Gasto', _reporte!.tipogasto ?? 'N/A'),
        _buildReadOnlyField('Categoria', _reporte!.categoria ?? 'N/A'),
        _buildReadOnlyField('Razon Social', _reporte!.proveedor ?? 'N/A'),
        _buildReadOnlyField('RUC Emisor', _reporte!.ruc ?? 'N/A'),
        _buildReadOnlyField('RUC Cliente', _reporte?.ruccliente ?? 'N/A'),
      ],
    );
  }

  // Sección del monto del gasto
  Widget _buildAmountSection() {
    if (_reporte == null) return Container();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Monto del Gasto',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        _buildReadOnlyField('Total', '${_reporte!.total} ${_reporte!.moneda}'),
        _buildReadOnlyField(
          'IGV',
          '${_reporte!.igv ?? 'N/A'} ${_reporte!.moneda}',
        ),
      ],
    );
  }

  // Sección de estado del gasto
  Widget _buildStatusSection() {
    if (_reporte == null) return Container();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Estado del Gasto',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        _buildReadOnlyField('Estado', _reporte!.estadoActual ?? 'Sin estado'),
      ],
    );
  }

  // Sección de Datos de la Factura
  Widget _buildFacturaDataSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Datos de la Factura',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        _buildReadOnlyField(
          'Tipo Comprobante',
          _reporte?.tipocomprobante ?? 'N/A',
        ),
        _buildReadOnlyField(
          'Fecha Emisión',
          formatDate(_reporte?.fecha) ?? 'N/A',
        ),
        _buildReadOnlyField('Serie', _reporte?.serie ?? 'N/A'),
        _buildReadOnlyField('Número', _reporte?.numero ?? 'N/A'),
        _buildReadOnlyField('Total', '${_reporte?.total} ${_reporte?.moneda}'),
      ],
    );
  }

  // Sección de Movilidad
  Widget _buildMovilidadSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildReadOnlyField('Origen', _reporte?.lugarorigen ?? 'N/A'),
        _buildReadOnlyField('Destino', _reporte?.lugardestino ?? 'N/A'),
        _buildReadOnlyField('Motivo Viajes', _reporte?.motivoviaje ?? 'N/A'),
        _buildReadOnlyField('Transporte', _reporte?.tipomovilidad ?? 'N/A'),
        _buildReadOnlyField('Placa', _reporte?.placa ?? 'N/A'),
      ],
    );
  }

  // Sección de Datos de la Factura
  Widget _buildFacturaNotaSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Observacion',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        _buildReadOnlyField('Comentario', _reporte?.obs ?? 'N/A'),
      ],
    );
  }

  // Campo de solo lectura
  Widget _buildReadOnlyField(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontSize: 14,
                color: Colors.grey,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}
