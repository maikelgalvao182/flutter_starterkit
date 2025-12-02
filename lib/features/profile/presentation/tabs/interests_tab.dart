import 'package:flutter/material.dart';
import 'package:partiu/features/auth/presentation/widgets/signup_widgets.dart';

class InterestsTab extends StatefulWidget {
  const InterestsTab({
    super.key,
    required this.interestsController,
  });

  final TextEditingController interestsController;

  @override
  State<InterestsTab> createState() => _InterestsTabState();
}

class _InterestsTabState extends State<InterestsTab> {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header da seção
        Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.favorite_outline,
                    color: Colors.blue,
                    size: 24,
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Interesses',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Selecione as categorias de atividades que você mais gosta',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
        
        // Widget de seleção de especialidade (interesses)
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: SpecialtySelectorWidget(
            initialSpecialty: widget.interestsController.text,
            onSpecialtyChanged: (value) {
              widget.interestsController.text = value ?? '';
            },
          ),
        ),
        
        const SizedBox(height: 16),
        
        // Preview dos interesses selecionados
        if (widget.interestsController.text.isNotEmpty)
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.blue.withValues(alpha: 0.2)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Interesse selecionado:',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.blue,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.interestsController.text,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}