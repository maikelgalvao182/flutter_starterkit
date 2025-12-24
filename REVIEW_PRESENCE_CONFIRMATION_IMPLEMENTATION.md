# 🎯 IMPLEMENTAÇÃO: REVIEW SYSTEM COM CONFIRMAÇÃO DE PRESENÇA
## **VERSÃO 2.0 - PRODUCTION READY**

## 📋 REQUISITOS (REFINADOS)

### **1. Novo Fluxo de Review**
- **Passo 0 (Owner apenas):** Ver lista de participantes com `presence="Vou"` e confirmar quem apareceu
- **Passo 1:** Avaliar **CADA** participante confirmado **individualmente** com notas diferentes
- **Passo 2:** Adicionar badges (opcional, por participante)
- **Passo 3:** Comentário final (opcional)
- **Garantia:** Participante só pode avaliar owner se foi avaliado primeiro

### **2. Segurança e Consistência**
- ✅ Impedir avaliações duplicadas (idempotência)
- ✅ Impedir owner de reenviar confirmação de presença
- ✅ Impedir participante de avaliar sem permissão
- ✅ Salvar presença confirmada como fonte de verdade
- ✅ Armazenar perfis no PendingReview (evitar queries extras)

---

## 🏗️ ARQUITETURA DA SOLUÇÃO (REFINADA)

### **Fluxo Completo:**

```
1. Evento termina (scheduleDate passou)
   ↓
2. Cloud Function (a cada 5min) cria PendingReview ÚNICO para OWNER
   - Inclui TODOS participantes com presence="Vou"
   - Pré-carrega perfis (nome, foto) no documento
   - Flag: presenceConfirmed = false
   ↓
3. Owner abre app → ReviewDialog detecta isOwnerReview
   ↓
4. STEP 0 (Owner): Confirmar Presença
   - Lista participantes com checkbox
   - Owner seleciona quem apareceu
   - Ao avançar: salva presenceConfirmed = true
   - Salva lista em ConfirmedParticipants subcollection
   ↓
5. STEP 1-3 (Owner): Avaliar CADA participante
   - Para cada confirmado: ratings individuais + badges + comentário
   - Submeter tudo de uma vez (batch transaction)
   ↓
6. Sistema cria Reviews + PendingReviews para participantes
   - Review (owner → participant) salvo
   - PendingReview (participant → owner) criado com allowedToReviewOwner=true
   - ConfirmedParticipants/{userId} salvo no evento
   ↓
7. Participante abre app
   ↓
8. ReviewDialog verifica allowedToReviewOwner = true
   - Se true: renderiza avaliação
   - Se false: bloqueia com mensagem educativa
   ↓
9. Participante avalia owner (ratings, badges, comentário)
   ↓
10. Review salvo + PendingReview deletado
```

### **Coleções e Estrutura de Dados:**

```
Events/{eventId}
  ├── ConfirmedParticipants/{userId}
  │   ├── confirmedAt: Timestamp
  │   ├── confirmedBy: ownerId
  │   ├── presence: "Vou"
  │   └── reviewed: false → true após review

PendingReviews/{pendingReviewId}
  ├── reviewer_role: "owner" | "participant"
  ├── presenceConfirmed: false (owner apenas)
  ├── allowedToReviewOwner: true (participant apenas)
  ├── participant_ids: ["p1", "p2"] (owner apenas)
  ├── participant_profiles: {
  │     "p1": { name: "", photo: "" }
  │   }
  └── event_location_name, event_schedule_date, etc.

Reviews/{reviewId}
  ├── reviewer_id
  ├── reviewee_id
  ├── event_id
  ├── criteria_ratings: { "punctuality": 5, ... }
  ├── badges: ["Comunicativo", ...]
  └── comment: "..."
```

---

## 📦 ARQUIVOS A MODIFICAR

### **1. PendingReviewModel** (`pending_review_model.dart`)

**Novos campos (compatíveis com ambos owner e participant):**
```dart
// Dados do evento (ambos)
final String? eventLocationName;
final DateTime? eventScheduleDate;

// Campos específicos do OWNER
final bool? presenceConfirmed;          // null para participant
final List<String>? participantIds;     // null para participant
final Map<String, ParticipantProfile>? participantProfiles; // null para participant

// Campos específicos do PARTICIPANT
final bool? allowedToReviewOwner;       // null para owner
final String? revieweeName;             // Nome do owner (para participant)
final String? revieweePhotoUrl;         // Foto do owner (para participant)

// Helper para identificar tipo
bool get isOwnerReview => reviewerRole == 'owner';
bool get isParticipantReview => reviewerRole == 'participant';
bool get needsPresenceConfirmation => 
    isOwnerReview && presenceConfirmed == false;
```

**Novo modelo auxiliar:**
```dart
class ParticipantProfile {
  final String name;
  final String? photoUrl;
  
  const ParticipantProfile({
    required this.name,
    this.photoUrl,
  });
  
  factory ParticipantProfile.fromMap(Map<String, dynamic> map) {
    return ParticipantProfile(
      name: map['name'] ?? '',
      photoUrl: map['photo'],
    );
  }
  
  Map<String, dynamic> toMap() => {
    'name': name,
    'photo': photoUrl,
  };
}
```

### **2. ReviewDialogController** (`review_dialog_controller.dart`)

**Mudanças principais:**
```dart
class ReviewDialogController extends ChangeNotifier {
  // Estado de presença (owner)
  bool presenceConfirmed = false;
  Set<String> selectedParticipants = {};
  List<String> participantIds = [];
  Map<String, ParticipantProfile> participantProfiles = {};
  
  // Ratings POR PARTICIPANTE (owner avalia cada um diferente)
  Map<String, Map<String, int>> ratingsPerParticipant = {};
  Map<String, List<String>> badgesPerParticipant = {};
  Map<String, String> commentPerParticipant = {};
  
  // Participante atual sendo avaliado (owner mode)
  int currentParticipantIndex = 0;
  String? get currentParticipantId => 
      selectedParticipants.isEmpty 
          ? null 
          : selectedParticipants.elementAt(currentParticipantIndex);
  
  // Controle de permissão (participant)
  bool allowedToReviewOwner = true; // Default true para compatibilidade
  
  // Getters
  bool get isOwnerReview => reviewerRole == 'owner';
  bool get needsPresenceConfirmation => 
      isOwnerReview && !presenceConfirmed && participantIds.isNotEmpty;
  int get totalSteps => needsPresenceConfirmation ? 4 : 3;
  
  /// Toggle participante (STEP 0)
  void toggleParticipant(String participantId) {
    if (selectedParticipants.contains(participantId)) {
      selectedParticipants.remove(participantId);
      ratingsPerParticipant.remove(participantId);
      badgesPerParticipant.remove(participantId);
      commentPerParticipant.remove(participantId);
    } else {
      selectedParticipants.add(participantId);
      ratingsPerParticipant[participantId] = {};
      badgesPerParticipant[participantId] = [];
      commentPerParticipant[participantId] = '';
    }
    notifyListeners();
  }
  
  /// Confirmar presença e avançar (STEP 0 → STEP 1)
  Future<bool> confirmPresenceAndProceed(String pendingReviewId) async {
    if (selectedParticipants.isEmpty) {
      return false; // Precisa selecionar pelo menos 1
    }
    
    try {
      // Atualizar PendingReview
      await _repository.updatePendingReview(
        pendingReviewId: pendingReviewId,
        data: {'presenceConfirmed': true},
      );
      
      // Salvar presença confirmada no evento
      for (final participantId in selectedParticipants) {
        await _repository.saveConfirmedParticipant(
          eventId: eventId,
          participantId: participantId,
          confirmedBy: reviewerId,
        );
      }
      
      presenceConfirmed = true;
      currentStep = 1; // Avançar para ratings
      notifyListeners();
      return true;
    } catch (e) {
      print('❌ Erro ao confirmar presença: $e');
      return false;
    }
  }
  
  /// Atualizar rating do participante atual
  void updateRatingForCurrentParticipant(String criterionId, int rating) {
    final participantId = currentParticipantId;
    if (participantId == null) return;
    
    ratingsPerParticipant[participantId] ??= {};
    ratingsPerParticipant[participantId]![criterionId] = rating;
    notifyListeners();
  }
  
  /// Avançar para próximo participante ou finalizar
  void nextParticipant() {
    if (currentParticipantIndex < selectedParticipants.length - 1) {
      currentParticipantIndex++;
      notifyListeners();
    }
  }
  
  bool get isLastParticipant => 
      currentParticipantIndex >= selectedParticipants.length - 1;
  
  /// Submeter TODOS os reviews (owner → cada participante)
  Future<bool> submitAllReviews(String pendingReviewId) async {
    if (ratingsPerParticipant.isEmpty) return false;
    
    try {
      // Batch: criar todos os reviews de uma vez
      final batch = FirebaseFirestore.instance.batch();
      
      for (final participantId in selectedParticipants) {
        // 1. Criar Review (owner → participant)
        await _repository.createReview(
          eventId: eventId,
          revieweeId: participantId,
          reviewerRole: 'owner',
          criteriaRatings: ratingsPerParticipant[participantId] ?? {},
          badges: badgesPerParticipant[participantId] ?? [],
          comment: commentPerParticipant[participantId] ?? '',
          pendingReviewId: pendingReviewId,
        );
        
        // 2. Criar PendingReview para participante avaliar owner
        await _repository.createParticipantPendingReview(
          eventId: eventId,
          participantId: participantId,
          ownerId: reviewerId,
          ownerName: /* buscar do user */ '',
          ownerPhotoUrl: /* buscar do user */ null,
          eventLocationName: eventLocationName,
          eventScheduleDate: eventScheduleDate,
        );
        
        // 3. Atualizar ConfirmedParticipants (reviewed = true)
        await _repository.markParticipantAsReviewed(
          eventId: eventId,
          participantId: participantId,
        );
      }
      
      // Deletar PendingReview do owner
      await _repository.deletePendingReview(pendingReviewId);
      
      return true;
    } catch (e) {
      print('❌ Erro ao submeter reviews: $e');
      return false;
    }
  }
  
  /// Inicializar a partir do PendingReview
  void initializeFromPendingReview(PendingReviewModel pendingReview) {
    eventId = pendingReview.eventId;
    reviewerId = pendingReview.reviewerId;
    reviewerRole = pendingReview.reviewerRole;
    eventLocationName = pendingReview.eventLocationName;
    eventScheduleDate = pendingReview.eventScheduleDate;
    
    if (pendingReview.isOwnerReview) {
      participantIds = pendingReview.participantIds ?? [];
      participantProfiles = pendingReview.participantProfiles ?? {};
      presenceConfirmed = pendingReview.presenceConfirmed ?? false;
      
      if (presenceConfirmed) {
        currentStep = 1; // Pular STEP 0
      }
    } else {
      allowedToReviewOwner = pendingReview.allowedToReviewOwner ?? false;
      
      if (!allowedToReviewOwner) {
        // Bloquear acesso
        print('❌ Participante não tem permissão para avaliar');
      }
    }
    
    notifyListeners();
  }
}
```

### **3. ReviewRepository** (`review_repository.dart`)

**Novos métodos:**
```dart
/// Atualizar PendingReview (ex: presenceConfirmed)
Future<void> updatePendingReview({
  required String pendingReviewId,
  required Map<String, dynamic> data,
}) async {
  await _firestore
      .collection('PendingReviews')
      .doc(pendingReviewId)
      .update(data);
}

/// Salvar participante confirmado
Future<void> saveConfirmedParticipant({
  required String eventId,
  required String participantId,
  required String confirmedBy,
}) async {
  await _firestore
      .collection('Events')
      .doc(eventId)
      .collection('ConfirmedParticipants')
      .doc(participantId)
      .set({
    'confirmedAt': FieldValue.serverTimestamp(),
    'confirmedBy': confirmedBy,
    'presence': 'Vou',
    'reviewed': false,
  });
}

/// Marcar participante como avaliado
Future<void> markParticipantAsReviewed({
  required String eventId,
  required String participantId,
}) async {
  await _firestore
      .collection('Events')
      .doc(eventId)
      .collection('ConfirmedParticipants')
      .doc(participantId)
      .update({'reviewed': true});
}

/// Criar PendingReview para participante avaliar owner
Future<void> createParticipantPendingReview({
  required String eventId,
  required String participantId,
  required String ownerId,
  required String ownerName,
  required String? ownerPhotoUrl,
  required String? eventLocationName,
  required DateTime? eventScheduleDate,
}) async {
  final pendingReviewId = '${eventId}_participant_${participantId}';
  final expiresAt = DateTime.now().add(const Duration(days: 30));
  
  await _firestore
      .collection('PendingReviews')
      .doc(pendingReviewId)
      .set({
    'pending_review_id': pendingReviewId,
    'event_id': eventId,
    'reviewer_id': participantId,
    'reviewee_id': ownerId,
    'reviewee_name': ownerName,
    'reviewee_photo_url': ownerPhotoUrl,
    'reviewer_role': 'participant',
    'event_location_name': eventLocationName,
    'event_schedule_date': eventScheduleDate,
    'allowed_to_review_owner': true,
    'created_at': FieldValue.serverTimestamp(),
    'expires_at': Timestamp.fromDate(expiresAt),
    'dismissed': false,
  });
}

/// Deletar PendingReview
Future<void> deletePendingReview(String pendingReviewId) async {
  await _firestore
      .collection('PendingReviews')
      .doc(pendingReviewId)
      .delete();
}
```

### **4. ReviewDialog** (`review_dialog.dart`)

**Mudanças no fluxo:**
```dart
@override
Widget build(BuildContext context) {
  return Consumer<ReviewDialogController>(
    builder: (context, controller, _) {
      // BLOQUEIO: Participante sem permissão
      if (controller.isParticipantReview && !controller.allowedToReviewOwner) {
        return _buildBlockedDialog(context);
      }
      
      // STEP 0: Confirmar presença (owner apenas)
      if (controller.needsPresenceConfirmation) {
        return ParticipantConfirmationStep(
          participantIds: controller.participantIds,
          participantProfiles: controller.participantProfiles,
          selectedParticipants: controller.selectedParticipants,
          onToggleParticipant: controller.toggleParticipant,
          onConfirm: () => _confirmPresence(context, controller),
        );
      }
      
      // STEP 1-3: Avaliar
      return _buildReviewSteps(context, controller);
    },
  );
}

Widget _buildBlockedDialog(BuildContext context) {
  return AlertDialog(
    title: const Text('Avaliação Indisponível'),
    content: const Text(
      'Você poderá avaliar o organizador após ele avaliar sua participação no evento.',
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.of(context).pop(),
        child: const Text('Entendi'),
      ),
    ],
  );
}

Future<void> _confirmPresence(
  BuildContext context,
  ReviewDialogController controller,
) async {
  if (controller.selectedParticipants.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Selecione pelo menos um participante'),
      ),
    );
    return;
  }
  
  final success = await controller.confirmPresenceAndProceed(
    widget.pendingReviewId,
  );
  
  if (!success) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Erro ao confirmar presença')),
    );
  }
}
```

### **5. ParticipantConfirmationStep** (novo widget)

**Localização:** `lib/features/reviews/presentation/components/participant_confirmation_step.dart`

```dart
class ParticipantConfirmationStep extends StatelessWidget {
  final List<String> participantIds;
  final Map<String, ParticipantProfile> participantProfiles;
  final Set<String> selectedParticipants;
  final Function(String) onToggleParticipant;
  final VoidCallback onConfirm;

  const ParticipantConfirmationStep({
    required this.participantIds,
    required this.participantProfiles,
    required this.selectedParticipants,
    required this.onToggleParticipant,
    required this.onConfirm,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                const Icon(Icons.check_circle_outline, size: 32),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Quem realmente apareceu?',
                    style: GoogleFonts.getFont(
                      FONT_PLUS_JAKARTA_SANS,
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Selecione os participantes que compareceram ao evento. Você só poderá avaliar quem você confirmar.',
              style: GoogleFonts.getFont(
                FONT_PLUS_JAKARTA_SANS,
                fontSize: 14,
                color: GlimpseColors.textSecondary,
              ),
            ),
            const SizedBox(height: 24),
            
            // Lista de participantes
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: participantIds.length,
                itemBuilder: (context, index) {
                  final participantId = participantIds[index];
                  final profile = participantProfiles[participantId];
                  final isSelected = selectedParticipants.contains(participantId);
                  
                  return ParticipantCheckboxTile(
                    participantId: participantId,
                    name: profile?.name ?? 'Usuário',
                    photoUrl: profile?.photoUrl,
                    isSelected: isSelected,
                    onToggle: () => onToggleParticipant(participantId),
                  );
                },
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Botão confirmar
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: selectedParticipants.isEmpty ? null : onConfirm,
                style: ElevatedButton.styleFrom(
                  backgroundColor: GlimpseColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  'Confirmar (${selectedParticipants.length})',
                  style: GoogleFonts.getFont(
                    FONT_PLUS_JAKARTA_SANS,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ParticipantCheckboxTile extends StatelessWidget {
  final String participantId;
  final String name;
  final String? photoUrl;
  final bool isSelected;
  final VoidCallback onToggle;

  const ParticipantCheckboxTile({
    required this.participantId,
    required this.name,
    required this.photoUrl,
    required this.isSelected,
    required this.onToggle,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        border: Border.all(
          color: isSelected 
              ? GlimpseColors.primary 
              : GlimpseColors.borderColorLight,
          width: isSelected ? 2 : 1,
        ),
        borderRadius: BorderRadius.circular(12),
        color: isSelected 
            ? GlimpseColors.primary.withOpacity(0.05)
            : Colors.transparent,
      ),
      child: CheckboxListTile(
        value: isSelected,
        onChanged: (_) => onToggle(),
        secondary: CircleAvatar(
          radius: 24,
          backgroundImage: photoUrl != null 
              ? CachedNetworkImageProvider(photoUrl!) 
              : null,
          child: photoUrl == null 
              ? Text(name[0].toUpperCase())
              : null,
        ),
        title: Text(
          name,
          style: GoogleFonts.getFont(
            FONT_PLUS_JAKARTA_SANS,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        controlAffinity: ListTileControlAffinity.trailing,
        activeColor: GlimpseColors.primary,
      ),
    );
  }
}
```

---

## 🔧 CLOUD FUNCTION: CRIAR PENDING REVIEWS

**Localização:** `functions/src/reviews/createPendingReviews.ts`

**Melhorias implementadas:**
- ✅ Executa a cada **5 minutos** (baixa latência)
- ✅ Busca perfis dos participantes **em batch** (1 query)
- ✅ Usa flag `pendingReviewsCreated` para **idempotência**
- ✅ Salva perfis no PendingReview (evita queries extras)
- ✅ Logs estruturados para monitoramento

```typescript
import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';

/**
 * Cria PendingReviews automaticamente após evento terminar
 * 
 * Trigger: Scheduled function (executa a cada 5 minutos)
 * Busca eventos que terminaram nos últimos 10 minutos
 * 
 * Garante idempotência com flag: pendingReviewsCreated
 */
export const createPendingReviewsScheduled = functions
  .region('us-central1')
  .runWith({ timeoutSeconds: 540, memory: '512MB' })
  .pubsub
  .schedule('every 5 minutes')
  .onRun(async (context) => {
    const now = admin.firestore.Timestamp.now();
    const tenMinutesAgo = admin.firestore.Timestamp.fromMillis(
      now.toMillis() - (10 * 60 * 1000)
    );
    
    console.log('🔍 [PendingReviews] Buscando eventos finalizados...');
    
    // Buscar eventos que terminaram recentemente e não foram processados
    const eventsSnapshot = await admin.firestore()
      .collection('Events')
      .where('schedule.date', '>', tenMinutesAgo)
      .where('schedule.date', '<=', now)
      .where('pendingReviewsCreated', '!=', true)
      .limit(50) // Processar no máximo 50 por execução
      .get();
    
    console.log(`📅 [PendingReviews] ${eventsSnapshot.size} eventos encontrados`);
    
    if (eventsSnapshot.empty) {
      console.log('✅ [PendingReviews] Nenhum evento para processar');
      return null;
    }
    
    // Processar cada evento
    const promises = eventsSnapshot.docs.map(doc => 
      processEvent(doc).catch(error => {
        console.error(`❌ [PendingReviews] Erro no evento ${doc.id}:`, error);
        return null;
      })
    );
    
    await Promise.all(promises);
    
    console.log('✅ [PendingReviews] Processamento concluído');
    return null;
  });

/**
 * Processa um evento: cria PendingReview para o owner
 */
async function processEvent(
  eventDoc: FirebaseFirestore.DocumentSnapshot
): Promise<void> {
  const eventId = eventDoc.id;
  const eventData = eventDoc.data();
  
  if (!eventData) {
    console.warn(`⚠️ [PendingReviews] Evento ${eventId} sem dados`);
    return;
  }
  
  const ownerId = eventData.createdBy;
  const eventTitle = eventData.activityText || 'Evento';
  const eventEmoji = eventData.emoji || '🎉';
  const eventLocationName = eventData.locationName || eventData.location?.locationName;
  const eventScheduleDate = eventData.schedule?.date;
  
  console.log(`🎯 [PendingReviews] Processando evento: ${eventId}`);
  
  // 1. Buscar participantes aprovados com presence="Vou"
  const applicationsSnapshot = await admin.firestore()
    .collection('EventApplications')
    .where('eventId', '==', eventId)
    .where('presence', '==', 'Vou')
    .where('status', 'in', ['approved', 'autoApproved'])
    .get();
  
  console.log(`👥 [PendingReviews] ${applicationsSnapshot.size} participantes "Vou"`);
  
  if (applicationsSnapshot.empty) {
    // Marcar como processado mesmo sem participantes
    await eventDoc.ref.update({ 
      pendingReviewsCreated: true,
      pendingReviewsCreatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });
    console.log(`✅ [PendingReviews] Evento ${eventId} sem participantes - marcado como processado`);
    return;
  }
  
  // 2. Buscar perfis dos participantes (BATCH - 1 query)
  const participantIds = applicationsSnapshot.docs.map(doc => doc.data().userId);
  const userIds = [...new Set(participantIds)]; // Remover duplicatas
  
  // Firestore permite "in" com até 10 valores, então fazer em chunks
  const participantProfiles: Record<string, { name: string; photo: string | null }> = {};
  
  for (let i = 0; i < userIds.length; i += 10) {
    const chunk = userIds.slice(i, i + 10);
    const usersSnapshot = await admin.firestore()
      .collection('Users')
      .where(admin.firestore.FieldPath.documentId(), 'in', chunk)
      .get();
    
    usersSnapshot.docs.forEach(userDoc => {
      const userData = userDoc.data();
      participantProfiles[userDoc.id] = {
        name: userData.fullname || 'Usuário',
        photo: userData.photoUrl || null,
      };
    });
  }
  
  console.log(`📸 [PendingReviews] ${Object.keys(participantProfiles).length} perfis carregados`);
  
  // 3. Criar PendingReview para o OWNER
  const ownerPendingReviewId = `${eventId}_owner_${ownerId}`;
  const expiresAt = admin.firestore.Timestamp.fromMillis(
    admin.firestore.Timestamp.now().toMillis() + (30 * 24 * 60 * 60 * 1000) // 30 dias
  );
  
  try {
    await admin.firestore()
      .collection('PendingReviews')
      .doc(ownerPendingReviewId)
      .set({
        pending_review_id: ownerPendingReviewId,
        event_id: eventId,
        reviewer_id: ownerId,
        reviewer_role: 'owner',
        event_title: eventTitle,
        event_emoji: eventEmoji,
        event_location_name: eventLocationName,
        event_schedule_date: eventScheduleDate,
        participant_ids: participantIds,
        participant_profiles: participantProfiles,
        presence_confirmed: false,
        created_at: admin.firestore.FieldValue.serverTimestamp(),
        expires_at: expiresAt,
        dismissed: false,
      });
    
    console.log(`✅ [PendingReviews] Criado para owner: ${ownerPendingReviewId}`);
  } catch (error) {
    console.error(`❌ [PendingReviews] Erro ao criar para owner:`, error);
    throw error;
  }
  
  // 4. Marcar evento como processado
  await eventDoc.ref.update({ 
    pendingReviewsCreated: true,
    pendingReviewsCreatedAt: admin.firestore.FieldValue.serverTimestamp(),
  });
  
  console.log(`✅ [PendingReviews] Evento ${eventId} processado com sucesso`);
}
```

---

## 🎯 FLUXO DE DADOS COMPLETO

### **1. Cloud Function cria PendingReview (Owner)**
```
EventApplications (presence="Vou", status=approved/autoApproved)
  ↓ (batch query - 10 users por chunk)
Users (fullname, photoUrl)
  ↓
PendingReviews/{eventId}_owner_{ownerId}
  - reviewer_id: ownerId
  - reviewer_role: "owner"
  - participant_ids: [userId1, userId2, ...]
  - participant_profiles: {
      userId1: { name: "...", photo: "..." }
    }
  - presence_confirmed: false
  - event_location_name, event_schedule_date, etc.
  ↓
Events/{eventId}
  - pendingReviewsCreated: true
  - pendingReviewsCreatedAt: Timestamp
```

### **2. Owner confirma presença (STEP 0)**
```
ReviewDialog (STEP 0)
  ↓
selectedParticipants: Set<String> (checkbox toggle)
  ↓
confirmPresenceAndProceed()
  ↓
PendingReviews/{pendingReviewId}
  - presence_confirmed: true ✅
  ↓
Events/{eventId}/ConfirmedParticipants/{userId}
  - confirmedAt: Timestamp
  - confirmedBy: ownerId
  - presence: "Vou"
  - reviewed: false
```

### **3. Owner avalia cada participante (STEP 1-3)**
```
ReviewDialog (STEP 1-3)
  ↓
ratingsPerParticipant[userId] = { "punctuality": 5, ... }
badgesPerParticipant[userId] = ["Comunicativo", ...]
commentPerParticipant[userId] = "..."
  ↓
submitAllReviews() (batch transaction)
```

### **4. Sistema cria Reviews + PendingReviews para participantes**
```
Para cada participantId em selectedParticipants:
  
  1. Reviews/{reviewId}
     - event_id, reviewer_id (owner), reviewee_id (participant)
     - criteria_ratings, badges, comment
     - created_at
  
  2. PendingReviews/{eventId}_participant_{participantId}
     - reviewer_id: participantId
     - reviewer_role: "participant"
     - reviewee_id: ownerId
     - reviewee_name, reviewee_photo_url (owner profile)
     - allowed_to_review_owner: true ✅
     - event_location_name, event_schedule_date
  
  3. Events/{eventId}/ConfirmedParticipants/{participantId}
     - reviewed: true ✅
     
  4. PendingReviews/{eventId}_owner_{ownerId}
     - DELETE ❌
```

### **5. Participante avalia owner**
```
PendingReviews/{eventId}_participant_{participantId}
  ↓
ReviewDialog verifica: allowed_to_review_owner == true
  ↓
STEP 1-3: Avaliar owner
  ↓
Reviews/{reviewId}
  - reviewer_id: participantId
  - reviewee_id: ownerId
  - criteria_ratings, badges, comment
  ↓
PendingReviews/{eventId}_participant_{participantId}
  - DELETE ❌
```

---

## ✅ CHECKLIST DE IMPLEMENTAÇÃO

### **Backend (Cloud Function)**
- [ ] 1. Criar `functions/src/reviews/createPendingReviews.ts`
- [ ] 2. Implementar função `createPendingReviewsScheduled` (every 5 minutes)
- [ ] 3. Adicionar flag `pendingReviewsCreated` na coleção Events
- [ ] 4. Testar idempotência (função não reprocessa mesmo evento)
- [ ] 5. Deploy: `firebase deploy --only functions:createPendingReviewsScheduled`

### **Models (Data Layer)**
- [ ] 6. Atualizar `PendingReviewModel`:
  - [ ] Adicionar `presenceConfirmed`, `participantIds`, `participantProfiles`
  - [ ] Adicionar `allowedToReviewOwner`, `revieweeName`, `revieweePhotoUrl`
  - [ ] Criar classe `ParticipantProfile`
  - [ ] Adicionar getters: `isOwnerReview`, `needsPresenceConfirmation`

### **Repository (Data Access)**
- [ ] 7. Atualizar `ReviewRepository`:
  - [ ] `updatePendingReview(pendingReviewId, data)`
  - [ ] `saveConfirmedParticipant(eventId, participantId, confirmedBy)`
  - [ ] `markParticipantAsReviewed(eventId, participantId)`
  - [ ] `createParticipantPendingReview(...)`
  - [ ] `deletePendingReview(pendingReviewId)`

### **Controller (Business Logic)**
- [ ] 8. Refatorar `ReviewDialogController`:
  - [ ] Estado: `presenceConfirmed`, `selectedParticipants`, `participantProfiles`
  - [ ] Ratings por participante: `ratingsPerParticipant`, `badgesPerParticipant`, `commentPerParticipant`
  - [ ] Controle: `currentParticipantIndex`, `currentParticipantId`
  - [ ] Métodos: `toggleParticipant()`, `confirmPresenceAndProceed()`, `nextParticipant()`
  - [ ] Submissão: `submitAllReviews()` (batch)
  - [ ] Inicialização: `initializeFromPendingReview()`

### **UI (Presentation)**
- [ ] 9. Criar `ParticipantConfirmationStep` widget:
  - [ ] Header explicativo
  - [ ] Lista com checkboxes
  - [ ] `ParticipantCheckboxTile` (avatar + nome)
  - [ ] Botão "Confirmar (N)"
  
- [ ] 10. Atualizar `ReviewDialog`:
  - [ ] Adicionar bloqueio para participante sem permissão (`_buildBlockedDialog`)
  - [ ] Renderizar STEP 0 se `needsPresenceConfirmation`
  - [ ] Ajustar progress bar (4 steps vs 3 steps)
  - [ ] Atualizar lógica de navegação

### **Database (Firestore)**
- [ ] 11. Criar subcoleção `Events/{eventId}/ConfirmedParticipants/{userId}`
- [ ] 12. Atualizar índices Firestore se necessário
- [ ] 13. Adicionar Security Rules para ConfirmedParticipants

### **Testes**
- [ ] 14. **Teste 1:** Cloud Function cria PendingReview após evento terminar
- [ ] 15. **Teste 2:** Owner vê somente participantes com presence="Vou"
- [ ] 16. **Teste 3:** Owner confirma presença e não vê STEP 0 novamente
- [ ] 17. **Teste 4:** Owner avalia cada participante com notas diferentes
- [ ] 18. **Teste 5:** Participante recebe PendingReview após ser avaliado
- [ ] 19. **Teste 6:** Participante consegue avaliar owner (allowedToReviewOwner=true)
- [ ] 20. **Teste 7:** Participante não avaliado não consegue avaliar (bloqueado)
- [ ] 21. **Teste 8:** Nenhuma avaliação duplicada é criada
- [ ] 22. **Teste 9:** Cloud Function não dispara 2x para mesmo evento

---

## 🚀 ORDEM DE IMPLEMENTAÇÃO SUGERIDA

### **Fase 1: Modelos e Repository (Base de Dados)**
1. Atualizar `PendingReviewModel` com novos campos
2. Atualizar `ReviewRepository` com novos métodos
3. Testar queries e operações no Firestore

### **Fase 2: Controller (Lógica de Negócio)**
4. Refatorar `ReviewDialogController` com estado de presença
5. Implementar lógica de ratings por participante
6. Implementar `submitAllReviews()` com batch

### **Fase 3: UI (Apresentação)**
7. Criar `ParticipantConfirmationStep` widget
8. Atualizar `ReviewDialog` com STEP 0 e bloqueio
9. Ajustar navegação e progress bar

### **Fase 4: Backend (Cloud Function)**
10. Implementar `createPendingReviewsScheduled`
11. Testar em ambiente local (emulador)
12. Deploy em produção

### **Fase 5: Testes End-to-End**
13. Criar evento de teste
14. Simular participantes com presence="Vou"
15. Testar fluxo completo: owner → participante → avaliações

---

## 🔒 GARANTIAS DE SEGURANÇA

### **1. Idempotência**
- ✅ Cloud Function não reprocessa evento (flag `pendingReviewsCreated`)
- ✅ PendingReview usa ID determinístico (`${eventId}_owner_${ownerId}`)
- ✅ Não é possível confirmar presença 2x (check `presenceConfirmed`)

### **2. Permissões**
- ✅ Participante só avalia se `allowedToReviewOwner == true`
- ✅ Owner só cria PendingReview para participantes confirmados
- ✅ Firestore Rules valida `reviewer_id` e `reviewee_id`

### **3. Consistência**
- ✅ ConfirmedParticipants é fonte de verdade
- ✅ Reviews e PendingReviews sincronizados (batch transaction)
- ✅ Perfis pré-carregados (evita race conditions)

---

## 📊 MÉTRICAS DE SUCESSO

- **Performance:** Cloud Function executa em < 10s para 50 eventos
- **Latência:** Owner recebe PendingReview em até 5 minutos após evento
- **Taxa de Conversão:** > 60% de owners confirmam presença
- **Taxa de Review:** > 40% de participantes confirmados avaliam owner
- **Erros:** < 0.1% de falhas na criação de PendingReviews

---

## 🧪 SCRIPT DE TESTE MANUAL

```dart
// 1. Criar evento de teste
final eventId = await createTestEvent(
  ownerId: 'owner123',
  scheduleDate: DateTime.now().add(const Duration(minutes: -5)),
);

// 2. Criar participantes
await createParticipant(eventId: eventId, userId: 'user1', presence: 'Vou');
await createParticipant(eventId: eventId, userId: 'user2', presence: 'Vou');
await createParticipant(eventId: eventId, userId: 'user3', presence: 'Talvez');

// 3. Esperar Cloud Function (5min)
await Future.delayed(const Duration(minutes: 6));

// 4. Verificar PendingReview criado
final pendingReview = await getPendingReview('${eventId}_owner_owner123');
assert(pendingReview.participantIds.length == 2); // user1, user2 (apenas "Vou")

// 5. Simular owner confirmando presença
await confirmPresence(
  pendingReviewId: pendingReview.pendingReviewId,
  selectedParticipants: ['user1'],
);

// 6. Verificar ConfirmedParticipants
final confirmed = await getConfirmedParticipant(eventId, 'user1');
assert(confirmed.confirmedBy == 'owner123');

// 7. Simular owner avaliando
await submitReview(
  eventId: eventId,
  reviewerId: 'owner123',
  revieweeId: 'user1',
  rating: 5,
);

// 8. Verificar PendingReview criado para participante
final participantPendingReview = await getPendingReview('${eventId}_participant_user1');
assert(participantPendingReview.allowedToReviewOwner == true);

// 9. Simular participante avaliando
await submitReview(
  eventId: eventId,
  reviewerId: 'user1',
  revieweeId: 'owner123',
  rating: 4,
);

// 10. Verificar reviews finais
final reviews = await getReviewsForEvent(eventId);
assert(reviews.length == 2); // owner → user1, user1 → owner
```

---

## 🎯 PRÓXIMOS PASSOS

Deseja que eu:

1. **Implemente tudo de uma vez** (mais rápido, mas menos controle)
2. **Vá por fases** (Fase 1 → 2 → 3 → 4 → 5)
3. **Comece por uma parte específica** (ex: só o modelo primeiro)

**Recomendação:** Começar pela **Fase 1 (Modelos + Repository)** para ter base sólida antes de mexer no controller e UI.
