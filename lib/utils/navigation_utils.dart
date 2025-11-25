import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:network_info_plus/network_info_plus.dart';

class DeviceUtils {
  static final DeviceInfoPlugin _deviceInfoPlugin = DeviceInfoPlugin();
  static final NetworkInfo _networkInfo = NetworkInfo();

  static String? _cachedMac;
  static String? _cachedIp;
  static String? _cachedName;
  static String? _cachedSerial;

  static Future<void> init() async {
    try {
      _cachedIp = await _networkInfo.getWifiIP();
      _cachedMac = await _getRealMacAddress();

      if (Platform.isAndroid) {
        final info = await _deviceInfoPlugin.androidInfo;
        _cachedName = info.model;
        _cachedSerial = info.serialNumber ?? 'No disponible';
      } else if (Platform.isIOS) {
        final info = await _deviceInfoPlugin.iosInfo;
        _cachedName = info.name;
        _cachedSerial = 'No disponible';
      } else if (Platform.isWindows) {
        final info = await _deviceInfoPlugin.windowsInfo;
        _cachedName = info.computerName;
        _cachedSerial = info.deviceId ?? 'No disponible';
      } else if (Platform.isMacOS) {
        final info = await _deviceInfoPlugin.macOsInfo;
        _cachedName = info.computerName;
        _cachedSerial = info.systemGUID ?? 'No disponible';
      }
    } catch (e) {
      _cachedIp = 'Error IP: $e';
      _cachedMac = 'Error MAC: $e';
      _cachedName = 'Error nombre: $e';
      _cachedSerial = 'Error serie: $e';
    }
  }

  static Future<String?> _getRealMacAddress() async {
    try {
      String? mac = await _networkInfo.getWifiBSSID();

      // En Android 10+ puede devolver "02:00:00:00:00:00"
      if (mac == null || mac == "02:00:00:00:00:00") {
        mac = await _networkInfo.getWifiName(); // fallback
      }
      return mac ?? 'No disponible';
    } catch (e) {
      return 'Error al obtener MAC: $e';
    }
  }

  static String getLocalIpAddress() => _cachedIp ?? 'Desconocido';
  static String getMacAddress() => _cachedMac ?? 'Desconocido';
  static String getDeviceName() => _cachedName ?? 'Desconocido';
  static String getSerialNumber() => _cachedSerial ?? 'Desconocido';

  static Map<String, String> toJson() {
    return {
      "hostname": getMacAddress(),
      "ip": getLocalIpAddress(),
      "nombre": getDeviceName(),
      "serie": getSerialNumber(),
    };
  }
}

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
/* void showMessageError(
  BuildContext context,
  String message, {
  Duration duration = const Duration(seconds: 2),
}) {
  ScaffoldMessenger.of(
    context,
  ).showSnackBar(SnackBar(content: Text(message), duration: duration));
} */

/* void showMessageError(
  BuildContext context,
  String message, {
  Duration duration = const Duration(seconds: 2),
}) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      duration: duration,
      elevation: 0,
      backgroundColor: Colors.transparent,
      behavior: SnackBarBehavior.floating,
      content: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0.8, end: 1.0),
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeOutBack,
        builder: (context, value, child) {
          return Transform.scale(
            scale: value,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
              decoration: BoxDecoration(
                color: Colors.green.shade600, // Puedes cambiar color
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: Colors.blue.shade200.withOpacity(0.5),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.white, size: 26),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      message,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    ),
  );
}
 */

void showMessageError(
  BuildContext context,
  String message, {
  Duration duration = const Duration(seconds: 2),
}) {
  final bool isRejected = message.toUpperCase().contains("RECHAZADO");

  final Color bgColor = isRejected
      ? Colors.red.shade600
      : Colors.green.shade600;
  final IconData iconData = isRejected
      ? Icons.close_rounded
      : Icons.check_circle;

  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      duration: duration,
      elevation: 0,
      backgroundColor: Colors.transparent,
      behavior: SnackBarBehavior.floating,
      content: AnimatedBuilder(
        animation: kAlwaysCompleteAnimation,
        builder: (context, child) {
          return TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.8, end: 1.0),
            duration: const Duration(milliseconds: 450),
            curve: Curves.easeOutBack,
            builder: (context, scale, _) {
              return Transform.scale(
                scale: scale,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    color: bgColor,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: bgColor.withOpacity(0.4),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      // 🔥 Animación diferente según aprobado/rechazado
                      isRejected
                          ? _ShakeIcon(iconData)
                          : Icon(iconData, color: Colors.white, size: 26),

                      const SizedBox(width: 12),

                      Expanded(
                        child: Text(
                          message,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    ),
  );
}

// --------------------------------------------------
// 🔴 Ícono con animación SHAKE (vibración)
// --------------------------------------------------
class _ShakeIcon extends StatefulWidget {
  final IconData icon;

  const _ShakeIcon(this.icon);

  @override
  State<_ShakeIcon> createState() => _ShakeIconState();
}

class _ShakeIconState extends State<_ShakeIcon>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _shake;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    )..forward();

    _shake = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0, end: -6), weight: 1),
      TweenSequenceItem(tween: Tween(begin: -6, end: 6), weight: 2),
      TweenSequenceItem(tween: Tween(begin: 6, end: -4), weight: 2),
      TweenSequenceItem(tween: Tween(begin: -4, end: 0), weight: 1),
    ]).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _shake,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(_shake.value, 0),
          child: Icon(widget.icon, color: Colors.white, size: 26),
        );
      },
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
