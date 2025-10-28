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
