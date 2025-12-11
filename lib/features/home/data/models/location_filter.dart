/// Filtro imutável para ranking de lugares
/// 
/// Segue o mesmo padrão do PeopleFilter
class LocationFilter {
  final String? state;
  final String? city;

  const LocationFilter({
    this.state,
    this.city,
  });

  LocationFilter copyWith({
    String? state,
    String? city,
  }) {
    return LocationFilter(
      state: state ?? this.state,
      city: city ?? this.city,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LocationFilter &&
          runtimeType == other.runtimeType &&
          state == other.state &&
          city == other.city;

  @override
  int get hashCode => state.hashCode ^ city.hashCode;
}
