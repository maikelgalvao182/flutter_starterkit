# 🚀 Deploy do WebSocket Server (NestJS)

## ✅ Arquitetura

O WebSocket server usa **NestJS** com Socket.IO Gateway e inclui:
- ✅ Autenticação Firebase
- ✅ Rooms por usuário (bride/vendor)
- ✅ Endpoint HTTP `/notify` para Cloud Functions

## 📦 1. Instalar dependências

```bash
cd wedding-websocket
npm install
```

## 🧪 2. Testar localmente

```bash
npm run start:dev
```

Deve aparecer:
```
🚀 WebSocket Service running on http://0.0.0.0:8080
📡 Socket.IO ready for connections
```

## 🌐 3. Deploy no Cloud Run

```bash
gcloud run deploy wedding-websocket \
  --source . \
  --port=8080 \
  --allow-unauthenticated \
  --use-http2 \
  --region=us-central1 \
  --set-env-vars INTERNAL_SECRET=4l2xIMZw3K/OFZImBF8G9j5CeV5APl3C4IjdBjpbYrs=
```

## 🔧 4. Atualizar variável de ambiente nas Cloud Functions

Certifique-se que a Cloud Function tem:
```
WEBSOCKET_URL=https://wedding-websocket-dux2nu33ua-uc.a.run.app
INTERNAL_SECRET=4l2xIMZw3K/OFZImBF8G9j5CeV5APl3C4IjdBjpbYrs=
```

## ✅ 5. Testar o fluxo completo

1. App conectado (vendor)
2. Bride aceita/rejeita aplicação
3. Vendor deve receber atualização instantânea

## 🔍 Verificar se está funcionando

```bash
# Health check
curl https://wedding-websocket-dux2nu33ua-uc.a.run.app/health

# Deve retornar:
{
  "status": "ok",
  "connectedClients": 0,
  "uptime": 123
}
```
