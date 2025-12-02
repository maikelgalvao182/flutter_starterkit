import 'package:partiu/core/utils/app_localizations.dart';
import 'package:flutter/material.dart';

/// Helper para converter constantes de ToastMessages em strings traduzidas
/// Substitui o uso direto de ToastMessages por traduções i18n
class ToastMessagesHelper {

  ToastMessagesHelper(this.context) {
    _i18n = AppLocalizations.of(context);
  }
  final BuildContext context;
  late final AppLocalizations _i18n;

  // === MENSAGENS DE SUCESSO ===
  
  String get profileUpdatedSuccessfully => _i18n.translate('profile_updated_successfully');
  String get experienceUpdatedSuccessfully => _i18n.translate('experience_updated_successfully');
  String get experienceDeactivatedSuccessfully => _i18n.translate('experience_deactivated_successfully');
  String get experiencePublishedSuccessfully => _i18n.translate('experience_published_successfully');
  String get accountCreatedSuccessfully => _i18n.translate('account_created_successfully');
  String get locationUpdatedSuccessfully => _i18n.translate('location_updated_successfully');
  
  String get imageUploadedSuccessfully => _i18n.translate('image_uploaded_successfully');
  String get imageRemovedSuccessfully => _i18n.translate('image_removed_successfully');
  String get videoRemovedSuccessfully => _i18n.translate('video_removed_successfully');
  String get videoUploadedProcessing => _i18n.translate('video_uploaded_processing');
  
  String get videoDeleted => _i18n.translate('video_deleted');
  String get videoUploaded => _i18n.translate('video_uploaded');
  String get imageDeleted => _i18n.translate('image_deleted');
  String get imageAdded => _i18n.translate('image_added');
  String get imageAddedToGallery => _i18n.translate('image_added_to_gallery');
  String get imageRemovedFromSelection => _i18n.translate('image_removed_from_selection');
  String get uploadLimit => _i18n.translate('upload_limit');
  String get selectionFailed => _i18n.translate('selection_failed');
  String get locationError => _i18n.translate('location_error');
  
  String get proposalSent => _i18n.translate('proposal_sent');
  
  String get applicationSubmittedSuccessfully => _i18n.translate('application_submitted_successfully');
  String get applicationRemoved => _i18n.translate('application_removed');
  String get applicationRemovedSuccessfully => _i18n.translate('application_removed_successfully');
  String get noApplicationsFound => _i18n.translate('no_applications_found');
  String get noApplicationsFoundMessage => _i18n.translate('no_applications_found_message');
  String get weddingAnnouncementCreatedSuccessfully => _i18n.translate('wedding_announcement_created_successfully');
  String get weddingAnnouncementPublishedSuccessfully => _i18n.translate('wedding_announcement_published_successfully');
  String get weddingAnnouncementMarkedAsInactive => _i18n.translate('wedding_announcement_marked_as_inactive');
  String get publishFailed => _i18n.translate('publish_failed');
  String get unpublishFailed => _i18n.translate('unpublish_failed');
  String get statusUpdated => _i18n.translate('status_updated');
  
  String get conversationDeleted => _i18n.translate('conversation_deleted');
  String get conversationDeletedSuccessfully => _i18n.translate('conversation_deleted_successfully');
  
  String get signatureCompleted => _i18n.translate('signature_completed');
  String get vipSubscriptionRestored => _i18n.translate('vip_subscription_restored');
  String get paymentConfirmedChatUnlocked => _i18n.translate('payment_confirmed_chat_unlocked');
  String get paymentConfirmedDrawerClosing => _i18n.translate('payment_confirmed_drawer_closing');
  String get paymentCancelled => _i18n.translate('payment_cancelled');
  String get paymentCancelledByUser => _i18n.translate('payment_cancelled_by_user');
  String get paymentVerificationFailed => _i18n.translate('payment_verification_failed');
  String get accountDeletedSuccessfully => _i18n.translate('account_deleted_successfully');
  String get accountDeletionErrorPrefix => _i18n.translate('account_deletion_error_prefix');
  
  String get userBlocked => _i18n.translate('user_blocked');
  String get userAlreadyBlocked => _i18n.translate('user_already_blocked');
  String get userUnblocked => _i18n.translate('user_unblocked');
  String get nothingToUnblock => _i18n.translate('nothing_to_unblock');
  String get profileReportedThanks => _i18n.translate('profile_reported_thanks');
  
  String get reviewSubmitted => _i18n.translate('review_submitted');
  String get reviewSubmittedSuccessfully => _i18n.translate('review_submitted_successfully');
  String get reviewAlreadySubmitted => _i18n.translate('review_already_submitted');
  String get reviewAlreadySubmittedMessage => _i18n.translate('review_already_submitted_message');
  
  String get emailCopiedToClipboard => _i18n.translate('email_copied_to_clipboard');
  String get fixCompleted => _i18n.translate('fix_completed');
  
  // === MENSAGENS DE DIÁLOGOS ===
  
  String get success => _i18n.translate('success');
  String get operationCompletedSuccessfully => _i18n.translate('operation_completed_successfully');
  String get information => _i18n.translate('information');
  String get operationCompleted => _i18n.translate('operation_completed');
  String get confirmed => _i18n.translate('confirmed');
  String get actionConfirmed => _i18n.translate('action_confirmed');
  
  // === MENSAGENS DE ERRO ===
  
  String get error => _i18n.translate('error');
  String get anErrorOccurred => _i18n.translate('an_error_occurred');
  String get anErrorHasOccurred => _i18n.translate('an_error_has_occurred');
  String get somethingWentWrong => _i18n.translate('something_went_wrong');
  
  String get userProfileNotFound => _i18n.translate('user_profile_not_found');
  String get userNotFound => _i18n.translate('user_not_found');
  String get errorLoadingUserProfile => _i18n.translate('error_loading_user_profile');
  String get userNotLoggedIn => _i18n.translate('user_not_logged_in');
  String get locationNotAvailable => _i18n.translate('location_not_available');
  
  String get updateFailed => _i18n.translate('update_failed');
  String get failedToLoad => _i18n.translate('failed_to_load');
  String get failedToSubmitApplication => _i18n.translate('failed_to_submit_application');
  
  String get uploadFailed => _i18n.translate('upload_failed');
  String get failedToRemove => _i18n.translate('failed_to_remove');
  String get fixFailed => _i18n.translate('fix_failed');
  String get deleteFailed => _i18n.translate('delete_failed');
  String get videoUploadFailed => _i18n.translate('video_upload_failed');
  
  String get purchaseFailed => _i18n.translate('purchase_failed');
  String get paymentError => _i18n.translate('payment_error');
  String get insufficientDataForPayment => _i18n.translate('insufficient_data_for_payment');
  
  String get failedToLoadAnnouncement => _i18n.translate('failed_to_load_announcement');
  String get failedToLoadProfile => _i18n.translate('failed_to_load_profile');
  String get errorLoadingUser => _i18n.translate('error_loading_user');
  
  String get locationPermissionsDenied => _i18n.translate('location_permissions_denied');
  String get gpsDisabled => _i18n.translate('gps_disabled');
  
  String get signInCanceled => _i18n.translate('sign_in_canceled');
  String get signInCanceledMessage => _i18n.translate('sign_in_canceled_message');
  String get authenticationFailed => _i18n.translate('authentication_failed');
  String get signInWithGoogleFailed => _i18n.translate('sign_in_with_google_failed');
  String get signInWithAppleFailed => _i18n.translate('sign_in_with_apple_failed');
  String get appleSignInNotAvailable => _i18n.translate('apple_sign_in_not_available');
  
  String get operationFailed => _i18n.translate('operation_failed');
  String get actionCanceled => _i18n.translate('action_canceled');
  String get confirmationRequired => _i18n.translate('confirmation_required');
}
