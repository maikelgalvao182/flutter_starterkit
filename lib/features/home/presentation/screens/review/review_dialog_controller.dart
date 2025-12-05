import 'package:dating_app/helpers/app_localizations.dart';
import 'package:dating_app/models/review_stats_model.dart';
import 'package:dating_app/services/review_stats_cache_service.dart';
import 'package:dating_app/services/review_workflow_service.dart';
import 'package:flutter/material.dart';

class ReviewDialogController extends ChangeNotifier {
  final ReviewWorkflowService _workflowService = ReviewWorkflowService();
  final String revieweeId;
  final String revieweeRole;
  
  ReviewDialogController({
    required this.revieweeId,
    required this.revieweeRole,
  }) {
    _loadReviewStats();
  }

  final TextEditingController commentController = TextEditingController();
  final Map<String, int> ratings = {};
  
  bool isLoadingStats = true;
  ReviewStats? reviewStats;
  
  bool isSubmitting = false;
  String? errorMessage;
  int currentStep = 0;

  @override
  void dispose() {
    commentController.dispose();
    super.dispose();
  }

  Future<void> _loadReviewStats() async {
    try {
      final stats = await ReviewStatsCacheService.getReviewStats(revieweeId);
      reviewStats = stats;
    } catch (_) {
      // ignore error
    } finally {
      isLoadingStats = false;
      notifyListeners();
    }
  }

  void setRating(String criterion, int value) {
    ratings[criterion] = value;
    errorMessage = null;
    notifyListeners();
  }

  void nextStep(AppLocalizations i18n) {
    if (ratings.isEmpty) {
      errorMessage = i18n.translate('please_provide_at_least_one_rating');
      notifyListeners();
      return;
    }
    errorMessage = null;
    currentStep = 1;
    notifyListeners();
  }

  Future<bool> submitReview({
    required String announcementId,
    required String applicationId,
    required String pendingReviewId,
    required AppLocalizations i18n,
  }) async {
    final comment = commentController.text.trim().isEmpty 
        ? null 
        : commentController.text.trim();

    isSubmitting = true;
    errorMessage = null;
    notifyListeners();

    try {
      await _workflowService.submitReview(
        announcementId: announcementId,
        applicationId: applicationId,
        revieweeId: revieweeId,
        ratings: ratings,
        pendingReviewId: pendingReviewId,
        comment: comment,
      );
      return true;
    } catch (e) {
      // Re-throw duplicate errors to be handled by UI (Toast)
      final isDuplicate = e.toString().contains('409') || 
          e.toString().toLowerCase().contains('duplicate') ||
          e.toString().toLowerCase().contains('already exists');
      
      if (isDuplicate) {
         rethrow; 
      }

      errorMessage = i18n.translate('failed_to_submit_review');
      isSubmitting = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> dismissReview(String pendingReviewId) async {
    try {
      return await _workflowService.dismissReview(pendingReviewId);
    } catch (e) {
      return false;
    }
  }
  
  List<String> getCriteriaList(AppLocalizations i18n) {
    if (revieweeRole == 'vendor') {
      return [
        i18n.translate('punctuality'),
        i18n.translate('posture_appearance'),
        i18n.translate('communication_sympathy'),
        i18n.translate('briefing_delivery'),
        i18n.translate('teamwork'),
      ];
    } else {
      return [
        i18n.translate('clear_instructions'),
        i18n.translate('payment_on_time'),
        i18n.translate('communication_support'),
      ];
    }
  }
}
