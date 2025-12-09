/// Arquitetura Modular do ReviewDialog Controller
/// 
/// Esta estrutura segue princípios SOLID e Clean Architecture:
library;
/// 
/// 📦 **review_dialog_state.dart**
///    - Gerencia ESTADO puro (dados)
///    - Sem lógica de negócio
///    - Imutável com copyWith()
/// 
/// ✅ **review_validation_service.dart**
///    - Validações de regras de negócio
///    - Verificações de permissão
///    - Validações de completude
/// 
/// 🎨 **review_ui_service.dart**
///    - Lógica de apresentação
///    - Formatação de textos
///    - Mensagens de erro
/// 
/// 📝 **review_batch_service.dart**
///    - Operações em lote (Firestore batch)
///    - Criação de documentos
///    - Operações de persistência
/// 
/// 🧭 **review_navigation_service.dart**
///    - Lógica de navegação entre steps
///    - Transições de estado
///    - Preparação de dados para navegação
/// 
/// 🎮 **review_dialog_controller_v2.dart**
///    - Orquestrador principal
///    - Delega para serviços especializados
///    - Gerencia ChangeNotifier

export 'review_dialog_state.dart';
export 'review_validation_service.dart';
export 'review_ui_service.dart';
export 'review_batch_service.dart';
export 'review_navigation_service.dart';
export '../review_dialog_controller.dart';
