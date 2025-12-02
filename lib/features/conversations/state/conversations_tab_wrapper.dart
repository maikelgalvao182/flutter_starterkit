import 'package:partiu/features/conversations/state/conversations_viewmodel.dart';
import 'package:partiu/features/conversations/ui/conversations_tab.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// Wrapper widget that provides ConversationsViewModel to the ConversationsTab
/// This allows the main tab to be more focused on UI presentation
class ConversationsTabWrapper extends StatefulWidget {
  const ConversationsTabWrapper({super.key});

  @override
  State<ConversationsTabWrapper> createState() => _ConversationsTabWrapperState();
}

class _ConversationsTabWrapperState extends State<ConversationsTabWrapper> 
    with AutomaticKeepAliveClientMixin {
  
  // Mantém o ViewModel vivo enquanto o wrapper existir
  late final ConversationsViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = ConversationsViewModel();
  }

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }
  
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return ChangeNotifierProvider.value(
      value: _viewModel,
      child: const ConversationsTab(),
    );
  }
}
