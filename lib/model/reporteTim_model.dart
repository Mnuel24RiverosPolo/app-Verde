class ReporteTim {
  final int? id; // Es nullable porque lo asigna la base de datos
  final String fechaGeneracion;
  final int tim;
  final int shipment;
  final String placa;
  final String localOrigen;
  final String localDestino;
  final String fechaEnvio;

  ReporteTim({
    this.id,
    required this.fechaGeneracion,
    required this.tim,
    required this.shipment,
    required this.placa,
    required this.localOrigen,
    required this.localDestino,
    required this.fechaEnvio,
  });

  // Convertir a Map para insertar en la base de datos
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'fecha_generacion': fechaGeneracion,
      'tim': tim,
      'shipment': shipment,
      'placa': placa,
      'local_origen': localOrigen,
      'local_destino': localDestino,
      'fecha_envio': fechaEnvio,
    };
  }

  // Crear un ReporteTim a partir de un Map
  factory ReporteTim.fromMap(Map<String, dynamic> map) {
    return ReporteTim(
      id: map['id'] as int?,
      fechaGeneracion: map['fecha_generacion'] as String,
      tim: map['tim'] as int,
      shipment: map['shipment'] as int,
      placa: map['placa'] as String,
      localOrigen: map['local_origen'] as String,
      localDestino: map['local_destino'] as String,
      fechaEnvio: map['fecha_envio'] as String,
    );
  }
}
