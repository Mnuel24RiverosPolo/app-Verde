class Ubicacion {
  final int? id;
  final String division;
  final String departamento;
  final String subdepartamento;
  final String clase;
  final String subclase;

  Ubicacion({
    this.id,
    required this.division,
    required this.departamento,
    required this.subdepartamento,
    required this.clase,
    required this.subclase,
  });

  // Convertir una instancia de Ubicacion a un Map (para la base de datos)
  Map<String, dynamic> toMap() {
    return {
      'division': division.isEmpty ? '' : division,
      'departamento': departamento.isEmpty ? '' : departamento,
      'subdepartamento': subdepartamento.isEmpty ? '' : subdepartamento,
      'clase': clase.isEmpty ? '' : clase,
      'subclase': subclase.isEmpty ? '' : subclase,
    };
  }

  // Crear una instancia de Ubicacion a partir de un Map (desde la base de datos)
  factory Ubicacion.fromMap(Map<String, dynamic> map) {
    return Ubicacion(
      id: map['id'] as int?,
      division: map['division'] ?? '', // Si es null, asignar cadena vacía
      departamento: map['departamento'] ?? '',
      subdepartamento: map['subdepartamento'] ?? '',
      clase: map['clase'] ?? '',
      subclase: map['subclase'] ?? '',
    );
  }
}
