/// Filtro imutável para ranking de pessoas
/// 
/// Segue o mesmo padrão do WeddingDiscoveryFilter
class PeopleFilter {
  final String? state;
  final String? city;

  const PeopleFilter({
    this.state,
    this.city,
  });

  PeopleFilter copyWith({
    String? state,
    String? city,
  }) {
    return PeopleFilter(
      state: state ?? this.state,
      city: city ?? this.city,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PeopleFilter &&
          runtimeType == other.runtimeType &&
          state == other.state &&
          city == other.city;

  @override
  int get hashCode => state.hashCode ^ city.hashCode;
}
