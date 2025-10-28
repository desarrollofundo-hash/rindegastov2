class UserModel {
  final String usecod;
  final String usenam;
  final String usedoc;
  final String useusr;
  final String usepas;
  final String estado;
  final String siscod;
  final String grucod;
  final String grudes;
  final String sedeUser;
  final String nombreapp;
  final String useestado;
  final String versionanterior;
  final String versionactual;
  final String idapp;

  UserModel({
    required this.usecod,
    required this.usenam,
    required this.usedoc,
    required this.useusr,
    required this.usepas,
    required this.estado,
    required this.siscod,
    required this.grucod,
    required this.grudes,
    required this.sedeUser,
    required this.nombreapp,
    required this.useestado,
    required this.versionanterior,
    required this.versionactual,
    required this.idapp,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      usecod: json['usecod'] ?? '',
      usenam: json['usenam'] ?? '',
      usedoc: json['usedoc'] ?? '',
      useusr: json['useusr'] ?? '',
      usepas: json['usepas'] ?? '',
      estado: json['estado'] ?? '',
      siscod: json['siscod'] ?? '',
      grucod: json['grucod'] ?? '',
      grudes: json['grudes'] ?? '',
      sedeUser: json['sede_user'] ?? '',
      nombreapp: json['nombreapp'] ?? '',
      useestado: json['useestado'] ?? '',
      versionanterior: json['versionanterior'] ?? '',
      versionactual: json['versionactual'] ?? '',
      idapp: json['idapp'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'usecod': usecod,
      'usenam': usenam,
      'usedoc': usedoc,
      'useusr': useusr,
      'usepas': usepas,
      'estado': estado,
      'siscod': siscod,
      'grucod': grucod,
      'grudes': grudes,
      'sede_user': sedeUser,
      'nombreapp': nombreapp,
      'useestado': useestado,
      'versionanterior': versionanterior,
      'versionactual': versionactual,
      'idapp': idapp,
    };
  }

  bool get isActive => estado == 'S';
  bool get isAdmin => useestado == 'ADMIN';
}
