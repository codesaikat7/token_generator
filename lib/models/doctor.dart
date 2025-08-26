class Doctor {
  final String id;
  final String name;
  final int lastTokenNumber;
  final DateTime lastTokenDate;
  final DateTime createdAt;

  Doctor({
    required this.id,
    required this.name,
    this.lastTokenNumber = 0,
    DateTime? lastTokenDate,
    DateTime? createdAt,
  })  : lastTokenDate = lastTokenDate ?? DateTime.now(),
        createdAt = createdAt ?? DateTime.now();

  Doctor copyWith({
    String? id,
    String? name,
    int? lastTokenNumber,
    DateTime? lastTokenDate,
    DateTime? createdAt,
  }) {
    return Doctor(
      id: id ?? this.id,
      name: name ?? this.name,
      lastTokenNumber: lastTokenNumber ?? this.lastTokenNumber,
      lastTokenDate: lastTokenDate ?? this.lastTokenDate,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'lastTokenNumber': lastTokenNumber,
      'lastTokenDate': lastTokenDate.millisecondsSinceEpoch,
      'createdAt': createdAt.millisecondsSinceEpoch,
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
      createdAt: DateTime.fromMillisecondsSinceEpoch(
        json['createdAt'] ?? DateTime.now().millisecondsSinceEpoch,
      ),
    );
  }

  bool get isToday => _isSameDay(createdAt, DateTime.now());

  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }

  // Get the last token number as a string for display
  String get lastTokenDisplay =>
      lastTokenNumber > 0 ? 'Token #$lastTokenNumber' : 'No tokens';

  // Get the date display for when doctor was added
  String get dateDisplay {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final createdDate =
        DateTime(createdAt.year, createdAt.month, createdAt.day);

    if (createdDate.isAtSameMomentAs(today)) {
      return 'Today';
    } else {
      // Format as DD/MM/YYYY
      final day = createdAt.day.toString().padLeft(2, '0');
      final month = createdAt.month.toString().padLeft(2, '0');
      final year = createdAt.year.toString();
      return 'Added on $day/$month/$year';
    }
  }
}
