// Colors provided via ConversationStyles
import 'package:partiu/core/constants/glimpse_styles.dart';
import 'package:partiu/core/utils/app_localizations.dart';
import 'package:partiu/features/conversations/utils/conversation_styles.dart';
// import 'package:partiu/shared/widgets/sliding_search_icon_button.dart'; // TODO: Implementar
import 'package:flutter/material.dart';

class ConversationsHeader extends StatelessWidget {
  const ConversationsHeader({required this.isDarkMode, super.key});
  final bool isDarkMode;

  @override
  Widget build(BuildContext context) {
    final i18n = AppLocalizations.of(context);
    return Padding(
      padding: ConversationStyles.headerPadding,
      child: Row(
        children: [
          Expanded(
            child: Text(
              i18n.translate('conversations'),
              style: GlimpseStyles.messagesTitleStyle(isDark: isDarkMode),
            ),
          ),
          // TODO: Implementar SlidingSearchIconButton
          // SlidingSearchIconButton(
          //   iconColor: ConversationStyles.searchIconColor(isDarkMode),
          //   iconSize: ConversationStyles.searchIconSize,
          //   placeholder: i18n.translate('search_profiles'),
          //   onQueryChanged: (q) => context.read<ConversationsViewModel>().updateQuery(q),
          // ),
          IconButton(
            icon: Icon(
              Icons.search,
              color: ConversationStyles.searchIconColor(isDarkMode),
              size: ConversationStyles.searchIconSize,
            ),
            onPressed: () {
              // TODO: Implementar busca
              print('TODO: Implementar busca de conversas');
            },
          ),
        ],
      ),
    );
  }
}
