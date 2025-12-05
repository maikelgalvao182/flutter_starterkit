import 'package:dating_app/dialogs/review_dialog_controller.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:dating_app/constants/constants.dart';

class ErrorMessageBox extends StatelessWidget {
  const ErrorMessageBox({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<ReviewDialogController>();
    final errorMessage = controller.errorMessage;

    if (errorMessage == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.red[200]!),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: Colors.red[700], size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              errorMessage,
              style: GoogleFonts.getFont(FONT_PLUS_JAKARTA_SANS, 
                fontSize: 13,
                color: Colors.red[700],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
