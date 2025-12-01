/// Constantes para mensagens de toasts da aplicação
class ToastMessages {
  
  // === MENSAGENS DE SUCESSO ===
  
  // Profile & User Management
  static const String profileUpdatedSuccessfully = 'Profile updated successfully';
  static const String photoUpdatedSuccessfully = 'Photo updated successfully';
  static const String photoUpdatedSuccessfullySubtitle = 'Your profile photo has been updated';
  static const String experienceUpdatedSuccessfully = 'Experience updated successfully';
  static const String experienceDeactivatedSuccessfully = 'Experience deactivated successfully';
  static const String experiencePublishedSuccessfully = 'Experience published successfully!';
  static const String accountCreatedSuccessfully = 'Your account has been created successfully!';
  static const String locationUpdatedSuccessfully = 'Location updated successfully!';
  
  // Media & Files
  static const String imageUploadedSuccessfully = 'Image uploaded successfully!';
  static const String imageRemovedSuccessfully = 'Image and file removed successfully!';
  static const String videoRemovedSuccessfully = 'Video and files removed successfully!';
  static const String videoUploadedProcessing = 'Video uploaded! Processing...';
  
  // Video Management
  static const String videoDeleted = 'Video Deleted';
  static const String videoUploaded = 'Video Uploaded';
  
  // Image Management  
  static const String imageDeleted = 'Image Deleted';
  static const String imageAdded = 'Image Added';
  static const String imageAddedToGallery = 'Image added to event gallery!';
  static const String imageRemovedFromSelection = 'Image removed from selection!';
  static const String uploadLimit = 'Upload Limit';
  static const String selectionFailed = 'Selection Failed';
  static const String locationError = 'Location Error';
  
  // Proposal Management
  static const String proposalSent = 'Proposal Sent';
  
  // Applications & Weddings
  static const String applicationSubmittedSuccessfully = 'Application submitted successfully!';
  static const String applicationRemoved = 'Application Removed';
  static const String applicationRemovedSuccessfully = 'Application successfully removed';
  static const String noApplicationsFound = 'No Applications Found';
  static const String noApplicationsFoundMessage = 'There are no applications associated with this vendor for your announcements';
  static const String weddingAnnouncementCreatedSuccessfully = 'Wedding announcement created successfully!';
  static const String weddingAnnouncementPublishedSuccessfully = 'Wedding announcement published successfully';
  static const String weddingAnnouncementMarkedAsInactive = 'Wedding announcement marked as inactive';
  static const String publishFailed = 'Failed to publish';
  static const String unpublishFailed = 'Failed to unpublish';
  static const String statusUpdated = 'Status updated';
  
  // Chat & Conversations
  static const String conversationDeleted = 'Conversation Deleted';
  static const String conversationDeletedSuccessfully = 'Conversation successfully deleted';
  
  // Payments & Subscriptions
  static const String signatureCompleted = 'signature_completed';
  static const String vipSubscriptionRestored = 'vip_subscription_restored';
  static const String paymentConfirmedChatUnlocked = 'payment_confirmed_chat_unlocked';
  static const String paymentConfirmedDrawerClosing = 'payment_confirmed_drawer_closing';
  static const String paymentCancelled = 'payment_cancelled';
  static const String paymentCancelledByUser = 'payment_cancelled_by_user';
  static const String paymentVerificationFailed = 'payment_verification_failed';
  static const String accountDeletedSuccessfully = 'Conta removida com sucesso';
  static const String accountDeletionErrorPrefix = 'Erro ao excluir conta';
  
  // Moderation & Safety
  static const String userBlocked = 'User blocked';
  static const String userAlreadyBlocked = 'You have already blocked this user';
  static const String userUnblocked = 'User unblocked';
  static const String nothingToUnblock = 'Nothing to unblock';
  static const String profileReportedThanks = 'Thank you! The profile will be reviewed';
  
  // Reviews
  static const String reviewSubmitted = 'Review Submitted';
  static const String reviewSubmittedSuccessfully = 'Your review has been submitted successfully!';
  static const String reviewAlreadySubmitted = 'Review Already Submitted';
  static const String reviewAlreadySubmittedMessage = 'You have already submitted a review for this event.';
  
  // Email & Clipboard
  static const String emailCopiedToClipboard = 'Email copied to clipboard';
  
  // Field Saving
  static const String saved = 'Saved';
  static const String fieldSavedLocally = 'Field saved locally';
  static const String changesSaved = 'Changes saved successfully';
  
  // Password Recovery
  static const String passwordResetLinkSent = 'Password reset link has been sent to your email';
  static const String passwordResetSuccess = 'Password Reset';
  
  // Fixes & Operations
  static const String fixCompleted = 'Fix completed';
  
  
  // === MENSAGENS DE DIÁLOGOS CONVERTIDAS ===
  
  // Success Messages
  static const String success = 'Success';
  static const String operationCompletedSuccessfully = 'Operation completed successfully';
  
  // Info Messages  
  static const String information = 'Information';
  static const String operationCompleted = 'Operation completed';
  
  // Confirmation Messages
  static const String confirmed = 'Confirmed';
  static const String actionConfirmed = 'Action confirmed successfully';
  
  
  // === MENSAGENS DE ERRO ===
  
  // Generic Errors
  static const String error = 'Error';
  static const String anErrorOccurred = 'An error occurred';
  static const String anErrorHasOccurred = 'An error has occurred';
  static const String somethingWentWrong = 'Something went wrong';
  
  // Profile & User Errors
  static const String userProfileNotFound = 'User profile not found';
  static const String userNotFound = 'User not found';
  static const String errorLoadingUserProfile = 'Error loading user profile';
  static const String userNotLoggedIn = 'User not logged in';
  static const String locationNotAvailable = 'Location not available';
  
  // Update & Status Errors
  static const String updateFailed = 'Update failed';
  static const String failedToLoad = 'Failed to load';
  static const String failedToSubmitApplication = 'Failed to submit application. You may have already applied.';
  
  // Media & Upload Errors
  static const String uploadFailed = 'Upload failed';
  static const String failedToRemove = 'Failed to remove';
  static const String fixFailed = 'Fix failed';
  
  // Video Management Errors
  static const String deleteFailed = 'Delete Failed';
  static const String videoUploadFailed = 'Upload Failed';
  
  // Payment & Subscription Errors
  static const String purchaseFailed = 'purchase_failed';
  static const String paymentError = 'payment_error';
  static const String insufficientDataForPayment = 'insufficient_data_for_payment';
  
  // Navigation & Loading Errors
  static const String failedToLoadAnnouncement = 'Failed to load announcement';
  static const String failedToLoadProfile = 'Failed to load profile';
  static const String errorLoadingUser = 'Error loading user';
  
  // Permission & Access Errors
  static const String locationPermissionsDenied = 'Location permissions are denied';
  static const String gpsDisabled = 'We were unable to get your current location. Please enable GPS to continue';
  
  // Authentication & Sign-In Errors
  static const String signInCanceled = 'Sign-in canceled';
  static const String signInCanceledMessage = 'You have canceled the sign-in process.';
  static const String authenticationFailed = 'Authentication failed';
  static const String signInWithGoogleFailed = 'Sign-in with Google failed';
  static const String signInWithAppleFailed = 'Sign-in with Apple failed';
  static const String appleSignInNotAvailable = 'Apple Sign-In is not available on this device';
  
  // Dialog Error Messages
  static const String operationFailed = 'Operation failed';
  static const String actionCanceled = 'Action canceled';
  static const String confirmationRequired = 'Confirmation required';
  
  
  // === MÉTODOS UTILITÁRIOS ===
  
  /// Retorna mensagem de erro genérica com detalhes
  static String getGenericErrorWithDetails(String details) {
    return '$anErrorOccurred. $details';
  }
  
  /// Retorna mensagem de falha com detalhes do erro
  static String getFailedWithDetails(String operation, String error) {
    return 'Falha ao $operation: $error';
  }
  
  /// Retorna mensagem de erro de carregamento com detalhes
  static String getLoadingErrorWithDetails(String resource, String error) {
    return 'Erro ao carregar $resource: $error';
  }
  
  /// Retorna mensagem de sucesso com dados específicos
  static String getSuccessWithData(String operation, String data) {
    return '$operation: $data';
  }
}
