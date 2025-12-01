/// Validadores para autenticação e cadastro
/// 
/// Classe utilitária que centraliza todas as regras de validação
/// para email, senha e outros campos do fluxo de auth/cadastro.
class AuthValidators {
  // Previne instanciação
  AuthValidators._();
  
  /// Valida formato de email
  /// 
  /// Retorna mensagem de erro ou null se válido.
  static String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your email';
    }
    
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$'
    );
    
    if (!emailRegex.hasMatch(value.trim())) {
      return 'Please enter a valid email';
    }
    
    return null;
  }
  
  /// Valida senha
  /// 
  /// [isSignUp] - Se true, aplica regras mais rigorosas (mínimo 6 caracteres)
  /// Retorna mensagem de erro ou null se válida.
  static String? validatePassword(String? value, {bool isSignUp = false}) {
    if (value == null || value.isEmpty) {
      return 'Please enter your password';
    }
    
    if (isSignUp && value.length < 6) {
      return 'Password must be at least 6 characters';
    }
    
    return null;
  }
  
  /// Valida nome completo
  /// 
  /// Retorna mensagem de erro ou null se válido.
  static String? validateFullName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter your full name';
    }
    
    if (value.trim().length < 2) {
      return 'Name must be at least 2 characters';
    }
    
    // Verifica se tem pelo menos um espaço (nome e sobrenome)
    if (!value.trim().contains(' ')) {
      return 'Please enter your full name (first and last name)';
    }
    
    return null;
  }
  
  /// Valida biografia
  /// 
  /// Retorna mensagem de erro ou null se válida.
  static String? validateBio(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please write something about yourself';
    }
    
    if (value.trim().length < 10) {
      return 'Bio must be at least 10 characters';
    }
    
    if (value.trim().length > 500) {
      return 'Bio must be less than 500 characters';
    }
    
    return null;
  }
  
  /// Valida se campo de texto não está vazio
  /// 
  /// Uso genérico para campos opcionais que quando preenchidos, 
  /// devem ter conteúdo mínimo.
  static String? validateOptionalText(String? value, {
    int minLength = 2,
    String fieldName = 'This field',
  }) {
    if (value == null || value.trim().isEmpty) {
      return null; // Opcional, pode estar vazio
    }
    
    if (value.trim().length < minLength) {
      return '$fieldName must be at least $minLength characters';
    }
    
    return null;
  }
  
  /// Verifica se email tem formato básico válido (validação rápida)
  /// 
  /// Retorna true se parece válido.
  static bool isEmailFormatValid(String email) {
    return validateEmail(email) == null;
  }
  
  /// Verifica se senha atende requisitos mínimos
  /// 
  /// Retorna true se válida.
  static bool isPasswordValid(String password, {bool isSignUp = false}) {
    return validatePassword(password, isSignUp: isSignUp) == null;
  }
}
