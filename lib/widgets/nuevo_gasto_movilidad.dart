import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
// intl and io are used in controller; removed from widget
import '../models/dropdown_option.dart';
// logic moved to controller
import '../controllers/nuevo_gasto_movilidad_controller.dart';
import '../screens/home_screen.dart';

/// Modal para crear nuevo gasto de movilidad después de seleccionar política
class NuevoGastoMovilidad extends StatefulWidget {
  final DropdownOption politicaSeleccionada;
  final VoidCallback onCancel;
  final Function(Map<String, dynamic>) onSave;

  const NuevoGastoMovilidad({
    super.key,
    required this.politicaSeleccionada,
    required this.onCancel,
    required this.onSave,
  });

  @override
  State<NuevoGastoMovilidad> createState() => _NuevoGastoMovilidadState();
}

class _NuevoGastoMovilidadState extends State<NuevoGastoMovilidad> {
  late NuevoGastoMovilidadController controller;
  // use controller.isScanning instead of local _isScanning
  // Focus nodes for fields we want to scroll into view when focused
  final FocusNode _focusProveedor = FocusNode();
  final FocusNode _focusRuc = FocusNode();
  final FocusNode _focusTipoDocumento = FocusNode();
  final FocusNode _focusNota = FocusNode();
  final FocusNode _focusOrigen = FocusNode();
  final FocusNode _focusDestino = FocusNode();
  final FocusNode _focusMotivo = FocusNode();
  // GlobalKeys to reliably find the field contexts
  final GlobalKey _keyDestino = GlobalKey();
  final GlobalKey _keyMotivo = GlobalKey();

  // Usar directamente controller.* desde el widget en lugar de getters intermedios
  GlobalKey<FormState> get _formKey => controller.formKey;

  @override
  void initState() {
    super.initState();
    controller = NuevoGastoMovilidadController(
      politicaSeleccionada: widget.politicaSeleccionada,
    );
    controller.addListener(_onControllerUpdated);
    controller.initialize();
    // Registrar listeners en FocusNodes para asegurar visibilidad
    _focusProveedor.addListener(() => _ensureVisibleOnFocus(_focusProveedor));
    _focusRuc.addListener(() => _ensureVisibleOnFocus(_focusRuc));
    _focusTipoDocumento.addListener(
      () => _ensureVisibleOnFocus(_focusTipoDocumento),
    );
    _focusNota.addListener(() => _ensureVisibleOnFocus(_focusNota));
    _focusOrigen.addListener(() => _ensureVisibleOnFocus(_focusOrigen));
    _focusDestino.addListener(() => _ensureVisibleOnFocus(_focusDestino));
    _focusMotivo.addListener(() => _ensureVisibleOnFocus(_focusMotivo));
  }

  // inicialización delegada al controlador

  void _onControllerUpdated() {
    if (!mounted) return;
    setState(() {});
  }

  @override
  void dispose() {
    controller.removeListener(_onControllerUpdated);
    controller.dispose();
    // dispose focus nodes
    _focusProveedor.dispose();
    _focusRuc.dispose();
    _focusTipoDocumento.dispose();
    _focusNota.dispose();
    _focusOrigen.dispose();
    _focusDestino.dispose();
    _focusMotivo.dispose();
    super.dispose();
  }

  void _ensureVisibleOnFocus(FocusNode node) {
    if (!node.hasFocus) return;
    // Esperar un frame para que el teclado aparezca
    Future.delayed(const Duration(milliseconds: 120), () {
      if (!mounted) return;
      BuildContext? contextField;
      // Si es destino o motivo, preferimos usar el GlobalKey para mayor fiabilidad
      if (node == _focusDestino) {
        contextField = _keyDestino.currentContext;
      } else if (node == _focusMotivo) {
        contextField = _keyMotivo.currentContext;
      }

      contextField ??= node.context;

      if (contextField != null) {
        Scrollable.ensureVisible(
          contextField,
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeInOut,
          alignment: 0.28, // un poco más arriba que antes para equilibrio
        );
      }
    });
  }

  @override
  void setState(VoidCallback fn) {
    // Evitar llamar a setState si el State ya no está montado o está en proceso de disposal.
    if (!mounted) return;
    super.setState(fn);
  }

  Future<void> _loadCategorias() async {
    await controller.loadCategorias();
  }

  Future<void> _loadTiposGasto() async {
    await controller.loadTiposGasto();
  }

  Future<void> _pickFile() async {
    try {
      await controller.pickFile(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al seleccionar archivo: $e')),
      );
    }
  }

  Future<void> _onGuardar() async {
    try {
      final id = await controller.save();
      if (id != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Gasto de movilidad guardado exitosamente'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
        Navigator.of(context).pop();
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const HomeScreen()),
          (route) => false,
        );
      }
    } catch (e) {
      final serverMessage = controller.extractServerMessage(e.toString());
      if (serverMessage.toLowerCase().contains('duplicad') ||
          serverMessage.toLowerCase().contains('ya existe') ||
          serverMessage.toLowerCase().contains('registrada')) {
        _showFacturaDuplicadaDialog(serverMessage);
      } else {
        _showErrorDialog(serverMessage);
      }
    }
  }

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
      child: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: Form(
              key: _formKey,
              child: SingleChildScrollView(
                // Añadir padding inferior dinámico para que el teclado no oculte los campos
                padding: EdgeInsets.fromLTRB(
                  16,
                  16,
                  16,
                  16 + MediaQuery.of(context).viewInsets.bottom,
                ),
                child: Column(
                  children: [
                    _buildArchivoSection(),
                    const SizedBox(height: 4),
                    _buildLectorSunatSection(),
                    const SizedBox(height: 4),
                    _buildDatosGeneralesSection(),
                    const SizedBox(height: 4),
                    _buildDatosPersonalizadosSection(),
                    const SizedBox(height: 4),
                    _buildMovilidadSection(),
                    const SizedBox(height: 4),
                    _buildActions(),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue.shade700, Colors.blue.shade400],
        ),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.directions_car, color: Colors.white, size: 28),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Nuevo Gasto - Movilidad',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  'Política: ${widget.politicaSeleccionada.value}',
                  style: const TextStyle(fontSize: 14, color: Colors.white70),
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

  Widget _buildDatosGeneralesSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.info, color: Colors.blue),
                const SizedBox(width: 8),
                const Text(
                  'Datos Generales',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: controller.proveedorController,
              focusNode: _focusProveedor,
              decoration: const InputDecoration(
                labelText: 'Proveedor *',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.business),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Proveedor es obligatorio';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: controller.fechaController,
                    decoration: const InputDecoration(
                      labelText: 'Fecha *',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.calendar_today),
                    ),
                    readOnly: true,
                    onTap: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now(),
                        firstDate: DateTime(2020),
                        lastDate: DateTime.now(),
                      );
                      if (date != null) {
                        controller.fechaController.text = date
                            .toLocal()
                            .toString()
                            .split(' ')[0];
                      }
                    },
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Fecha es obligatoria';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextFormField(
                    controller: controller.totalController,
                    decoration: const InputDecoration(
                      labelText: 'Total *',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.attach_money),
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Total es obligatorio';
                      }
                      if (double.tryParse(value) == null) {
                        return 'Ingrese un monto válido';
                      }
                      return null;
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: controller.monedaController.text.isEmpty
                  ? 'PEN'
                  : controller.monedaController.text,
              decoration: const InputDecoration(
                labelText: 'Moneda *',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.monetization_on),
              ),
              items: const [
                DropdownMenuItem(value: 'PEN', child: Text('PEN - Soles')),
                DropdownMenuItem(value: 'USD', child: Text('USD - Dólares')),
                DropdownMenuItem(value: 'EUR', child: Text('EUR - Euros')),
              ],
              onChanged: (value) {
                controller.monedaController.text = value ?? 'PEN';
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDatosPersonalizadosSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.settings, color: Colors.blue),
                const SizedBox(width: 8),
                const Text(
                  'Datos Personalizados',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),

            if (controller.isLoadingCategorias)
              const Center(
                child: Column(
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 8),
                    Text('Cargando categorías...'),
                  ],
                ),
              )
            else if (controller.error != null)
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
                        'Error: ${controller.error}',
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
            else if (controller.categoriasMovilidad.isEmpty)
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
                        'No hay categorías disponibles para movilidad',
                        style: TextStyle(color: Colors.orange),
                      ),
                    ),
                  ],
                ),
              )
            else
              DropdownButtonFormField<DropdownOption>(
                decoration: const InputDecoration(
                  labelText: 'Categoría *',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.category),
                ),
                value: controller.selectedCategoria,
                items: controller.categoriasMovilidad.map((categoria) {
                  return DropdownMenuItem<DropdownOption>(
                    value: categoria,
                    child: Text(categoria.value),
                  );
                }).toList(),
                onChanged: (value) {
                  controller.updateSelectedCategoria(value);
                },
                validator: (value) {
                  if (value == null) return 'Categoría es obligatoria';
                  return null;
                },
              ),

            const SizedBox(height: 16),

            if (controller.isLoadingTiposGasto)
              const Center(
                child: Column(
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 8),
                    Text('Cargando tipos de gasto...'),
                  ],
                ),
              )
            else if (controller.error != null)
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
                        'Error: ${controller.error}',
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
              DropdownButtonFormField<DropdownOption>(
                decoration: const InputDecoration(
                  labelText: 'Tipo Gasto *',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.receipt),
                ),
                value: controller.selectedTipoGasto,
                items: controller.tiposGasto.map((tipo) {
                  return DropdownMenuItem<DropdownOption>(
                    value: tipo,
                    child: Text(tipo.value),
                  );
                }).toList(),
                onChanged: (value) {
                  controller.updateSelectedTipoGasto(value);
                },
                validator: (value) {
                  if (value == null) return 'Tipo Gasto es obligatorio';
                  return null;
                },
              ),

            const SizedBox(height: 16),

            TextFormField(
              controller: controller.rucController,
              focusNode: _focusRuc,
              decoration: const InputDecoration(
                labelText: 'RUC Proveedor *',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.business),
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.trim().isEmpty)
                  return 'RUC es obligatorio';
                return null;
              },
            ),

            const SizedBox(height: 16),

            TextFormField(
              controller: controller.rucClienteController,
              enabled: false,
              decoration: InputDecoration(
                labelText: 'RUC Cliente',
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.lock),
                suffixIcon: Icon(Icons.info_outline, color: Colors.grey[600]),
                helperText: 'RUC de la empresa seleccionada',
                filled: true,
                fillColor: Colors.grey[100],
              ),
            ),

            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: controller.serieFacturaController,
                    decoration: const InputDecoration(
                      labelText: 'Serie *',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.receipt_long),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty)
                        return 'Serie es obligatorio';
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: controller.numeroFacturaController,
                    decoration: const InputDecoration(
                      labelText: 'Número *',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.confirmation_number),
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty)
                        return 'Número es obligatorio';
                      return null;
                    },
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: controller.tipoDocumentoController,
                    focusNode: _focusTipoDocumento,
                    decoration: const InputDecoration(
                      labelText: 'Tipo Documento *',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.description),
                      hintText: 'Se llena automáticamente desde QR',
                    ),
                    readOnly: true,
                    validator: (value) {
                      if (value == null || value.isEmpty)
                        return 'Tipo Documento es obligatorio';
                      return null;
                    },
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            TextFormField(
              controller: controller.notaController,
              focusNode: _focusNota,
              decoration: const InputDecoration(
                labelText: 'Nota',
                hintText: 'Observaciones o comentarios',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.note_add),
              ),
              maxLines: 3,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMovilidadSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.directions_car, color: Colors.blue),
                const SizedBox(width: 8),
                const Text(
                  'Detalles de Movilidad',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: controller.origenController,
              focusNode: _focusOrigen,
              decoration: const InputDecoration(
                labelText: 'Origen *',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.my_location),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Origen es obligatorio';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            Container(
              key: _keyDestino,
              child: TextFormField(
                controller: controller.destinoController,
                focusNode: _focusDestino,
                onTap: () {
                  // Forzar ensureVisible con un pequeño delay mayor para dispositivos
                  Future.delayed(
                    const Duration(milliseconds: 220),
                    () => _ensureVisibleOnFocus(_focusDestino),
                  );
                },
                decoration: const InputDecoration(
                  labelText: 'Destino *',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.location_on),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Destino es obligatorio';
                  }
                  return null;
                },
              ),
            ),
            const SizedBox(height: 12),
            Container(
              key: _keyMotivo,
              child: TextFormField(
                controller: controller.motivoViajeController,
                focusNode: _focusMotivo,
                onTap: () {
                  Future.delayed(
                    const Duration(milliseconds: 240),
                    () => _ensureVisibleOnFocus(_focusMotivo),
                  );
                },
                decoration: const InputDecoration(
                  labelText: 'Motivo del Viaje *',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.description),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Motivo del Viaje es obligatorio';
                  }
                  return null;
                },
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: controller.tipoTransporteController.text.isEmpty
                  ? 'Taxi'
                  : controller.tipoTransporteController.text,
              decoration: const InputDecoration(
                labelText: 'Tipo de Transporte',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.directions_car),
              ),
              items: const [
                DropdownMenuItem(value: 'Taxi', child: Text('Taxi')),
                DropdownMenuItem(value: 'Uber', child: Text('Uber')),
                DropdownMenuItem(value: 'Bus', child: Text('Bus')),
                DropdownMenuItem(value: 'Metro', child: Text('Metro')),
                DropdownMenuItem(value: 'Avión', child: Text('Avión')),
                DropdownMenuItem(value: 'Otro', child: Text('Otro')),
              ],
              onChanged: (value) {
                controller.tipoTransporteController.text = value ?? 'Taxi';
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildArchivoSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.attach_file, color: Colors.blue),
                const SizedBox(width: 4),
                const Expanded(
                  child: Text(
                    'Adjuntar Evidencia',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: _pickFile,
                  icon: Icon(
                    (controller.selectedImage == null &&
                            controller.selectedFile == null)
                        ? Icons.add
                        : Icons.edit,
                    size: 16,
                  ),
                  label: Text(
                    (controller.selectedImage == null &&
                            controller.selectedFile == null)
                        ? 'Seleccionar'
                        : 'Cambiar',
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    textStyle: const TextStyle(fontSize: 12),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              height: 120,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(8),
                color: Colors.grey.shade50,
              ),
              child:
                  (controller.selectedImage != null ||
                      controller.selectedFile != null)
                  ? Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          controller.selectedFileType == 'image'
                              ? Icons.image
                              : Icons.picture_as_pdf,
                          size: 48,
                          color: Colors.green.shade600,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          controller.selectedFileName ?? 'Archivo seleccionado',
                          style: const TextStyle(fontSize: 12),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Archivo adjuntado correctamente',
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.green.shade600,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    )
                  : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.cloud_upload,
                          size: 48,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'No hay archivo seleccionado',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Use el botón "Seleccionar" para agregar evidencia',
                          style: TextStyle(
                            color: Colors.grey.shade500,
                            fontSize: 12,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  /// Construir la sección del lector de código SUNAT
  Widget _buildLectorSunatSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.qr_code_scanner, color: Colors.blue),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Lector de Código QR',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: controller.isScanning ? null : _scanQRCode,
                  icon: Icon(
                    controller.isScanning
                        ? Icons.hourglass_empty
                        : Icons.qr_code_scanner,
                    size: 16,
                  ),
                  label: Text(
                    controller.isScanning ? 'Escaneando...' : 'Escanear QR',
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    textStyle: const TextStyle(fontSize: 12),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: controller.hasScannedData
                    ? Colors.green.shade50
                    : Colors.grey.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: controller.hasScannedData
                      ? Colors.green.shade200
                      : Colors.grey.shade300,
                ),
              ),
              child: controller.hasScannedData
                  ? Column(
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.check_circle,
                              color: Colors.green.shade600,
                              size: 20,
                            ),
                            const SizedBox(width: 4),
                            const Text(
                              'Código QR procesado correctamente',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: Colors.green,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Los datos han sido extraídos y aplicados a los campos correspondientes',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.green.shade700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        TextButton.icon(
                          onPressed: _clearScannedData,
                          icon: const Icon(Icons.clear, size: 16),
                          label: const Text('Limpiar Datos'),
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.orange,
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
                          size: 20,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            'Escanee el código QR de la factura ',
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
    controller.setScanning(true);

    try {
      // Navegar a la pantalla de escáner
      final qrData = await Navigator.push<String>(
        context,
        MaterialPageRoute(builder: (context) => _QRScannerScreen()),
      );

      if (qrData != null && qrData.isNotEmpty) {
        controller.processQRData(qrData);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al escanear QR: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      controller.setScanning(false);
    }
  }

  /// Procesar los datos del QR y llenar los campos
  // El procesamiento del QR y normalización ahora están en el controlador

  /// Limpiar los datos escaneados
  void _clearScannedData() {
    controller.clearScannedData();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Datos del QR limpiados'),
        backgroundColor: Colors.orange,
      ),
    );
  }

  Widget _buildActions() {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          if (controller.selectedImage == null &&
              controller.selectedFile == null)
            Container(
              padding: const EdgeInsets.all(4),
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.warning, color: Colors.orange.shade600),
                  const SizedBox(width: 8),
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
                child: OutlinedButton(
                  onPressed: widget.onCancel,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    side: BorderSide(color: Colors.grey.shade400),
                  ),
                  child: const Text('Cancelar', style: TextStyle(fontSize: 16)),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton(
                  onPressed: controller.isLoading ? null : _onGuardar,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue.shade600,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                  ),
                  child: controller.isLoading
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
                      : const Text(
                          'Guardar Gasto',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  // Normalización de fecha ahora en el controlador si es necesario

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
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.receipt_long,
                  color: Colors.orange,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Factura Ya Registrada',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.orange,
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
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange.withOpacity(0.2)),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.info_outline,
                      color: Colors.orange,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'Esta factura ya ha sido registrada previamente en el sistema.',
                        style: TextStyle(fontSize: 14, color: Colors.black87),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              if (message.isNotEmpty)
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.grey.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    message,
                    style: const TextStyle(fontSize: 12, color: Colors.black54),
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
                padding: const EdgeInsets.all(10),
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
                  'Error del Servidor',
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
            padding: const EdgeInsets.all(10),
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
                'Cerrar',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        );
      },
    );
  }

  // Extracción de mensajes del servidor delegada al controlador
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
          // Botón de linterna con estado visual
          _TorchButton(controller: cameraController),
        ],
      ),
      body: Stack(
        children: [
          // Cámara escáner
          MobileScanner(controller: cameraController, onDetect: _onQRDetected),

          // Overlay con marco de escaneo animado
          AnimatedQrOverlay(
            borderColor: Colors.blueAccent,
            borderWidth: 6,
            cutOutSize: 280,
            lineColor: Colors.cyanAccent,
            overlayColor: Colors.black54,
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

// Widget simple para overlay del escáner QR
class QrScannerOverlay extends StatelessWidget {
  final double cutOutSize;
  final Color borderColor;
  final double borderWidth;
  final Color overlayColor;

  const QrScannerOverlay({
    Key? key,
    this.cutOutSize = 250,
    this.borderColor = Colors.blue,
    this.borderWidth = 3.0,
    this.overlayColor = const Color.fromRGBO(0, 0, 0, 80),
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: QrScannerPainter(
        cutOutSize: cutOutSize,
        borderColor: borderColor,
        borderWidth: borderWidth,
        overlayColor: overlayColor,
      ),
    );
  }
}

class QrScannerPainter extends CustomPainter {
  final double cutOutSize;
  final Color borderColor;
  final double borderWidth;
  final Color overlayColor;

  QrScannerPainter({
    required this.cutOutSize,
    required this.borderColor,
    required this.borderWidth,
    required this.overlayColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    final cutOutRect = Rect.fromCenter(
      center: rect.center,
      width: cutOutSize,
      height: cutOutSize,
    );

    // Dibujar overlay con cut-out
    final backgroundPath = Path()
      ..addRect(rect)
      ..addRect(cutOutRect)
      ..fillType = PathFillType.evenOdd;

    final backgroundPaint = Paint()
      ..color = overlayColor
      ..style = PaintingStyle.fill;

    canvas.drawPath(backgroundPath, backgroundPaint);

    // Dibujar esquinas del marco
    final borderPaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = borderWidth;

    final cornerLength = 30.0;
    final path = Path();

    // Esquina superior izquierda
    path.moveTo(cutOutRect.left, cutOutRect.top + cornerLength);
    path.lineTo(cutOutRect.left, cutOutRect.top);
    path.lineTo(cutOutRect.left + cornerLength, cutOutRect.top);

    // Esquina superior derecha
    path.moveTo(cutOutRect.right - cornerLength, cutOutRect.top);
    path.lineTo(cutOutRect.right, cutOutRect.top);
    path.lineTo(cutOutRect.right, cutOutRect.top + cornerLength);

    // Esquina inferior derecha
    path.moveTo(cutOutRect.right, cutOutRect.bottom - cornerLength);
    path.lineTo(cutOutRect.right, cutOutRect.bottom);
    path.lineTo(cutOutRect.right - cornerLength, cutOutRect.bottom);

    // Esquina inferior izquierda
    path.moveTo(cutOutRect.left + cornerLength, cutOutRect.bottom);
    path.lineTo(cutOutRect.left, cutOutRect.bottom);
    path.lineTo(cutOutRect.left, cutOutRect.bottom - cornerLength);

    canvas.drawPath(path, borderPaint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

/// Overlay animado con línea de escaneo
class AnimatedQrOverlay extends StatefulWidget {
  final double cutOutSize;
  final Color borderColor;
  final double borderWidth;
  final Color overlayColor;
  final Color lineColor;

  const AnimatedQrOverlay({
    Key? key,
    this.cutOutSize = 250,
    this.borderColor = Colors.blue,
    this.borderWidth = 3.0,
    this.overlayColor = const Color.fromRGBO(0, 0, 0, 150),
    this.lineColor = Colors.cyan,
  }) : super(key: key);

  @override
  _AnimatedQrOverlayState createState() => _AnimatedQrOverlayState();
}

class _AnimatedQrOverlayState extends State<AnimatedQrOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return CustomPaint(
          painter: AnimatedQrPainter(
            progress: _controller.value,
            cutOutSize: widget.cutOutSize,
            borderColor: widget.borderColor,
            borderWidth: widget.borderWidth,
            overlayColor: widget.overlayColor,
            lineColor: widget.lineColor,
          ),
          child: Container(),
        );
      },
    );
  }
}

class AnimatedQrPainter extends CustomPainter {
  final double progress;
  final double cutOutSize;
  final Color borderColor;
  final double borderWidth;
  final Color overlayColor;
  final Color lineColor;

  AnimatedQrPainter({
    required this.progress,
    required this.cutOutSize,
    required this.borderColor,
    required this.borderWidth,
    required this.overlayColor,
    required this.lineColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    final cutOutRect = Rect.fromCenter(
      center: rect.center,
      width: cutOutSize,
      height: cutOutSize,
    );

    // Overlay
    final backgroundPath = Path()
      ..addRect(rect)
      ..addRect(cutOutRect)
      ..fillType = PathFillType.evenOdd;

    final backgroundPaint = Paint()
      ..color = overlayColor
      ..style = PaintingStyle.fill;

    canvas.drawPath(backgroundPath, backgroundPaint);

    // Border corners
    final borderPaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = borderWidth
      ..strokeCap = StrokeCap.round;

    final cornerLength = 34.0;
    final path = Path();

    // Top-left
    path.moveTo(cutOutRect.left, cutOutRect.top + cornerLength);
    path.lineTo(cutOutRect.left, cutOutRect.top + 6);
    path.lineTo(cutOutRect.left + cornerLength, cutOutRect.top + 6);

    // Top-right
    path.moveTo(cutOutRect.right - cornerLength, cutOutRect.top + 6);
    path.lineTo(cutOutRect.right - 6, cutOutRect.top + 6);
    path.lineTo(cutOutRect.right - 6, cutOutRect.top + cornerLength);

    // Bottom-right
    path.moveTo(cutOutRect.right - 6, cutOutRect.bottom - cornerLength);
    path.lineTo(cutOutRect.right - 6, cutOutRect.bottom - 6);
    path.lineTo(cutOutRect.right - cornerLength, cutOutRect.bottom - 6);

    // Bottom-left
    path.moveTo(cutOutRect.left + cornerLength, cutOutRect.bottom - 6);
    path.lineTo(cutOutRect.left + 6, cutOutRect.bottom - 6);
    path.lineTo(cutOutRect.left + 6, cutOutRect.bottom - cornerLength);

    canvas.drawPath(path, borderPaint);

    // Animated scanning line
    final linePaint = Paint()
      ..shader =
          LinearGradient(
            colors: [
              lineColor.withOpacity(0.0),
              lineColor,
              lineColor.withOpacity(0.0),
            ],
          ).createShader(
            Rect.fromLTWH(
              cutOutRect.left,
              0,
              cutOutRect.width,
              cutOutRect.height,
            ),
          )
      ..style = PaintingStyle.fill
      ..strokeWidth = 2.0;

    final y = cutOutRect.top + (cutOutRect.height * progress);
    final lineRect = Rect.fromLTWH(
      cutOutRect.left + 4,
      y - 1.5,
      cutOutRect.width - 8,
      3,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(lineRect, const Radius.circular(2)),
      linePaint,
    );
  }

  @override
  bool shouldRepaint(covariant AnimatedQrPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.cutOutSize != cutOutSize;
  }
}

/// Botón de linterna con estado
class _TorchButton extends StatefulWidget {
  final MobileScannerController controller;

  const _TorchButton({Key? key, required this.controller}) : super(key: key);

  @override
  State<_TorchButton> createState() => _TorchButtonState();
}

class _TorchButtonState extends State<_TorchButton> {
  bool _torchOn = false;

  Future<void> _toggle() async {
    try {
      await widget.controller.toggleTorch();
      setState(() {
        _torchOn = !_torchOn;
      });
    } catch (_) {
      // ignore errors toggling torch
    }
  }

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(
        _torchOn ? Icons.flash_on : Icons.flash_off,
        color: Colors.white,
      ),
      onPressed: _toggle,
      tooltip: _torchOn ? 'Apagar linterna' : 'Encender linterna',
    );
  }
}
