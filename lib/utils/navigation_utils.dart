import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Cierra el foco y el teclado, y si es posible hace pop en el Navigator.
void safePop(BuildContext context, [dynamic result]) {
  try {
    FocusManager.instance.primaryFocus?.unfocus();
    SystemChannels.textInput.invokeMethod('TextInput.hide');
  } catch (_) {}

  if (Navigator.of(context).canPop()) {
    Navigator.of(context).pop(result);
  }
}

Color getStatusColor(String? estado) {
  switch (estado?.toUpperCase()) {
    case 'EN INFORME':
      return const Color.fromARGB(255, 168, 159, 76);
    case 'EN AUDITORIA':
      return Colors.blue;
    case 'RECHAZADO':
    case 'ELIMINADO':
      return Colors.red;
    case 'EN REVISION':
      return Colors.orange;
    case 'APROBADO':
      return Colors.green;
    default:
      return const Color.fromARGB(255, 255, 254, 254);
  }
}

String formatDate(String? fecha) {
  if (fecha == null || fecha.isEmpty) {
    return 'Sin fecha';
  }

  try {
    // Intentar parsear diferentes formatos de fecha
    DateTime? dateTime;

    // Formato ISO: 2025-10-04T00:00:00
    if (fecha.contains('T')) {
      dateTime = DateTime.tryParse(fecha);
    }
    // Formato dd/MM/yyyy
    else if (fecha.contains('/')) {
      final parts = fecha.split('/');
      if (parts.length == 3) {
        dateTime = DateTime.tryParse(
          '${parts[2]}-${parts[1].padLeft(2, '0')}-${parts[0].padLeft(2, '0')}',
        );
      }
    }
    // Formato yyyy-MM-dd
    else if (fecha.contains('-')) {
      dateTime = DateTime.tryParse(fecha);
    }

    if (dateTime != null) {
      return '${dateTime.day.toString().padLeft(2, '0')}/${dateTime.month.toString().padLeft(2, '0')}/${dateTime.year}';
    }
  } catch (e) {
    // Si hay error en el parseo, devolver la fecha original
  }

  return fecha;
}
