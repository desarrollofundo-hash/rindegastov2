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
    final size = MediaQuery.of(context).size;
    final isSmallScreen = size.width < 360;
    final isLargeScreen = size.width >= 480;

    // Valores responsivos
    final dialogPadding = isSmallScreen
        ? 16.0
        : isLargeScreen
        ? 32.0
        : 24.0;
    final titleFontSize = isSmallScreen
        ? 18.0
        : isLargeScreen
        ? 24.0
        : 20.0;
    final subtitleFontSize = isSmallScreen
        ? 12.0
        : isLargeScreen
        ? 15.0
        : 14.0;
    final dropdownFontSize = isSmallScreen
        ? 14.0
        : isLargeScreen
        ? 17.0
        : 16.0;
    final buttonFontSize = isSmallScreen
        ? 14.0
        : isLargeScreen
        ? 17.0
        : 16.0;
    final spacingSmall = isSmallScreen ? 6.0 : 8.0;
    final spacingMedium = isSmallScreen ? 10.0 : 14.0;
    final spacingLarge = isSmallScreen
        ? 16.0
        : isLargeScreen
        ? 32.0
        : 24.0;
    final borderRadius = isSmallScreen ? 16.0 : 20.0;

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      insetPadding: EdgeInsets.symmetric(
        horizontal: isSmallScreen ? 12 : 20,
        vertical: isSmallScreen ? 24 : 40,
      ),
      child: Container(
        padding: EdgeInsets.all(dialogPadding),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(borderRadius),
          gradient: Theme.of(context).brightness == Brightness.dark
              ? LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Theme.of(context).cardColor,
                    Theme.of(context).scaffoldBackgroundColor,
                  ],
                )
              : LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Colors.blue.shade50, Colors.white],
                ),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Icono y título
              Text(
                '¡Bienvenido ${widget.userName} 👋!',
                style: TextStyle(
                  fontSize: titleFontSize,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Theme.of(context).textTheme.headlineSmall?.color
                      : Colors.black87,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              SizedBox(height: spacingSmall),

              Text(
                'Selecciona la empresa con la que vas a trabajar',
                style: TextStyle(
                  fontSize: subtitleFontSize,
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Theme.of(
                          context,
                        ).textTheme.bodyMedium?.color?.withOpacity(0.7)
                      : Colors.grey.shade600,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              SizedBox(height: spacingMedium),

              // Lista desplegable de empresas o estados de carga/error
              if (isLoading)
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(isSmallScreen ? 16 : 20),
                  child: Column(
                    children: [
                      SizedBox(
                        height: 35,
                        width: 35,
                        child: CircularProgressIndicator(
                          strokeWidth: isSmallScreen ? 2 : 2.5,
                        ),
                      ),
                      SizedBox(height: spacingMedium),
                      Text(
                        'Cargando empresas...',
                        style: TextStyle(
                          color: Theme.of(context).brightness == Brightness.dark
                              ? Theme.of(context).textTheme.bodyMedium?.color
                              : Colors.grey,
                          fontSize: subtitleFontSize,
                        ),
                      ),
                    ],
                  ),
                )
              else if (errorMessage != null)
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.red.shade900.withOpacity(0.3)
                        : Colors.red.shade50,
                    border: Border.all(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.red.shade700
                          : Colors.red.shade200,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        Icons.error,
                        color: Colors.red.shade600,
                        size: isSmallScreen ? 28 : 32,
                      ),
                      SizedBox(height: spacingSmall),
                      Text(
                        errorMessage!,
                        style: TextStyle(
                          color: Theme.of(context).brightness == Brightness.dark
                              ? Colors.red.shade300
                              : Colors.red.shade700,
                          fontSize: subtitleFontSize,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: spacingMedium),
                      ElevatedButton.icon(
                        onPressed: _loadUserCompanies,
                        icon: const Icon(Icons.refresh, size: 18),
                        label: Text(
                          'Reintentar',
                          style: TextStyle(fontSize: subtitleFontSize),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red.shade600,
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(
                            horizontal: isSmallScreen ? 16 : 20,
                            vertical: isSmallScreen ? 8 : 10,
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              else if (userCompanies.isEmpty)
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.orange.shade900.withOpacity(0.3)
                        : Colors.orange.shade50,
                    border: Border.all(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.orange.shade700
                          : Colors.orange.shade200,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        Icons.business_outlined,
                        color: Colors.orange.shade600,
                        size: isSmallScreen ? 28 : 32,
                      ),
                      SizedBox(height: spacingSmall),
                      Text(
                        'No tienes empresas asignadas',
                        style: TextStyle(
                          color: Theme.of(context).brightness == Brightness.dark
                              ? Colors.orange.shade300
                              : Colors.orange.shade700,
                          fontSize: subtitleFontSize,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                )
              else
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.symmetric(
                    horizontal: isSmallScreen ? 12 : 16,
                    vertical: isSmallScreen ? 2 : 4,
                  ),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Theme.of(context).dividerColor
                          : Colors.grey.shade300,
                    ),
                    borderRadius: BorderRadius.circular(12),
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Theme.of(context).cardColor
                        : Colors.white,
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      dropdownColor:
                          Theme.of(context).brightness == Brightness.dark
                          ? Theme.of(context).cardColor
                          : Colors.white,
                      value: selectedCompany,
                      hint: Text(
                        'Seleccione una empresa',
                        style: TextStyle(
                          color: Theme.of(context).brightness == Brightness.dark
                              ? Theme.of(context).hintColor
                              : Colors.grey.shade600,
                          fontSize: dropdownFontSize,
                        ),
                      ),
                      isExpanded: true,
                      icon: Icon(
                        Icons.arrow_drop_down,
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Theme.of(context).primaryColor
                            : Colors.blue.shade700,
                        size: isSmallScreen ? 24 : 28,
                      ),
                      style: TextStyle(
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Theme.of(context).textTheme.bodyMedium?.color
                            : Colors.black87,
                        fontSize: dropdownFontSize,
                      ),
                      items: userCompanies.map((company) {
                        return DropdownMenuItem<String>(
                          value: company.id.toString(),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                company.empresa,
                                style: TextStyle(
                                  fontSize: dropdownFontSize - 1,
                                  fontWeight: FontWeight.w500,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                company.ruc,
                                style: TextStyle(
                                  fontSize: isSmallScreen ? 9 : 10,
                                  fontWeight: FontWeight.w500,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
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
              SizedBox(height: spacingLarge),

              // Botones - Responsive
              if (isSmallScreen)
                Column(
                  children: [
                    SizedBox(
                      width: double.infinity,
                      child: TextButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.symmetric(
                            vertical: 12,
                            horizontal: 16,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                            side: BorderSide(
                              color:
                                  Theme.of(context).brightness ==
                                      Brightness.dark
                                  ? Theme.of(context).dividerColor
                                  : Colors.grey.shade300,
                            ),
                          ),
                        ),
                        child: Text(
                          'Cancelar',
                          style: TextStyle(
                            color:
                                Theme.of(context).brightness == Brightness.dark
                                ? Theme.of(context).textTheme.bodyMedium?.color
                                : Colors.grey.shade600,
                            fontSize: buttonFontSize,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
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
                              ? (Theme.of(context).brightness == Brightness.dark
                                    ? Colors.blue.shade600
                                    : Colors.blue.shade700)
                              : (Theme.of(context).brightness == Brightness.dark
                                    ? Colors.grey.shade700
                                    : Colors.grey.shade300),
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: Text(
                          isLoading
                              ? 'Cargando...'
                              : userCompanies.isEmpty && !isLoading
                              ? 'Sin empresas'
                              : 'Continuar',
                          style: TextStyle(
                            fontSize: buttonFontSize,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                )
              else
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                            side: BorderSide(
                              color:
                                  Theme.of(context).brightness ==
                                      Brightness.dark
                                  ? Theme.of(context).dividerColor
                                  : Colors.grey.shade300,
                            ),
                          ),
                        ),
                        child: Text(
                          'Cancelar',
                          style: TextStyle(
                            color:
                                Theme.of(context).brightness == Brightness.dark
                                ? Theme.of(context).textTheme.bodyMedium?.color
                                : Colors.grey.shade600,
                            fontSize: buttonFontSize,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 16),
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
                              ? (Theme.of(context).brightness == Brightness.dark
                                    ? Colors.blue.shade600
                                    : Colors.blue.shade700)
                              : (Theme.of(context).brightness == Brightness.dark
                                    ? Colors.grey.shade700
                                    : Colors.grey.shade300),
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: Text(
                          isLoading
                              ? 'Cargando...'
                              : userCompanies.isEmpty && !isLoading
                              ? 'Sin empresas'
                              : 'Continuar',
                          style: TextStyle(
                            fontSize: buttonFontSize,
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
      ),
    );
  }
}
