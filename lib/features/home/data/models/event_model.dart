/// Modelo simplificado de evento para exibição no mapa
class EventModel {
  final String id;
  final String emoji;
  final String createdBy;
  final double lat;
  final double lng;
  final String title;
  final String? locationName;

  EventModel({
    required this.id,
    required this.emoji,
    required this.createdBy,
    required this.lat,
    required this.lng,
    required this.title,
    this.locationName,
  });
}
