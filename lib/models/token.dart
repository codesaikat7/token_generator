class Token {
  final String id;
  final int tokenNumber;
  final String patientName;
  final String patientId;
  final String doctorId;
  final DateTime generatedAt;

  Token({
    required this.id,
    required this.tokenNumber,
    required this.patientName,
    required this.patientId,
    required this.doctorId,
    DateTime? generatedAt,
  }) : generatedAt = generatedAt ?? DateTime.now();

  Token copyWith({
    String? id,
    int? tokenNumber,
    String? patientName,
    String? patientId,
    String? doctorId,
    DateTime? generatedAt,
  }) {
    return Token(
      id: id ?? this.id,
      tokenNumber: tokenNumber ?? this.tokenNumber,
      patientName: patientName ?? this.patientName,
      patientId: patientId ?? this.patientId,
      doctorId: doctorId ?? this.doctorId,
      generatedAt: generatedAt ?? this.generatedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'tokenNumber': tokenNumber,
      'patientName': patientName,
      'patientId': patientId,
      'doctorId': doctorId,
      'generatedAt': generatedAt.millisecondsSinceEpoch,
    };
  }

  factory Token.fromJson(Map<String, dynamic> json) {
    return Token(
      id: json['id'],
      tokenNumber: json['tokenNumber'],
      patientName: json['patientName'],
      patientId: json['patientId'],
      doctorId: json['doctorId'],
      generatedAt: DateTime.fromMillisecondsSinceEpoch(
        json['generatedAt'] ?? DateTime.now().millisecondsSinceEpoch,
      ),
    );
  }
}
