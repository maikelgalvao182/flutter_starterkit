import 'package:partiu/features/location/presentation/screens/update_location_screen_refactored.dart';
import 'package:flutter/material.dart';

/// Router for update location screen
class UpdateLocationScreenRouter extends StatelessWidget {
  const UpdateLocationScreenRouter({
    super.key,
    this.isSignUpProcess = true,
  });
  
  final bool isSignUpProcess;
  
  @override
  Widget build(BuildContext context) {
    return UpdateLocationScreenRefactored(isSignUpProcess: isSignUpProcess);
  }
}
