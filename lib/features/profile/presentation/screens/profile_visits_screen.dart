import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import 'package:partiu/common/state/app_state.dart';
import 'package:partiu/core/constants/constants.dart';
import 'package:partiu/core/constants/glimpse_colors.dart';
import 'package:partiu/core/utils/app_localizations.dart';
import 'package:partiu/shared/widgets/glimpse_app_bar.dart';
import 'package:partiu/shared/widgets/glimpse_empty_state.dart';
import 'package:partiu/features/profile/data/services/visits_service.dart';
import 'package:partiu/shared/widgets/stable_avatar.dart';
import 'package:partiu/features/profile/presentation/screens/profile_screen_optimized.dart';
import 'package:partiu/core/models/user.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Tela para exibir as visitas ao perfil do usuário
class ProfileVisitsScreen extends StatefulWidget {
  const ProfileVisitsScreen({super.key});

  @override
  State<ProfileVisitsScreen> createState() => _ProfileVisitsScreenState();
}

class _ProfileVisitsScreenState extends State<ProfileVisitsScreen> {
  final _visitsService = VisitsService.instance;
  final _firestore = FirebaseFirestore.instance;
  
  List<Map<String, dynamic>> _visits = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadVisits();
  }

  Future<void> _loadVisits() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final userId = AppState.currentUserId;
      if (userId == null || userId.isEmpty) {
        setState(() {
          _error = 'Usuário não autenticado';
          _isLoading = false;
        });
        return;
      }

      // Buscar visitas do Firestore
      final visitsSnapshot = await _firestore
          .collection('Users')
          .doc(userId)
          .collection('visits')
          .orderBy('visitedAt', descending: true)
          .limit(50)
          .get();

      final visits = <Map<String, dynamic>>[];
      
      for (final doc in visitsSnapshot.docs) {
        final data = doc.data();
        final visitorId = data['visitorId'] as String?;
        
        if (visitorId != null) {
          // Buscar dados do visitante
          final userDoc = await _firestore.collection('Users').doc(visitorId).get();
          if (userDoc.exists) {
            final userData = userDoc.data();
            visits.add({
              'visitorId': visitorId,
              'visitedAt': data['visitedAt'] as Timestamp?,
              'userName': userData?['userName'] as String? ?? 'Usuário',
              'photoUrl': userData?['photoUrl'] as String?,
              'userProfilePhoto': userData?['userProfilePhoto'] as String?,
              'city': userData?['city'] as String?,
              'state': userData?['state'] as String?,
            });
          }
        }
      }

      setState(() {
        _visits = visits;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('❌ [ProfileVisitsScreen] Erro ao carregar visitas: $e');
      setState(() {
        _error = 'Erro ao carregar visitas';
        _isLoading = false;
      });
    }
  }

  String _formatTimestamp(Timestamp? timestamp) {
    if (timestamp == null) return '';
    
    final date = timestamp.toDate();
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inMinutes < 1) {
      return 'Agora mesmo';
    } else if (difference.inHours < 1) {
      final minutes = difference.inMinutes;
      return '$minutes ${minutes == 1 ? 'minuto' : 'minutos'} atrás';
    } else if (difference.inDays < 1) {
      final hours = difference.inHours;
      return '$hours ${hours == 1 ? 'hora' : 'horas'} atrás';
    } else if (difference.inDays < 7) {
      final days = difference.inDays;
      return '$days ${days == 1 ? 'dia' : 'dias'} atrás';
    } else if (difference.inDays < 30) {
      final weeks = (difference.inDays / 7).floor();
      return '$weeks ${weeks == 1 ? 'semana' : 'semanas'} atrás';
    } else if (difference.inDays < 365) {
      final months = (difference.inDays / 30).floor();
      return '$months ${months == 1 ? 'mês' : 'meses'} atrás';
    } else {
      final years = (difference.inDays / 365).floor();
      return '$years ${years == 1 ? 'ano' : 'anos'} atrás';
    }
  }

  Future<void> _navigateToProfile(String visitorId) async {
    try {
      final userDoc = await _firestore.collection('Users').doc(visitorId).get();
      if (userDoc.exists) {
        final userData = userDoc.data()!;
        final user = User.fromDocument(userData);
        
        if (mounted) {
          await Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => ProfileScreenOptimized(
                user: user,
                currentUserId: AppState.currentUserId ?? '',
              ),
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('❌ [ProfileVisitsScreen] Erro ao navegar para perfil: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context).translate('error_loading_profile')),
            backgroundColor: Colors.red[700],
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final i18n = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: GlimpseAppBar(
        title: i18n.translate('profile_visits') ?? 'Visitas ao Perfil',
      ),
      body: _buildBody(i18n),
    );
  }

  Widget _buildBody(AppLocalizations i18n) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          color: GlimpseColors.primary,
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Iconsax.info_circle,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              _error!,
              style: GoogleFonts.getFont(
                FONT_PLUS_JAKARTA_SANS,
                fontSize: 16,
                color: GlimpseColors.textSubTitle,
              ),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: _loadVisits,
              child: Text(
                'Tentar novamente',
                style: GoogleFonts.getFont(
                  FONT_PLUS_JAKARTA_SANS,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: GlimpseColors.primary,
                ),
              ),
            ),
          ],
        ),
      );
    }

    if (_visits.isEmpty) {
      return Center(
        child: GlimpseEmptyState.standard(
          text: i18n.translate('no_visits_yet') ?? 'Nenhuma visita ainda',
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(20),
      itemCount: _visits.length,
      separatorBuilder: (context, index) => const Divider(
        height: 1,
        color: GlimpseColors.lightTextField,
      ),
      itemBuilder: (context, index) {
        final visit = _visits[index];
        final visitorId = visit['visitorId'] as String;
        final userName = visit['userName'] as String;
        final photoUrl = visit['photoUrl'] as String?;
        final userProfilePhoto = visit['userProfilePhoto'] as String?;
        final city = visit['city'] as String?;
        final state = visit['state'] as String?;
        final visitedAt = visit['visitedAt'] as Timestamp?;

        String location = '';
        if (city != null && state != null) {
          location = '$city, $state';
        } else if (city != null) {
          location = city;
        }

        return Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => _navigateToProfile(visitorId),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Row(
                children: [
                  // Avatar
                  StableAvatar(
                    userId: visitorId,
                    size: 56,
                    borderRadius: const BorderRadius.all(Radius.circular(10)),
                    photoUrl: photoUrl ?? userProfilePhoto,
                    enableNavigation: false,
                  ),
                  const SizedBox(width: 12),
                  // Nome e localização
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          userName,
                          style: GoogleFonts.getFont(
                            FONT_PLUS_JAKARTA_SANS,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: GlimpseColors.primaryColorLight,
                          ),
                        ),
                        if (location.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(
                                Iconsax.location,
                                size: 14,
                                color: GlimpseColors.textSubTitle,
                              ),
                              const SizedBox(width: 4),
                              Flexible(
                                child: Text(
                                  location,
                                  style: GoogleFonts.getFont(
                                    FONT_PLUS_JAKARTA_SANS,
                                    fontSize: 13,
                                    color: GlimpseColors.textSubTitle,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Tempo
                  Text(
                    _formatTimestamp(visitedAt),
                    style: GoogleFonts.getFont(
                      FONT_PLUS_JAKARTA_SANS,
                      fontSize: 12,
                      color: GlimpseColors.textSubTitle,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
