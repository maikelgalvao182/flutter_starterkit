import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:partiu/core/constants/glimpse_colors.dart';

class GlimpseLoadingScreen extends StatelessWidget {
  const GlimpseLoadingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: const Center(
        child: CupertinoActivityIndicator(
          radius: 16,
          color: GlimpseColors.primaryColorLight,
        ),
      ),
    );
  }
}
