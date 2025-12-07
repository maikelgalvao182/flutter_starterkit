import 'package:flutter/material.dart';
import 'package:partiu/core/constants/glimpse_colors.dart';
import 'package:partiu/features/reviews/presentation/dialogs/review_dialog_controller.dart';

/// Barra de progresso do ReviewDialog
class ReviewDialogProgressBar extends StatelessWidget {
  final ReviewDialogController controller;

  const ReviewDialogProgressBar({
    required this.controller,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 4,
      margin: const EdgeInsets.symmetric(horizontal: 20),
      child: LinearProgressIndicator(
        value: controller.progress,
        backgroundColor: Colors.grey.shade200,
        valueColor: AlwaysStoppedAnimation(GlimpseColors.primary),
      ),
    );
  }
}
