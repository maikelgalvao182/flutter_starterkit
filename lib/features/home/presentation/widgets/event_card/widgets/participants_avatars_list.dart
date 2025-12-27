import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:partiu/core/constants/constants.dart';
import 'package:partiu/core/constants/glimpse_colors.dart';
import 'package:partiu/shared/stores/user_store.dart';
import 'package:partiu/shared/widgets/AnimatedSlideIn.dart';
import 'package:partiu/shared/widgets/stable_avatar.dart';

/// Widget reativo que exibe lista horizontal de avatares dos participantes
/// Usa dados pré-carregados do controller + Stream do Firestore para atualizações
class ParticipantsAvatarsList extends StatefulWidget {
  const ParticipantsAvatarsList({
    required this.eventId,
    required this.creatorId,
    this.preloadedParticipants,
    this.maxVisible = 5,
    super.key,
  });

  final String eventId;
  final String? creatorId;
  /// Dados pré-carregados do EventCardController para exibição instantânea
  final List<Map<String, dynamic>>? preloadedParticipants;
  final int maxVisible;

  @override
  State<ParticipantsAvatarsList> createState() => _ParticipantsAvatarsListState();
}

class _ParticipantsAvatarsListState extends State<ParticipantsAvatarsList> {
  /// Flag para saber se já recebemos dados do servidor
  bool _hasReceivedServerData = false;
  
  /// Cache local para exibir enquanto aguarda dados do servidor
  late List<Map<String, dynamic>>? _cachedParticipants;
  
  /// 🎯 IDs dos participantes que acabaram de entrar (para animar apenas eles)
  final Set<String> _newlyAddedIds = {};
  
  /// Flag para saber se é o primeiro build (nunca anima no primeiro build)
  bool _isFirstBuild = true;
  
  @override
  void initState() {
    super.initState();
    // ✅ Usar dados pré-carregados do controller como estado inicial
    _cachedParticipants = widget.preloadedParticipants;
    if (_cachedParticipants != null && _cachedParticipants!.isNotEmpty) {
      debugPrint('🚀 [ParticipantsAvatarsList] Usando ${_cachedParticipants!.length} participantes pré-carregados');
    }
  }
  
  /// Stream de participantes aprovados com dados do usuário
  Stream<List<Map<String, dynamic>>> get _participantsStream {
    debugPrint('🔵 [ParticipantsAvatarsList] Stream INICIADO para eventId: ${widget.eventId}');
    
    return FirebaseFirestore.instance
        .collection('EventApplications')
        .where('eventId', isEqualTo: widget.eventId)
        .where('status', whereIn: ['approved', 'autoApproved'])
        .snapshots()
        .asyncMap((snapshot) async {
          debugPrint('📥 [ParticipantsAvatarsList] Snapshot recebido');
          debugPrint('   └─ isFromCache: ${snapshot.metadata.isFromCache}');
          debugPrint('   └─ hasPendingWrites: ${snapshot.metadata.hasPendingWrites}');
          debugPrint('   └─ docs.length: ${snapshot.docs.length}');
          
          // Se é do cache E já recebemos dados do servidor antes,
          // ignorar para evitar avatar fantasma ao sair do evento
          if (snapshot.metadata.isFromCache && _hasReceivedServerData) {
            debugPrint('⚠️ [ParticipantsAvatarsList] Ignorando CACHE (já temos dados do servidor)');
            return _cachedParticipants ?? <Map<String, dynamic>>[];
          }
          
          // Marca que recebemos dados do servidor
          if (!snapshot.metadata.isFromCache) {
            _hasReceivedServerData = true;
          }
          
          final participants = <Map<String, dynamic>>[];
          
          for (final doc in snapshot.docs) {
            final userId = doc.data()['userId'] as String?;
            debugPrint('👤 [ParticipantsAvatarsList] Processando doc: ${doc.id}');
            debugPrint('   └─ userId: $userId');
            if (userId == null) continue;
            
            // Buscar dados do usuário
            final userDoc = await FirebaseFirestore.instance
                .collection('Users')
                .doc(userId)
                .get();
            
            debugPrint('📄 [ParticipantsAvatarsList] UserDoc exists: ${userDoc.exists}');
            
            if (userDoc.exists) {
              final userData = userDoc.data()!;
              final fullName = userData['fullName'] ?? 'Anônimo';
              final photoUrl = userData['photoUrl'] ?? '';
              
              // 🔑 Capturar timestamp de aprovação para ordenação estável
              final approvedAt = doc.data()['approvedAt'] as Timestamp?;
              
              debugPrint('✅ [ParticipantsAvatarsList] Dados do usuário:');
              debugPrint('   └─ fullName: $fullName');
              debugPrint('   └─ photoUrl: $photoUrl');
              debugPrint('   └─ isCreator: ${userId == widget.creatorId}');
              debugPrint('   └─ approvedAt: $approvedAt');
              
              participants.add({
                'userId': userId,
                'fullName': fullName,
                'photoUrl': photoUrl,
                'isCreator': userId == widget.creatorId,
                'approvedAt': approvedAt, // 👈 ESSENCIAL para ordem estável
              });
            }
          }
          
          // 🎯 Ordenação estável: criador primeiro, depois por approvedAt
          // Isso garante que novos participantes SEMPRE entram à direita
          participants.sort((a, b) {
            // 1️⃣ Criador sempre primeiro
            if (a['isCreator'] == true && b['isCreator'] != true) return -1;
            if (b['isCreator'] == true && a['isCreator'] != true) return 1;
            
            // 2️⃣ Ambos não são criador → ordenar por approvedAt (mais antigo primeiro)
            final aTime = a['approvedAt'] as Timestamp?;
            final bTime = b['approvedAt'] as Timestamp?;
            
            // Se algum não tem timestamp, manter posição atual
            if (aTime == null && bTime == null) return 0;
            if (aTime == null) return 1; // Sem timestamp vai pro final
            if (bTime == null) return -1;
            
            return aTime.compareTo(bTime);
          });
          
          debugPrint('📊 [ParticipantsAvatarsList] Total participantes: ${participants.length}');
          for (var p in participants) {
            debugPrint('   └─ ${p['fullName']} (${p['userId']}) - photoUrl: ${p['photoUrl']}');
          }
          
          // ✅ PRELOAD: Carregar avatares antes da UI renderizar
          for (final p in participants) {
            final pUserId = p['userId'] as String?;
            final pPhotoUrl = p['photoUrl'] as String?;
            if (pUserId != null && pPhotoUrl != null && pPhotoUrl.isNotEmpty) {
              UserStore.instance.preloadAvatar(pUserId, pPhotoUrl);
            }
          }
          
          // 🎯 DIFF: Calcular quem REALMENTE entrou (para animar apenas eles)
          final oldIds = (_cachedParticipants ?? [])
              .map((p) => p['userId'] as String?)
              .whereType<String>()
              .toSet();
          final newIds = participants
              .map((p) => p['userId'] as String?)
              .whereType<String>()
              .toSet();
          
          final addedIds = newIds.difference(oldIds);
          
          debugPrint('🔍 [ParticipantsAvatarsList] DIFF:');
          debugPrint('   └─ _isFirstBuild: $_isFirstBuild');
          debugPrint('   └─ oldIds: $oldIds');
          debugPrint('   └─ newIds: $newIds');
          debugPrint('   └─ addedIds: $addedIds');
          
          // Só anima se NÃO for primeiro build E tiver novos IDs
          if (!_isFirstBuild && addedIds.isNotEmpty) {
            _newlyAddedIds
              ..clear()
              ..addAll(addedIds);
            debugPrint('✨ [ParticipantsAvatarsList] Marcando para animar: $_newlyAddedIds');
          } else if (_isFirstBuild) {
            // Primeiro build: não animar ninguém
            _newlyAddedIds.clear();
            debugPrint('🏁 [ParticipantsAvatarsList] Primeiro build - sem animação');
            // ✅ Marcar que primeiro build já passou (para próximas emissões)
            _isFirstBuild = false;
          }
          // Não limpa _newlyAddedIds se addedIds estiver vazio (mantém estado anterior)
          
          // Atualiza cache local
          _cachedParticipants = participants;
          
          return participants;
        });
  }

  @override
  Widget build(BuildContext context) {
    // Altura fixa para evitar popping durante carregamento
    // Avatar (40) + spacing (4) + nome (17) + padding top (12) = 73
    const fixedHeight = 73.0;
    
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _participantsStream,
      builder: (context, snapshot) {
        // Usa dados do snapshot ou cache local para evitar flicker
        final participants = snapshot.data ?? _cachedParticipants ?? [];
        
        debugPrint('🎨 [ParticipantsAvatarsList] BUILD:');
        debugPrint('   └─ snapshot.hasData: ${snapshot.hasData}');
        debugPrint('   └─ participants.length: ${participants.length}');
        debugPrint('   └─ _newlyAddedIds: $_newlyAddedIds');
        
        // Container com altura fixa para evitar layout shift
        return SizedBox(
          height: participants.isEmpty ? 0 : fixedHeight,
          child: participants.isEmpty
              ? const SizedBox.shrink()
              : _buildParticipantsList(participants),
        );
      },
    );
  }
  
  Widget _buildParticipantsList(List<Map<String, dynamic>> participants) {
    final visible = participants.take(widget.maxVisible).toList();
    final remaining = participants.length - visible.length;

    return Column(
      children: [
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (int i = 0; i < visible.length; i++)
              _buildParticipantWidget(visible[i], i),
            
            if (remaining > 0)
              Padding(
                padding: const EdgeInsets.only(left: 8),
                child: _RemainingCounter(count: remaining),
              ),
          ],
        ),
      ],
    );
  }
  
  /// 🎯 Constrói widget do participante: anima APENAS se acabou de entrar
  Widget _buildParticipantWidget(Map<String, dynamic> participant, int index) {
    final userId = participant['userId'] as String;
    final isNewlyAdded = _newlyAddedIds.contains(userId);
    
    final child = Padding(
      padding: EdgeInsets.only(left: index == 0 ? 0 : 8),
      child: _ParticipantItem(
        key: ValueKey('participant_$userId'),
        participant: participant,
        isCreator: participant['isCreator'] == true,
      ),
    );
    
    // ✅ Animar APENAS quem acabou de entrar
    if (isNewlyAdded) {
      debugPrint('🎬 [ParticipantsAvatarsList] Animando entrada de: $userId');
      return AnimatedSlideIn(
        key: ValueKey('anim_$userId'),
        delay: Duration(milliseconds: index * 100),
        offsetX: 60.0,
        child: child,
      );
    }
    
    // ✅ Participantes existentes: renderiza estável, sem animação
    return child;
  }
}

/// Item individual de participante (avatar + nome)
class _ParticipantItem extends StatelessWidget {
  const _ParticipantItem({
    required this.participant,
    required this.isCreator,
    super.key,
  });

  final Map<String, dynamic> participant;
  final bool isCreator;

  @override
  Widget build(BuildContext context) {
    final userId = participant['userId'] as String;
    final photoUrl = participant['photoUrl'] as String?;
    final fullName = participant['fullName'] as String? ?? 'Anônimo';

    return Column(
      children: [
        SizedBox(
          width: 40,
          height: 40,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              StableAvatar(
                userId: userId,
                photoUrl: photoUrl,
                size: 40,
                borderRadius: BorderRadius.circular(999),
                enableNavigation: true,
              ),
              if (isCreator)
                Positioned(
                  bottom: -2,
                  right: 0,
                  child: Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: GlimpseColors.primary,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        SizedBox(
          width: 50,
          child: Text(
            fullName,
            style: GoogleFonts.getFont(
              FONT_PLUS_JAKARTA_SANS,
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: GlimpseColors.textSubTitle,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

/// Contador de participantes restantes (+X)
class _RemainingCounter extends StatelessWidget {
  const _RemainingCounter({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: GlimpseColors.lightTextField,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              '+$count',
              style: GoogleFonts.getFont(
                FONT_PLUS_JAKARTA_SANS,
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: GlimpseColors.textSubTitle,
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
        const SizedBox(width: 50, height: 17),
      ],
    );
  }
}
