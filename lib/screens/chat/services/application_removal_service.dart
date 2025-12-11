import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:partiu/common/state/app_state.dart';
import 'package:partiu/core/constants/toast_messages.dart';
import 'package:partiu/dialogs/common_dialogs.dart';
import 'package:partiu/dialogs/progress_dialog.dart';
import 'package:partiu/core/utils/app_localizations.dart';import 'package:partiu/core/services/toast_service.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:partiu/core/constants/constants.dart';

// Helper model for selecting which application to remove
class ApplicationCandidate {
  
  ApplicationCandidate({
    required this.announcementId,
    required this.announcementName,
    required this.categoryId,
    required this.categoryName,
    required this.vendorId,
  });
  final String announcementId;
  final String announcementName;
  final String categoryId;
  final String categoryName;
  final String vendorId;
}

class ApplicationRemovalService {
  factory ApplicationRemovalService() => _instance;
  ApplicationRemovalService._internal();
  // B1.1: Singleton pattern para evitar múltiplas instâncias
  static final ApplicationRemovalService _instance = ApplicationRemovalService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Fetch all applications for a vendor from bride's announcements
  /// OR fetch vendor's own applications if vendor is looking to cancel
  Future<List<ApplicationCandidate>> _getCandidateApplications(String vendorId) async {
  final currentUserId = AppState.currentUserId ?? '';
    final candidates = <ApplicationCandidate>[];


    // Determine who is doing the removal:
    // - If current user is BRIDE → remove vendor's application from bride's announcements
    // - If current user is VENDOR → remove vendor's own applications (vendorId should be currentUserId)
    
    // TODO: Implementar lógica de detecção de papel (bride/vendor) quando disponível
    // Por enquanto, assumir que é bride se currentUserId != vendorId
    final isBride = currentUserId != vendorId;
    
    // Fetch announcements
    QuerySnapshot<Map<String, dynamic>>? annsSnap;
    
    try {
      if (isBride) {
        // Bride: get HER announcements
        annsSnap = await _firestore
            .collection('WeddingAnnouncements')
            .where('brideId', isEqualTo: currentUserId)
            .get();
        
        if (annsSnap.docs.isEmpty) {
          annsSnap = await _firestore
              .collection('WeddingAnnouncements')
              .where('bride_id', isEqualTo: currentUserId)
              .get();
        }
      } else {
        // Vendor: get ALL announcements where THIS vendor applied
        // We need to fetch all announcements and filter by vendorId in applications
        annsSnap = await _firestore
            .collection('WeddingAnnouncements')
            .where('applications', isNotEqualTo: null)
            .get();
      }
    } catch (e) {
      return candidates;
    }
    
    // Debug: Show all announcement IDs and bride IDs
    for (final doc in annsSnap.docs) {
      final data = doc.data();
      
      // Show ALL vendors in this announcement
      final apps = data['applications'] as Map<String, dynamic>?;
      if (apps != null) {
        apps.forEach((categoryId, categoryApps) {
          if (categoryApps is List) {
            for (final app in categoryApps) {
              if (app is Map<String, dynamic>) {
              }
            }
          }
        });
      }
    }

    // Collect candidate applications that match this vendor
    for (final doc in annsSnap.docs) {
      final data = doc.data();
      final annId = doc.id;
      final annName = (data['eventName'] ?? data['event_name'] ?? '') as String;


      final apps = data['applications'] as Map<String, dynamic>?;
      if (apps == null) {
        continue;
      }

      final briefs = data['categoryBriefs'] as Map<String, dynamic>? ?? {};
      for (final entry in apps.entries) {
        final categoryId = entry.key;
        final list = entry.value as List<dynamic>? ?? const [];
        
        
        for (final raw in list) {
          if (raw is Map<String, dynamic>) {
            final appVendorId = raw['vendorId'];
            
            
            if (appVendorId == vendorId) {
              final vendorIdFromData = raw['vendorId'] as String; // safe cast inside condition
              final categoryName = (briefs[categoryId] is Map<String, dynamic>)
                  ? (briefs[categoryId]['categoryName'] ?? '') as String
                  : '';
              
              
              candidates.add(
                ApplicationCandidate(
                  announcementId: annId,
                  announcementName: annName,
                  categoryId: categoryId,
                  categoryName: categoryName,
                  vendorId: vendorIdFromData,
                ),
              );
            }
          }
        }
      }
    }

    return candidates;
  }

  /// Reject a specific application candidate
  Future<bool> _rejectCandidate(ApplicationCandidate candidate) async {
    try {
      // TODO: Implement application rejection logic when vendor_applications_api is available
      // For now, just update the Firestore document directly
      await _firestore
          .collection('WeddingAnnouncements')
          .doc(candidate.announcementId)
          .update({
        'applications.${candidate.categoryId}': FieldValue.arrayRemove([
          {'vendorId': candidate.vendorId}
        ])
      });
      
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Show confirmation dialog for rejecting a candidate
  Future<void> _showRejectConfirmation({
    required BuildContext context,
    required ApplicationCandidate candidate,
    required AppLocalizations i18n,
    required ProgressDialog progressDialog,
    required VoidCallback onSuccess,
  }) async {
    confirmDialog(
      context,
      title: i18n.translate('remove_application'),
      message: i18n.translate('reject_application_message')
          .replaceAll('{announcement}', candidate.announcementName.isNotEmpty ? candidate.announcementName : candidate.announcementId)
          .replaceAll('{category}', candidate.categoryName.isNotEmpty ? candidate.categoryName : candidate.categoryId),
      positiveText: i18n.translate('CONFIRM'),
      negativeAction: () => Navigator.of(context).pop(),
      positiveAction: () async {
        Navigator.of(context).pop();
        progressDialog.show(i18n.translate('processing'));
        
        final success = await _rejectCandidate(candidate);
        await progressDialog.hide();
        
    if (success) {
          ToastService.showSuccess(
        message: i18n.translate('application_removed_subtitle',
      )
        .replaceAll('{announcement}', candidate.announcementName.isNotEmpty ? candidate.announcementName : candidate.announcementId),
          );
          onSuccess();
        } else {
          ToastService.showError(
        message: i18n.translate('an_error_has_occurred',
      ),
          );
        }
      },
    );
  }

  /// Show application selection bottom sheet
  Future<void> _showApplicationSelectionSheet({
    required BuildContext context,
    required List<ApplicationCandidate> candidates,
    required AppLocalizations i18n,
    required ProgressDialog progressDialog,
    required VoidCallback onSuccess,
  }) async {
    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Text(
                i18n.translate('select_application_to_remove'),
                style: GoogleFonts.getFont(FONT_PLUS_JAKARTA_SANS, fontSize: 16, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              ...candidates.map((candidate) => ListTile(
                    leading: const Icon(Icons.highlight_off, color: Colors.redAccent),
                    title: Text(candidate.announcementName.isNotEmpty ? candidate.announcementName : candidate.announcementId),
                    subtitle: Text(candidate.categoryName.isNotEmpty ? candidate.categoryName : candidate.categoryId),
                    onTap: () async {
                      Navigator.of(ctx).pop();
                      await _showRejectConfirmation(
                        context: context,
                        candidate: candidate,
                        i18n: i18n,
                        progressDialog: progressDialog,
                        onSuccess: onSuccess,
                      );
                    },
                  )),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  /// Main method to handle application removal process
  Future<void> handleRemoveApplication({
    required BuildContext context,
    required String vendorId,
    required AppLocalizations i18n,
    required ProgressDialog progressDialog,
    required VoidCallback onSuccess,
  }) async {
    
    try {
      // Show processing
      progressDialog.show(i18n.translate('processing'));

      
      // Get candidate applications
      final candidates = await _getCandidateApplications(vendorId);


      // Hide processing before showing UI
      await progressDialog.hide();

      if (candidates.isEmpty) {
        
        ToastService.showError(
          message: ToastMessages.noApplicationsFoundMessage,
        );
        return;
      }

      if (candidates.length == 1) {
        
        // Single candidate - show confirmation directly
        await _showRejectConfirmation(
          context: context,
          candidate: candidates.first,
          i18n: i18n,
          progressDialog: progressDialog,
          onSuccess: onSuccess,
        );
        return;
      }


      // Multiple candidates - show selection sheet
      await _showApplicationSelectionSheet(
        context: context,
        candidates: candidates,
        i18n: i18n,
        progressDialog: progressDialog,
        onSuccess: onSuccess,
      );
    } catch (e) {
      
      await progressDialog.hide();
      ToastService.showError(
        message: i18n.translate('an_error_has_occurred',
      ),
      );
    }
  }
}
