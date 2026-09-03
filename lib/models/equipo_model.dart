

class Equipo {
  final String id;
  final String codigo;
  final bool estado; // true = OPERATIVO (BIEN), false = FALLA (MAL)
  final String? observacion;
  final String? salonId;

  Equipo({
    required this.id,
    required this.codigo,
    required this.estado,
    this.observacion,
    this.salonId,
  });

  factory Equipo.fromJson(Map<String, dynamic> json) {
    return Equipo(
      id: json['id']?.toString() ?? '',
      codigo: json['codigo']?.toString() ?? 'PC-00',
      estado: json['estado'] is bool
          ? json['estado']
          : (json['estado'] == 1 || json['estado'] == 'true'),
      observacion: json['observacion']?.toString(),
      salonId: json['salon_id']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'codigo': codigo,
      'estado': estado,
      'observacion': observacion,
      'salon_id': salonId,
    };
  }

  Equipo copyWith({
    String? id,
    String? codigo,
    bool? estado,
    String? observacion,
    String? salonId,
  }) {
    return Equipo(
      id: id ?? this.id,
      codigo: codigo ?? this.codigo,
      estado: estado ?? this.estado,
      observacion: observacion ?? this.observacion,
      salonId: salonId ?? this.salonId,
    );
  }
}
