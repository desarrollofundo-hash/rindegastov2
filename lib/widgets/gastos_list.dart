import 'package:flutter/material.dart';
import '../models/gasto_model.dart';

class GastosList extends StatelessWidget {
  final List<Gasto> gastos;
  final Future<void> Function() onRefresh;
  final void Function(Gasto)? onTap;

  const GastosList({
    super.key,
    required this.gastos,
    required this.onRefresh,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: gastos.isEmpty
          ? ListView(
              children: const [
                SizedBox(height: 100),
                Center(
                  child: Text(
                    "No hay gastos disponibles",
                    style: TextStyle(color: Colors.grey, fontSize: 16),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            )
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: gastos.length,
              itemBuilder: (context, index) {
                final gasto = gastos[index];
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
                        gasto.titulo,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            gasto.categoria,
                            style: TextStyle(color: Colors.grey[700]),
                          ),
                          Text(
                            gasto.fecha,
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                      trailing: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            gasto.monto,
                            style: const TextStyle(
                              color: Colors.indigo,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 1),
                          Chip(
                            label: Text(
                              gasto.estado,
                              style: const TextStyle(fontSize: 6),
                            ),
                            backgroundColor: gasto.estado == "Borrador"
                                ? Colors.orange[100]
                                : gasto.estado == "Enviados"
                                ? Colors.green[100]
                                : Colors.blue[100],
                          ),
                        ],
                      ),
                      onTap: onTap != null ? () => onTap!(gasto) : null,
                    ),
                  ),
                );
              },
            ),
    );
  }
}
