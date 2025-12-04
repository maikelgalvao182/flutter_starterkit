/// Modelo simplificado de evento para exibição no mapa
class EventModel {
  final String id;
  final String emoji;
  final String createdBy;
  final double lat;
  final double lng;
  final String title;
  final String? locationName;
  final double? distanceKm;
  final bool isAvailable;
  final String? creatorFullName;
  final DateTime? scheduleDate;
  final String? privacyType;

  EventModel({
    required this.id,
    required this.emoji,
    required this.createdBy,
    required this.lat,
    required this.lng,
    required this.title,
    this.locationName,
    this.distanceKm,
    this.isAvailable = true,
    this.creatorFullName,
    this.scheduleDate,
    this.privacyType,
  });

  /// Factory para criar EventModel a partir de um Map
  factory EventModel.fromMap(Map<String, dynamic> map, String id) {
    // Tentar extrair coordenadas da raiz ou do objeto location
    final location = map['location'] as Map<String, dynamic>?;
    final lat = (map['latitude'] as num?)?.toDouble() ?? 
                (location?['latitude'] as num?)?.toDouble() ?? 
                0.0;
    final lng = (map['longitude'] as num?)?.toDouble() ?? 
                (location?['longitude'] as num?)?.toDouble() ?? 
                0.0;
    
    final locationName = map['locationName'] as String? ?? 
                         location?['locationName'] as String?;

    // Parse scheduleDate
    DateTime? scheduleDate;
    if (map['scheduleDate'] != null) {
      try {
        scheduleDate = DateTime.parse(map['scheduleDate'] as String);
      } catch (_) {
        scheduleDate = null;
      }
    }

    return EventModel(
      id: id,
      emoji: map['emoji'] as String? ?? '🎉',
      createdBy: map['createdBy'] as String? ?? '',
      lat: lat,
      lng: lng,
      title: map['activityText'] as String? ?? '',
      locationName: locationName,
      distanceKm: (map['distanceKm'] as num?)?.toDouble(),
      isAvailable: map['isAvailable'] as bool? ?? true,
      creatorFullName: map['creatorFullName'] as String?,
      scheduleDate: scheduleDate,
      privacyType: map['privacyType'] as String?,
    );
  }

  /// Cria uma cópia com campos atualizados
  EventModel copyWith({
    String? id,
    String? emoji,
    String? createdBy,
    double? lat,
    double? lng,
    String? title,
    String? locationName,
    double? distanceKm,
    bool? isAvailable,
    String? creatorFullName,
    DateTime? scheduleDate,
    String? privacyType,
  }) {
    return EventModel(
      id: id ?? this.id,
      emoji: emoji ?? this.emoji,
      createdBy: createdBy ?? this.createdBy,
      lat: lat ?? this.lat,
      lng: lng ?? this.lng,
      title: title ?? this.title,
      locationName: locationName ?? this.locationName,
      distanceKm: distanceKm ?? this.distanceKm,
      isAvailable: isAvailable ?? this.isAvailable,
      creatorFullName: creatorFullName ?? this.creatorFullName,
      scheduleDate: scheduleDate ?? this.scheduleDate,
      privacyType: privacyType ?? this.privacyType,
    );
  }
}
