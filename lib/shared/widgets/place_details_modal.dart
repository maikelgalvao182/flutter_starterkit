import 'package:flutter/material.dart';
import 'package:partiu/features/home/presentation/widgets/place_card/place_card.dart';
import 'package:partiu/features/home/presentation/widgets/place_card/place_card_controller.dart';

/// Modal reutilizável para exibir detalhes de localização de um evento
class PlaceDetailsModal {
  /// Exibe modal com informações do local
  /// 
  /// [preloadedData] dados já carregados (locationName, formattedAddress, placeId, photoReferences)
  /// para evitar query redundante ao Firestore
  static void show(
    BuildContext context,
    String eventId, {
    Map<String, dynamic>? preloadedData,
  }) {
    final placeController = PlaceCardController(
      eventId: eventId,
      preloadedData: preloadedData,
    );
    
    // Iniciar carregamento em background (visitantes)
    placeController.load();

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Container(
          constraints: BoxConstraints(
            maxWidth: 500,
            maxHeight: MediaQuery.of(context).size.height * 0.85,
          ),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handler (barra de arraste)
              Container(
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              
              // Conteúdo do PlaceCard
              Flexible(
                child: SingleChildScrollView(
                  child: Padding(
                    padding: EdgeInsets.only(
                      bottom: MediaQuery.of(context).padding.bottom + 16,
                    ),
                    child: PlaceCard(controller: placeController),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ).whenComplete(() => placeController.dispose());
  }
}
