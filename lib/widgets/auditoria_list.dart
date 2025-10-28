import 'package:flu2/models/reporte_auditioria_model.dart';
import 'package:flutter/material.dart';

class AuditoriaList extends StatelessWidget {
  final List<ReporteAuditoria> auditorias;
  final Future<void> Function() onRefresh;
  final void Function(ReporteAuditoria)? onTap;

  const AuditoriaList({
    super.key,
    required this.auditorias,
    required this.onRefresh,
    this.onTap,
  });
  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: auditorias.isEmpty
          ? ListView(
              children: const [
                SizedBox(height: 100),
                Center(
                  child: Text(
                    "No hay auditorias disponibles",
                    style: TextStyle(color: Colors.grey, fontSize: 16),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            )
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: auditorias.length,
              itemBuilder: (context, index) {
                final auditoria = auditorias[index];
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 400),
                  curve: Curves.easeInOut,
                  child: Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(12),
                      title: Text(
                        auditoria.titulo ?? 'Sin título',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            auditoria.politica ?? 'Sin política',
                            style: TextStyle(color: Colors.grey[700]),
                          ),
                          Text(
                            auditoria.estadoActual ?? 'Sin estado',
                            style: TextStyle(color: Colors.grey[700]),
                          ),
                          if (auditoria.fecCre != null)
                            Text(
                              'Creado el: ${auditoria.fecCre}',
                              style: TextStyle(color: Colors.grey[500]),
                            ),
                        ],
                      ),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: onTap != null ? () => onTap!(auditoria) : null,
                    ),
                  ),
                );
              },
            ),
    );
  }
}