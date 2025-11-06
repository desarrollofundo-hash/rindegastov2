import 'package:flutter/material.dart';
import '../models/dropdown_option.dart';
import '../models/gasto_model.dart';
import '../services/api_service.dart';
import '../screens/informe_flow_screen.dart';

/// Modal para crear un nuevo informe con título y política
class NuevoInformeModal extends StatefulWidget {
  final Function(Gasto) onInformeCreated;
  final VoidCallback onCancel;

  const NuevoInformeModal({
    super.key,
    required this.onInformeCreated,
    required this.onCancel,
  });

  @override
  State<NuevoInformeModal> createState() => _NuevoInformeModalState();
}

class _NuevoInformeModalState extends State<NuevoInformeModal> {
  final _formKey = GlobalKey<FormState>();
  final _tituloController = TextEditingController();
  final _notaController = TextEditingController();
  final ApiService _apiService = ApiService();

  List<DropdownOption> _politicas = [];
  DropdownOption? _selectedPolitica;
  bool _isLoadingPoliticas = true;
  bool _isCreatingInforme = false;
  String? _errorPoliticas;

  @override
  void initState() {
    super.initState();
    _loadPoliticas();
  }

  @override
  void dispose() {
    _tituloController.dispose();
    _notaController.dispose();
    super.dispose();
  }

  /// Maneja el cierre del modal asegurando que se retire el foco
  /// para que no vuelva al campo de búsqueda de la pantalla padre.
  void _handleCancel() {
    // Retirar cualquier foco activo
    FocusScope.of(context).unfocus();
    // Delegar a la callback que cerrará el modal (normalmente Navigator.pop)
    widget.onCancel();
  }

  Future<void> _loadPoliticas() async {
    // Asegurar que el widget esté montado antes de llamar a setState
    if (!mounted) return;
    setState(() {
      _isLoadingPoliticas = true;
      _errorPoliticas = null;
    });

    try {
      final politicas = await _apiService.getRendicionPoliticas();
      if (!mounted) return;
      setState(() {
        _politicas = politicas;
        _isLoadingPoliticas = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorPoliticas = e.toString();
        _isLoadingPoliticas = false;
      });
    }
  }

  Future<void> _crearInforme() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedPolitica == null) return;

    if (mounted) {
      setState(() {
        _isCreatingInforme = true;
      });
    }

    try {
      // Navegar a la pantalla de flujo de informe
      final resultado = await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => InformeFlowScreen(
            tituloInforme: _tituloController.text.trim(),
            politicaSeleccionada: _selectedPolitica!,
            nota: _notaController.text.trim().isNotEmpty
                ? _notaController.text.trim()
                : null,
          ),
        ),
      );

      // Si el usuario completó el flujo exitosamente
      if (resultado == true) {
        // Crear el informe final
        final fechaCreacion = DateTime.now();
        final descripcionBase =
            'Informe creado el ${fechaCreacion.day}/${fechaCreacion.month}/${fechaCreacion.year}';
        final nota = _notaController.text.trim();
        final descripcionCompleta = nota.isNotEmpty
            ? '$descripcionBase\nNota: $nota'
            : descripcionBase;

        final nuevoInforme = Gasto(
          titulo: _tituloController.text.trim(),
          descripcion: descripcionCompleta,
          monto: '0.00',
          fecha:
              '${fechaCreacion.day}/${fechaCreacion.month}/${fechaCreacion.year}',
          categoria: 'Informe',
          estado: 'Completado',
        );

        widget.onInformeCreated(nuevoInforme);
        // Cerrar el modal una vez que el flujo se completó correctamente
        if (mounted) {
          // Retirar foco antes de cerrar para evitar que vuelva al campo de búsqueda
          FocusScope.of(context).unfocus();
          Navigator.of(context).pop();
        }
      }
    } catch (e) {
      // Sólo actualizar estado y mostrar errores si el State sigue montado
      if (mounted) {
        setState(() {
          _isCreatingInforme = false;
        });

        _mostrarSnackbarError(e.toString());
      }
    }
  }

  void _mostrarSnackbarError(String error) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('❌ Error al crear informe: $error'),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 5),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Handle del modal
          Container(
            /* margin: const EdgeInsets.only(top: 2),
            width: 40,
            height: 4, */
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.indigo.shade700, Colors.indigo.shade400],
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.description, color: Colors.white, size: 28),
                const SizedBox(width: 6),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'NUEVO INFORME',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        'Crea un nuevo informe ',
                        style: TextStyle(fontSize: 12, color: Colors.white70),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: _handleCancel,
                  icon: const Icon(Icons.close, color: Colors.white),
                ),
              ],
            ),
          ),

          // Contenido
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: _buildContent(),
            ),
          ),

          // Botones de acción
          Container(
            padding: const EdgeInsets.all(20),

            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _isCreatingInforme ? null : _handleCancel,
                    icon: const Icon(Icons.cancel),
                    label: const Text('Cancelar'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      side: BorderSide(color: Colors.grey.shade400),
                      foregroundColor: Colors.grey.shade700,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed:
                        _tituloController.text.trim().isEmpty ||
                            _selectedPolitica == null
                        ? null
                        : _crearInforme,
                    icon: Icon(Icons.save),
                    label: Text('Crear Informe'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.indigo,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      disabledBackgroundColor: Colors.grey[300],
                      disabledForegroundColor: Colors.grey[600],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 35),
        ],
      ),
    );
  }

  Widget _buildContent() {
    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Campo de título
            const Text(
              'Información del Informe',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),

            TextFormField(
              controller: _tituloController,
              decoration: InputDecoration(
                labelText: 'Título del Informe *',
                hintText: 'Ej: Informe de gastos octubre 2025',
                prefixIcon: const Icon(Icons.title, color: Colors.indigo),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Colors.indigo, width: 2),
                ),
                errorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.red.shade400, width: 2),
                ),
                focusedErrorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.red.shade600, width: 2),
                ),
                filled: true,
                fillColor: Colors.grey.shade50,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 16,
                ),
              ),
              maxLength: 100,
              textCapitalization: TextCapitalization.words,
              onChanged: (value) {
                if (!mounted) return;
                setState(() {}); // Para actualizar el estado del botón
              },
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Por favor ingresa un título para el informe';
                }
                if (value.trim().length < 3) {
                  return 'El título debe tener al menos 3 caracteres';
                }
                return null;
              },
            ),

            const SizedBox(height: 1),

            // Dropdown de políticas
            const Text(
              'Política Aplicable',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 4),

            _buildPoliticasDropdown(),

            const SizedBox(height: 16),
            // Campo de nota
            TextFormField(
              controller: _notaController,
              decoration: InputDecoration(
                labelText: 'Nota (opcional)',
                hintText: 'Ej: Gastos del viaje de trabajo a ...',
                prefixIcon: const Icon(Icons.note_add, color: Colors.indigo),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Colors.indigo, width: 2),
                ),
                filled: true,
                fillColor: Colors.grey.shade50,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 16,
                ),
                alignLabelWithHint: true,
              ),
              maxLines: 4,
              minLines: 3,
              maxLength: 200,
              textInputAction: TextInputAction.newline,
              keyboardType: TextInputType.multiline,
              textCapitalization: TextCapitalization.sentences,
            ),

            // Información adicional

            // Espaciador para el scrolling
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildPoliticasDropdown() {
    if (_isLoadingPoliticas) {
      return Container(
        height: 64,
        /* padding: const EdgeInsets.symmetric(horizontal: 16), */
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(12),
          color: Colors.grey.shade50,
        ),
        child: const Center(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation(Colors.indigo),
                ),
              ),
              SizedBox(width: 12),
              Text(
                'Cargando políticas...',
                style: TextStyle(color: Colors.grey, fontSize: 14),
              ),
            ],
          ),
        ),
      );
    }

    if (_errorPoliticas != null) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.red.shade300),
          borderRadius: BorderRadius.circular(12),
          color: Colors.red.shade50,
        ),
        child: Column(
          children: [
            Row(
              children: [
                Icon(Icons.error_outline, color: Colors.red.shade600, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Error al cargar políticas',
                    style: TextStyle(
                      color: Colors.red.shade700,
                      fontWeight: FontWeight.w500,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _loadPoliticas,
                icon: const Icon(Icons.refresh, size: 18),
                label: const Text('Reintentar'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return DropdownButtonFormField<DropdownOption>(
      value: _selectedPolitica,
      decoration: InputDecoration(
        labelText: 'Política *',

        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.indigo, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.red.shade400, width: 2),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.red.shade600, width: 2),
        ),
        filled: true,
        fillColor: Colors.grey.shade50,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
      ),
      hint: const Text('Seleccionar política...'),
      isExpanded: true,
      items: _politicas.map((politica) {
        return DropdownMenuItem<DropdownOption>(
          value: politica,
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.indigo.shade50,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(Icons.policy, color: Colors.indigo, size: 16),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  politica.value,
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        );
      }).toList(),
      onChanged: (value) {
        if (!mounted) return;
        setState(() {
          _selectedPolitica = value;
        });
      },
      validator: (value) {
        if (value == null) {
          return 'Por favor selecciona una política';
        }
        return null;
      },
      icon: const Icon(Icons.arrow_drop_down, color: Colors.indigo),
      iconSize: 24,
      dropdownColor: Colors.white,
      style: const TextStyle(color: Colors.black87),
    );
  }
}
