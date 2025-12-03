import 'package:partiu/shared/widgets/my_circular_progress.dart';
import 'package:flutter/material.dart';

/// Fullscreen white overlay showing a centered spinner and a single line text.
/// Use inside a Stack (it expands) or directly as a route body.
class Processing extends StatelessWidget {
  const Processing({super.key, this.text});
  final String? text;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      width: double.infinity,
      height: double.infinity,
      alignment: Alignment.center,
      child: const MyCircularProgress(),
    );
  }
}
