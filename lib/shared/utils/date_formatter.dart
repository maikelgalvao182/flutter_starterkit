import 'package:intl/intl.dart';

/// Serviço utilitário para formatação de datas
/// 
/// Centraliza toda lógica de formatação, evitando duplicação
class DateFormatter {
  DateFormatter._();

  /// Formata a data para exibição (hoje, amanhã ou dia específico)
  static String formatDate(DateTime? date) {
    if (date == null) return '';
    
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    final eventDay = DateTime(date.year, date.month, date.day);
    
    if (eventDay == today) {
      return 'hoje';
    } else if (eventDay == tomorrow) {
      return 'amanhã';
    } else {
      return 'dia ${DateFormat('dd/MM').format(date)}';
    }
  }

  /// Formata o horário para exibição (apenas se for horário específico)
  /// 
  /// Retorna string vazia se for meia-noite exata (00:00), 
  /// pois isso indica horário flexível (só data)
  static String formatTime(DateTime? date) {
    if (date == null) return '';
    
    // Se for meia-noite exata (00:00), significa que é flexible (só data)
    if (date.hour == 0 && date.minute == 0) {
      return '';
    }
    
    // Caso contrário, mostrar o horário formatado
    return DateFormat('HH:mm').format(date);
  }
}
