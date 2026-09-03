

class Salon {
  final String id;
  final String nombre;

  Salon({
    required this.id,
    required this.nombre,
  });

  factory Salon.fromJson(Map<String, dynamic> json) {
    return Salon(
      id: json['id']?.toString() ?? '',
      nombre: json['nombre']?.toString() ?? 'Salón',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nombre': nombre,
    };
  }
}
