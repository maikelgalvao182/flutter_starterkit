#!/bin/bash

# Script para configurar TTL Policy no Firestore
# Collection: ProfileVisits
# Field: expireAt
# Retention: 7 dias (configurado no código)

echo "🔧 Configurando TTL Policy para ProfileVisits..."
echo ""
echo "⚠️  IMPORTANTE: Execute este comando manualmente no Firebase Console"
echo "    Ainda não há suporte completo via CLI para TTL policies"
echo ""
echo "📋 Instruções:"
echo ""
echo "1. Acesse: https://console.firebase.google.com"
echo "2. Selecione projeto: Partiu"
echo "3. Menu: Firestore Database → TTL"
echo "4. Clique: 'Create TTL policy'"
echo "5. Configure:"
echo "   - Collection group ID: ProfileVisits"
echo "   - Timestamp field: expireAt"
echo "   - Status: Enabled"
echo "6. Salve a configuração"
echo ""
echo "✅ Após configurar, visitas com mais de 7 dias serão deletadas automaticamente"
echo ""

# Alternativa: gcloud (requer configuração adicional)
echo "🔄 Alternativa via gcloud (avançado):"
echo ""
echo "gcloud firestore fields ttls update expireAt \\"
echo "  --collection-group=ProfileVisits \\"
echo "  --enable-ttl \\"
echo "  --project=partiu-app"
echo ""
