# Chaves SHA1 e SHA256 - Partiu/Boora

## 🔧 Ambiente de Desenvolvimento (Sandbox/Debug)

### Debug Keystore
- **Localização**: `~/.android/debug.keystore`
- **Alias**: `androiddebugkey`
- **Password**: `android`

### Fingerprints

#### SHA1
```
E7:12:4C:B1:AA:4B:B5:AC:D1:C8:80:27:C6:43:4D:39:D5:E0:5C:1D
```

#### SHA256
```
EA:97:C7:44:51:F9:E3:0E:C0:4D:18:BC:7C:69:86:11:77:65:97:E6:EA:F2:C6:62:53:6D:FE:6D:91:F6:C0:8F
```

---

## 🚀 Ambiente de Produção (Release)

> ⚠️ **IMPORTANTE**: Atualmente o projeto está usando o debug keystore para release builds.
> 
> Para produção, é necessário:
> 1. Criar um keystore de produção
> 2. Configurar o signing no `android/app/build.gradle.kts`
> 3. Gerar novas chaves SHA1 e SHA256

### Criar Keystore de Produção

```bash
keytool -genkey -v -keystore ~/upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload
```

### Configurar Signing

Adicione ao `android/app/build.gradle.kts`:

```kotlin
android {
    // ... outras configurações

    signingConfigs {
        create("release") {
            storeFile = file(System.getenv("KEYSTORE_PATH") ?: "/path/to/your/keystore.jks")
            storePassword = System.getenv("KEYSTORE_PASSWORD")
            keyAlias = System.getenv("KEY_ALIAS")
            keyPassword = System.getenv("KEY_PASSWORD")
        }
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("release")
            // ... outras configurações
        }
    }
}
```

### Extrair Chaves do Keystore de Produção

Após criar o keystore de produção, execute:

```bash
keytool -list -v -keystore ~/upload-keystore.jks -alias upload
```

---

## 📱 Uso das Chaves

### Firebase Console
1. Acesse o [Firebase Console](https://console.firebase.google.com/)
2. Vá em **Project Settings** > **General**
3. Role até **Your apps** > **Android app**
4. Adicione as chaves SHA1 e SHA256 em **SHA certificate fingerprints**

### Google Cloud Console (para Google Maps, etc)
1. Acesse o [Google Cloud Console](https://console.cloud.google.com/)
2. Vá em **APIs & Services** > **Credentials**
3. Configure as chaves SHA1 e SHA256 nas credenciais da API

### Google Sign-In / Play Services
As chaves SHA1 são necessárias para:
- Google Sign-In
- Google Maps
- Firebase Authentication (Google)
- Firebase Dynamic Links
- Play Integrity API

---

## 🔍 Comandos Úteis

### Ver certificado do debug keystore
```bash
keytool -list -v -keystore ~/.android/debug.keystore -storepass android -alias androiddebugkey
```

### Ver apenas SHA1 e SHA256 (simplificado)
```bash
keytool -list -v -keystore ~/.android/debug.keystore -storepass android | grep -E "SHA1|SHA256"
```

### Verificar keystore personalizado
```bash
keytool -list -v -keystore /path/to/your/keystore.jks -alias your-alias
```

---

## ⚠️ Notas Importantes

1. **NUNCA** commite keystores de produção no Git
2. Use variáveis de ambiente para senhas
3. Mantenha backup seguro do keystore de produção
4. Se perder o keystore de produção, não será possível atualizar o app na Play Store
5. Use keystores diferentes para debug e release
6. Adicione ambas as chaves (SHA1 e SHA256) no Firebase

---

**Gerado em**: 23 de dezembro de 2025
