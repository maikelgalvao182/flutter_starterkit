import 'package:flutter/material.dart';
import 'package:partiu/core/constants/glimpse_colors.dart';
import 'package:shimmer/shimmer.dart';

/// Shimmer loading para PeopleRankingCard
/// Replica EXATAMENTE a estrutura e espaçamentos do card real
class PeopleRankingCardShimmer extends StatelessWidget {
  const PeopleRankingCardShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.grey.shade300,
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Shimmer.fromColors(
          baseColor: GlimpseColors.lightTextField,
          highlightColor: Colors.white,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header - Avatar 64x64 + textos
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Avatar
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(100),
                    ),
                  ),
                  
                  const SizedBox(width: 36),
                  
                  // Informações
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Nome (altura aproximada do texto com fontSize 15)
                        Container(
                          width: double.infinity,
                          height: 18,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        
                        const SizedBox(height: 16),
                        
                        // Localização (altura do texto fontSize 13)
                        Container(
                          width: 140,
                          height: 16,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        
                        const SizedBox(height: 12),
                        
                        // Rating summary (altura do texto + ícone)
                        Container(
                          width: 224,
                          height: 18,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(width: 12),
                  
                  // Posição
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                ],
              ),
              
              // SizedBox(height: 8) - igual ao card quando tem badges
              const SizedBox(height: 8),
              
              // Badges section
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Divider com margin bottom 12
                  Container(
                    height: 1,
                    color: GlimpseColors.borderColorLight,
                    margin: const EdgeInsets.only(bottom: 12),
                  ),
                  
                  // SizedBox com altura 40 para os badges
                  SizedBox(
                    height: 40,
                    child: Row(
                      children: [
                        Container(
                          width: 100,
                          height: 32,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          width: 90,
                          height: 32,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          width: 80,
                          height: 32,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              
              // SizedBox(height: 12) - igual ao card quando tem critérios
              const SizedBox(height: 12),
              
              // Criteria breakdown - CriteriaBars com divider
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Divider do CriteriaBars (showDivider: true)
                  Container(
                    height: 1,
                    color: GlimpseColors.borderColorLight,
                    margin: const EdgeInsets.only(bottom: 8),
                  ),
                  
                  // 4 barras de critério
                  Column(
                    children: List.generate(4, (index) {
                      return Padding(
                        padding: EdgeInsets.only(bottom: index < 3 ? 6 : 0),
                        child: Row(
                          children: [
                            // Label (width: 90)
                            Container(
                              width: 90,
                              height: 14,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                            
                            // Barra de progresso (minHeight: 6)
                            Expanded(
                              child: Container(
                                height: 6,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                            ),
                            
                            const SizedBox(width: 8),
                            
                            // Valor numérico (width: 20)
                            Container(
                              width: 20,
                              height: 14,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

