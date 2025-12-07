import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:partiu/core/constants/glimpse_colors.dart';
import 'package:partiu/core/constants/glimpse_styles.dart';
import 'package:partiu/shared/widgets/glimpse_button.dart';

class ProfileActionsSection extends StatelessWidget {
  const ProfileActionsSection({
    super.key,
    this.onAddFriend,
    this.onMessage,
  });

  final VoidCallback? onAddFriend;
  final VoidCallback? onMessage;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(left: 20, right: 20, bottom: 22),
      child: Row(
        children: [
          Expanded(
            child: GlimpseButton(
              text: 'Adicionar',
              outline: true,
              backgroundColor: GlimpseColors.borderColorLight,
              textColor: GlimpseColors.primaryColorLight,
              icon: Iconsax.profile_2user,
              onTap: onAddFriend ?? () {},
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: GlimpseButton(
              text: 'Mensagem',
              backgroundColor: GlimpseColors.primary,
              textColor: Colors.white,
              icon: Iconsax.message,
              onTap: onMessage ?? () {},
            ),
          ),
        ],
      ),
    );
  }
}
