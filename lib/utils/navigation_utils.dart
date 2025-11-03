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
      return const Color.fromARGB(255, 163, 152, 54);
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
      return Colors.grey;
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

int diferenciaEnDias(String fecha1, String fecha2) {
  DateTime? parseDate(String fecha) {
    try {
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

      return dateTime;
    } catch (_) {
      return null;
    }
  }

  final DateTime? d1 = parseDate(fecha1);
  final DateTime? d2 = parseDate(fecha2);

  if (d1 == null || d2 == null) {
    throw FormatException('Una o ambas fechas no tienen un formato válido');
  }

  // Calcula la diferencia en días (valor absoluto)
  return d1.difference(d2).inDays.abs();
}

void main() {
  print(diferenciaEnDias('01/11/2025', '2025-10-29')); // ➜ 3
  print(diferenciaEnDias('2025-10-04T00:00:00', '2025-10-01')); // ➜ 3
}

/// Muestra un SnackBar con un mensaje en la pantalla
void showMessageError(
  BuildContext context,
  String message, {
  Duration duration = const Duration(seconds: 2),
}) {
  ScaffoldMessenger.of(
    context,
  ).showSnackBar(SnackBar(content: Text(message), duration: duration));
}

