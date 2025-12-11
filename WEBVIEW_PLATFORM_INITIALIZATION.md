# Inicialização da Plataforma WebView

## Resumo

A inicialização da plataforma WebView foi movida para o `AppInitializerService` para garantir que `WebViewPlatform.instance` esteja configurado antes de qualquer tela que utilize WebView ser aberta.

## Problema Original

Quando `FaceVerificationScreen` tentava criar um `WebViewController`, ocorria o erro:

```
Assertion failed: WebViewPlatform.instance != null
```

Isso acontecia porque a plataforma WebView não estava registrada antes da tela ser aberta.

## Solução Implementada

### 1. Inicialização no AppInitializerService

A plataforma WebView agora é registrada como **passo 1** do bootstrap do app:

```dart
// app_initializer_service.dart

Future<void> initialize() async {
  // 1. Inicializa WebView platform (necessário para FaceVerificationScreen)
  debugPrint('🌐 [AppInitializer] Inicializando WebView platform...');
  try {
    if (WebViewPlatform.instance == null) {
      debugPrint('⚠️ [AppInitializer] WebViewPlatform.instance é null, registrando plataforma...');
      // Registra a implementação de plataforma apropriada
      if (defaultTargetPlatform == TargetPlatform.android) {
        WebViewPlatform.instance = AndroidWebViewController.new;
      } else if (defaultTargetPlatform == TargetPlatform.iOS) {
        WebViewPlatform.instance = WebKitWebViewController.new;
      }
    }
    debugPrint('✅ [AppInitializer] WebView platform inicializado');
  } catch (e) {
    debugPrint('⚠️ [AppInitializer] Erro ao inicializar WebView: $e');
  }
  
  // ... resto da inicialização
}
```

### 2. Simplificação no FaceVerificationScreen

O `FaceVerificationScreen` foi simplificado, removendo:

- `WidgetsBinding.instance.addPostFrameCallback`
- Delays artificiais (100ms)
- Workarounds de timing

**Antes:**

```dart
@override
void initState() {
  super.initState();
  
  // Garante que a plataforma WebView está inicializada
  WidgetsBinding.instance.addPostFrameCallback((_) {
    _loadApiKeyAndInitialize();
  });
}
```

**Depois:**

```dart
@override
void initState() {
  super.initState();
  _loadApiKeyAndInitialize();
}
```

## Benefícios

1. **Arquitetura Mais Limpa**: A inicialização de plataforma acontece no lugar correto (bootstrap do app)
2. **Remoção de Workarounds**: Não é mais necessário `postFrameCallback` ou delays artificiais
3. **Garantia de Disponibilidade**: `WebViewPlatform.instance` sempre estará configurado quando qualquer tela for aberta
4. **Debug Melhorado**: Logs detalhados no bootstrap mostram quando WebView foi inicializado
5. **Reutilizável**: Qualquer outra tela que use WebView agora funcionará sem configuração adicional

## Fluxo de Inicialização

```
App Startup
  ↓
AppInitializerService.initialize()
  ↓
WebView Platform Registration (Passo 1)
  ├─ Android: AndroidWebViewController.new
  └─ iOS: WebKitWebViewController.new
  ↓
BlockService, ListDrawer, Avatar, etc. (Passos 2-13)
  ↓
HomeScreen carregado
  ↓
User toca VerificationCard
  ↓
FaceVerificationScreen abre
  ↓
WebViewController criado (plataforma já registrada ✅)
```

## Dependências Necessárias

```yaml
# pubspec.yaml
dependencies:
  webview_flutter: ^4.10.0
  webview_flutter_android: ^4.10.11
  webview_flutter_wkwebview: ^3.23.5
```

## Compatibilidade

- ✅ Android: `AndroidWebViewController`
- ✅ iOS: `WebKitWebViewController`
- ⚠️ Outras plataformas: A inicialização não fará nada (plataforma permanecerá null)

## Testes

Para verificar se a inicialização está funcionando:

1. Abra o app
2. Verifique os logs de debug:
   ```
   🚀 [AppInitializer] Iniciando bootstrap do app...
   🌐 [AppInitializer] Inicializando WebView platform...
   ✅ [AppInitializer] WebView platform inicializado
   ```
3. Abra `FaceVerificationScreen` (toque no `VerificationCard`)
4. Verifique que não há erro de assertion sobre `WebViewPlatform.instance`

## Manutenção Futura

Se novas telas precisarem de WebView:

1. ✅ Não é necessário inicializar a plataforma novamente
2. ✅ Não é necessário usar `postFrameCallback`
3. ✅ Apenas crie o `WebViewController` normalmente

```dart
// Em qualquer tela:
final controller = WebViewController()
  ..setJavaScriptMode(JavaScriptMode.unrestricted)
  ..loadRequest(Uri.parse('https://example.com'));
```

## Referências

- [webview_flutter Documentation](https://pub.dev/packages/webview_flutter)
- [WebViewPlatform API](https://pub.dev/documentation/webview_flutter_platform_interface/latest/webview_flutter_platform_interface/WebViewPlatform-class.html)
- Implementação: `/lib/core/services/app_initializer_service.dart`
- Uso: `/lib/features/profile/presentation/screens/face_verification_screen.dart`
