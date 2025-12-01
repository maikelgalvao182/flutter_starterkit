/// Constantes e variáveis globais do Partiuu
library;

/// Modelo de interesse/tag
class InterestTag {
  final String id;
  final String icon;
  final String nameKey; // Chave de tradução
  final String category;

  const InterestTag({
    required this.id,
    required this.icon,
    required this.nameKey,
    required this.category,
  });
}

/// Categorias de interesses
class InterestCategory {
  static const food = 'food';
  static const nightlife = 'nightlife';
  static const culture = 'culture';
  static const outdoor = 'outdoor';
  static const sports = 'sports';
  static const work = 'work';
  static const wellness = 'wellness';
  static const values = 'values';
}

/// Lista completa de interesses organizados por categoria
const List<InterestTag> interestListDisplay = [
  // 🍽️ Comida & Gastronomia
  InterestTag(id: 'japanese', icon: '🍣', nameKey: 'interest_japanese', category: InterestCategory.food),
  InterestTag(id: 'pizza', icon: '🍕', nameKey: 'interest_pizza', category: InterestCategory.food),
  InterestTag(id: 'burgers', icon: '🍔', nameKey: 'interest_burgers', category: InterestCategory.food),
  InterestTag(id: 'pasta', icon: '🍝', nameKey: 'interest_pasta', category: InterestCategory.food),
  InterestTag(id: 'beer_pub', icon: '🍻', nameKey: 'interest_beer_pub', category: InterestCategory.food),
  InterestTag(id: 'wines', icon: '🍷', nameKey: 'interest_wines', category: InterestCategory.food),
  InterestTag(id: 'sweets_cafes', icon: '🧁', nameKey: 'interest_sweets_cafes', category: InterestCategory.food),
  InterestTag(id: 'mexican', icon: '🌮', nameKey: 'interest_mexican', category: InterestCategory.food),
  InterestTag(id: 'healthy_food', icon: '🥗', nameKey: 'interest_healthy_food', category: InterestCategory.food),
  InterestTag(id: 'bbq', icon: '🔥', nameKey: 'interest_bbq', category: InterestCategory.food),
  InterestTag(id: 'vegetarian', icon: '🥗', nameKey: 'interest_vegetarian', category: InterestCategory.food),
  InterestTag(id: 'vegan', icon: '🌱', nameKey: 'interest_vegan', category: InterestCategory.food),
  InterestTag(id: 'food_markets', icon: '🛒', nameKey: 'interest_food_markets', category: InterestCategory.food),

  // 🎉 Vida Noturna & Entretenimento
  InterestTag(id: 'live_music_bar', icon: '🎵', nameKey: 'interest_live_music_bar', category: InterestCategory.nightlife),
  InterestTag(id: 'cocktails', icon: '🍸', nameKey: 'interest_cocktails', category: InterestCategory.nightlife),
  InterestTag(id: 'karaoke', icon: '🎤', nameKey: 'interest_karaoke', category: InterestCategory.nightlife),
  InterestTag(id: 'nightclub', icon: '🪩', nameKey: 'interest_nightclub', category: InterestCategory.nightlife),
  InterestTag(id: 'standup_theater', icon: '🎭', nameKey: 'interest_standup_theater', category: InterestCategory.nightlife),
  InterestTag(id: 'cinema', icon: '🎬', nameKey: 'interest_cinema', category: InterestCategory.nightlife),
  InterestTag(id: 'board_games', icon: '🎲', nameKey: 'interest_board_games', category: InterestCategory.nightlife),
  InterestTag(id: 'gaming', icon: '🎮', nameKey: 'interest_gaming', category: InterestCategory.nightlife),
  InterestTag(id: 'themed_parties', icon: '🥳', nameKey: 'interest_themed_parties', category: InterestCategory.nightlife),
  InterestTag(id: 'samba', icon: '🥁', nameKey: 'interest_samba', category: InterestCategory.nightlife),
  InterestTag(id: 'shopping', icon: '🛍️', nameKey: 'interest_shopping', category: InterestCategory.nightlife),

  // 🎨 Cultura & Artes
  InterestTag(id: 'museums', icon: '🎨', nameKey: 'interest_museums', category: InterestCategory.culture),
  InterestTag(id: 'book_club', icon: '📚', nameKey: 'interest_book_club', category: InterestCategory.culture),
  InterestTag(id: 'photography', icon: '📸', nameKey: 'interest_photography', category: InterestCategory.culture),
  InterestTag(id: 'workshops', icon: '✏️', nameKey: 'interest_workshops', category: InterestCategory.culture),
  InterestTag(id: 'concerts', icon: '🎧', nameKey: 'interest_concerts', category: InterestCategory.culture),
  InterestTag(id: 'language_exchange', icon: '🗣️', nameKey: 'interest_language_exchange', category: InterestCategory.culture),
  InterestTag(id: 'film_screenings', icon: '🎥', nameKey: 'interest_film_screenings', category: InterestCategory.culture),
  InterestTag(id: 'street_art', icon: '🎭', nameKey: 'interest_street_art', category: InterestCategory.culture),

  // 🌳 Ar Livre & Aventura
  InterestTag(id: 'light_trails', icon: '🚶', nameKey: 'interest_light_trails', category: InterestCategory.outdoor),
  InterestTag(id: 'parks', icon: '🌳', nameKey: 'interest_parks', category: InterestCategory.outdoor),
  InterestTag(id: 'beach', icon: '☀️', nameKey: 'interest_beach', category: InterestCategory.outdoor),
  InterestTag(id: 'bike', icon: '🚴', nameKey: 'interest_bike', category: InterestCategory.outdoor),
  InterestTag(id: 'climbing', icon: '🧗', nameKey: 'interest_climbing', category: InterestCategory.outdoor),
  InterestTag(id: 'outdoor_activities', icon: '🧘', nameKey: 'interest_outdoor_activities', category: InterestCategory.outdoor),
  InterestTag(id: 'pets', icon: '🐶', nameKey: 'interest_pets', category: InterestCategory.outdoor),
  InterestTag(id: 'sunset', icon: '🌅', nameKey: 'interest_sunset', category: InterestCategory.outdoor),
  InterestTag(id: 'pool', icon: '🏊', nameKey: 'interest_pool', category: InterestCategory.outdoor),
  InterestTag(id: 'camping', icon: '🏕️', nameKey: 'interest_camping', category: InterestCategory.outdoor),

  // ⚽ Esportes
  InterestTag(id: 'soccer', icon: '⚽', nameKey: 'interest_soccer', category: InterestCategory.sports),
  InterestTag(id: 'basketball', icon: '🏀', nameKey: 'interest_basketball', category: InterestCategory.sports),
  InterestTag(id: 'tennis', icon: '🎾', nameKey: 'interest_tennis', category: InterestCategory.sports),
  InterestTag(id: 'beach_tennis', icon: '🏓', nameKey: 'interest_beach_tennis', category: InterestCategory.sports),
  InterestTag(id: 'skating', icon: '🛼', nameKey: 'interest_skating', category: InterestCategory.sports),
  InterestTag(id: 'running', icon: '🏃', nameKey: 'interest_running', category: InterestCategory.sports),
  InterestTag(id: 'cycling', icon: '🚴', nameKey: 'interest_cycling', category: InterestCategory.sports),
  InterestTag(id: 'gym', icon: '🏋️', nameKey: 'interest_gym', category: InterestCategory.sports),
  InterestTag(id: 'light_activities', icon: '🤸', nameKey: 'interest_light_activities', category: InterestCategory.sports),

  // 💼 Trabalho & Estilo de Vida
  InterestTag(id: 'remote_work', icon: '💻', nameKey: 'interest_remote_work', category: InterestCategory.work),
  InterestTag(id: 'content_creators', icon: '🎥', nameKey: 'interest_content_creators', category: InterestCategory.work),
  InterestTag(id: 'career_talks', icon: '💬', nameKey: 'interest_career_talks', category: InterestCategory.work),
  InterestTag(id: 'tech_innovation', icon: '📱', nameKey: 'interest_tech_innovation', category: InterestCategory.work),

  // 🧘 Bem-estar & Saúde
  InterestTag(id: 'yoga', icon: '🧘', nameKey: 'interest_yoga', category: InterestCategory.wellness),
  InterestTag(id: 'meditation', icon: '🧘‍♂️', nameKey: 'interest_meditation', category: InterestCategory.wellness),
  InterestTag(id: 'pilates', icon: '🤸', nameKey: 'interest_pilates', category: InterestCategory.wellness),
  InterestTag(id: 'spa', icon: '💆', nameKey: 'interest_spa', category: InterestCategory.wellness),
  InterestTag(id: 'cold_plunge', icon: '🧊', nameKey: 'interest_cold_plunge', category: InterestCategory.wellness),
  InterestTag(id: 'healthy_lifestyle', icon: '🥗', nameKey: 'interest_healthy_lifestyle', category: InterestCategory.wellness),
  InterestTag(id: 'relaxing_walks', icon: '🚶', nameKey: 'interest_relaxing_walks', category: InterestCategory.wellness),

  // 🤝 Valores & Comunidade
  InterestTag(id: 'lgbtqia', icon: '🌈', nameKey: 'interest_lgbtqia', category: InterestCategory.values),
  InterestTag(id: 'sustainability', icon: '🌱', nameKey: 'interest_sustainability', category: InterestCategory.values),
  InterestTag(id: 'volunteering', icon: '🙌', nameKey: 'interest_volunteering', category: InterestCategory.values),
  InterestTag(id: 'animal_cause', icon: '🐾', nameKey: 'interest_animal_cause', category: InterestCategory.values),
];

/// Retorna os interesses filtrados por categoria
List<InterestTag> getInterestsByCategory(String category) {
  return interestListDisplay.where((interest) => interest.category == category).toList();
}
