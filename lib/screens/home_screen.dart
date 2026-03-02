import 'package:flu2/models/reporte_auditioria_model.dart';
import 'package:flu2/models/reporte_revision_model.dart';
import 'package:flu2/models/rol_usuario_app_model.dart';
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

  List<RolUsuarioApp> _rolusuario = [];
  List<RolUsuarioApp> _allRolUsuario = [];

  OverlayEntry? _fabOverlay;

  @override
  void initState() {
    super.initState();
    _loadRolUsuario();
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

  Future<void> _loadRolUsuario() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final rolusuario = await _apiService.getRolUsuarioApp(
        iduser: UserService().currentUserCode,
        idapp: '12',
      );
      if (!mounted) return;

      setState(() {
        _rolusuario = rolusuario;
        _allRolUsuario = List.from(rolusuario);
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
              onPressed: _loadRolUsuario,
            ),
          ),
        );
      }
    }
  }

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
        idad: UserService().currentUserCode,
        area: CompanyService().currentUserArea,
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
      final revision = await _apiService.getReportesRendicionRevision(
        id: '1',
        idrev: '1',
        gerencia: CompanyService().currentUserGerencia,
        ruc: CompanyService().companyRuc,
      );
      if (!mounted) return;

      setState(() {
        _revision = revision;
        _allRevision = List.from(revision);
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
    _removeFabOverlay();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) => const ProfileModal(),
    ).then((_) {
      // Desactivar el focus del buscador cuando se cierra el modal
      _searchFocusNode.unfocus();
      // Restaurar el FAB después de cerrar el modal
      if (mounted) {
        WidgetsBinding.instance.addPostFrameCallback(
          (_) => _updateFabOverlay(),
        );
      }
    });
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
      final index = _revision.indexWhere((i) => i.idRev == revisionModel.idRev);
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    _removeFabOverlay();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? Colors.grey[900] : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) => EditReporteModal(
        reporte: reporte,
        onSave: (reporteActualizado) {
          // ✅ Recargar los reportes después de guardar
          _loadReportes();
        },
      ),
    ).then((_) {
      // Desactivar el focus del buscador cuando se cierra el modal
      _searchFocusNode.unfocus();
      // Restaurar el FAB después de cerrar el modal
      if (mounted) {
        WidgetsBinding.instance.addPostFrameCallback(
          (_) => _updateFabOverlay(),
        );
      }
    });
  }

  // ========== PANTALLAS REFACTORIZADAS ==========

  Widget _buildPantallaInicio() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: isDark ? Colors.grey[900] : Colors.white,
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: isDark ? Colors.grey[900] : Colors.white,

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
          tabLabels: const ["Todos", "Aprobado", "Rechazado"],
          /* tabColors: const [Colors.indigo, Colors.indigo], */
          tabColors: Theme.of(context).brightness == Brightness.dark
              ? [Colors.white, Colors.white] // modo oscuro → letras claras
              : [Colors.indigo, Colors.indigo], // modo claro → letras oscuras
          tabViews: [
            InformesReporteList(
              informes: _informes,
              informe: [],
              onInformeUpdated: _actualizarInforme,
              onInformeDeleted: _eliminarInforme,
              showEmptyStateButton: true,
              onEmptyStateButtonPressed: _agregarInforme,
              onRefresh: _loadInformes,
              emptyMessage: "No hay informes disponibles",
            ),
            InformesReporteList(
              informes: _informes
                  .where(
                    (a) => (a.estadoActual ?? '').toLowerCase().contains(
                      'aprobado',
                    ),
                  )
                  .toList(),
              informe: [],
              onInformeUpdated: _actualizarInforme,
              onInformeDeleted: _eliminarInforme,
              showEmptyStateButton: false,
              onRefresh: _loadInformes,
              emptyMessage: "No hay ningún reporte aprobado por el momento",
            ),
            InformesReporteList(
              informes: _informes
                  .where(
                    (a) => (a.estadoActual ?? '').toLowerCase().contains(
                      'rechazado',
                    ),
                  )
                  .toList(),
              informe: [],
              onInformeUpdated: _actualizarInforme,
              onInformeDeleted: _eliminarInforme,
              showEmptyStateButton: false,
              onRefresh: _loadInformes,
              emptyMessage: "No hay ningún informe rechazado",
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPantallaAditoria() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: isDark ? Colors.grey[900] : Colors.white,
        appBar: CustomAppBar(
          hintText: "Buscar en Auditoría...",
          onProfilePressed: () => _mostrarEditarPerfil(context),
          notificationCount: _notificaciones,
          onNotificationPressed: _decrementarNotificaciones,
          onSearch: _handleSearchAuditoria,
          controller: _searchController,
          focusNode: _searchFocusNode,
        ),

        // 🔹 TabbedScreen con 3 pestañas
        body: TabbedScreen(
          tabLabels: const ["Todos", "Pendiente", "Rechazado"],
          /*           tabColors: const [Colors.indigo, Colors.orange, Colors.red],
 */
          tabColors: Theme.of(context).brightness == Brightness.dark
              ? [Colors.white, Colors.white] // modo oscuro → letras claras
              : [Colors.indigo, Colors.indigo], // modo claro → letras oscuras
          tabViews: [
            // 🟢 TAB 1: Todos
            InformesAuditoriaList(
              auditorias: _auditoria,
              onAuditoriaUpdated: _actualizarAuditoria,
              onAuditoriaDeleted: _eliminarAuditoria,
              showEmptyStateButton: false,
              onRefresh: loadAuditoria,
              emptyMessage: "No hay ninguna auditoría disponible",
            ),

            //  TAB 2: Pendiente
            InformesAuditoriaList(
              auditorias: _auditoria
                  .where(
                    (a) => (a.estadoActual ?? '').toLowerCase().contains(
                      'en auditoria',
                    ),
                  )
                  .toList(),
              onAuditoriaUpdated: _actualizarAuditoria,
              onAuditoriaDeleted: _eliminarAuditoria,
              showEmptyStateButton: false,
              onRefresh: loadAuditoria,
              emptyMessage: "No hay ninguna auditoría pendiente",
            ),

            // 🔴 TAB 3: Rechazado
            InformesAuditoriaList(
              auditorias: _auditoria
                  .where(
                    (a) =>
                        (a.estadoActual ?? '').toLowerCase().contains('rechaz'),
                  )
                  .toList(),
              onAuditoriaUpdated: _actualizarAuditoria,
              onAuditoriaDeleted: _eliminarAuditoria,
              showEmptyStateButton: false,
              onRefresh: loadAuditoria,
              emptyMessage: "No hay ninguna auditoría rechazado",
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPantallaRevision() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: isDark ? Colors.grey[900] : Colors.white,

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
          tabLabels: const ["Todos", "Pendiente", "Aprobado"],
          /*           tabColors: const [Colors.indigo],
 */
          tabColors: Theme.of(context).brightness == Brightness.dark
              ? [Colors.white, Colors.white] // modo oscuro → letras claras
              : [Colors.indigo, Colors.indigo], // modo claro → letras oscuras
          tabViews: [
            InformesRevisionList(
              revision: _revision,
              onRevisionUpdated: _actualizarRevision,
              onRevisionDeleted: _eliminarRevision,
              showEmptyStateButton: false,
              onRefresh: _loadRevision,
              emptyMessage: "No hay ninguna revisión disponible",
            ),

            //TAB 2
            InformesRevisionList(
              revision: _revision
                  .where(
                    (a) => (a.estadoActual ?? '').toLowerCase().contains(
                      'en revision',
                    ),
                  )
                  .toList(),
              onRevisionUpdated: _actualizarRevision,
              onRevisionDeleted: _eliminarRevision,
              showEmptyStateButton: false,
              onRefresh: _loadRevision,
              emptyMessage: "No hay ninguna revisión pendiente",
            ),

            //TAB 3
            InformesRevisionList(
              revision: _revision
                  .where(
                    (a) => (a.estadoActual ?? '').toLowerCase().contains(
                      'aprobado',
                    ),
                  )
                  .toList(),
              onRevisionUpdated: _actualizarRevision,
              onRevisionDeleted: _eliminarRevision,
              showEmptyStateButton: false,
              onRefresh: _loadRevision,
              emptyMessage: "No hay ninguna revisión aprobado",
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
        final idrend = (r.idrend);
        // Para estado en Reporte usamos 'obs' o 'destino' si aplica
        final estado = (r.obs ?? r.estadoActual ?? '').toLowerCase();

        return ruc.contains(q) ||
            categoria.contains(q) ||
            monto.contains(q) ||
            rucCliente.contains(q) ||
            politica.contains(q) ||
            idrend.toString().contains(q) ||
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
        _auditoria = List.from(_allAuditoria);
      });
      return;
    }

    final q = query.toLowerCase();

    setState(() {
      _auditoria = _allAuditoria.where((aud) {
        final titulo = (aud.titulo ?? '').toLowerCase();
        final nota = (aud.nota ?? '').toLowerCase();
        final cantidad = aud.cantidad.toString().toLowerCase();
        final total = aud.total.toString().toLowerCase();
        final politica = (aud.politica ?? '').toLowerCase();
        final estado = (aud.estadoActual ?? aud.estado ?? '').toLowerCase();

        return titulo.contains(q) ||
            nota.contains(q) ||
            cantidad.contains(q) ||
            total.contains(q) ||
            politica.contains(q) ||
            estado.contains(q);
      }).toList();
    });
  }

  void _handleSearchRevision(String query) {
    if (query.trim().isEmpty) {
      setState(() {
        _revision = List.from(_allRevision);
      });
      return;
    }

    final q = query.toLowerCase();

    setState(() {
      _revision = _allRevision.where((rev) {
        final titulo = (rev.titulo ?? '').toLowerCase();
        final nota = (rev.nota ?? '').toLowerCase();
        final cantidad = rev.cantidad.toString().toLowerCase();
        final total = rev.total.toString().toLowerCase();
        final politica = (rev.politica ?? '').toLowerCase();
        final estado = (rev.estadoActual ?? rev.estado ?? '').toLowerCase();

        return titulo.contains(q) ||
            nota.contains(q) ||
            cantidad.contains(q) ||
            total.contains(q) ||
            politica.contains(q) ||
            estado.contains(q);
      }).toList();
    });
  }
  /* 
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
 */
  // ========== MÉTODOS DE INFORMES ==========
  /* 
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
 */

  Future<void> _agregarInforme() async {
    // ✅ Remover FAB INMEDIATAMENTE antes de abrir el modal
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
          if (mounted) {
            _loadInformes();
          }
        },
        onCancel: () {
          Navigator.of(context).pop();
        },
      ),
    );
    // Restaurar el FAB después de cerrar el modal
    if (mounted) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _updateFabOverlay());
    }
  }

  // ===== Overlay FAB helpers =====
  /*   OverlayEntry _createFabOverlay() {
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
 */

  OverlayEntry _createFabOverlay() {
    return OverlayEntry(
      builder: (context) {
        final double safeBottom = MediaQuery.of(context).viewPadding.bottom;
        const double bottomNavHeight = 56.0;
        const double extraMargin = 20.0;
        final double bottomOffset = safeBottom + bottomNavHeight + extraMargin;

        /* return Positioned(
          right: 10,
          bottom: bottomOffset,
          child: SafeArea(child: NuevoInformeFab(onPressed: _agregarInforme)),
        ); */
        return Positioned(
          right: 10,
          bottom: bottomOffset,
          child: SafeArea(
            child: AnimatedOpacity(
              opacity: 1.0,
              duration: const Duration(milliseconds: 200), // ← Más rápido
              child: NuevoInformeFab(onPressed: _agregarInforme),
            ),
          ),
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
    if (_fabOverlay != null) {
      _fabOverlay?.remove();
      _fabOverlay = null;
    }
  }

  void _updateFabOverlay() {
    if (!mounted) return;
    if (_selectedIndex == 1) {
      _insertFabOverlay();
    } else {
      _removeFabOverlay();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // ✅ Función auxiliar para verificar si el usuario tiene acceso por idSubMenu
    bool _tienePermiso(int idSubMenu) {
      return _rolusuario.any((item) => item.idSubMenu == idSubMenu);
    }

    // 🔍 Verificar permisos según los idSubMenu
    final bool puedeGastos = _tienePermiso(500);
    final bool puedeInformes = _tienePermiso(501);
    final bool puedeAuditoria = _tienePermiso(502);
    final bool puedeRevision = _tienePermiso(503);

    // 🧩 Construir solo las páginas permitidas
    final List<Widget> pages = [
      if (puedeGastos) _buildPantallaInicio(), // Gastos
      if (puedeInformes) _buildPantallaInformes(), // Informes
      if (puedeAuditoria) _buildPantallaAditoria(), // Auditoría
      if (puedeRevision) _buildPantallaRevision(), // Revisión
    ];

    // 🧭 Construir dinámicamente los iconos del menú inferior
    final List<NavigationDestination> destinations = [
      if (puedeGastos) _animatedIcon(MdiIcons.cashPlus, "Gastos", 0),
      if (puedeInformes) _animatedIcon(Feather.file_text, "Informes", 1),
      if (puedeAuditoria)
        _animatedIcon(MdiIcons.shieldCheckOutline, "Auditoría", 2),
      if (puedeRevision) _animatedIcon(Feather.check_circle, "Revisión", 3),
    ];

    // Evitar index fuera de rango si hay menos pestañas disponibles
    final safeIndex = pages.isEmpty
        ? 0
        : _selectedIndex.clamp(0, pages.length - 1);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;

        // Si no está en la primera pestaña, regresar a la primera
        if (_selectedIndex != 0) {
          setState(() {
            _selectedIndex = 0;
          });
          return;
        }

        // Si está en la primera pestaña, mostrar confirmación para salir
        final shouldPop = await _showExitConfirmation(context);
        if (shouldPop && context.mounted) {
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        backgroundColor: isDark ? Colors.grey[900] : Colors.white,
        body: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: pages.isNotEmpty
              ? pages[safeIndex]
              : Center(
                  child: CircularProgressIndicator(
                    color: isDark ? Colors.white : const Color(0xFF1565C0),
                    strokeWidth: 5.0,
                  ),
                ),
        ),
        // 🧊 Barra inferior flotante moderna
        bottomNavigationBar: pages.isEmpty
            ? null
            : Padding(
                padding: const EdgeInsets.only(left: 7, right: 7, bottom: 1),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 400),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.black : Colors.white,
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [
                      BoxShadow(
                        color: isDark
                            ? Colors.black.withOpacity(0.5)
                            : Colors.black.withOpacity(0.2),
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
                        indicatorColor: isDark ? Colors.black : Colors.white,
                        backgroundColor: Colors.transparent,

                        labelTextStyle:
                            WidgetStateProperty.resolveWith<TextStyle>((
                              states,
                            ) {
                              return TextStyle(
                                color: states.contains(WidgetState.selected)
                                    ? const Color(0xFF1565C0)
                                    : isDark
                                    ? Colors.grey[400]
                                    : Colors.grey.shade700,
                                fontWeight:
                                    states.contains(WidgetState.selected)
                                    ? FontWeight.bold
                                    : FontWeight.w500,
                              );
                            }),
                      ),
                      child: NavigationBar(
                        elevation: 0,
                        selectedIndex: safeIndex,
                        onDestinationSelected: (index) async {
                          _searchController.clear();
                          _searchFocusNode.unfocus();

                          // ✅ REMOVER FAB INMEDIATAMENTE (sin delay)
                          _removeFabOverlay();
                          if (mounted) {
                            setState(() {
                              _selectedIndex = pages.isEmpty
                                  ? 0
                                  : index.clamp(0, pages.length - 1);
                            });
                          }

                          // 🔁 Recargar la data correspondiente
                          if (puedeGastos && index == 0) {
                            await _loadReportes();
                          } else if (puedeInformes && index == 1) {
                            await _loadInformes();
                          } else if (puedeAuditoria && index == 2) {
                            await loadAuditoria();
                          } else if (puedeRevision && index == 3) {
                            await _loadRevision();
                          }

                          WidgetsBinding.instance.addPostFrameCallback(
                            (_) => _updateFabOverlay(),
                          );
                        },
                        destinations: destinations,
                      ),
                    ),
                  ),
                ),
              ),
      ),
    );
  }

  /// 🎨 Ícono animado tipo Material con efecto de rebote
  NavigationDestination _animatedIcon(IconData icon, String label, int index) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
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
            color: isSelected
                ? const Color(0xFF1565C0)
                : isDark
                ? Colors.grey[400]
                : Colors.grey.shade600,
          ),
        ),
      ),
      label: label,
    );
  }

  /// Mostrar diálogo de confirmación para salir de la app
  Future<bool> _showExitConfirmation(BuildContext context) async {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: isDark ? Colors.grey[850] : Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Text(
              '¿Salir de la aplicación?',
              style: TextStyle(
                color: isDark ? Colors.white : Colors.black87,
                fontWeight: FontWeight.w600,
              ),
            ),
            content: Text(
              '¿Estás seguro de que quieres salir?',
              style: TextStyle(
                color: isDark ? Colors.grey[300] : Colors.grey[700],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text(
                  'Cancelar',
                  style: TextStyle(
                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                  ),
                ),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: isDark ? Colors.red[700] : Colors.red[600],
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text('Salir'),
              ),
            ],
          ),
        ) ??
        false;
  }
}
