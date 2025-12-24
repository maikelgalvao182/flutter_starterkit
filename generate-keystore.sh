#!/bin/bash

# Script para gerar keystore de produção para Android
# Uso: ./generate-keystore.sh

echo "🔐 Gerando keystore de produção para Android..."
echo ""

# Verificar se keystore já existe
if [ -f "android/app/partiu-release-key.jks" ]; then
    echo "⚠️  Keystore já existe em android/app/partiu-release-key.jks"
    read -p "Deseja substituir? (s/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Ss]$ ]]; then
        echo "❌ Operação cancelada"
        exit 1
    fi
    rm android/app/partiu-release-key.jks
fi

# Solicitar informações
echo "📝 Preencha as informações do certificado:"
echo ""
read -p "Alias da chave (ex: partiu-key): " KEY_ALIAS
read -sp "Senha da chave: " KEY_PASSWORD
echo ""
read -sp "Confirme a senha da chave: " KEY_PASSWORD_CONFIRM
echo ""

if [ "$KEY_PASSWORD" != "$KEY_PASSWORD_CONFIRM" ]; then
    echo "❌ Senhas não coincidem!"
    exit 1
fi

read -sp "Senha do keystore: " STORE_PASSWORD
echo ""
read -sp "Confirme a senha do keystore: " STORE_PASSWORD_CONFIRM
echo ""

if [ "$STORE_PASSWORD" != "$STORE_PASSWORD_CONFIRM" ]; then
    echo "❌ Senhas não coincidem!"
    exit 1
fi

echo ""
read -p "Nome completo (ex: Maikel Galvao): " CN_NAME
read -p "Organização (ex: Partiu): " CN_ORG
read -p "Cidade (ex: São Paulo): " CN_CITY
read -p "Estado (ex: SP): " CN_STATE
read -p "País (código de 2 letras, ex: BR): " CN_COUNTRY

# Gerar keystore
echo ""
echo "🔨 Gerando keystore..."
keytool -genkey -v -keystore android/app/partiu-release-key.jks \
    -alias "$KEY_ALIAS" \
    -keyalg RSA \
    -keysize 2048 \
    -validity 10000 \
    -storepass "$STORE_PASSWORD" \
    -keypass "$KEY_PASSWORD" \
    -dname "CN=$CN_NAME, OU=$CN_ORG, O=$CN_ORG, L=$CN_CITY, ST=$CN_STATE, C=$CN_COUNTRY"

if [ $? -eq 0 ]; then
    echo "✅ Keystore gerado com sucesso!"
    echo ""
    
    # Criar arquivo key.properties
    echo "📝 Criando arquivo key.properties..."
    cat > android/key.properties << EOF
storePassword=$STORE_PASSWORD
keyPassword=$KEY_PASSWORD
keyAlias=$KEY_ALIAS
storeFile=app/partiu-release-key.jks
EOF
    
    echo "✅ Arquivo key.properties criado!"
    echo ""
    
    # Adicionar ao .gitignore
    if ! grep -q "key.properties" .gitignore; then
        echo "" >> .gitignore
        echo "# Android signing" >> .gitignore
        echo "android/key.properties" >> .gitignore
        echo "android/app/*.jks" >> .gitignore
        echo "✅ Adicionado ao .gitignore"
    fi
    
    # Obter SHA-1 e SHA-256
    echo ""
    echo "🔑 SHA-1 e SHA-256 do certificado:"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    keytool -list -v -keystore android/app/partiu-release-key.jks \
        -alias "$KEY_ALIAS" \
        -storepass "$STORE_PASSWORD" | grep -E "SHA1:|SHA256:"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    echo "📋 IMPORTANTE:"
    echo "1. Adicione esses hashes no Google Cloud Console:"
    echo "   https://console.cloud.google.com/apis/credentials"
    echo ""
    echo "2. Configure nas restrições da API Key do Google Maps:"
    echo "   - Nome do pacote: com.maikelgalvao.partiu"
    echo "   - SHA-1 acima"
    echo ""
    echo "3. NUNCA compartilhe o arquivo .jks ou as senhas!"
    echo ""
    echo "✅ Configuração completa!"
    echo "📦 Agora você pode fazer build de release: flutter build appbundle --release"
else
    echo "❌ Erro ao gerar keystore!"
    exit 1
fi
