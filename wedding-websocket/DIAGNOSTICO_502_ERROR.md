# 🔍 DIAGNÓSTICO: Erro 502 - WebSocket Cloud Run

**Data:** 26 de novembro de 2025  
**Serviço:** wedding-websocket  
**URL:** https://wedding-websocket-dux2nu33ua-uc.a.run.app  
**Erro:** `upstream connect error or disconnect/reset before headers. reset reason: protocol error`

---

## ❌ PROBLEMA IDENTIFICADO

**CAUSA RAIZ:** Incompatibilidade de protocolo entre Cloud Run e NestJS

- ✅ Cloud Run configurado para **HTTP/2 (h2c)** na porta 8080
- ❌ NestJS inicializando servidor **HTTP/1.1** por padrão
- 🔴 Load Balancer do Cloud Run recusa conexões por "protocol error"

---

## 📋 CHECKLIST DE VERIFICAÇÃO

### 🔥 1. SOBRE O CONTAINER WEBSOCKET

#### 1.1 - Servidor HTTP Normal?
**✅ SIM** - O serviço usa NestJS com Express HTTP server completo

```typescript
const app = await NestFactory.create(AppModule);
await app.listen(port, '0.0.0.0');
```

#### 1.2 - Escuta em `process.env.PORT`?
**✅ SIM** - Código correto:

```typescript
const port = parseInt(process.env.PORT || '8080', 10);
await app.listen(port, '0.0.0.0');
```

#### 1.3 - Endpoint POST /notify existe?
**✅ SIM** - Implementado em `NotifyController`:

```typescript
@Controller('notify')
export class NotifyController {
  @Post()
  notifyChange(...) { ... }
}
```

#### 1.4 - Servidor inicializa corretamente?
**⚠️ PARCIALMENTE** - NestJS cria HTTP server internamente, mas:
- ✅ Usa estrutura correta (não é só `io.listen()`)
- ❌ NÃO está configurado para HTTP/2
- ❌ Cloud Run espera h2c, mas recebe HTTP/1.1

**Código atual (HTTP/1.1):**
```typescript
const app = await NestFactory.create(AppModule);
// Internamente cria: http.createServer(expressApp)
```

**Código esperado pelo Cloud Run (HTTP/2):**
```typescript
// Precisa de adaptador HTTP/2 explícito
```

---

### 🔥 2. SOBRE CONFIG DO CLOUD RUN

#### 2.1 - Allow unauthenticated invocations?
**✅ SIM** - Confirmado pela ausência de erro 403

#### 2.2 - Rota HTTP listada?
**✅ SIM** 
```
URL: https://wedding-websocket-dux2nu33ua-uc.a.run.app
Region: us-central1
```

#### 2.3 - URL raiz responde?
**❌ NÃO** - Retorna 502, não 200/404

```bash
$ curl https://wedding-websocket-dux2nu33ua-uc.a.run.app/
< HTTP/2 502
upstream connect error or disconnect/reset before headers. reset reason: protocol error
```

**🔴 Diagnóstico:** O Load Balancer não consegue estabelecer conexão HTTP/2 com o container

---

### 🔥 3. SOBRE O ENDPOINT /notify

#### 3.1 - POST /notify implementado?
**✅ SIM** - Logs confirmam o mapeamento da rota:

```
[RouterExplorer] Mapped {/notify, POST} route +1ms
```

#### 3.2 - Funciona localmente?
**🟡 NÃO TESTADO** - Mas a implementação está correta

#### 3.3 - Usa Express JSON Middleware?
**✅ SIM** - NestJS habilita automaticamente

#### 3.4 - Sem erro "Cannot POST /notify"?
**⚠️ INCONCLUSIVO** - O container nunca processa a requisição por causa do erro de protocolo

---

### 🔥 4. SOBRE FIREWALL / HEADERS / AUTH

#### 4.1 - NÃO exige Authorization Bearer?
**❌ NÃO** - O endpoint **EXIGE** Authorization:

```typescript
const expectedSecret = process.env.INTERNAL_SECRET || 'your-secret-key';
if (!auth || auth !== `Bearer ${expectedSecret}`) {
  throw new UnauthorizedException('Invalid secret');
}
```

**⚠️ ATENÇÃO:** Este não é o problema principal (o erro 502 acontece antes da autenticação)

#### 4.2 - Authorization configurada?
**⚠️ PARCIAL** - Secret definido no `.env` local, mas:
- 🔴 Secret não configurado no Cloud Run como variável de ambiente
- 🔴 Mesmo se estivesse, o erro de protocolo impede alcançar essa lógica

#### 4.3 - Payload < 32 MB?
**✅ SIM** - Testes usaram payloads mínimos (< 100 bytes)

---

### 🔥 5. SOBRE O SERVIDOR ESTAR FECHANDO CONEXÕES

#### 5.1 - NÃO chama `res.end()` prematuramente?
**✅ SIM** - NestJS gerencia resposta corretamente

#### 5.2 - NÃO lança exceções silenciosas?
**✅ SIM** - Logs não mostram crashes

#### 5.3 - NÃO é WebSocket puro?
**✅ SIM** - É servidor HTTP completo com WebSocket adicional

---

### 🔥 6. SOBRE TESTES

#### 6.1 - curl retorna 502?
**✅ SIM** - Confirmado:

```bash
$ curl -v https://wedding-websocket-dux2nu33ua-uc.a.run.app/notify
< HTTP/2 502
upstream connect error or disconnect/reset before headers. reset reason: protocol error
```

#### 6.2 - Browser também falha?
**✅ SIM** - Mesmo erro (502)

---

## 🚨 EVIDÊNCIAS DO PROBLEMA

### 1. Configuração do Cloud Run (h2c):
```yaml
containers:
  - containerPort: 8080
    name: h2c  # ⚠️ Espera HTTP/2!
```

### 2. Logs do Container (Servidor Inicia):
```
[NestApplication] Nest application successfully started
🚀 WebSocket Service running on http://0.0.0.0:8080
```

### 3. Logs de Requisição (Nunca Processada):
```
POST 502 https://wedding-websocket-dux2nu33ua-uc.a.run.app/notify
# Nenhum log do controller aparece!
```

### 4. Teste cURL (Protocol Error):
```
< HTTP/2 502
upstream connect error or disconnect/reset before headers. reset reason: protocol error
```

---

## 🔧 SOLUÇÃO

### Opção 1: Forçar HTTP/1.1 no Cloud Run (RECOMENDADO)

Redeployar com protocolo HTTP/1.1 explícito:

```bash
gcloud run deploy wedding-websocket \
  --source . \
  --region=us-central1 \
  --allow-unauthenticated \
  --project=wedconnexpro \
  --port=8080 \
  --use-http2=false
```

**OU** adicionar ao `gcloud-run.yaml`:

```yaml
apiVersion: serving.knative.dev/v1
kind: Service
metadata:
  name: wedding-websocket
spec:
  template:
    spec:
      containers:
      - image: gcr.io/wedconnexpro/wedding-websocket
        ports:
        - name: http1  # ⚠️ Mudança crítica!
          containerPort: 8080
```

---

### Opção 2: Habilitar HTTP/2 no NestJS (COMPLEXO)

Requer adaptador HTTP/2 nativo:

```typescript
// main.ts
import * as http2 from 'http2';
import { ExpressAdapter } from '@nestjs/platform-express';
import * as express from 'express';

async function bootstrap() {
  const expressApp = express();
  
  const server = http2.createSecureServer({
    allowHTTP1: true, // Compatibilidade
  }, expressApp);

  const app = await NestFactory.create(
    AppModule,
    new ExpressAdapter(expressApp),
  );

  await app.init();
  server.listen(port);
}
```

**⚠️ Problemas:**
- Requer certificados SSL (complexo no Cloud Run)
- Socket.IO pode ter problemas com HTTP/2
- Não é suportado nativamente pelo NestJS

---

## ✅ RECOMENDAÇÃO FINAL

**USAR OPÇÃO 1: Forçar HTTP/1.1 no Cloud Run**

**Razões:**
1. ✅ Socket.IO funciona perfeitamente com HTTP/1.1
2. ✅ NestJS não requer alterações
3. ✅ Cloud Run suporta HTTP/1.1 sem problemas
4. ✅ WebSocket funciona independente da versão HTTP
5. ✅ Implementação simples (1 comando)

---

## 📝 PROBLEMAS SECUNDÁRIOS IDENTIFICADOS

### 1. Variável de Ambiente Ausente
```typescript
const expectedSecret = process.env.INTERNAL_SECRET || 'your-secret-key';
```

**Solução:** Adicionar ao deploy:
```bash
gcloud run deploy wedding-websocket \
  --set-env-vars INTERNAL_SECRET=your-actual-secret-key
```

### 2. Logs Incompletos
- O container inicia mas não processa requisições
- Sugerir adicionar health check endpoint:

```typescript
@Get('health')
getHealth() {
  return { status: 'ok', timestamp: new Date().toISOString() };
}
```

---

## 🎯 PRÓXIMOS PASSOS

1. ✅ **Redeployar com HTTP/1.1:**
   ```bash
   gcloud run deploy wedding-websocket \
     --source . \
     --region=us-central1 \
     --allow-unauthenticated \
     --project=wedconnexpro \
     --port=8080 \
     --use-http2=false \
     --set-env-vars INTERNAL_SECRET=your-secret-key
   ```

2. ✅ **Testar endpoint raiz:**
   ```bash
   curl https://wedding-websocket-dux2nu33ua-uc.a.run.app/
   # Espera: "Hello World!" (200 OK)
   ```

3. ✅ **Testar endpoint /notify:**
   ```bash
   curl -X POST \
     -H "Content-Type: application/json" \
     -H "Authorization: Bearer your-secret-key" \
     -d '{"brideId":"test","vendorId":"test","type":"create","application":{}}' \
     https://wedding-websocket-dux2nu33ua-uc.a.run.app/notify
   # Espera: {"success":true}
   ```

4. ✅ **Verificar logs:**
   ```bash
   gcloud run services logs read wedding-websocket \
     --region=us-central1 \
     --project=wedconnexpro \
     --limit=20
   # Espera ver: "HTTP NOTIFY ENDPOINT CALLED"
   ```

---

## 📊 RESUMO EXECUTIVO

| Aspecto | Status | Observação |
|---------|--------|------------|
| **Código NestJS** | ✅ OK | Implementação correta |
| **Endpoint /notify** | ✅ OK | Rota mapeada |
| **Porta 8080** | ✅ OK | Configurada |
| **Protocolo HTTP** | ❌ **ERRO** | **h2c vs HTTP/1.1** |
| **Cloud Run Config** | ⚠️ PARCIAL | Falta `INTERNAL_SECRET` |
| **Autenticação** | ⚠️ BLOQUEADO | Não alcança devido a 502 |

**SEVERIDADE:** 🔴 **CRÍTICA** - Serviço completamente indisponível

**TEMPO ESTIMADO DE CORREÇÃO:** 5 minutos (1 comando + testes)

---

## 🔗 REFERÊNCIAS

- [Cloud Run HTTP/2 vs HTTP/1.1](https://cloud.google.com/run/docs/configuring/http2)
- [NestJS HTTP Adapter](https://docs.nestjs.com/faq/http-adapter)
- [Socket.IO with Cloud Run](https://socket.io/docs/v4/tutorial/step-10)
- [Error 502 Troubleshooting](https://cloud.google.com/run/docs/troubleshooting#502)
