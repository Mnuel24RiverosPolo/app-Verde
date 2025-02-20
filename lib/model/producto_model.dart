class Producto {
  final int? id;
  final String subclase;
  final String proveedor;
  final String sku;
  final String ean;
  final String descripcion;
  final int casePack;

  Producto({
    this.id,
    required this.subclase,
    required this.proveedor,
    required this.sku,
    required this.ean,
    required this.descripcion,
    required this.casePack,
  });

  Map<String, dynamic> toMap() {
    return {
      'subclase': subclase,
      'proveedor': proveedor,
      'sku': sku,
      'ean': ean,
      'descripcion': descripcion,
      'case_pack': casePack,
    };
  }

  factory Producto.fromMap(Map<String, dynamic> map) {
    return Producto(
      id: map['id'],
      subclase: map['subclase'] ?? '',
      proveedor: map['proveedor'] ?? '',
      sku: map['sku'] ?? '',
      ean: map['ean'] ?? '',
      descripcion: map['descripcion'] ?? '',
      casePack: map['case_pack'] ?? 0,
    );
  }
}
