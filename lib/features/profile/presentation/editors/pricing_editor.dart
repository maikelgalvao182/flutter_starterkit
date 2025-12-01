import 'package:flutter/material.dart';

/// Placeholder for PricingEditor
/// TODO: Implement pricing editor
class PricingEditor extends StatelessWidget {
  final TextEditingController startingPriceController;
  final TextEditingController averagePriceController;
  
  const PricingEditor({
    super.key,
    required this.startingPriceController,
    required this.averagePriceController,
  });
  
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TextField(
          controller: startingPriceController,
          decoration: const InputDecoration(
            labelText: 'Preço Inicial',
            hintText: '\$0.00',
          ),
          keyboardType: TextInputType.number,
        ),
        const SizedBox(height: 16),
        TextField(
          controller: averagePriceController,
          decoration: const InputDecoration(
            labelText: 'Preço Médio',
            hintText: '\$0.00',
          ),
          keyboardType: TextInputType.number,
        ),
      ],
    );
  }
}
