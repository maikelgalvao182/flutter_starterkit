import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:partiu/core/constants/constants.dart';
import 'package:partiu/core/constants/glimpse_colors.dart';
import 'package:partiu/core/services/toast_service.dart';
import 'package:partiu/core/utils/app_localizations.dart';
import 'package:partiu/features/reviews/data/models/pending_review_model.dart';
import 'package:partiu/features/reviews/data/repositories/review_repository.dart';
import 'package:partiu/features/reviews/presentation/components/badge_selection_step.dart';
import 'package:partiu/features/reviews/presentation/components/comment_step.dart';
import 'package:partiu/features/reviews/presentation/components/participant_confirmation_step.dart';
import 'package:partiu/features/reviews/presentation/components/rating_criteria_step.dart';
import 'package:partiu/features/reviews/presentation/dialogs/controller/review_batch_service.dart';
import 'package:partiu/features/reviews/presentation/dialogs/controller/review_dialog_state.dart';
import 'package:partiu/shared/widgets/glimpse_button.dart';
import 'package:partiu/shared/widgets/glimpse_close_button.dart';

/// Fluxo refatorado: 4 bottom sheets (uma decisão por etapa)
///
/// - Owner: (opcional) presença/participantes → ratings → badges → comentário/final
/// - Participant: ratings → badges → comentário/final
///
/// Regras:
/// - Retorno explícito de dados entre etapas
/// - Submit só no final
/// - Sem `currentStep` global na UI
class ReviewDialog {
  static Future<bool?> show(
    BuildContext context, {
    required PendingReviewModel pendingReview,
  }) async {
    final repo = ReviewRepository();

    // Owner: step 0 (condicionado)
    List<String> participantsToReview = const [];
    if (pendingReview.isOwnerReview) {
      final fromField = pendingReview.confirmedParticipantIds ?? const <String>[];
      final fromProfiles = (pendingReview.participantProfiles ?? const <String, ParticipantProfile>{})
          .entries
          .where((e) => e.value.presenceConfirmed)
          .map((e) => e.key)
          .toList();

      final initialConfirmed = fromField.isNotEmpty ? fromField : fromProfiles;

      if (pendingReview.needsPresenceConfirmation) {
        final selected = await _showOwnerPresenceSheet(
          context,
          pendingReview: pendingReview,
          initialSelected: initialConfirmed,
        );
        if (selected == null) {
          return false;
        }

        // Persistir confirmação (backend precisa disso para liberar reviews)
        await _persistPresenceConfirmation(
          repo,
          pendingReview: pendingReview,
          selectedParticipantIds: selected,
        );

        if (!context.mounted) {
          return false;
        }

        participantsToReview = selected;
      } else {
        participantsToReview = initialConfirmed.isNotEmpty
            ? initialConfirmed
            : (pendingReview.participantIds ?? const <String>[]);
      }

      if (participantsToReview.isEmpty) {
        return false;
      }

      final ratingsPerParticipant = <String, Map<String, int>>{};
      final badgesPerParticipant = <String, List<String>>{};
      final commentPerParticipant = <String, String>{};

      for (var i = 0; i < participantsToReview.length; i++) {
        final participantId = participantsToReview[i];
        final profile = pendingReview.participantProfiles?[participantId];
        final displayName = (profile?.name.isNotEmpty == true) ? profile!.name : 'Participante';
        final displayPhotoUrl = profile?.photoUrl;
        final isLast = i == participantsToReview.length - 1;
        final remaining = _remainingParticipants(
          pendingReview: pendingReview,
          participantsToReview: participantsToReview,
          currentIndex: i,
        );

        final ratings = await _showRatingsSheet(
          context,
          title: 'Como foi a experiência?',
          allowProceed: true,
          revieweeName: displayName,
          revieweePhotoUrl: displayPhotoUrl,
        );
        if (!context.mounted) return false;
        if (ratings == null) {
          return false;
        }

        final badges = await _showBadgesSheet(
          context,
          title: 'Destaque qualidades',
          revieweeName: displayName,
          revieweePhotoUrl: displayPhotoUrl,
        );
        if (!context.mounted) return false;
        if (badges == null) {
          return false;
        }

        final comment = await _showCommentSheet(
          context,
          title: 'Deixe um comentário',
          primaryButtonText: isLast ? 'Enviar avaliações' : 'Continuar',
          revieweeName: displayName,
          revieweePhotoUrl: displayPhotoUrl,
          remainingParticipants: remaining,
        );
        if (!context.mounted) return false;
        if (comment == null) {
          return false;
        }

        ratingsPerParticipant[participantId] = ratings;
        badgesPerParticipant[participantId] = badges;
        commentPerParticipant[participantId] = comment;
      }

      try {
        await _submitOwnerBatch(
          pendingReview: pendingReview,
          participantIds: participantsToReview,
          ratingsPerParticipant: ratingsPerParticipant,
          badgesPerParticipant: badgesPerParticipant,
          commentPerParticipant: commentPerParticipant,
        );

        if (!context.mounted) {
          return true;
        }

        final i18n = AppLocalizations.of(context);
        final message = participantsToReview.length > 1
            ? i18n
                .translate('reviews_sent_successfully')
                .replaceAll('{count}', participantsToReview.length.toString())
            : i18n.translate('review_sent_successfully');
        ToastService.showSuccess(message: message);

        return true;
      } catch (e) {
        if (context.mounted) {
          ToastService.showError(message: e.toString());
        }
        return false;
      }
    }

    // Participant flow
    final allowed = pendingReview.allowedToReviewOwner ?? false;
    final ratings = await _showRatingsSheet(
      context,
      title: 'Como foi a experiência?',
      allowProceed: allowed,
      revieweeName: pendingReview.revieweeName,
      revieweePhotoUrl: pendingReview.revieweePhotoUrl,
      blockedMessage:
          'Você não tem permissão para avaliar este evento. Sua presença pode não ter sido confirmada pelo organizador.',
    );
    if (!context.mounted) return false;
    if (ratings == null) {
      return false;
    }

    final badges = await _showBadgesSheet(
      context,
      title: 'Destaque qualidades',
      revieweeName: pendingReview.revieweeName,
      revieweePhotoUrl: pendingReview.revieweePhotoUrl,
    );
    if (!context.mounted) return false;
    if (badges == null) {
      return false;
    }

    final comment = await _showCommentSheet(
      context,
      title: 'Deixe um comentário',
      primaryButtonText: 'Enviar avaliação',
      revieweeName: pendingReview.revieweeName,
      revieweePhotoUrl: pendingReview.revieweePhotoUrl,
      remainingParticipants: const [],
    );
    if (!context.mounted) return false;
    if (comment == null) {
      return false;
    }

    try {
      await repo.createReview(
        eventId: pendingReview.eventId,
        revieweeId: pendingReview.revieweeId,
        reviewerRole: pendingReview.reviewerRole,
        criteriaRatings: ratings,
        badges: badges,
        comment: comment.trim().isEmpty ? null : comment.trim(),
        pendingReviewId: pendingReview.pendingReviewId,
      );

      if (!context.mounted) {
        return true;
      }

      final i18n = AppLocalizations.of(context);
      ToastService.showSuccess(message: i18n.translate('review_sent_successfully'));
      return true;
    } catch (e) {
      if (context.mounted) {
        ToastService.showError(message: e.toString());
      }
      return false;
    }
  }

  static List<Map<String, String>> _remainingParticipants({
    required PendingReviewModel pendingReview,
    required List<String> participantsToReview,
    required int currentIndex,
  }) {
    final profiles = pendingReview.participantProfiles;
    if (profiles == null) return const [];

    final out = <Map<String, String>>[];
    for (var i = currentIndex + 1; i < participantsToReview.length; i++) {
      final id = participantsToReview[i];
      final p = profiles[id];
      if (p == null) continue;
      out.add({
        'id': id,
        'name': p.name,
        'photoUrl': p.photoUrl ?? '',
      });
    }
    return out;
  }
}

// -----------------------------------------------------------------------------
// Presence (Owner)
// -----------------------------------------------------------------------------

Future<List<String>?> _showOwnerPresenceSheet(
  BuildContext context, {
  required PendingReviewModel pendingReview,
  required List<String> initialSelected,
}) {
  final screenHeight = MediaQuery.of(context).size.height;
  final maxHeight = screenHeight * 0.85;

  return showModalBottomSheet<List<String>>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    isDismissible: false,
    enableDrag: false,
    builder: (sheetContext) {
      return _OwnerPresenceSheet(
        pendingReview: pendingReview,
        initialSelected: initialSelected,
        maxHeight: maxHeight,
      );
    },
  );
}

class _OwnerPresenceSheet extends StatefulWidget {
  const _OwnerPresenceSheet({
    required this.pendingReview,
    required this.initialSelected,
    required this.maxHeight,
  });

  final PendingReviewModel pendingReview;
  final List<String> initialSelected;
  final double maxHeight;

  @override
  State<_OwnerPresenceSheet> createState() => _OwnerPresenceSheetState();
}

class _OwnerPresenceSheetState extends State<_OwnerPresenceSheet> {
  late final List<String> _selected = List<String>.from(widget.initialSelected);

  void _toggle(String participantId) {
    setState(() {
      if (_selected.contains(participantId)) {
        _selected.remove(participantId);
      } else {
        _selected.add(participantId);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final pending = widget.pendingReview;
    final participantIds = pending.participantIds ?? const <String>[];
    final profiles = pending.participantProfiles ?? const <String, ParticipantProfile>{};

    return _SheetScaffold(
      maxHeight: widget.maxHeight,
      title: 'Confirmar presença',
      subtitle: null,
      onClose: () => Navigator.of(context, rootNavigator: true).pop<List<String>?>(null),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: ParticipantConfirmationStep(
          participantIds: participantIds,
          participantProfiles: profiles,
          selectedParticipants: _selected,
          onToggleParticipant: _toggle,
          eventTitle: pending.eventTitle,
          eventEmoji: pending.eventEmoji,
          eventDate: pending.eventDate,
        ),
      ),
      primaryButtonText: 'Continuar',
      primaryEnabled: _selected.isNotEmpty,
      onPrimaryPressed: () => Navigator.of(context, rootNavigator: true).pop<List<String>>(_selected),
    );
  }
}

Future<void> _persistPresenceConfirmation(
  ReviewRepository repo, {
  required PendingReviewModel pendingReview,
  required List<String> selectedParticipantIds,
}) async {
  if (selectedParticipantIds.isEmpty) return;

  final participantProfilesUpdate = <String, dynamic>{};
  for (final participantId in selectedParticipantIds) {
    participantProfilesUpdate['participant_profiles.$participantId.presence_confirmed'] = true;
  }

  await repo.updatePendingReview(
    pendingReviewId: pendingReview.pendingReviewId,
    data: {
      'confirmed_participant_ids': selectedParticipantIds,
      ...participantProfilesUpdate,
    },
  );

  for (final participantId in selectedParticipantIds) {
    await repo.saveConfirmedParticipant(
      eventId: pendingReview.eventId,
      participantId: participantId,
      confirmedBy: pendingReview.reviewerId,
    );
  }
}

// -----------------------------------------------------------------------------
// Ratings
// -----------------------------------------------------------------------------

Future<Map<String, int>?> _showRatingsSheet(
  BuildContext context, {
  required String title,
  required bool allowProceed,
  required String revieweeName,
  required String? revieweePhotoUrl,
  String? blockedMessage,
}) {
  final screenHeight = MediaQuery.of(context).size.height;
  final maxHeight = screenHeight * 0.85;

  return showModalBottomSheet<Map<String, int>>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    isDismissible: false,
    enableDrag: false,
    builder: (sheetContext) {
      return _RatingsSheet(
        maxHeight: maxHeight,
        title: title,
        allowProceed: allowProceed,
        blockedMessage: blockedMessage,
        revieweeName: revieweeName,
        revieweePhotoUrl: revieweePhotoUrl,
      );
    },
  );
}

class _RatingsSheet extends StatefulWidget {
  const _RatingsSheet({
    required this.maxHeight,
    required this.title,
    required this.allowProceed,
    required this.blockedMessage,
    required this.revieweeName,
    required this.revieweePhotoUrl,
  });

  final double maxHeight;
  final String title;
  final bool allowProceed;
  final String? blockedMessage;
  final String revieweeName;
  final String? revieweePhotoUrl;

  @override
  State<_RatingsSheet> createState() => _RatingsSheetState();
}

class _RatingsSheetState extends State<_RatingsSheet> {
  final Map<String, int> _ratings = {};

  @override
  Widget build(BuildContext context) {
    final canProceed = widget.allowProceed && _ratings.length >= MINIMUM_REQUIRED_RATINGS;

    return _SheetScaffold(
      maxHeight: widget.maxHeight,
      title: widget.title,
      subtitle: null,
      onClose: () => Navigator.of(context, rootNavigator: true).pop<Map<String, int>?>(null),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          children: [
            CircleAvatar(
              radius: 28,
              backgroundColor: GlimpseColors.primary.withValues(alpha: 0.2),
              backgroundImage: widget.revieweePhotoUrl != null ? NetworkImage(widget.revieweePhotoUrl!) : null,
              child: widget.revieweePhotoUrl == null
                  ? Text(
                      widget.revieweeName.isNotEmpty ? widget.revieweeName[0].toUpperCase() : '?',
                      style: GoogleFonts.getFont(
                        FONT_PLUS_JAKARTA_SANS,
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: GlimpseColors.primary,
                      ),
                    )
                  : null,
            ),
            const SizedBox(height: 8),
            Text(
              widget.revieweeName,
              textAlign: TextAlign.center,
              style: GoogleFonts.getFont(
                FONT_PLUS_JAKARTA_SANS,
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: GlimpseColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            if (!widget.allowProceed && widget.blockedMessage != null) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: GlimpseColors.error.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: GlimpseColors.error.withValues(alpha: 0.3),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.error_outline,
                      color: GlimpseColors.error,
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        widget.blockedMessage!,
                        style: GoogleFonts.getFont(
                          FONT_PLUS_JAKARTA_SANS,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: GlimpseColors.error,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],
            RatingCriteriaStep(
              ratings: _ratings,
              onRatingChanged: (criterion, value) {
                setState(() {
                  _ratings[criterion] = value;
                });
              },
            ),
          ],
        ),
      ),
      primaryButtonText: 'Continuar',
      primaryEnabled: canProceed,
      onPrimaryPressed: () => Navigator.of(context, rootNavigator: true).pop<Map<String, int>>(_ratings),
    );
  }
}

// -----------------------------------------------------------------------------
// Badges
// -----------------------------------------------------------------------------

Future<List<String>?> _showBadgesSheet(
  BuildContext context, {
  required String title,
  required String revieweeName,
  required String? revieweePhotoUrl,
}) {
  final screenHeight = MediaQuery.of(context).size.height;
  final maxHeight = screenHeight * 0.85;

  return showModalBottomSheet<List<String>>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    isDismissible: false,
    enableDrag: false,
    builder: (sheetContext) {
      return _BadgesSheet(
        maxHeight: maxHeight,
        title: title,
        revieweeName: revieweeName,
        revieweePhotoUrl: revieweePhotoUrl,
      );
    },
  );
}

class _BadgesSheet extends StatefulWidget {
  const _BadgesSheet({
    required this.maxHeight,
    required this.title,
    required this.revieweeName,
    required this.revieweePhotoUrl,
  });

  final double maxHeight;
  final String title;
  final String revieweeName;
  final String? revieweePhotoUrl;

  @override
  State<_BadgesSheet> createState() => _BadgesSheetState();
}

class _BadgesSheetState extends State<_BadgesSheet> {
  final List<String> _selectedBadges = [];

  @override
  Widget build(BuildContext context) {
    return _SheetScaffold(
      maxHeight: widget.maxHeight,
      title: widget.title,
      subtitle: null,
      onClose: () => Navigator.of(context, rootNavigator: true).pop<List<String>?>(null),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          children: [
            CircleAvatar(
              radius: 28,
              backgroundColor: GlimpseColors.primary.withValues(alpha: 0.2),
              backgroundImage: widget.revieweePhotoUrl != null ? NetworkImage(widget.revieweePhotoUrl!) : null,
              child: widget.revieweePhotoUrl == null
                  ? Text(
                      widget.revieweeName.isNotEmpty ? widget.revieweeName[0].toUpperCase() : '?',
                      style: GoogleFonts.getFont(
                        FONT_PLUS_JAKARTA_SANS,
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: GlimpseColors.primary,
                      ),
                    )
                  : null,
            ),
            const SizedBox(height: 8),
            Text(
              widget.revieweeName,
              textAlign: TextAlign.center,
              style: GoogleFonts.getFont(
                FONT_PLUS_JAKARTA_SANS,
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: GlimpseColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            BadgeSelectionStep(
              selectedBadges: _selectedBadges,
              onBadgeToggle: (badgeKey) {
                setState(() {
                  if (_selectedBadges.contains(badgeKey)) {
                    _selectedBadges.remove(badgeKey);
                  } else {
                    _selectedBadges.add(badgeKey);
                  }
                });
              },
            ),
          ],
        ),
      ),
      primaryButtonText: 'Continuar',
      primaryEnabled: true,
      onPrimaryPressed: () => Navigator.of(context, rootNavigator: true).pop<List<String>>(_selectedBadges),
    );
  }
}

// -----------------------------------------------------------------------------
// Comment (final)
// -----------------------------------------------------------------------------

Future<String?> _showCommentSheet(
  BuildContext context, {
  required String title,
  required String primaryButtonText,
  required String revieweeName,
  required String? revieweePhotoUrl,
  required List<Map<String, String>> remainingParticipants,
}) {
  final screenHeight = MediaQuery.of(context).size.height;
  final maxHeight = screenHeight * 0.85;

  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    isDismissible: false,
    enableDrag: false,
    builder: (sheetContext) {
      return _CommentSheet(
        maxHeight: maxHeight,
        title: title,
        primaryButtonText: primaryButtonText,
        revieweeName: revieweeName,
        revieweePhotoUrl: revieweePhotoUrl,
        remainingParticipants: remainingParticipants,
      );
    },
  );
}

class _CommentSheet extends StatefulWidget {
  const _CommentSheet({
    required this.maxHeight,
    required this.title,
    required this.primaryButtonText,
    required this.revieweeName,
    required this.revieweePhotoUrl,
    required this.remainingParticipants,
  });

  final double maxHeight;
  final String title;
  final String primaryButtonText;
  final String revieweeName;
  final String? revieweePhotoUrl;
  final List<Map<String, String>> remainingParticipants;

  @override
  State<_CommentSheet> createState() => _CommentSheetState();
}

class _CommentSheetState extends State<_CommentSheet> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isKeyboardOpen = MediaQuery.of(context).viewInsets.bottom > 0;

    return _SheetScaffold(
      maxHeight: widget.maxHeight,
      title: widget.title,
      subtitle: null,
      onClose: () => Navigator.of(context, rootNavigator: true).pop<String?>(null),
      body: SingleChildScrollView(
        padding: EdgeInsets.only(
          left: 24,
          right: 24,
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Column(
          children: [
            if (!isKeyboardOpen) ...[
              CircleAvatar(
                radius: 28,
                backgroundColor: GlimpseColors.primary.withValues(alpha: 0.2),
                backgroundImage: widget.revieweePhotoUrl != null ? NetworkImage(widget.revieweePhotoUrl!) : null,
                child: widget.revieweePhotoUrl == null
                    ? Text(
                        widget.revieweeName.isNotEmpty ? widget.revieweeName[0].toUpperCase() : '?',
                        style: GoogleFonts.getFont(
                          FONT_PLUS_JAKARTA_SANS,
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: GlimpseColors.primary,
                        ),
                      )
                    : null,
              ),
              const SizedBox(height: 8),
              Text(
                widget.revieweeName,
                textAlign: TextAlign.center,
                style: GoogleFonts.getFont(
                  FONT_PLUS_JAKARTA_SANS,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: GlimpseColors.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
            ],
            CommentStep(
              controller: _controller,
              remainingParticipants: widget.remainingParticipants,
            ),
          ],
        ),
      ),
      primaryButtonText: widget.primaryButtonText,
      primaryEnabled: true,
      onPrimaryPressed: () => Navigator.of(context, rootNavigator: true).pop<String>(_controller.text.trim()),
    );
  }
}

// -----------------------------------------------------------------------------
// Submit (Owner)
// -----------------------------------------------------------------------------

Future<void> _submitOwnerBatch({
  required PendingReviewModel pendingReview,
  required List<String> participantIds,
  required Map<String, Map<String, int>> ratingsPerParticipant,
  required Map<String, List<String>> badgesPerParticipant,
  required Map<String, String> commentPerParticipant,
}) async {
  final firestore = FirebaseFirestore.instance;

  // Build state object for batch service
  final state = ReviewDialogState(
    eventId: pendingReview.eventId,
    revieweeId: pendingReview.revieweeId,
    reviewerRole: pendingReview.reviewerRole,
    reviewerId: pendingReview.reviewerId,
    eventTitle: pendingReview.eventTitle,
    eventEmoji: pendingReview.eventEmoji,
    eventLocationName: pendingReview.eventLocation,
    eventScheduleDate: pendingReview.eventDate,
  )
    ..selectedParticipants = List<String>.from(participantIds)
    ..participantProfiles = pendingReview.participantProfiles ?? {}
    ..ratingsPerParticipant = ratingsPerParticipant
    ..badgesPerParticipant = badgesPerParticipant
    ..commentPerParticipant = commentPerParticipant;

  final ownerData = await ReviewBatchService.prepareOwnerData(state.reviewerId, firestore);
  final ownerName = ownerData['ownerName'] ?? 'Organizador';
  final ownerPhotoUrl = ownerData['ownerPhotoUrl'];

  var batch = firestore.batch();
  var opCount = 0;
  const maxBatchSize = 490;

  for (final participantId in participantIds) {
    ReviewBatchService.createReviewBatch(
      batch,
      participantId,
      state,
      firestore,
      reviewerName: ownerName,
      reviewerPhotoUrl: ownerPhotoUrl,
    );
    opCount++;

    if (opCount >= maxBatchSize) {
      await batch.commit();
      batch = firestore.batch();
      opCount = 0;
    }
  }

  // Deletar PendingReview do owner
  batch.delete(firestore.collection('PendingReviews').doc(pendingReview.pendingReviewId));
  opCount++;

  if (opCount > 0) {
    await batch.commit();
  }

  // Pós-batch: marcar reviewed (não falhar o fluxo inteiro se uma dessas falhar)
  for (final participantId in participantIds) {
    try {
      await ReviewBatchService.markParticipantReviewedSeparate(participantId, pendingReview.eventId, firestore);
    } catch (_) {
      // silencioso
    }
  }
}

// -----------------------------------------------------------------------------
// UI scaffolding
// -----------------------------------------------------------------------------

class _SheetScaffold extends StatelessWidget {
  const _SheetScaffold({
    required this.maxHeight,
    required this.title,
    required this.subtitle,
    required this.onClose,
    required this.body,
    required this.primaryButtonText,
    required this.primaryEnabled,
    required this.onPrimaryPressed,
  });

  final double maxHeight;
  final String title;
  final String? subtitle;
  final VoidCallback onClose;
  final Widget body;
  final String primaryButtonText;
  final bool primaryEnabled;
  final VoidCallback onPrimaryPressed;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(maxHeight: maxHeight),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _SheetHeader(title: title, subtitle: subtitle, onClose: onClose),
          const SizedBox(height: 16),
          Flexible(child: body),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: GlimpseButton(
              text: primaryButtonText,
              isProcessing: false,
              onPressed: primaryEnabled ? onPrimaryPressed : null,
            ),
          ),
          SizedBox(height: MediaQuery.of(context).padding.bottom + 16),
        ],
      ),
    );
  }
}

class _SheetHeader extends StatelessWidget {
  const _SheetHeader({
    required this.title,
    required this.subtitle,
    required this.onClose,
  });

  final String title;
  final String? subtitle;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 12, left: 20, right: 20),
      child: Column(
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: GlimpseColors.borderColorLight,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const SizedBox(width: 32),
              Expanded(
                child: Column(
                  children: [
                    Text(
                      title,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.getFont(
                        FONT_PLUS_JAKARTA_SANS,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: GlimpseColors.primaryColorLight,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle!,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.getFont(
                          FONT_PLUS_JAKARTA_SANS,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: GlimpseColors.textSecondary,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              GlimpseCloseButton(size: 32, onPressed: onClose),
            ],
          ),
        ],
      ),
    );
  }
}