class Publisher {
  final int id;
  final String name;
  final String city;
  final DateTime? deletedAt;

  const Publisher({
    required this.id,
    required this.name,
    required this.city,
    this.deletedAt,
  });

  bool get isDeleted => deletedAt != null;

  Publisher copyWith({
    String? name,
    String? city,
    DateTime? deletedAt,
    bool clearDeletedAt = false,
  }) {
    return Publisher(
      id: id,
      name: name ?? this.name,
      city: city ?? this.city,
      deletedAt: clearDeletedAt ? null : (deletedAt ?? this.deletedAt),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'city': city,
        'deletedAt': deletedAt?.toIso8601String(),
      };

  factory Publisher.fromJson(Map<String, dynamic> json) => Publisher(
        id: json['id'] as int? ?? 0,
        name: json['name'] as String? ?? '',
        city: json['city'] as String? ?? '',
        deletedAt: json['deletedAt'] == null ? null : DateTime.tryParse(json['deletedAt'] as String),
      );
}