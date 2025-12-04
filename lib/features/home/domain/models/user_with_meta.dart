import 'package:partiu/shared/models/user_model.dart';

class UserWithMeta {
  final UserModel user;
  final double? distanceKm;
  final List<String> commonInterests;

  UserWithMeta({
    required this.user,
    required this.distanceKm,
    required this.commonInterests,
  });
}
