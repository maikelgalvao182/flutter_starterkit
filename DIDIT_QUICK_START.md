# Guia Rápido: Integração Didit

## 🚀 Setup em 5 Minutos

### 1. Configurar Firestore

Adicione documento em `AppInfo/didio`:

```javascript
{
  "api_key": "sua-api-key-aqui",
  "app_id": "seu-app-id-aqui",
  "callback_url": "https://partiu.app/verification/callback"
}
```

### 2. Usar no Código

```dart
import 'package:partiu/screens/verification/didit_verification_screen.dart';
import 'package:permission_handler/permission_handler.dart';

// Verificar permissões primeiro
await Permission.camera.request();
await Permission.microphone.request();

// Abrir tela de verificação
final verified = await Navigator.push<bool>(
  context,
  MaterialPageRoute(
    builder: (context) => const DiditVerificationScreen(),
  ),
);

if (verified == true) {
  print('✅ Usuário verificado!');
}
```

### 3. Verificar Status

```dart
import 'package:partiu/core/services/face_verification_service.dart';

// Verificar se está verificado
final isVerified = await FaceVerificationService.instance.isUserVerified();

// Observar mudanças
FaceVerificationService.instance
    .watchVerificationStatus(userId)
    .listen((verified) {
  print('Status: $verified');
});
```

## 📱 Testar

1. Execute: `flutter pub get`
2. Execute no dispositivo: `flutter run`
3. Navegue para a tela de verificação
4. Complete a verificação facial
5. Verifique que `user_is_verified = true` no Firestore

## 📝 Arquivos Criados

- ✅ `lib/core/models/didit_session.dart`
- ✅ `lib/core/services/didit_verification_service.dart`
- ✅ `lib/screens/verification/didit_verification_screen.dart`
- ✅ `lib/screens/verification/didit_verification_example.dart`
- ✅ `android/app/src/main/res/xml/provider_paths.xml`
- ✅ AndroidManifest.xml atualizado
- ✅ Info.plist já configurado

## 🔧 Dependências Instaladas

- ✅ `flutter_inappwebview: ^6.0.0`
- ✅ `permission_handler: ^11.0.0`

## ⚠️ IMPORTANTE

Para **produção**, mova a criação de sessões para uma Cloud Function para proteger a API key.

Ver detalhes em: `DIDIT_INTEGRATION_COMPLETE.md`
