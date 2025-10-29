import 'package:flu2/models/reporte_auditioria_model.dart';
import 'package:flu2/models/reporte_revision_detalle.dart';
import 'package:flu2/models/reporte_revision_model.dart';
import 'package:flu2/widgets/editar_auditoria_modal.dart';
import 'package:flutter/material.dart';
import '../models/reporte_auditoria_detalle.dart';
import '../services/api_service.dart';

class RevisionDetalleModal extends StatefulWidget {
  final ReporteRevision revision;
  const RevisionDetalleModal({super.key, required this.revision});
  
  @override
  State<StatefulWidget> createState() {
    // TODO: implement createState
    throw UnimplementedError();
  }
}
