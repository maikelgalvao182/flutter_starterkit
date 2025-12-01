/// Serviço para converter nomes de estados para abreviações
class StateAbbreviationService {
  /// Mapa de estados brasileiros e suas abreviações
  static const Map<String, String> _brazilianStates = {
    // Estados completos -> Abreviações
    'acre': 'AC',
    'alagoas': 'AL',
    'amapá': 'AP',
    'amazonas': 'AM',
    'bahia': 'BA',
    'ceará': 'CE',
    'distrito federal': 'DF',
    'espírito santo': 'ES',
    'goiás': 'GO',
    'maranhão': 'MA',
    'mato grosso': 'MT',
    'mato grosso do sul': 'MS',
    'minas gerais': 'MG',
    'pará': 'PA',
    'paraíba': 'PB',
    'paraná': 'PR',
    'pernambuco': 'PE',
    'piauí': 'PI',
    'rio de janeiro': 'RJ',
    'rio grande do norte': 'RN',
    'rio grande do sul': 'RS',
    'rondônia': 'RO',
    'roraima': 'RR',
    'santa catarina': 'SC',
    'são paulo': 'SP',
    'sergipe': 'SE',
    'tocantins': 'TO',
  };

  /// Mapa de estados americanos e suas abreviações
  static const Map<String, String> _usStates = {
    'alabama': 'AL',
    'alaska': 'AK',
    'arizona': 'AZ',
    'arkansas': 'AR',
    'california': 'CA',
    'colorado': 'CO',
    'connecticut': 'CT',
    'delaware': 'DE',
    'florida': 'FL',
    'georgia': 'GA',
    'hawaii': 'HI',
    'idaho': 'ID',
    'illinois': 'IL',
    'indiana': 'IN',
    'iowa': 'IA',
    'kansas': 'KS',
    'kentucky': 'KY',
    'louisiana': 'LA',
    'maine': 'ME',
    'maryland': 'MD',
    'massachusetts': 'MA',
    'michigan': 'MI',
    'minnesota': 'MN',
    'mississippi': 'MS',
    'missouri': 'MO',
    'montana': 'MT',
    'nebraska': 'NE',
    'nevada': 'NV',
    'new hampshire': 'NH',
    'new jersey': 'NJ',
    'new mexico': 'NM',
    'new york': 'NY',
    'north carolina': 'NC',
    'north dakota': 'ND',
    'ohio': 'OH',
    'oklahoma': 'OK',
    'oregon': 'OR',
    'pennsylvania': 'PA',
    'rhode island': 'RI',
    'south carolina': 'SC',
    'south dakota': 'SD',
    'tennessee': 'TN',
    'texas': 'TX',
    'utah': 'UT',
    'vermont': 'VT',
    'virginia': 'VA',
    'washington': 'WA',
    'west virginia': 'WV',
    'wisconsin': 'WI',
    'wyoming': 'WY',
    'district of columbia': 'DC',
  };

  /// Converte nome do estado para abreviação
  /// 
  /// Retorna a abreviação se encontrada, caso contrário retorna o valor original
  /// 
  /// Exemplos:
  /// - "São Paulo" -> "SP"
  /// - "California" -> "CA"
  /// - "SP" -> "SP" (já é abreviação)
  static String getAbbreviation(String? stateName) {
    if (stateName == null || stateName.isEmpty) return '';
    
    // Se já é uma abreviação (2 letras maiúsculas), retorna como está
    if (stateName.length == 2 && stateName == stateName.toUpperCase()) {
      return stateName;
    }
    
    // Normaliza o nome do estado (lowercase, remove acentos extras)
    final normalized = stateName.toLowerCase().trim();
    
    // Tenta encontrar nos estados brasileiros
    if (_brazilianStates.containsKey(normalized)) {
      return _brazilianStates[normalized]!;
    }
    
    // Tenta encontrar nos estados americanos
    if (_usStates.containsKey(normalized)) {
      return _usStates[normalized]!;
    }
    
    // Se não encontrar, retorna o valor original
    // (pode ser outro país ou estado desconhecido)
    return stateName;
  }

  /// Verifica se o texto é uma abreviação de estado válida
  static bool isAbbreviation(String? text) {
    if (text == null || text.isEmpty) return false;
    
    // Abreviações são sempre 2 letras maiúsculas
    if (text.length != 2) return false;
    if (text != text.toUpperCase()) return false;
    
    // Verifica se existe nos mapas
    return _brazilianStates.containsValue(text) || _usStates.containsValue(text);
  }
}
