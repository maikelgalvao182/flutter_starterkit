# 📋 PLANO DE MIGRAÇÃO: SISTEMA DE ASSINATURAS (RevenueCat)

**Projeto Origem:** Advanced-Dating  
**Projeto Destino:** Partiu  
**Data:** 02/12/2025  
**Estratégia:** Copiar e colar arquivos, ajustar imports mínimos

---

## 📦 INVENTÁRIO COMPLETO DE ARQUIVOS

### 🎯 CORE - Serviços RevenueCat (3 arquivos)
```
lib/services/
├── simple_revenue_cat_service.dart         [CORE] Wrapper do RevenueCat SDK
├── vip_access_service.dart                 [CORE] Gerenciamento de acesso VIP global
└── subscription_monitoring_service.dart    [CORE] Monitoramento em tempo real de assinatura
```

### 🏗️ DOMAIN - Modelos de Negócio (1 arquivo)
```
lib/features/subscription/domain/
└── subscription_plan.dart                  [DOMAIN] Enum de planos (monthly, annual)
```

### 🎮 CONTROLLERS (1 arquivo)
```
lib/features/subscription/presentation/controllers/
└── subscription_purchase_controller.dart   [CONTROLLER] Lógica de compra e restore
```

### 🎨 PRESENTATION - Widgets (6 arquivos)
```
lib/features/subscription/presentation/widgets/
├── subscription_active_badge.dart          [UI] Badge de assinatura ativa
├── subscription_benefits_list.dart         [UI] Lista de benefícios VIP
├── subscription_footer.dart                [UI] Footer com termos e restore
├── subscription_header.dart                [UI] Header do diálogo
├── subscription_plan_card.dart             [UI] Card de plano individual
└── subscription_states.dart                [UI] Estados: loading, error, empty
```

### 🎬 ANIMATIONS (1 arquivo)
```
lib/features/subscription/presentation/animations/
└── dialog_slide_animation.dart             [ANIMATION] Slide animation para dialog
```

### 🔌 PROVIDERS (1 arquivo)
```
lib/providers/
└── simple_subscription_provider.dart       [PROVIDER] Provider para gerenciar estado
```

### 💬 DIALOG PRINCIPAL (1 arquivo)
```
lib/dialogs/
└── vip_dialog.dart                         [DIALOG] Dialog principal de assinatura
```

### 🛠️ HELPERS & UTILS (2 arquivos)
```
lib/helpers/
├── vip_access_helper.dart                  [HELPER] Helper para verificar acesso VIP
└── toast_messages_helper.dart              [HELPER] Mensagens de toast traduzidas
```

### 📢 TOAST SYSTEM (2 arquivos)
```
lib/services/
└── toast_service.dart                      [SERVICE] Serviço de toasts

lib/constants/
├── toast_messages.dart                     [CONSTANTS] Mensagens de toast
└── toast_constants.dart                    [CONSTANTS] Constantes de toast
```

### 🐛 DEBUG (1 arquivo - OPCIONAL)
```
lib/services/
└── vip_status_debugger.dart                [DEBUG] Debugger de status VIP (opcional)
```

---

## 📊 ESTATÍSTICAS

- **Total de arquivos:** 19 arquivos
- **Arquivos core (obrigatórios):** 16 arquivos
- **Arquivos opcionais (debug):** 3 arquivos
- **Linhas estimadas:** ~2500 linhas de código

---

## 🎯 ETAPAS DE MIGRAÇÃO

### ✅ ETAPA 1: CORE SERVICES (Fundação)
**Prioridade:** CRÍTICA  
**Tempo estimado:** 30 min  
**Dependências:** RevenueCat SDK (purchases_flutter)

**Arquivos a copiar:**
1. `lib/services/simple_revenue_cat_service.dart`
2. `lib/services/vip_access_service.dart`
3. `lib/services/subscription_monitoring_service.dart`

**Ajustes necessários:**
- ✏️ Imports: `dating_app` → `partiu`
- ✏️ Verificar se `purchases_flutter` está no `pubspec.yaml`
- ✏️ Configurar API keys do RevenueCat (iOS/Android)

**Validação:**
```dart
// Testar se inicializa corretamente
await SimpleRevenueCatService.initialize();
print('RevenueCat inicializado: ${SimpleRevenueCatService.isConfigured}');
```

---

### ✅ ETAPA 2: DOMAIN & HELPERS (Modelos)
**Prioridade:** ALTA  
**Tempo estimado:** 15 min  
**Dependências:** Etapa 1

**Arquivos a copiar:**
1. `lib/features/subscription/domain/subscription_plan.dart`
2. `lib/helpers/vip_access_helper.dart`
3. `lib/helpers/toast_messages_helper.dart`

**Ajustes necessários:**
- ✏️ Imports: `dating_app` → `partiu`
- ✏️ `vip_access_helper.dart` usa `SubscriptionMonitoringService` (já copiado)
- ✏️ `toast_messages_helper.dart` usa `AppLocalizations` (verificar se existe)

**Validação:**
```dart
// Testar enum de planos
print('Planos: ${SubscriptionPlan.values}');

// Testar helper
print('É VIP: ${VipAccessHelper.isVip()}');
```

---

### ✅ ETAPA 3: TOAST SYSTEM (Feedback Visual)
**Prioridade:** ALTA  
**Tempo estimado:** 20 min  
**Dependências:** Etapa 2

**Arquivos a copiar:**
1. `lib/services/toast_service.dart`
2. `lib/constants/toast_messages.dart`
3. `lib/constants/toast_constants.dart`

**Ajustes necessários:**
- ✏️ Imports: `dating_app` → `partiu`
- ✏️ Verificar se usa algum package de toast (ex: `toastification`)
- ✏️ Adaptar cores/estilos para o tema do Partiu

**Validação:**
```dart
// Testar toast
ToastService.showSuccess(
  context: context,
  title: 'Teste',
  subtitle: 'Toast funcionando',
);
```

---

### ✅ ETAPA 4: PROVIDER (Estado Global)
**Prioridade:** ALTA  
**Tempo estimado:** 15 min  
**Dependências:** Etapa 1

**Arquivos a copiar:**
1. `lib/providers/simple_subscription_provider.dart`

**Ajustes necessários:**
- ✏️ Imports: `dating_app` → `partiu`
- ✏️ Usa `SimpleRevenueCatService` (já copiado)
- ✏️ Registrar provider no main.dart

**Validação:**
```dart
// No main.dart
MultiProvider(
  providers: [
    ChangeNotifierProvider(create: (_) => SimpleSubscriptionProvider()),
  ],
  child: MyApp(),
)
```

---

### ✅ ETAPA 5: CONTROLLER (Lógica de Compra)
**Prioridade:** CRÍTICA  
**Tempo estimado:** 20 min  
**Dependências:** Etapas 1, 2, 4

**Arquivos a copiar:**
1. `lib/features/subscription/presentation/controllers/subscription_purchase_controller.dart`

**Ajustes necessários:**
- ✏️ Imports: `dating_app` → `partiu`
- ✏️ Usa `SimpleSubscriptionProvider` (já copiado)
- ✏️ Usa `SubscriptionPlan` (já copiado)
- ✏️ Callbacks de sucesso/erro

**Validação:**
```dart
// Testar controller
final controller = SubscriptionPurchaseController(
  provider: provider,
  onSuccess: () => print('Sucesso'),
  onError: (err) => print('Erro: $err'),
);
await controller.initialize();
```

---

### ✅ ETAPA 6: ANIMATIONS (UI Polida)
**Prioridade:** MÉDIA  
**Tempo estimado:** 10 min  
**Dependências:** Nenhuma (standalone)

**Arquivos a copiar:**
1. `lib/features/subscription/presentation/animations/dialog_slide_animation.dart`

**Ajustes necessários:**
- ✏️ Nenhum (código puro de animação)
- ✏️ Verificar se usa `SingleTickerProviderStateMixin`

**Validação:**
```dart
// Testar animação
final animation = DialogSlideAnimation(vsync: this);
animation.enter();
```

---

### ✅ ETAPA 7: UI WIDGETS (Interface)
**Prioridade:** ALTA  
**Tempo estimado:** 40 min  
**Dependências:** Etapas 1, 2, 3, 5

**Arquivos a copiar:**
1. `lib/features/subscription/presentation/widgets/subscription_active_badge.dart`
2. `lib/features/subscription/presentation/widgets/subscription_benefits_list.dart`
3. `lib/features/subscription/presentation/widgets/subscription_footer.dart`
4. `lib/features/subscription/presentation/widgets/subscription_header.dart`
5. `lib/features/subscription/presentation/widgets/subscription_plan_card.dart`
6. `lib/features/subscription/presentation/widgets/subscription_states.dart`

**Ajustes necessários:**
- ✏️ Imports: `dating_app` → `partiu`
- ✏️ `subscription_plan_card.dart` usa `Package` do RevenueCat
- ✏️ `subscription_benefits_list.dart` usa i18n
- ✏️ Verificar se `GlimpseButton` existe no Partiu (provavelmente sim)
- ✏️ Adaptar cores/estilos para o tema do Partiu

**Validação:**
```dart
// Testar widget individual
SubscriptionPlanCard(
  package: package,
  isSelected: true,
  onTap: () {},
)
```

---

### ✅ ETAPA 8: VIP DIALOG (Integração Final)
**Prioridade:** CRÍTICA  
**Tempo estimado:** 30 min  
**Dependências:** TODAS as etapas anteriores

**Arquivos a copiar:**
1. `lib/dialogs/vip_dialog.dart`

**Ajustes necessários:**
- ✏️ Imports: `dating_app` → `partiu`
- ✏️ Usa TODOS os arquivos anteriores
- ✏️ Integrar com navegação do Partiu
- ✏️ Adaptar layout se necessário

**Validação:**
```dart
// Abrir dialog
showDialog(
  context: context,
  builder: (_) => const VipDialog(),
);
```

---

### ✅ ETAPA 9: CONFIGURAÇÃO & INTEGRAÇÃO (Setup Final)
**Prioridade:** CRÍTICA  
**Tempo estimado:** 30 min  
**Dependências:** Etapa 8

**Tarefas:**
1. ✅ Adicionar `purchases_flutter` ao `pubspec.yaml`
2. ✅ Configurar API Keys do RevenueCat:
   - iOS: `Info.plist` → `RevenueCat_iOS_API_Key`
   - Android: `AndroidManifest.xml` → metadata
3. ✅ Criar produtos no RevenueCat Dashboard:
   - `monthly_subscription`
   - `annual_subscription`
4. ✅ Inicializar RevenueCat no `main.dart`:
   ```dart
   await SimpleRevenueCatService.initialize();
   ```
5. ✅ Registrar listener global:
   ```dart
   SubscriptionMonitoringService.startListening();
   ```
6. ✅ Integrar VipDialog nos locais necessários:
   - Tela de perfil
   - Features premium
   - Notificações (se usar masking)

**Validação:**
```dart
// Verificar inicialização completa
print('RevenueCat configurado: ${SimpleRevenueCatService.isConfigured}');
print('Listener ativo: ${SubscriptionMonitoringService.isListening}');
print('Tem acesso VIP: ${VipAccessHelper.isVip()}');
```

---

### 🐛 ETAPA 10 (OPCIONAL): DEBUG TOOLS
**Prioridade:** BAIXA  
**Tempo estimado:** 10 min  
**Dependências:** Etapa 1

**Arquivos a copiar:**
1. `lib/services/vip_status_debugger.dart` (OPCIONAL)

**Ajustes necessários:**
- ✏️ Imports: `dating_app` → `partiu`
- ✏️ Apenas para debug, pode ser ignorado em produção

**Validação:**
```dart
// Mostrar debug de status
VipStatusDebugger.printStatus();
```

---

## 🔧 DEPENDÊNCIAS DO PUBSPEC.YAML

Adicionar ao `pubspec.yaml` do Partiu:

```yaml
dependencies:
  # RevenueCat SDK
  purchases_flutter: ^8.2.3
  
  # Toast (se não existir)
  toastification: ^2.3.0  # ou outro package de toast usado
  
  # Provider (provavelmente já existe)
  provider: ^6.1.2
```

---

## 📝 CHECKLIST DE MIGRAÇÃO

### Pré-requisitos
- [ ] Verificar se `purchases_flutter` está instalado
- [ ] Verificar se `provider` está instalado
- [ ] Verificar se `AppLocalizations` existe no Partiu
- [ ] Verificar se `GlimpseButton` existe no Partiu
- [ ] Criar conta no RevenueCat Dashboard
- [ ] Criar produtos no RevenueCat (monthly, annual)

### Etapa 1: Core Services
- [ ] Copiar `simple_revenue_cat_service.dart`
- [ ] Copiar `vip_access_service.dart`
- [ ] Copiar `subscription_monitoring_service.dart`
- [ ] Ajustar imports
- [ ] Testar inicialização

### Etapa 2: Domain & Helpers
- [ ] Copiar `subscription_plan.dart`
- [ ] Copiar `vip_access_helper.dart`
- [ ] Copiar `toast_messages_helper.dart`
- [ ] Ajustar imports
- [ ] Testar enum e helpers

### Etapa 3: Toast System
- [ ] Copiar `toast_service.dart`
- [ ] Copiar `toast_messages.dart`
- [ ] Copiar `toast_constants.dart`
- [ ] Ajustar imports
- [ ] Testar toast

### Etapa 4: Provider
- [ ] Copiar `simple_subscription_provider.dart`
- [ ] Ajustar imports
- [ ] Registrar no main.dart
- [ ] Testar provider

### Etapa 5: Controller
- [ ] Copiar `subscription_purchase_controller.dart`
- [ ] Ajustar imports
- [ ] Testar controller

### Etapa 6: Animations
- [ ] Copiar `dialog_slide_animation.dart`
- [ ] Testar animação

### Etapa 7: UI Widgets
- [ ] Copiar `subscription_active_badge.dart`
- [ ] Copiar `subscription_benefits_list.dart`
- [ ] Copiar `subscription_footer.dart`
- [ ] Copiar `subscription_header.dart`
- [ ] Copiar `subscription_plan_card.dart`
- [ ] Copiar `subscription_states.dart`
- [ ] Ajustar imports
- [ ] Adaptar estilos
- [ ] Testar widgets

### Etapa 8: VIP Dialog
- [ ] Copiar `vip_dialog.dart`
- [ ] Ajustar imports
- [ ] Testar dialog

### Etapa 9: Configuração Final
- [ ] Adicionar dependências ao pubspec.yaml
- [ ] Configurar API Keys do RevenueCat
- [ ] Criar produtos no Dashboard
- [ ] Inicializar no main.dart
- [ ] Integrar em features premium
- [ ] Testar fluxo completo

### Etapa 10 (Opcional): Debug
- [ ] Copiar `vip_status_debugger.dart` (se necessário)

---

## 🎨 AJUSTES DE ESTILO

Após copiar todos os arquivos, revisar:

1. **Cores:**
   - Substituir cores específicas do Advanced-Dating por cores do Partiu
   - Verificar `GlimpseColors` vs cores customizadas

2. **Fontes:**
   - Manter `FONT_PLUS_JAKARTA_SANS` (provavelmente igual)
   - Ajustar tamanhos se necessário

3. **Espaçamentos:**
   - Verificar se padding/margin seguem guidelines do Partiu

4. **i18n:**
   - Adicionar chaves de tradução faltantes em `assets/lang/`

---

## 🧪 TESTES FINAIS

Após completar todas as etapas:

1. **Teste de Inicialização:**
   ```dart
   await SimpleRevenueCatService.initialize();
   ```

2. **Teste de Ofertas:**
   ```dart
   final offerings = await SimpleRevenueCatService.getOfferings();
   print('Ofertas disponíveis: ${offerings?.all}');
   ```

3. **Teste de Compra (Sandbox):**
   - Abrir VipDialog
   - Selecionar plano
   - Realizar compra de teste
   - Verificar se acesso é concedido

4. **Teste de Restore:**
   - Fazer logout
   - Fazer login novamente
   - Clicar em "Restore Purchases"
   - Verificar se acesso é restaurado

5. **Teste de Listener:**
   - Assinar
   - Verificar se app detecta mudança
   - Verificar se VipDialog fecha automaticamente

---

## 📚 DOCUMENTAÇÃO ADICIONAL

- **RevenueCat Docs:** https://docs.revenuecat.com/
- **purchases_flutter:** https://pub.dev/packages/purchases_flutter
- **Configuração iOS:** https://docs.revenuecat.com/docs/ios-sdk-setup
- **Configuração Android:** https://docs.revenuecat.com/docs/android-sdk-setup

---

## ⚠️ NOTAS IMPORTANTES

1. **API Keys são SECRETAS:**
   - Nunca commitar API keys no git
   - Usar environment variables ou Firebase Remote Config

2. **Produtos no RevenueCat:**
   - Criar produtos ANTES de testar
   - IDs devem bater: código ↔️ Dashboard ↔️ App Store/Play Store

3. **Sandbox vs Produção:**
   - Testar SEMPRE em sandbox primeiro
   - Usar contas de teste do App Store Connect / Play Console

4. **Listener Global:**
   - Apenas UM listener deve estar ativo
   - Inicializar no main.dart
   - Não esquecer de dispose()

5. **Cache de CustomerInfo:**
   - RevenueCat faz cache automático
   - Não precisa implementar cache manual

---

## 🎯 ESTRATÉGIA DE EXECUÇÃO

### Ordem recomendada:
1. Etapa 1 → Testar
2. Etapa 2 → Testar
3. Etapa 3 → Testar
4. Etapa 4 → Testar
5. Etapa 5 → Testar
6. Etapa 6
7. Etapa 7 → Testar cada widget
8. Etapa 8 → Testar dialog completo
9. Etapa 9 → Configuração e integração
10. Testes finais end-to-end

### Tempo total estimado: **3-4 horas**

---

## ✅ RESULTADO ESPERADO

Após completar todas as etapas, o Partiu terá:

- ✅ Sistema de assinaturas RevenueCat integrado
- ✅ VipDialog funcional e elegante
- ✅ Verificação de acesso VIP em tempo real
- ✅ Compra e restore de assinaturas
- ✅ UI polida com animações suaves
- ✅ Toast feedback para usuário
- ✅ Listener global de mudanças de assinatura
- ✅ Debug tools (opcional)

---

## 📞 SUPORTE

Em caso de dúvidas ou problemas:
1. Verificar logs do RevenueCat
2. Consultar documentação oficial
3. Testar em sandbox primeiro
4. Validar produtos no Dashboard

---

**Autor:** GitHub Copilot  
**Versão:** 1.0  
**Status:** Pronto para execução ✅
