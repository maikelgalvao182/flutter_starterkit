import 'package:partiu/core/utils/app_localizations.dart';
import 'package:partiu/shared/models/user_model.dart';
import 'package:partiu/shared/widgets/glimpse_text_field.dart';
import 'package:firebase_auth/firebase_auth.dart' as fire_auth;
import 'package:flutter/material.dart';

/// Widget de informações pessoais (nome completo)
/// Extraído de TelaInformacoesPessoais para reutilização no wizard
class PersonalInfoWidget extends StatefulWidget {
  const PersonalInfoWidget({
    required this.initialName,
    required this.onNameChanged,
    super.key,
  });

  final String initialName;
  final ValueChanged<String> onNameChanged;

  @override
  State<PersonalInfoWidget> createState() => _PersonalInfoWidgetState();
}

class _PersonalInfoWidgetState extends State<PersonalInfoWidget> {
  late AppLocalizations _i18n;
  late TextEditingController _nameController;
  bool _hasInitialized = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    
    // Inicialização após primeiro frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_hasInitialized) {
        _hasInitialized = true;
        _initializeName();
      }
    });
  }

  void _initializeName() async {
    // Se o initialName já veio preenchido (do SignupWizard), usa ele
    if (widget.initialName.isNotEmpty) {
      _nameController.text = widget.initialName;
      return;
    }
    
    // Caso contrário, busca do OAuth (fallback para compatibilidade)
    final oauthName = await UserModel(userId: "temp").getOAuthDisplayName();

    // Fallback: tenta também o displayName do Firebase
    var prefillName = (oauthName ?? '').trim();
    if (prefillName.isEmpty) {
      final fbName = fire_auth.FirebaseAuth.instance.currentUser?.displayName;
      if (fbName != null && fbName.trim().isNotEmpty) {
        prefillName = fbName.trim();
      }
    }

    if (prefillName.isNotEmpty) {
      _nameController.text = prefillName;
      widget.onNameChanged(prefillName);
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _i18n = AppLocalizations.of(context);
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Campo Nome Completo
        GlimpseTextField(
          labelText: _i18n.translate('full_name'),
          hintText: _i18n.translate('enter_your_full_name'),
          controller: _nameController,
          textCapitalization: TextCapitalization.words,
          onChanged: widget.onNameChanged,
        ),
      ],
    );
  }
}
