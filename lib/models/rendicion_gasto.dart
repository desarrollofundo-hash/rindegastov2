class RendicionGasto {
  // Ejemplo de JSON para RendicionGasto
  final int idRend;
  final int idUser;
  final String dni;
  final String politica;
  final String categoria;
  final String tipogasto;
  final String ruc;
  final String proveedor;
  final String tipoCombrobante;
  final String serie;
  final String numero;
  final double igv;
  final DateTime fecha;
  final double total;
  final String moneda;
  final String rucCliente;
  final String desEmp;
  final String desSed;
  final String idCuenta;
  final String consumidor;
  final String regimen;
  final String destino;
  final String glosa;
  final String motivoViaje;
  final String lugarOrigen;
  final String lugarDestino;
  final String tipoMovilidad;
  final String obs;
  final String estado;
  final DateTime fecCre;
  final int useReg;
  final String hostname;
  final DateTime fecEdit;
  final int useEdit;
  final int useElim;

  RendicionGasto({
    required this.idRend,
    required this.idUser,
    required this.dni,
    required this.politica,
    required this.categoria,
    required this.tipogasto,
    required this.ruc,
    required this.proveedor,
    required this.tipoCombrobante,
    required this.serie,
    required this.numero,
    required this.igv,
    required this.fecha,
    required this.total,
    required this.moneda,
    required this.rucCliente,
    required this.desEmp,
    required this.desSed,
    required this.idCuenta,
    required this.consumidor,
    required this.regimen,
    required this.destino,
    required this.glosa,
    required this.motivoViaje,
    required this.lugarOrigen,
    required this.lugarDestino,
    required this.tipoMovilidad,
    required this.obs,
    required this.estado,
    required this.fecCre,
    required this.useReg,
    required this.hostname,
    required this.fecEdit,
    required this.useEdit,
    required this.useElim, required idReporte, required String id,
  });

  // Factory constructor para crear una instancia de RendicionGasto desde un mapa (usado para la base de datos)
  factory RendicionGasto.fromMap(Map<String, dynamic> map) {
    return RendicionGasto(
      idRend: map['idRend'] as int,
      idUser: map['idUser'] as int,
      dni: map['dni'] as String,
      politica: map['politica'] as String,
      categoria: map['categoria'] as String,
      tipogasto: map['tipogasto'] as String,
      ruc: map['ruc'] as String,
      proveedor: map['proveedor'] as String,
      tipoCombrobante: map['tipoCombrobante'] as String,
      serie: map['serie'] as String,
      numero: map['numero'] as String,
      igv: map['igv'] as double,
      fecha: DateTime.parse(map['fecha'] as String),
      total: map['total'] as double,
      moneda: map['moneda'] as String,
      rucCliente: map['rucCliente'] as String,
      desEmp: map['desEmp'] as String,
      desSed: map['desSed'] as String,
      idCuenta: map['idCuenta'] as String,
      consumidor: map['consumidor'] as String,
      regimen: map['regimen'] as String,
      destino: map['destino'] as String,
      glosa: map['glosa'] as String,
      motivoViaje: map['motivoViaje'] as String,
      lugarOrigen: map['lugarOrigen'] as String,
      lugarDestino: map['lugarDestino'] as String,
      tipoMovilidad: map['tipoMovilidad'] as String,
      obs: map['obs'] as String,
      estado: map['estado'] as String,
      fecCre: DateTime.parse(map['fecCre'] as String),
      useReg: map['useReg'] as int,
      hostname: map['hostname'] as String,
      fecEdit: DateTime.parse(map['fecEdit'] as String),
      useEdit: map['useEdit'] as int,
      useElim: map['useElim'] as int, idReporte: null, id: '',
    );
  }

  // Método para convertir una instancia de RendicionGasto a un mapa (usado para la base de datos)
  Map<String, dynamic> toMap() {
    return {
      'idRend': idRend,
      'idUser': idUser,
      'dni': dni,
      'politica': politica,
      'categoria': categoria,
      'tipogasto': tipogasto,
      'ruc': ruc,
      'proveedor': proveedor,
      'tipoCombrobante': tipoCombrobante,
      'serie': serie,
      'numero': numero,
      'igv': igv,
      'fecha': fecha.toIso8601String(),
      'total': total,
      'moneda': moneda,
      'rucCliente': rucCliente,
      'desEmp': desEmp,
      'desSed': desSed,
      'idCuenta': idCuenta,
      'consumidor': consumidor,
      'regimen': regimen,
      'destino': destino,
      'glosa': glosa,
      'motivoViaje': motivoViaje,
      'lugarOrigen': lugarOrigen,
      'lugarDestino': lugarDestino,
      'tipoMovilidad': tipoMovilidad,
      'obs': obs,
      'estado': estado,
      'fecCre': fecCre.toIso8601String(),
      'useReg': useReg,
      'hostname': hostname,
      'fecEdit': fecEdit.toIso8601String(),
      'useEdit': useEdit,
      'useElim': useElim,
    };
  }
}
