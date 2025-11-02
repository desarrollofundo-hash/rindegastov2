import 'package:flu2/models/reporte_auditioria_model.dart';
import 'package:flu2/models/reporte_revision_model.dart';
import 'package:flu2/widgets/auditoria_list.dart';
import 'package:flu2/widgets/informes_auditoria_list.dart';
import 'package:flu2/widgets/informes_revision_list.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import 'package:flutter/material.dart';
import 'package:flu2/app/app.dart';
import '../widgets/nuevo_informe_fab.dart';
import '../widgets/custom_app_bar.dart';
import '../widgets/profile_modal.dart';
import '../widgets/informes_reporte_list.dart';
import '../widgets/reportes_list.dart';
import '../widgets/edit_reporte_modal.dart';
import '../widgets/nuevo_informe_modal.dart';
import '../widgets/tabbed_screen.dart';
import '../models/gasto_model.dart';
import '../models/reporte_informe_model.dart';
import '../services/api_service.dart';
import '../services/user_service.dart';
import '../services/company_service.dart';
import '../models/reporte_model.dart';
import './informes/detalle_informe_screen.dart';
import '../widgets/informes_revision_list.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with RouteAware {
  int _selectedIndex = 0;
  int _notificaciones = 5;
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  // Variables para API
  final ApiService _apiService = ApiService();
  List<Reporte> _reportes = [];
  List<Reporte> _allReportes = [];
  bool _isLoading = false;

  // Datos para informes y revisión
  List<ReporteInforme> _informes = [];
  List<ReporteInforme> _allInformes = [];
  final List<Gasto> gastosRecepcion = [];

  // Datos para auditoria
  List<ReporteAuditoria> _auditoria = [];
  // Este campo guarda el backup de auditoría (se usa para resetear búsquedas).
  // Está definido intencionalmente aunque actualmente no se lea en todas partes.
  // ignore: unused_field
  List<ReporteAuditoria> _allAuditoria = [];
  // Overlay para el FAB independiente de la barra inferior

  List<ReporteRevision> _revision = [];
  List<ReporteRevision> _allRevision = [];

  OverlayEntry? _fabOverlay;

  @override
  void initState() {
    super.initState();
    // Sólo cargar datos si hay usuario y empresa seleccionada. Evita
    // peticiones con parámetros vacíos (que pueden causar 400 Bad Request)
    if (UserService().isLoggedIn && CompanyService().isLoggedIn) {
      _loadReportes();
      _loadInformes();
      loadAuditoria();
      _loadRevision();
    }

    // Escuchar cambios en la empresa seleccionada para refrescar la pantalla
    CompanyService().addListener(_onCompanyChanged);

    // Insertar el FAB en overlay según el índice actual después del primer frame
    WidgetsBinding.instance.addPostFrameCallback((_) => _updateFabOverlay());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (route != null) {
      routeObserver.subscribe(this, route);
    }
  }

  @override
  void didPushNext() {
    // Se abrió una nueva ruta encima (por ejemplo un modal): ocultar el FAB overlay
    _removeFabOverlay();
  }

  @override
  void didPopNext() {
    // Volvimos a esta ruta tras cerrar la que estaba encima: restaurar el FAB si aplica
    WidgetsBinding.instance.addPostFrameCallback((_) => _updateFabOverlay());
  }

  @override
  void dispose() {
    // Remover overlay si está presente
    _removeFabOverlay();

    // Cancelar suscripción al RouteObserver
    try {
      routeObserver.unsubscribe(this);
    } catch (_) {}

    _apiService.dispose();
    CompanyService().removeListener(_onCompanyChanged);
    super.dispose();
  }

  void _onCompanyChanged() {
    // Cuando la empresa cambia, recargamos los datos que dependen del RUC
    if (!mounted) return;
    // Limpiar y quitar foco del buscador para que el cursor no aparezca ahí
    _searchController.clear();
    _searchFocusNode.unfocus();

    // Evitar recargar si no hay usuario o empresa (por ejemplo después de logout)
    if (UserService().isLoggedIn && CompanyService().isLoggedIn) {
      _loadReportes();
      _loadInformes();
      loadAuditoria();
      _loadRevision();
    } else {
      // Si no hay sesión, limpiar listas y forzar rebuild
      setState(() {
        _reportes = [];
        _allReportes = [];
        _informes = [];
        _allInformes = [];
        _auditoria = [];
        _allAuditoria = [];
        _revision = [];
        _allRevision = [];
        _isLoading = false;
      });
      return;
    }
    // También forzamos rebuild por si hay textos que muestran el nombre de la empresa
    setState(() {});
  }

  // ========== MÉTODOS API ==========

  Future<void> _loadReportes() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final reportes = await _apiService.getReportesRendicionGasto(
        id: '1',
        idrend: '1',
        user: UserService().currentUserCode,
        ruc: CompanyService().companyRuc,
      );
      if (!mounted) return;

      setState(() {
        _reportes = reportes;
        _allReportes = List.from(reportes);
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      // Mostrar error en SnackBar
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cargar reportes: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
            action: SnackBarAction(
              label: 'Reintentar',
              textColor: Colors.white,
              onPressed: _loadReportes,
            ),
          ),
        );
      }
    }
  }

  Future<void> _loadInformes() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final informes = await _apiService.getReportesRendicionInforme(
        id: '1',
        idrend: '1',
        user: UserService().currentUserCode,
        ruc: CompanyService().companyRuc,
      );
      if (!mounted) return;

      setState(() {
        _informes = informes;
        _allInformes = List.from(informes);
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      // Mostrar error en SnackBar
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cargar informes: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
            action: SnackBarAction(
              label: 'Reintentar',
              textColor: Colors.white,
              onPressed: _loadInformes,
            ),
          ),
        );
      }
    }
  }

  Future<void> loadAuditoria() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
    });

    // DEBUG: confirmar que el pull-to-refresh dispara la carga

    try {
      final auditoria = await _apiService.getReportesRendicionAuditoria(
        id: '1',
        idad: '1',
        user: UserService().currentUserCode,
        ruc: CompanyService().companyRuc,
      );
      if (!mounted) return;

      setState(() {
        _auditoria = auditoria;
        _allAuditoria = List.from(auditoria);
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      // Mostrar error en SnackBar
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cargar auditoria: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
            action: SnackBarAction(
              label: 'Reintentar',
              textColor: Colors.white,
              onPressed: loadAuditoria,
            ),
          ),
        );
      }
    }
  }

  Future<void> _loadRevision() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final revision = await _apiService.getReportesRendicionAuditoria(
        id: '1',
        idad: '1',
        user: UserService().currentUserCode,
        ruc: CompanyService().companyRuc,
      );
      if (!mounted) return;
      /* 
      setState(() {
        _revision = _auditoria;
        _allRevision = List.from(revision);
        _isLoading = false;
      }); */
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      // Mostrar error en SnackBar
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cargar revisión: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
            action: SnackBarAction(
              label: 'Reintentar',
              textColor: Colors.white,
              onPressed: _loadRevision,
            ),
          ),
        );
      }
    }
  }
  // ========== MÉTODOS REUTILIZABLES ==========

  void _mostrarEditarPerfil(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) => const ProfileModal(),
    );
  }

  void _decrementarNotificaciones() {
    setState(() {
      if (_notificaciones > 0) _notificaciones--;
    });
  }

  void _actualizarInforme(ReporteInforme informeActualizado) {
    setState(() {
      final index = _informes.indexWhere(
        (i) => i.idInf == informeActualizado.idInf,
      );
      if (index != -1) {
        _informes[index] = informeActualizado;
      }
    });
  }

  void _actualizarAuditoria(ReporteAuditoria auditoriaModel) {
    setState(() {
      final index = _informes.indexWhere(
        (i) => i.idInf == auditoriaModel.idInf,
      );
      if (index != -1) {
        _auditoria[index] = auditoriaModel;
      }
    });
  }

  void _eliminarInforme(ReporteInforme informe) {
    setState(() {
      _informes.remove(informe);
    });
  }

  void _eliminarAuditoria(ReporteAuditoria auditoria) {
    setState(() {
      _auditoria.remove(auditoria);
    });
  }

  void _actualizarRevision(ReporteRevision revisionModel) {
    setState(() {
      final index = _revision.indexWhere((i) => i.idAd == revisionModel.idAd);
      if (index != -1) {
        _revision[index] = revisionModel;
      }
    });
  }

  void _eliminarRevision(ReporteRevision revision) {
    setState(() {
      _revision.remove(revision);
    });
  }

  void _mostrarEditarReporte(Reporte reporte) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) => EditReporteModal(reporte: reporte),
    );
  }

  // ========== PANTALLAS REFACTORIZADAS ==========

  Widget _buildPantallaInicio() {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        appBar: CustomAppBar(
          hintText: "Buscar Reportes...",
          onProfilePressed: () => _mostrarEditarPerfil(context),
          notificationCount: _notificaciones,
          onNotificationPressed: _decrementarNotificaciones,
          onSearch: _handleSearchReportes,
          controller: _searchController,
          focusNode: _searchFocusNode,
        ),
        body: ReportesList(
          reportes: _reportes,
          onRefresh: _loadReportes,
          isLoading: _isLoading,
          onTap: _mostrarEditarReporte,
        ),
      ),
    );
  }

  Widget _buildPantallaInformes() {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: Colors.white,

        appBar: CustomAppBar(
          hintText: "Buscar Informes...",
          onProfilePressed: () => _mostrarEditarPerfil(context),
          notificationCount: _notificaciones,
          onNotificationPressed: _decrementarNotificaciones,
          onSearch: _handleSearchInformes,
          controller: _searchController,
          focusNode: _searchFocusNode,
        ),
        body: TabbedScreen(
          tabLabels: const ["Todos", "Borrador"],
          tabColors: const [Colors.indigo, Colors.indigo],
          tabViews: [
            InformesReporteList(
              informes: _informes,
              informe: [],
              onInformeUpdated: _actualizarInforme,
              onInformeDeleted: _eliminarInforme,
              showEmptyStateButton: true,
              onEmptyStateButtonPressed: _agregarInforme,
              onRefresh: _loadInformes,
            ),
            InformesReporteList(
              informes: _informes.where((i) => i.estado == "Borrador").toList(),
              informe: [],
              onInformeUpdated: _actualizarInforme,
              onInformeDeleted: _eliminarInforme,
              showEmptyStateButton: false,
              onRefresh: _loadInformes,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPantallaAditoria() {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: Colors.white,

        appBar: CustomAppBar(
          hintText: "Buscar en Auditoría...",
          onProfilePressed: () => _mostrarEditarPerfil(context),
          notificationCount: _notificaciones,
          onNotificationPressed: _decrementarNotificaciones,
          onSearch: _handleSearchAuditoria,
          controller: _searchController,
          focusNode: _searchFocusNode,
        ),
        body: TabbedScreen(
          tabLabels: const ["Todos"],
          tabColors: const [Colors.green],
          tabViews: [
            InformesAuditoriaList(
              auditorias: _auditoria,
              auditoria: [],
              onAuditoriaUpdated: _actualizarAuditoria,
              onAuditoriaDeleted: _eliminarAuditoria,
              showEmptyStateButton: false,
              onRefresh: loadAuditoria,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPantallaRevision() {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: Colors.white,

        appBar: CustomAppBar(
          hintText: "Buscar en Revisión...",
          onProfilePressed: () => _mostrarEditarPerfil(context),
          notificationCount: _notificaciones,
          onNotificationPressed: _decrementarNotificaciones,
          onSearch: _handleSearchRevision,
          controller: _searchController,
          focusNode: _searchFocusNode,
        ),
        body: TabbedScreen(
          tabLabels: const ["Todos"],
          tabColors: const [Colors.green],
          tabViews: [
            InformesRevisionList(
              revisio: _revision,
              revision: [],
              onRevisionUpdated: _actualizarRevision,
              onRevisionDeleted: _eliminarRevision,
              showEmptyStateButton: false,
              onRefresh: _loadRevision,
            ),
          ],
        ),
      ),
    );
  }

  void _handleSearchReportes(String query) {
    if (query.trim().isEmpty) {
      setState(() {
        _reportes = List.from(_allReportes);
      });
      return;
    }

    final q = query.toLowerCase();

    setState(() {
      _reportes = _allReportes.where((r) {
        final ruc = (r.ruc ?? '').toLowerCase();
        final categoria = (r.categoria ?? '').toLowerCase();
        final monto = (r.total?.toString() ?? '').toLowerCase();
        final rucCliente = (r.ruccliente ?? '').toLowerCase();
        final politica = (r.politica ?? '').toLowerCase();
        // Para estado en Reporte usamos 'obs' o 'destino' si aplica
        final estado = (r.obs ?? r.destino ?? '').toLowerCase();

        return ruc.contains(q) ||
            categoria.contains(q) ||
            monto.contains(q) ||
            rucCliente.contains(q) ||
            politica.contains(q) ||
            estado.contains(q);
      }).toList();
    });
  }

  void _handleSearchInformes(String query) {
    if (query.trim().isEmpty) {
      setState(() {
        _informes = List.from(_allInformes);
      });
      return;
    }

    final q = query.toLowerCase();

    setState(() {
      _informes = _allInformes.where((inf) {
        final titulo = (inf.titulo ?? '').toLowerCase();
        final nota = (inf.nota ?? '').toLowerCase();
        final cantidad = inf.cantidad.toString().toLowerCase();
        final total = inf.total.toString().toLowerCase();
        final categoria = (inf.politica ?? '').toLowerCase();
        final estado = (inf.estadoActual ?? inf.estado ?? '').toLowerCase();

        return titulo.contains(q) ||
            nota.contains(q) ||
            cantidad.contains(q) ||
            total.contains(q) ||
            categoria.contains(q) ||
            estado.contains(q);
      }).toList();
    });
  }

  void _handleSearchAuditoria(String query) {
    if (query.trim().isEmpty) {
      setState(() {
        _informes = List.from(_allInformes);
      });
      return;
    }

    final q = query.toLowerCase();

    setState(() {
      _informes = _allInformes.where((inf) {
        final titulo = (inf.titulo ?? '').toLowerCase();
        final nota = (inf.nota ?? '').toLowerCase();
        final cantidad = inf.cantidad.toString().toLowerCase();
        final total = inf.total.toString().toLowerCase();
        final categoria = (inf.politica ?? '').toLowerCase();
        final estado = (inf.estadoActual ?? inf.estado ?? '').toLowerCase();

        return titulo.contains(q) ||
            nota.contains(q) ||
            cantidad.contains(q) ||
            total.contains(q) ||
            categoria.contains(q) ||
            estado.contains(q);
      }).toList();
    });
  }

  void _handleSearchRevision(String query) {
    if (query.trim().isEmpty) {
      setState(() {
        _informes = List.from(_allInformes);
      });
      return;
    }

    final q = query.toLowerCase();

    setState(() {
      _informes = _allInformes.where((inf) {
        final titulo = (inf.titulo ?? '').toLowerCase();
        final nota = (inf.nota ?? '').toLowerCase();
        final cantidad = inf.cantidad.toString().toLowerCase();
        final total = inf.total.toString().toLowerCase();
        final categoria = (inf.politica ?? '').toLowerCase();
        final estado = (inf.estadoActual ?? inf.estado ?? '').toLowerCase();

        return titulo.contains(q) ||
            nota.contains(q) ||
            cantidad.contains(q) ||
            total.contains(q) ||
            categoria.contains(q) ||
            estado.contains(q);
      }).toList();
    });
  }

  // ========== MÉTODOS DE INFORMES ==========

  Future<void> _agregarInforme() async {
    // Ocultar el FAB overlay antes de abrir el modal para evitar que quede visible
    _removeFabOverlay();

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(5)),
      ),
      builder: (BuildContext context) => NuevoInformeModal(
        onInformeCreated: (nuevoInforme) {
          // Después de crear el informe, recargamos la lista
          _loadInformes();
        },
        onCancel: () {
          Navigator.of(context).pop();
        },
      ),
    );

    // Restaurar el FAB en overlay si seguimos en la pestaña Informes
    WidgetsBinding.instance.addPostFrameCallback((_) => _updateFabOverlay());
  }

  // ===== Overlay FAB helpers =====
  OverlayEntry _createFabOverlay() {
    return OverlayEntry(
      builder: (context) {
        // Calcular offset para que el FAB quede por encima de la barra inferior
        final double safeBottom = MediaQuery.of(context).viewPadding.bottom;
        // Altura estimada de la barra inferior (NavigationBarTheme height = 16)
        const double bottomNavHeight = 56.0;
        // Margen extra entre la barra y el FAB (aumentado para subir el botón)
        const double extraMargin = 20.0;

        final double bottomOffset = safeBottom + bottomNavHeight + extraMargin;

        return Positioned(
          right: 10,
          bottom: bottomOffset,
          child: SafeArea(child: NuevoInformeFab(onPressed: _agregarInforme)),
        );
      },
    );
  }

  void _insertFabOverlay() {
    if (_fabOverlay != null) return;
    _fabOverlay = _createFabOverlay();
    final overlay = Overlay.of(context);
    overlay.insert(_fabOverlay!);
  }

  void _removeFabOverlay() {
    _fabOverlay?.remove();
    _fabOverlay = null;
  }

  void _updateFabOverlay() {
    if (!mounted) return;
    if (_selectedIndex == 1) {
      _insertFabOverlay();
    } else {
      _removeFabOverlay();
    }
  }

  // ========== BUILD PRINCIPAL ACTUALIZADO ==========
  /* 
  @override
  Widget build(BuildContext context) {
    final List<Widget> pages = [
      _buildPantallaInicio(), // 0 - Gastos
      _buildPantallaInformes(), // 1 - Informes
      _buildPantallaAditoria(), // 2 - Auditoría
      _buildPantallaRevision(), // 3 - Revisión
    ];

    return Scaffold(
      body: pages[_selectedIndex],
      // FAB moved to OverlayEntry to remain independent from bottomNavigationBar

      /// 🌈 Fondo degradado + barra de navegación
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFF1565C0), // azul medio
              Color(0xFF0D47A1), // azul oscuro
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 10,
              offset: Offset(0, -2),
            ),
          ],
        ),
        child: NavigationBar(
          backgroundColor:
              Colors.blueAccent, // 👈 importante para ver el degradado
          indicatorColor: Colors.white.withOpacity(0.2), // color del resaltado
          selectedIndex: _selectedIndex,
          onDestinationSelected: (index) {
            setState(() => _selectedIndex = index.clamp(0, pages.length - 1));
          },
          destinations: [
            _animatedIcon(Icons.monetization_on, "Gastos", 0),
            _animatedIcon(Icons.description, "Informes", 1),
            _animatedIcon(Icons.assignment_turned_in_outlined, "Auditoría", 2),
            _animatedIcon(Icons.inbox, "Revisión", 3),
          ],
        ),
      ),
    );
  }

  /// ✨ Ícono animado con rotación y zoom
  NavigationDestination _animatedIcon(IconData icon, String label, int index) {
    bool isSelected = _selectedIndex == index;

    return NavigationDestination(
      icon: AnimatedRotation(
        duration: const Duration(milliseconds: 400),
        turns: isSelected ? 1 / 24 : 0, // pequeño giro
        curve: Curves.easeOutBack,
        child: AnimatedScale(
          scale: isSelected ? 1.3 : 1.0, // efecto de zoom
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
          child: Icon(
            icon,
            color: isSelected
                ? Colors.white
                : Colors.white, // colores sobre fondo azul
            size: 28,
          ),
        ),
      ),
      label: label,
    );
  } */

  @override
  Widget build(BuildContext context) {
    final List<Widget> pages = [
      _buildPantallaInicio(), // 0 - Gastos
      _buildPantallaInformes(), // 1 - Informes
      _buildPantallaAditoria(), // 2 - Auditoría
      _buildPantallaRevision(), // 3 - Revisión
    ];

    return Scaffold(
      backgroundColor: Colors.white,
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: pages[_selectedIndex],
      ),

      // FAB moved to an OverlayEntry so it stays independent from the bottom bar

      // 🧊 Barra inferior flotante moderna
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.only(left: 7, right: 7, bottom: 1),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 400),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 15,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(30),
            child: NavigationBarTheme(
              data: NavigationBarThemeData(
                height: 70,
                indicatorColor: Colors.white.withOpacity(0.3),
                backgroundColor: Colors.transparent,
                labelTextStyle: WidgetStateProperty.resolveWith<TextStyle>((
                  states,
                ) {
                  return TextStyle(
                    color: states.contains(WidgetState.selected)
                        ? const Color(0xFF1565C0)
                        : Colors.grey.shade700,
                    fontWeight: states.contains(WidgetState.selected)
                        ? FontWeight.bold
                        : FontWeight.w500,
                  );
                }),
              ),
              child: NavigationBar(
                elevation: 0,
                selectedIndex: _selectedIndex,
                onDestinationSelected: (index) async {
                  // Limpiar campo de búsqueda al cambiar de pestaña
                  _searchController.clear();
                  _searchFocusNode.unfocus();

                  setState(() {
                    _selectedIndex = index.clamp(0, pages.length - 1);
                  });

                  // 🔁 Recargar la data correspondiente a la pestaña seleccionada
                  switch (index) {
                    case 0:
                      await _loadReportes();
                      break;
                    case 1:
                      await _loadInformes();
                      break;
                    case 2:
                      await loadAuditoria();
                      break;
                    case 3:
                      await _loadRevision();
                      break;
                  }

                  // Actualizar el FAB overlay después del frame
                  WidgetsBinding.instance.addPostFrameCallback(
                    (_) => _updateFabOverlay(),
                  );
                },

                destinations: [
                  _animatedIcon(MdiIcons.cashMultiple, "Gastos", 0),
                  _animatedIcon(Feather.file_text, "Informes", 1),
                  _animatedIcon(MdiIcons.shieldCheckOutline, "Auditoría", 2),
                  _animatedIcon(Feather.inbox, "Revisión", 3),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// 🎨 Ícono animado tipo Material con efecto de rebote
  NavigationDestination _animatedIcon(IconData icon, String label, int index) {
    bool isSelected = _selectedIndex == index;

    return NavigationDestination(
      icon: AnimatedRotation(
        turns: isSelected ? 1 : 0,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOutBack,
        child: AnimatedScale(
          duration: const Duration(milliseconds: 300),
          scale: isSelected ? 1.2 : 1.0,
          curve: Curves.easeOutBack,
          child: Icon(
            icon,
            size: 26,
            color: isSelected ? const Color(0xFF1565C0) : Colors.grey.shade600,
          ),
        ),
      ),
      label: label,
    );
  }
}
