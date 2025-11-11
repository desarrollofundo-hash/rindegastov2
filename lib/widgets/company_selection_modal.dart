import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../screens/home_screen.dart';
import '../services/api_service.dart';
import '../services/company_service.dart';
import '../models/user_company.dart';

class CompanySelectionModal extends StatefulWidget {
  final String userName;
  final int userId; // Agregar userId para la API
  final bool shouldNavigateToHome;

  const CompanySelectionModal({
    super.key,
    required this.userName,
    required this.userId,
    this.shouldNavigateToHome = true,
  });

  @override
  State<CompanySelectionModal> createState() => _CompanySelectionModalState();
}

class _CompanySelectionModalState extends State<CompanySelectionModal> {
  String? selectedCompany;
  List<UserCompany> userCompanies = [];
  final ApiService _apiService = ApiService();
  bool isLoading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    _loadUserCompanies();
  }

  /// Cargar empresas del usuario desde la API
  Future<void> _loadUserCompanies() async {
    try {
      if (mounted) {
        setState(() {
          isLoading = true;
          errorMessage = null;
        });
      }

      final companiesData = await _apiService.getUserCompanies(widget.userId);

      if (companiesData.isEmpty) {
        if (mounted) {
          setState(() {
            errorMessage = 'No se encontraron empresas asociadas al usuario';
            isLoading = false;
          });
        }
        return;
      }

      final companies = companiesData
          .map((json) => UserCompany.fromJson(json))
          .toList();

      if (mounted) {
        setState(() {
          userCompanies = companies;
          isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          errorMessage = 'Error al cargar empresas: $e';
          isLoading = false;
        });
      }
    }
  }

  void _continueToHome() {
    if (selectedCompany != null) {
      // Buscar la empresa seleccionada
      final selectedUserCompany = userCompanies.firstWhere(
        (company) => company.id.toString() == selectedCompany,
      );

      // 🏢 GUARDAR LA EMPRESA SELECCIONADA EN EL SERVICIO
      CompanyService().setCurrentCompany(selectedUserCompany);

      // Quitar foco de cualquier TextField antes de cerrar modales
      FocusScope.of(context).unfocus();

      // Cerrar el modal de selección de empresa
      Navigator.of(context).pop();

      // Si el modal fue abierto desde el flujo de login -> navegar a Home
      if (widget.shouldNavigateToHome) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const HomeScreen()),
        );
      } else {
        // Si fue abierto desde el perfil (shouldNavigateToHome == false),
        // cerramos también el modal del perfil (bottom sheet) para volver
        // a la pantalla principal y permitir que HomeScreen escuche el
        // cambio de empresa y se refresque.
        // Hacemos un pop adicional si es posible.
        if (Navigator.of(context).canPop()) {
          try {
            FocusScope.of(context).unfocus();
            Navigator.of(context).pop();
          } catch (_) {
            // Ignorar si no se puede hacer pop adicional
          }
        }
      }

      // Mostrar mensaje de confirmación con más detalles
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Empresa: ${selectedUserCompany.empresa}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              if (selectedUserCompany.sucursal.isNotEmpty)
                Text(
                  'Sucursal: ${selectedUserCompany.sucursal}',
                  style: const TextStyle(fontSize: 12),
                ),
            ],
          ),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          duration: const Duration(seconds: 4),
        ),
      );

      // Asegurar que el foco y el teclado se oculten una vez que la navegación termine
      WidgetsBinding.instance.addPostFrameCallback((_) {
        FocusManager.instance.primaryFocus?.unfocus();
        SystemChannels.textInput.invokeMethod('TextInput.hide');
      });
    }
  }

  @override
  void dispose() {
    _apiService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.blue.shade50, Colors.white],
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icono y título
            Text(
              '¡Bienvenido ${widget.userName} 👋!',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),

            Text(
              'Selecciona la empresa con la que vas a trabajar',
              style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 14),

            // Lista desplegable de empresas o estados de carga/error
            if (isLoading)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                child: const Column(
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 12),
                    Text(
                      'Cargando empresas...',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              )
            else if (errorMessage != null)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  border: Border.all(color: Colors.red.shade200),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Icon(Icons.error, color: Colors.red.shade600, size: 32),
                    const SizedBox(height: 8),
                    Text(
                      errorMessage!,
                      style: TextStyle(
                        color: Colors.red.shade700,
                        fontSize: 14,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      onPressed: _loadUserCompanies,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Reintentar'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red.shade600,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
              )
            else if (userCompanies.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  border: Border.all(color: Colors.orange.shade200),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.business_outlined,
                      color: Colors.orange.shade600,
                      size: 32,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'No tienes empresas asignadas',
                      style: TextStyle(
                        color: Colors.orange.shade700,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              )
            else
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(12),
                  color: Colors.white,
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: selectedCompany,
                    hint: Text(
                      'Seleccione una empresa',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 16,
                      ),
                    ),
                    isExpanded: true,
                    icon: Icon(
                      Icons.arrow_drop_down,
                      color: Colors.blue.shade700,
                    ),
                    style: const TextStyle(color: Colors.black87, fontSize: 16),
                    items: userCompanies.map((company) {
                      return DropdownMenuItem<String>(
                        value: company.id.toString(),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              company.empresa,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Text(
                              company.ruc,
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                    onChanged: (String? value) {
                      setState(() {
                        selectedCompany = value;
                      });
                    },
                  ),
                ),
              ),
            const SizedBox(height: 24),

            // Botones
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                        side: BorderSide(color: Colors.grey.shade300),
                      ),
                    ),
                    child: Text(
                      'Cancelar',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed:
                        (selectedCompany != null &&
                            !isLoading &&
                            userCompanies.isNotEmpty)
                        ? _continueToHome
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          (selectedCompany != null &&
                              !isLoading &&
                              userCompanies.isNotEmpty)
                          ? Colors.blue.shade700
                          : Colors.grey.shade300,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      elevation:
                          (selectedCompany != null &&
                              !isLoading &&
                              userCompanies.isNotEmpty)
                          ? 2
                          : 0,
                    ),
                    child: Text(
                      isLoading
                          ? 'Cargando...'
                          : userCompanies.isEmpty && !isLoading
                          ? 'Sin empresas'
                          : 'Continuar',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
