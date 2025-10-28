import 'package:flutter/material.dart';
import '../models/dropdown_option.dart';
import '../services/api_service.dart';

/// Widget de dropdown que carga las opciones dinámicamente desde la API
class ApiDropdownField extends StatefulWidget {
  /// Función para obtener las opciones desde la API
  final Future<List<DropdownOption>> Function() fetchOptions;

  /// Callback cuando se selecciona una opción
  final ValueChanged<DropdownOption?> onChanged;

  /// Opción seleccionada actualmente
  final DropdownOption? value;

  /// Texto del hint cuando no hay selección
  final String hint;

  /// Label del campo
  final String? label;

  /// Texto de error personalizado
  final String? errorText;

  /// Si es requerido o no
  final bool isRequired;

  /// Si está habilitado o no
  final bool enabled;

  /// Icono personalizado
  final IconData? icon;

  /// Estilo del dropdown
  final InputDecoration? decoration;

  /// Callback para personalizar el texto mostrado de cada opción
  final String Function(DropdownOption)? displayText;

  const ApiDropdownField({
    super.key,
    required this.fetchOptions,
    required this.onChanged,
    this.value,
    this.hint = 'Seleccionar...',
    this.label,
    this.errorText,
    this.isRequired = false,
    this.enabled = true,
    this.icon,
    this.decoration,
    this.displayText,
  });

  @override
  State<ApiDropdownField> createState() => _ApiDropdownFieldState();
}

class _ApiDropdownFieldState extends State<ApiDropdownField> {
  List<DropdownOption> _options = [];
  bool _isLoading = false;
  String? _errorMessage;
  bool _hasLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadOptions();
  }

  /// Carga las opciones desde la API
  Future<void> _loadOptions() async {
    if (_hasLoaded) return; // Evitar cargas múltiples
    if (mounted) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }

    try {
      final options = await widget.fetchOptions();
      if (!mounted) return;
      setState(() {
        _options = options;
        _isLoading = false;
        _hasLoaded = true;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString().replaceAll('Exception: ', '');
      });
    }
  }

  /// Reintenta cargar las opciones
  Future<void> _retryLoad() async {
    if (mounted) {
      setState(() {
        _hasLoaded = false;
      });
    }
    await _loadOptions();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.label != null) ...[
          Text(
            widget.label!,
            style: Theme.of(
              context,
            ).textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 8),
        ],

        InputDecorator(
          decoration:
              widget.decoration ??
              InputDecoration(
                hintText: widget.hint,
                errorText: widget.errorText ?? _errorMessage,
                prefixIcon: widget.icon != null ? Icon(widget.icon) : null,
                border: const OutlineInputBorder(),
                enabled: widget.enabled && !_isLoading,
              ),
          child: _buildDropdownContent(),
        ),
      ],
    );
  }

  Widget _buildDropdownContent() {
    // Estado de carga
    if (_isLoading) {
      return const Row(
        children: [
          SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          SizedBox(width: 12),
          Text('Cargando opciones...'),
        ],
      );
    }

    // Estado de error
    if (_errorMessage != null) {
      return Row(
        children: [
          const Icon(Icons.error_outline, color: Colors.red, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Error al cargar',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ),
          IconButton(
            onPressed: _retryLoad,
            icon: const Icon(Icons.refresh, size: 20),
            tooltip: 'Reintentar',
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      );
    }

    // Estado sin opciones
    if (_options.isEmpty) {
      return Text(
        'No hay opciones disponibles',
        style: TextStyle(color: Colors.grey[600]),
      );
    }

    // Dropdown normal con opciones cargadas
    return DropdownButtonHideUnderline(
      child: DropdownButton<DropdownOption>(
        value: widget.value,
        isExpanded: true,
        hint: Text(widget.hint),
        onChanged: widget.enabled ? widget.onChanged : null,
        items: _options.map<DropdownMenuItem<DropdownOption>>((option) {
          return DropdownMenuItem<DropdownOption>(
            value: option,
            child: Text(
              widget.displayText?.call(option) ?? option.value,
              overflow: TextOverflow.ellipsis,
            ),
          );
        }).toList(),
      ),
    );
  }
}

/// Widget simplificado para casos comunes de dropdown
class SimpleApiDropdown extends StatelessWidget {
  final String endpoint;
  final ValueChanged<DropdownOption?> onChanged;
  final DropdownOption? value;
  final String hint;
  final String? label;
  final bool isRequired;

  const SimpleApiDropdown({
    super.key,
    required this.endpoint,
    required this.onChanged,
    this.value,
    this.hint = 'Seleccionar...',
    this.label,
    this.isRequired = false,
  });

  @override
  Widget build(BuildContext context) {
    final apiService = ApiService();

    return ApiDropdownField(
      fetchOptions: () => apiService.getDropdownOptionsPolitica(endpoint),
      onChanged: onChanged,
      value: value,
      hint: hint,
      label: label,
      isRequired: isRequired,
    );
  }
}

/// Dropdown específico para categorías
class CategoriasDropdown extends StatelessWidget {
  final ValueChanged<DropdownOption?> onChanged;
  final DropdownOption? value;
  final String? label;

  const CategoriasDropdown({
    super.key,
    required this.onChanged,
    this.value,
    this.label = 'Categoría',
  });

  @override
  Widget build(BuildContext context) {
    final apiService = ApiService();

    return ApiDropdownField(
      fetchOptions: apiService.getCategorias,
      onChanged: onChanged,
      value: value,
      hint: 'Seleccionar categoría...',
      label: label,
      icon: Icons.category,
    );
  }
}

/// Dropdown específico para políticas
class PoliticasDropdown extends StatelessWidget {
  final ValueChanged<DropdownOption?> onChanged;
  final DropdownOption? value;
  final String? label;

  const PoliticasDropdown({
    super.key,
    required this.onChanged,
    this.value,
    this.label = 'Política',
  });

  @override
  Widget build(BuildContext context) {
    final apiService = ApiService();

    return ApiDropdownField(
      fetchOptions: apiService.getPoliticas,
      onChanged: onChanged,
      value: value,
      hint: 'Seleccionar política...',
      label: label,
      icon: Icons.policy,
    );
  }
}

/// Dropdown específico para usuarios
class UsuariosDropdown extends StatelessWidget {
  final ValueChanged<DropdownOption?> onChanged;
  final DropdownOption? value;
  final String? label;

  const UsuariosDropdown({
    super.key,
    required this.onChanged,
    this.value,
    this.label = 'Usuario',
  });

  @override
  Widget build(BuildContext context) {
    final apiService = ApiService();

    return ApiDropdownField(
      fetchOptions: apiService.getUsuarios,
      onChanged: onChanged,
      value: value,
      hint: 'Seleccionar usuario...',
      label: label,
      icon: Icons.person,
    );
  }
}

/// ==================== DROPDOWNS ESPECÍFICOS DE RENDICIÓN ====================

/// Dropdown específico para políticas de rendición
class RendicionPoliticasDropdown extends StatelessWidget {
  final ValueChanged<DropdownOption?> onChanged;
  final DropdownOption? value;
  final String? label;

  const RendicionPoliticasDropdown({
    super.key,
    required this.onChanged,
    this.value,
    this.label = 'Política de rendición',
  });

  @override
  Widget build(BuildContext context) {
    final apiService = ApiService();

    return ApiDropdownField(
      fetchOptions: apiService.getRendicionPoliticas,
      onChanged: onChanged,
      value: value,
      hint: 'Seleccionar política...',
      label: label,
      icon: Icons.policy,
    );
  }
}

/// Dropdown específico para categorías de rendición (puede depender de una política)
class RendicionCategoriasDropdown extends StatelessWidget {
  final ValueChanged<DropdownOption?> onChanged;
  final DropdownOption? value;
  final String? label;

  /// NOMBRE de la política seleccionada (no ID)
  final String? politicaNombre;

  const RendicionCategoriasDropdown({
    super.key,
    required this.onChanged,
    this.value,
    this.label = 'Categoría de rendición',
    this.politicaNombre,
  });

  @override
  Widget build(BuildContext context) {
    final apiService = ApiService();

    return ApiDropdownField(
      fetchOptions: () => apiService.getRendicionCategorias(
        politica: politicaNombre ?? 'todos',
      ),
      onChanged: onChanged,
      value: value,
      hint: 'Seleccionar categoría...',
      label: label,
      icon: Icons.category,
    );
  }
}

/// Widget combinado que maneja la dependencia entre políticas y categorías de rendición
class RendicionDropdownsCombinados extends StatefulWidget {
  /// Callback cuando se selecciona una política
  final ValueChanged<DropdownOption?> onPoliticaChanged;

  /// Callback cuando se selecciona una categoría
  final ValueChanged<DropdownOption?> onCategoriaChanged;

  /// Política seleccionada actual
  final DropdownOption? politicaSeleccionada;

  /// Categoría seleccionada actual
  final DropdownOption? categoriaSeleccionada;

  /// Si se debe mostrar el label de los campos
  final bool showLabels;

  const RendicionDropdownsCombinados({
    super.key,
    required this.onPoliticaChanged,
    required this.onCategoriaChanged,
    this.politicaSeleccionada,
    this.categoriaSeleccionada,
    this.showLabels = true,
  });

  @override
  State<RendicionDropdownsCombinados> createState() =>
      _RendicionDropdownsCombinadosState();
}

class _RendicionDropdownsCombinadosState
    extends State<RendicionDropdownsCombinados> {
  /// Key para forzar la recarga del dropdown de categorías
  int _categoriasKey = 0;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Dropdown de políticas
        RendicionPoliticasDropdown(
          value: widget.politicaSeleccionada,
          onChanged: (politica) {
            // Limpiar categoría seleccionada cuando cambie la política
            widget.onCategoriaChanged(null);

            // Notificar cambio de política
            widget.onPoliticaChanged(politica);

            // Forzar recarga del dropdown de categorías
            setState(() {
              _categoriasKey++;
            });
          },
          label: widget.showLabels ? 'Política de rendición' : null,
        ),

        const SizedBox(height: 16),

        // Dropdown de categorías (dependiente de la política)
        RendicionCategoriasDropdown(
          key: ValueKey(_categoriasKey),
          value: widget.categoriaSeleccionada,
          onChanged: widget.onCategoriaChanged,
          politicaNombre: widget.politicaSeleccionada?.value,
          label: widget.showLabels ? 'Categoría de rendición' : null,
        ),
      ],
    );
  }
}
