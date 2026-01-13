import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:partiu/core/constants/constants.dart';
import 'package:partiu/core/constants/glimpse_colors.dart';
import 'package:partiu/core/utils/app_localizations.dart';
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
  /// Cache local para exibir imediatamente (sem stream/firestore aqui)
  List<Map<String, dynamic>> _cachedParticipants = const [];

  /// 🎯 IDs dos participantes que acabaram de entrar (para animar apenas eles)
  final Set<String> _newlyAddedIds = <String>{};

  /// Flag para saber se é o primeiro build (nunca anima no primeiro build)
  bool _isFirstBuild = true;
  
  @override
  void initState() {
    super.initState();
    _updateParticipants(widget.preloadedParticipants ?? const []);
  }

  @override
  void didUpdateWidget(covariant ParticipantsAvatarsList oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.preloadedParticipants != widget.preloadedParticipants) {
      _updateParticipants(widget.preloadedParticipants ?? const []);
    }
  }

  void _updateParticipants(List<Map<String, dynamic>> next) {
    final oldIds = _cachedParticipants
        .map((p) => p['userId'] as String?)
        .whereType<String>()
        .toSet();
    final newIds = next
        .map((p) => p['userId'] as String?)
        .whereType<String>()
        .toSet();

    final addedIds = newIds.difference(oldIds);

    if (!_isFirstBuild && addedIds.isNotEmpty) {
      _newlyAddedIds
        ..clear()
        ..addAll(addedIds);
    } else if (_isFirstBuild) {
      _newlyAddedIds.clear();
      _isFirstBuild = false;
    }

    _cachedParticipants = next;

    // ✅ PRELOAD: Carregar avatares antes da UI renderizar
    for (final p in _cachedParticipants) {
      final pUserId = p['userId'] as String?;
      final pPhotoUrl = p['photoUrl'] as String?;
      if (pUserId != null && pPhotoUrl != null && pPhotoUrl.isNotEmpty) {
        UserStore.instance.preloadAvatar(pUserId, pPhotoUrl);
      }
    }

    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    // Altura fixa para evitar popping durante carregamento
    // Avatar (40) + spacing (4) + nome (17) + padding top (12) = 73
    const fixedHeight = 73.0;

    final participants = _cachedParticipants;

    return SizedBox(
      height: participants.isEmpty ? 0 : fixedHeight,
      child: participants.isEmpty
          ? const SizedBox.shrink()
          : _buildParticipantsList(participants),
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
    final i18n = AppLocalizations.of(context);

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
              i18n.translate('plus_count').replaceAll('{count}', count.toString()),
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
