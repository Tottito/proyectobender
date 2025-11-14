class Propiedad {
  final String id;
  final String titulo;
  final String direccion;
  final double alquilerMensual;
  final String imagen;

  Propiedad({
    required this.id,
    required this.titulo,
    required this.direccion,
    required this.alquilerMensual,
    required this.imagen,
  });

  // Para leer desde Firestore
  factory Propiedad.fromMap(String id, Map<String, dynamic> data) {
    // Conversión segura de número a double
    double alquiler = 0.0;
    final alquilerData = data['alquilerMensual'];

    if (alquilerData is int) {
      alquiler = alquilerData.toDouble();
    } else if (alquilerData is double) {
      alquiler = alquilerData;
    } else if (alquilerData is String) {
      alquiler = double.tryParse(alquilerData) ?? 0.0;
    }

    return Propiedad(
      id: id,
      titulo: data['titulo']?.toString() ?? 'Sin título',
      direccion: data['direccion']?.toString() ?? 'Sin dirección',
      alquilerMensual: alquiler,
      imagen: data['imagen']?.toString() ?? '',
    );
  }

  // Para guardar en Firestore
  Map<String, dynamic> toMap() {
    return {
      'titulo': titulo,
      'direccion': direccion,
      'alquilerMensual': alquilerMensual,
      'imagen': imagen,
    };
  }
}