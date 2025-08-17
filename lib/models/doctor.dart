class Doctor {
  final String id;
  final String name;
  final int lastTokenNumber;
  final DateTime lastTokenDate;

  Doctor({
    required this.id,
    required this.name,
    this.lastTokenNumber = 0,
    DateTime? lastTokenDate,
  }) : lastTokenDate = lastTokenDate ?? DateTime.now();

  Doctor copyWith({
    String? id,
    String? name,
    int? lastTokenNumber,
    DateTime? lastTokenDate,
  }) {
    return Doctor(
      id: id ?? this.id,
      name: name ?? this.name,
      lastTokenNumber: lastTokenNumber ?? this.lastTokenNumber,
      lastTokenDate: lastTokenDate ?? this.lastTokenDate,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'lastTokenNumber': lastTokenNumber,
      'lastTokenDate': lastTokenDate.millisecondsSinceEpoch,
    };
  }

  factory Doctor.fromJson(Map<String, dynamic> json) {
    return Doctor(
      id: json['id'],
      name: json['name'],
      lastTokenNumber: json['lastTokenNumber'] ?? 0,
      lastTokenDate: DateTime.fromMillisecondsSinceEpoch(
        json['lastTokenDate'] ?? DateTime.now().millisecondsSinceEpoch,
      ),
    );
  }

  bool get isToday => _isSameDay(lastTokenDate, DateTime.now());

  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }
}
