---
applyTo: '*Partiu*'
---

# 📋 Guia de Boas Práticas Flutter - Partiu

> **Objetivo**: Código limpo, performático e consistente seguindo convenções Flutter/Dart

---

## 📝 1. Naming Conventions (Padrões Obrigatórios)

### ✔️ **camelCase**

**Usar para:**
- Variáveis
- Métodos
- Propriedades de classes
- Campos do Firestore (`createdAt`, `userId`, etc.)

**Exemplos:**
```dart
userName, createdAt, isVerified, rankingScore
```

---

### ✔️ **PascalCase**

**Usar para:**
- Nomes de classes
- Widgets
- Enums

**Exemplos:**
```dart
UserModel, ActivityCard, LocationService
```

---

### ✔️ **minúsculo + plural**

**Usar para:**
- Nomes de coleções Firestore

**Exemplos:**
```dart
users, activities, places, reviews
```

---

### ✔️ **UPPER_SNAKE_CASE**

**Usar SOMENTE para:**
- Constantes globais

**Exemplos:**
```dart
DEFAULT_RADIUS_KM
MAX_PARTICIPANTS
```

---

### ❌ **NÃO usar snake_case**

> ⚠️ **IMPORTANTE**: Evite 100% para modelos, Firestore e propriedades. Só gera inconsistência.

---

## 🧩 2. Estrutura e Organização — Evitar Rebuilds e Complexidade

### ✔️ **Boas Práticas**

#### Divida widgets grandes em componentes menores
- Um widget = uma responsabilidade
- Subárvores menores → menos rebuilds

#### Transforme funções que retornam widgets → em widgets de verdade
- Isso ajuda o Flutter a reutilizar instâncias e cortar reconstruções

#### Use `const` sempre que possível
- Isso sozinho reduz uma tonelada de rebuilds

#### Evite passar listas literais para Row, Column, ListView
- Crie widgets menores e estáveis para cada item

---

### ❌ **Não coloque lógica dentro de widgets**

**O que EVITAR no `build()`:**
- ❌ Nada de `.forEach`, `.map`, cálculos, filtros
- ❌ Não faça I/O, buscas, awaits, parsing

**Onde colocar:**
- ✅ Toda lógica vai para **ViewModel/Service/Repository**

---

## 🔄 3. Estado e Atualizações

### ✔️ **Rebuilds Inteligentes**

#### Envolva apenas a parte que precisa rebuildar
- Use `ValueListenableBuilder` / `Selector` / `AnimatedBuilder`
- Evite rebuildar tela inteira por causa de um detalhe

#### Ao usar `setState()`, coloque-o no menor widget possível
- `setState()` alto = destruição total da árvore

#### Prefira modelos imutáveis
- Alterações → nova instância

#### Use caching inteligente
**Exemplos:**
- Avatar cache
- Maps cache
- Membros do chat
- Locais frequentes

---

## ⚡ 4. Performance Prática — O que Mais Afeta FPS

### ❌ **Evite `Opacity`**

**Use alternativas:**
- ✅ `AnimatedOpacity` para animações
- ✅ Alpha direto no `Color` para imagens

---

### ❌ **Evite recortes (Clip) em animações**
- Especialmente `ClipRRect` com `antiAliasWithSaveLayer`

---

### ❌ **Evite `saveLayer()`**
- Só quando não tiver alternativa

---

### ❌ **Evite cálculos intrínsecos (intrinsic width/height)**
- Causam duas passagens de layout → lag

---

### ❌ **Evite aninhamentos profundos**

```
✅ 3 níveis é saudável
❌ 10 níveis = gambiarra invisível
```

---

## 🧭 5. Listas, Grids e Rolagem

### ✔️ **Prefira construção preguiçosa**

```dart
ListView.builder
GridView.builder
```

### ✔️ **Mantenha `itemCount` consistente**
- Mudanças na lista inteira devem ser controladas, não explosivas

### ❌ **Não coloque lógica pesada dentro do `itemBuilder`**

---

## 🧱 6. Widgets Estáveis = Performance Estável

### ✔️ **Sempre que possível, torne widgets puras folhas**
- Um widget que não depende de estado é um widget que nunca rebuilda

### ✔️ **Use Keys com sabedoria**
- `ValueKey` para listas dinâmicas, evitando movimentações desnecessárias

### ✔️ **Não use `==` customizado em widgets**
- Pode gerar O(n²) de comparação

---

## 🧪 7. Diagnóstico Rápido

### **Ferramentas que você DEVE usar:**

#### Flutter DevTools → Performance
- `Repaint Rainbow`
- `Rebuild Tracker`
- `Checkerboard Offscreen Layers`

---

### **Perguntas ao avaliar um PR:**

- [ ] Alguma lógica está dentro do `build()`?
- [ ] Existe algum `Opacity` óbvio que poderia ser removido?
- [ ] Este `setState()` está no lugar mais baixo possível?
- [ ] Os widgets pequenos estão marcados como `const`?
- [ ] Existem listas literais sendo reconstruídas à toa?
- [ ] Há alguma coleção Firestore usando `snake_case`? (se sim: arrumar)

---

## 🧠 8. Regras de Ouro — 12 Mandamentos do Flutter Limpo

| # | Mandamento |
|---|------------|
| 1️⃣ | **UI não pensa. Lógica não desenha.** |
| 2️⃣ | **`build()` deve ser sempre barato.** |
| 3️⃣ | **Todo widget possível deve ser `const`.** |
| 4️⃣ | **Estados devem ser mínimos.** |
| 5️⃣ | **Nunca coloque lógica dentro do `build()`.** |
| 6️⃣ | **Use `camelCase`. Sempre.** |
| 7️⃣ | **Rebuild só do que muda.** |
| 8️⃣ | **Evite `Opacity`. Evite `Clip`. Evite `saveLayer`.** |
| 9️⃣ | **Quebre widgets grandes.** |
| 🔟 | **Modelos imutáveis.** |
| 1️⃣1️⃣ | **Estrutura previsível de camadas.** |
| 1️⃣2️⃣ | **Mapa mental: menos coisa = mais rápido.** |

---

**📌 Lembre-se:** Seguir essas práticas não é apenas sobre performance, mas sobre **manutenibilidade e consistência** do código ao longo do tempo.
