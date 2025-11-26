import 'package:flutter/material.dart';
import '../services/api_service.dart';

/// Modal para seleccionar política antes de mostrar la factura
class PoliticaSelectionModal extends StatefulWidget {
  final Function(String) onPoliticaSelected;
  final VoidCallback onCancel;

  const PoliticaSelectionModal({
    super.key,
    required this.onPoliticaSelected,
    required this.onCancel,
  });

  @override
  State<PoliticaSelectionModal> createState() => _PoliticaSelectionModalState();
}

class _PoliticaSelectionModalState extends State<PoliticaSelectionModal> {
  String? _selectedPolitica;
  List<String> _politicas = [];
  bool _isLoading = false;
  String? _error;
  final ApiService _apiService = ApiService();

  @override
  void initState() {
    super.initState();
    _loadPoliticas();
  }

  Future<void> _loadPoliticas() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final politicas = await _apiService.getRendicionPoliticas();
      if (!mounted) return;
      setState(() {
        _politicas = politicas.map((e) => e.value.toString()).toList();
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }
  /* 
  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.6,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle del modal
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Título
          Row(
            children: [
              Icon(
                Icons.policy,
                color: Theme.of(context).primaryColor,
                size: 28,
              ),
              const SizedBox(width: 12),
              const Text(
                'Seleccionar Política',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Selecciona la política aplicable',
            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
          ),
          const SizedBox(height: 24),

          // Dropdown de políticas desde API
          if (_isLoading) const Center(child: CircularProgressIndicator()),
          if (!_isLoading && _error != null)
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Error al cargar políticas: $_error',
                    style: TextStyle(color: Colors.red),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: _loadPoliticas,
                    child: const Text('Reintentar'),
                  ),
                ],
              ),
            ),
          if (!_isLoading && _error == null)
            DropdownButtonFormField<String>(
              dropdownColor: Colors.white,
              decoration: const InputDecoration(
                labelText: 'Seleccionar Política',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.policy),
              ),
              value: _selectedPolitica,
              items: _politicas
                  .map(
                    (politica) => DropdownMenuItem<String>(
                      value: politica,
                      child: Text(politica),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                setState(() {
                  _selectedPolitica = value;
                });
              },
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Debes seleccionar una política';
                }
                return null;
              },
            ),

          const Spacer(),

          // Botones de acción
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    side: BorderSide(color: Colors.grey[400]!),
                  ),
                  child: const Text(
                    'Cancelar',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: _selectedPolitica != null
                      ? () {
                          widget.onPoliticaSelected(_selectedPolitica!);
                        }
                      : null,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: Theme.of(context).primaryColor,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text(
                    'Continuar',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
 */

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.55,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 50),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle del modal
          Center(
            child: Container(
              width: 45,
              height: 5,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Título con mejor estilo
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.policy_outlined,
                  color: Theme.of(context).primaryColor,
                  size: 28,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Seleccionar Política',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.2,
                ),
              ),
            ],
          ),

          const SizedBox(height: 6),

          Text(
            'Elige la política aplicable para continuar.',
            style: TextStyle(fontSize: 15, color: Colors.grey[600]),
          ),

          const SizedBox(height: 24),

          // CONTENIDO
          if (_isLoading) const Center(child: CircularProgressIndicator()),

          if (!_isLoading && _error != null)
            Center(
              child: Column(
                children: [
                  Text(
                    'Error al cargar políticas',
                    style: TextStyle(color: Colors.red[700], fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  Text(_error!, style: TextStyle(color: Colors.red[400])),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _loadPoliticas,
                    child: const Text('Reintentar'),
                  ),
                ],
              ),
            ),

          if (!_isLoading && _error == null)
            DropdownButtonFormField<String>(
              dropdownColor: Colors.white,
              decoration: InputDecoration(
                labelText: 'Seleccionar Política',
                labelStyle: TextStyle(color: Colors.grey[700]),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                prefixIcon: const Icon(Icons.policy_outlined),
              ),
              value: _selectedPolitica,
              items: _politicas
                  .map((p) => DropdownMenuItem(value: p, child: Text(p)))
                  .toList(),
              onChanged: (value) {
                setState(() => _selectedPolitica = value);
              },
            ),

          const Spacer(),

          // BOTONES DE ACCIÓN MEJORADOS
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    side: BorderSide(color: Colors.grey[350]!),
                  ),
                  child: const Text(
                    'Cancelar',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: _selectedPolitica == null
                      ? null
                      : () => widget.onPoliticaSelected(_selectedPolitica!),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    backgroundColor: Theme.of(context).primaryColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 3,
                  ),
                  child: const Text(
                    'Continuar',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.2,
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
}
