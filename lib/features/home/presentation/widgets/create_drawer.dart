import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:partiu/core/constants/constants.dart';
import 'package:partiu/core/constants/glimpse_colors.dart';
import 'package:partiu/features/home/presentation/screens/location_picker/location_picker_page_refactored.dart';
import 'package:partiu/plugins/locationpicker/entities/location_result.dart';
import 'package:partiu/shared/widgets/glimpse_button.dart';
import 'package:partiu/shared/widgets/glimpse_close_button.dart';

/// Bottom sheet para criar nova atividade
class CreateDrawer extends StatefulWidget {
  const CreateDrawer({super.key});

  @override
  State<CreateDrawer> createState() => _CreateDrawerState();
}

class _CreateDrawerState extends State<CreateDrawer> {
  final TextEditingController _activityController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _activityController.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    _activityController.removeListener(_onTextChanged);
    _activityController.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    setState(() {});
  }

  void _handleCreate() async {
    if (_activityController.text.trim().isEmpty) return;

    // Salvar dados necessários
    final activityText = _activityController.text;
    final navigator = Navigator.of(context);
    
    // Fechar teclado
    FocusScope.of(context).unfocus();
    
    // Fechar o drawer imediatamente
    navigator.pop();

    // Navegar para o LocationPicker
    try {
      final LocationResult? locationResult = await navigator.push<LocationResult>(
        MaterialPageRoute(
          builder: (_) => const LocationPickerPageRefactored(),
          fullscreenDialog: true,
        ),
      );

      if (locationResult != null && locationResult.latLng != null) {
        debugPrint('Atividade: $activityText');
        debugPrint('Local: ${locationResult.formattedAddress}');
        // TODO: Continuar fluxo de criação
      }
    } catch (e) {
      debugPrint('Erro na navegação: \$e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Container(
          color: Colors.white,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle e botão de fechar
              Padding(
                padding: const EdgeInsets.only(
                  top: 12,
                  left: 20,
                  right: 20,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Handle centralizado (spacer para ocupar espaço)
                    const SizedBox(width: 32),
                    
                    // Handle no centro
                    Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: GlimpseColors.borderColorLight,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    
                    // Botão de fechar
                    const GlimpseCloseButton(
                      size: 32,
                    ),
                  ],
                ),
              ),

              // Container com emoji
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: GlimpseColors.lightTextField,
                  borderRadius: BorderRadius.circular(40),
                ),
                child: const Center(
                  child: Text(
                    '🎉',
                    style: TextStyle(fontSize: 40),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Título
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Partiu...',
                      style: GoogleFonts.getFont(
                        FONT_PLUS_JAKARTA_SANS,
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: GlimpseColors.textSubTitle,
                      ),
                    ),
                    Text(
                      'Sugestão?',
                      style: GoogleFonts.getFont(
                        FONT_PLUS_JAKARTA_SANS,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: GlimpseColors.primary,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Text Field
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: TextField(
                    controller: _activityController,
                    autofocus: true,
                    maxLines: 1,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: InputDecoration(
                      hintText: 'Correr no parque, tomar um chop...',
                      hintStyle: GoogleFonts.getFont(
                        FONT_PLUS_JAKARTA_SANS,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: GlimpseColors.textHint,
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    style: GoogleFonts.getFont(
                      FONT_PLUS_JAKARTA_SANS,
                      fontSize: 16,
                      fontWeight: FontWeight.w400,
                      color: GlimpseColors.textSubTitle,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 8),

              // Botão de criar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: GlimpseButton(
                  text: 'Continuar',
                  onPressed: _activityController.text.trim().isNotEmpty
                      ? _handleCreate
                      : null,
                ),
              ),

              // Padding bottom para safe area
              SizedBox(height: MediaQuery.of(context).padding.bottom + 16),
            ],
          ),
        ),
      ),
    );
  }
}
