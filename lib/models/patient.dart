class Patient {
  final String id;
  final String name;
  final String doctorId;
  final DateTime createdAt;

  Patient({
    required this.id,
    required this.name,
    required this.doctorId,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Patient copyWith({
    String? id,
    String? name,
    String? doctorId,
    DateTime? createdAt,
  }) {
    return Patient(
      id: id ?? this.id,
      name: name ?? this.name,
      doctorId: doctorId ?? this.doctorId,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'doctorId': doctorId,
      'createdAt': createdAt.millisecondsSinceEpoch,
    };
  }

  factory Patient.fromJson(Map<String, dynamic> json) {
    return Patient(
      id: json['id'],
      name: json['name'],
      doctorId: json['doctorId'],
      createdAt: DateTime.fromMillisecondsSinceEpoch(
        json['createdAt'] ?? DateTime.now().millisecondsSinceEpoch,
      ),
    );
  }
}
