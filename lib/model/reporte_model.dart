class Reporte {
  final int? id;
  final int? tim;
  final String olpn;
  final String pallet;
  final String tipoInventario;
  final String tipoSku;
  final String subdpto;
  final String ean;
  final String sku;
  final String descripcion;
  final int casePack;
  final double unidades;
  final double cajas;
  double recibidos;
  final String fechavencimiento;
  final String faltantes;

  bool fastRegister;

  Reporte({
    this.id,
    this.tim,
    required this.olpn,
    required this.pallet,
    required this.tipoInventario,
    required this.tipoSku,
    required this.subdpto,
    required this.ean,
    required this.sku,
    required this.descripcion,
    required this.casePack,
    required this.unidades,
    required this.cajas,
    required this.recibidos,
    required this.fechavencimiento,
    required this.faltantes,
    bool? fastRegister,
  }) : fastRegister = fastRegister ?? (recibidos != 0);

  Map<String, dynamic> toMap() {
    // Excluye 'id' si es null, para evitar que se pase a la base de datos.
    return {
      'olpn': olpn.isEmpty ? '' : olpn,
      'tim': tim ?? 0,
      'pallet': pallet.isEmpty ? '' : pallet,
      'tipo_inventario': tipoInventario.isEmpty ? '' : tipoInventario,
      'tipo_sku': tipoSku.isEmpty ? '' : tipoSku,
      'subdpto': subdpto.isEmpty ? '' : subdpto,
      'ean': ean.isEmpty ? '' : ean,
      'sku': sku.isEmpty ? '' : sku,
      'descripcion': descripcion.isEmpty ? '' : descripcion,
      'case_pack': casePack,
      'unidades': unidades,
      'cajas': cajas,
      'recibidos': recibidos ?? 0,
      'fechavencimiento': fechavencimiento.isEmpty ? '' : fechavencimiento,
      'faltantes': faltantes.isEmpty ? '' : faltantes,
    };
  }

  // Convertir un Map a un Reporte
  factory Reporte.fromMap(Map<String, dynamic> map) {
    return Reporte(
      id: map['id'] as int?,
      tim:   map['tim'] ?? 0,
      olpn: map['olpn'] ?? '', // Si 'olpn' es null, asignar cadena vacía
      pallet: map['pallet'] ?? '', // Si 'pallet' es null, asignar cadena vacía
      tipoInventario: map['tipoinventario'] ?? '',
      tipoSku: map['tipo_sku'] ?? '',
      subdpto: map['subdpto'] ?? '',
      ean: map['ean'] ?? '',
      sku: map['sku'] ?? '',
      descripcion: map['descripcion'] ?? '',
      casePack: map['case_pack'] ?? 0, // Si 'case_pack' es null, asignar 0
      unidades: map['unidades'] ?? 0.0, // Si 'unidades' es null, asignar 0
      cajas: map['cajas'] ?? 0.0, // Si 'cajas' es null, asignar 0
      recibidos: map['recibidos'] ?? 0, // Si 'recibidos' es null, asignar 0
      fechavencimiento: map['fechavencimiento'] ?? '',
      faltantes: map['faltantes'] ?? '',
    );
  }
}
