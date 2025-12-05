import 'package:dating_app/screens/ranking/models/ranking_entry.dart';
import 'package:dating_app/screens/ranking/widgets/winner_podium_card.dart';
import 'package:flutter/material.dart';

/// Widget que exibe o pódio dos 3 primeiros colocados no ranking
/// 
/// Layout vertical em lista com bordas e fundos coloridos:
/// - 1º lugar: borda dourada, fundo dourado suave
/// - 2º lugar: borda prateada, fundo prateado suave  
/// - 3º lugar: borda bronze, fundo bronze suave
class RankingPodium extends StatelessWidget {
  const RankingPodium({
    required this.firstPlace,
    required this.secondPlace,
    required this.thirdPlace,
    super.key,
  });

  final RankingEntry firstPlace;
  final RankingEntry secondPlace;
  final RankingEntry thirdPlace;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Column(
        children: [
          // 1º Lugar
          WinnerPodiumCard(entry: firstPlace),
          const SizedBox(height: 8),
          
          // 2º Lugar
          WinnerPodiumCard(entry: secondPlace),
          const SizedBox(height: 8),
          
          // 3º Lugar
          WinnerPodiumCard(entry: thirdPlace),
        ],
      ),
    );
  }
}
