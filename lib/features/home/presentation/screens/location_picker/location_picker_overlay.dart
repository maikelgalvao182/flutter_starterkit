import 'package:flutter/material.dart';
import 'package:partiu/plugins/locationpicker/place_picker.dart';

/// Overlay para exibir sugestões de autocomplete
class LocationPickerOverlay extends StatelessWidget {
  const LocationPickerOverlay({
    super.key,
    required this.suggestions,
    required this.top,
    required this.width,
  });

  final List<RichSuggestion> suggestions;
  final double top;
  final double width;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: top,
      width: width,
      child: Material(
        elevation: 4,
        child: Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.4,
          ),
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: suggestions.length,
            itemBuilder: (context, index) => suggestions[index],
          ),
        ),
      ),
    );
  }
}

/// Widget de loading para autocomplete
class AutocompleteLoadingOverlay extends StatelessWidget {
  const AutocompleteLoadingOverlay({
    super.key,
    required this.top,
    required this.width,
    required this.message,
  });

  final double top;
  final double width;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: top,
      width: width,
      child: Material(
        elevation: 1,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          child: Row(
            children: [
              const SizedBox(
                height: 24,
                width: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              const SizedBox(width: 24),
              Expanded(
                child: Text(
                  message,
                  style: const TextStyle(fontSize: 16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
