import 'package:flutter/material.dart';
import 'package:partiu/core/models/user.dart';
import 'package:partiu/core/utils/app_localizations.dart';
import 'package:partiu/features/profile/presentation/controllers/profile_controller.dart';
import 'package:partiu/features/profile/presentation/components/profile_header.dart';
import 'package:partiu/features/profile/presentation/widgets/about_me_section.dart';
import 'package:partiu/features/profile/presentation/widgets/basic_information_profile_section.dart';
import 'package:partiu/features/profile/presentation/widgets/interests_profile_section.dart';
import 'package:partiu/features/profile/presentation/widgets/languages_profile_section.dart';
import 'package:partiu/features/profile/presentation/widgets/gallery_profile_section.dart';
import 'package:partiu/features/profile/presentation/widgets/review_card.dart';
import 'package:partiu/features/profile/presentation/widgets/reviews_header.dart';
import 'package:partiu/shared/stores/user_store.dart';

/// Builder de conteúdo do perfil seguindo padrão do dating app
/// 
/// Organiza todas as seções do perfil de forma modular
class ProfileContentBuilder {
  const ProfileContentBuilder({
    required this.controller,
    required this.displayUser,
    required this.myProfile,
    required this.i18n,
    required this.currentUserId,
  });

  final ProfileController controller;
  final User displayUser;
  final bool myProfile;
  final AppLocalizations i18n;
  final String currentUserId;

  Widget build() {
    return Column(
      children: [
        // HEADER com foto, nome, idade
        RepaintBoundary(
          child: ProfileHeader(
            key: ValueKey('${displayUser.userId}_${displayUser.userProfilePhoto}'),
            user: displayUser,
            isMyProfile: myProfile,
            i18n: i18n,
          ),
        ),
        
        const SizedBox(height: 24),
        
        // SECTIONS
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildAboutMe(),
            _buildBasicInfo(),
            _buildInterests(),
            _buildLanguages(),
            _buildGallery(),
            _buildReviews(),
          ],
        ),
        
        const SizedBox(height: 40),
      ],
    );
  }

  Widget _buildAboutMe() {
    return ValueListenableBuilder<String?>(
      valueListenable: UserStore.instance.getBioNotifier(displayUser.userId),
      builder: (context, bio, _) {
        if (bio == null || bio.trim().isEmpty) return const SizedBox();
        return RepaintBoundary(
          child: AboutMeSection(userId: displayUser.userId),
        );
      },
    );
  }

  Widget _buildBasicInfo() {
    return RepaintBoundary(
      child: BasicInformationProfileSection(userId: displayUser.userId),
    );
  }

  Widget _buildInterests() {
    return ValueListenableBuilder<List<String>?>(
      valueListenable: UserStore.instance.getInterestsNotifier(displayUser.userId),
      builder: (context, interests, _) {
        if (interests == null || interests.isEmpty) return const SizedBox();
        return RepaintBoundary(
          child: InterestsProfileSection(userId: displayUser.userId),
        );
      },
    );
  }

  Widget _buildLanguages() {
    return ValueListenableBuilder<String?>(
      valueListenable: UserStore.instance.getLanguagesNotifier(displayUser.userId),
      builder: (context, languages, _) {
        if (languages == null || languages.trim().isEmpty) return const SizedBox();
        return RepaintBoundary(
          child: LanguagesProfileSection(userId: displayUser.userId),
        );
      },
    );
  }

  Widget _buildGallery() {
    // Galeria não precisa de ValueListenableBuilder pois usa dados diretos do User
    if (displayUser.userGallery == null || displayUser.userGallery!.isEmpty) {
      return const SizedBox.shrink();
    }
    return RepaintBoundary(
      child: GalleryProfileSection(galleryMap: displayUser.userGallery),
    );
  }

  Widget _buildReviews() {
    return ValueListenableBuilder(
      valueListenable: controller.reviewStats,
      builder: (context, stats, _) {
        if (stats == null || stats.isEmpty) {
          return const SizedBox.shrink();
        }

        return RepaintBoundary(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header com estatísticas
                ReviewsHeader(stats: stats),
                
                const SizedBox(height: 16),
                
                // Lista de reviews
                ValueListenableBuilder(
                  valueListenable: controller.reviews,
                  builder: (context, reviews, _) {
                    if (reviews.isEmpty) {
                      return const SizedBox.shrink();
                    }

                    return Column(
                      children: reviews.take(5).map((review) {
                        return ReviewCard(review: review);
                      }).toList(),
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
