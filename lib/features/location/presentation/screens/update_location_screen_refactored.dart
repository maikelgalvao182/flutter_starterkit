import 'package:partiu/core/constants/glimpse_colors.dart';
import 'package:partiu/core/constants/constants.dart';
import 'package:partiu/core/config/dependency_provider.dart';
import 'package:partiu/core/utils/app_localizations.dart';
import 'package:partiu/core/router/app_router.dart';
import 'package:partiu/features/location/presentation/viewmodels/update_location_view_model.dart';
import 'package:partiu/shared/widgets/glimpse_button.dart';
import 'package:partiu/shared/widgets/dialogs/dialog_styles.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;

/// Tela de atualização de localização - Refatorada seguindo MVVM
/// 
/// Este widget é "burro" - apenas exibe UI e delega toda lógica ao ViewModel
class UpdateLocationScreenRefactored extends StatefulWidget {

  const UpdateLocationScreenRefactored({
    super.key,
    this.isSignUpProcess = true,
  });
  
  final bool isSignUpProcess;

  @override
  UpdateLocationScreenRefactoredState createState() => UpdateLocationScreenRefactoredState();
}

class UpdateLocationScreenRefactoredState extends State<UpdateLocationScreenRefactored> {
  late AppLocalizations _i18n;
  late UpdateLocationViewModel _viewModel;
  bool _isSaving = false;
  
  // Map controller
  GoogleMapController? _mapController;
  
  // Delay map rendering to prevent navigation jank
  final Future<bool> _mapReadyFuture = Future.delayed(const Duration(milliseconds: 500), () => true);

  @override
  void initState() {
    super.initState();
    
    // Inicia rastreamento após o build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _viewModel.startLocationTracking(_i18n.translate('location_not_available'));
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Obtém ViewModel via DI
    final serviceLocator = DependencyProvider.of(context).serviceLocator;
    _viewModel = serviceLocator.get<UpdateLocationViewModel>();
    _i18n = AppLocalizations.of(context);
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }

  /// Callback quando o mapa é criado
  void _onMapCreated(GoogleMapController controller) async {
    _mapController = controller;
    
    // Aplica estilo do mapa se disponível
    try {
      final style = await rootBundle.loadString('assets/map_styles/clean.json');
      // ignore: deprecated_member_use
      await controller.setMapStyle(style);
    } catch (_) {
      // Silently fail if style loading fails
    }
    
    // Move câmera para posição atual se disponível
    if (_viewModel.currentPosition != null) {
      controller.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: _viewModel.currentPosition!,
            zoom: 15,
          ),
        ),
      );
    }
  }

  /// Processa o salvamento da localização
  Future<void> _handleSaveLocation() async {
    final userId = firebase_auth.FirebaseAuth.instance.currentUser?.uid;
    
    if (userId == null) {
      _showErrorDialog(_i18n.translate('user_not_logged_in'));
      return;
    }
    
    // Aguarda GPS estar pronto
    final isReady = await _viewModel.waitForLocationReady();
    if (!isReady) {
      _showErrorDialog(_i18n.translate('location_not_available'));
      return;
    }
    
    // Mostra loading no botão
    setState(() => _isSaving = true);
    
    // Salva localização
    await _viewModel.saveCurrentLocation(userId);
    
    // Aguarda o estado mudar
    await Future.delayed(const Duration(milliseconds: 100));
    
    // Esconde loading
    if (mounted) setState(() => _isSaving = false);
    
    // Trata o resultado baseado no estado
    if (_viewModel.saveState == LocationSaveState.success) {
      final message = '${_i18n.translate("location_updated_successfully")}\n${_viewModel.savedLocation}';
      _showSuccessDialog(message);

      if (widget.isSignUpProcess) {
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) context.go(AppRoutes.home);
        });
      } else {
        Future.delayed(const Duration(seconds: 1), () {
          if (mounted) Navigator.of(context).pop(true);
        });
      }
    } else if (_viewModel.saveState == LocationSaveState.error) {
      _showErrorDialog(_viewModel.saveError ?? 'Unknown error');
    }
  }
  
  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: DialogStyles.containerBorderRadius),
        child: Container(
          margin: DialogStyles.containerMargin,
          padding: DialogStyles.containerPadding,
          decoration: DialogStyles.containerDecoration,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DialogStyles.buildWarningIcon(icon: Icons.error_outline, iconSize: 40),
              const SizedBox(height: DialogStyles.spacingAfterIcon),
              DialogStyles.buildTitle(_i18n.translate('error')),
              const SizedBox(height: DialogStyles.spacingAfterTitle),
              DialogStyles.buildMessage(message),
              const SizedBox(height: DialogStyles.spacingBeforeButtons),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: DialogStyles.positiveButtonStyle,
                  child: Text('OK', style: DialogStyles.positiveButtonTextStyle),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  void _showSuccessDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: DialogStyles.containerBorderRadius),
        child: Container(
          margin: DialogStyles.containerMargin,
          padding: DialogStyles.containerPadding,
          decoration: DialogStyles.containerDecoration,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DialogStyles.buildSuccessIcon(icon: Icons.check_circle_outline, iconSize: 40),
              const SizedBox(height: DialogStyles.spacingAfterIcon),
              DialogStyles.buildTitle(_i18n.translate('success')),
              const SizedBox(height: DialogStyles.spacingAfterTitle),
              DialogStyles.buildMessage(message),
              const SizedBox(height: DialogStyles.spacingBeforeButtons),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: DialogStyles.successButtonStyle,
                  child: Text('OK', style: DialogStyles.successButtonTextStyle),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    _i18n = AppLocalizations.of(context);
    
    return Scaffold(
        appBar: AppBar(
          elevation: 0,
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.white,
          centerTitle: false,
          automaticallyImplyLeading: false,
          title: Text(
            _i18n.translate('your_current_location'),
            style: GoogleFonts.getFont(FONT_PLUS_JAKARTA_SANS, 
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Colors.black,
            ),
          ),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.black),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.white,
        body: ListenableBuilder(
          listenable: _viewModel,
          builder: (context, child) {
            return Stack(
              children: [
                // Google Maps em tela cheia
                FutureBuilder<bool>(
                  future: _mapReadyFuture,
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const Center(
                        child: CupertinoActivityIndicator(
                          color: GlimpseColors.primary,
                          radius: 14,
                        ),
                      );
                    }
                    
                    return GoogleMap(
                      key: const ValueKey('update-location-map'),
                      onMapCreated: _onMapCreated,
                      initialCameraPosition: CameraPosition(
                        target: _viewModel.currentPosition ?? UpdateLocationViewModel.defaultLocation,
                        zoom: 15,
                      ),
                      markers: _viewModel.markers,
                      myLocationEnabled: true,
                      myLocationButtonEnabled: false,
                      mapToolbarEnabled: false,
                      zoomControlsEnabled: false,
                      onTap: (LatLng position) {
                        _viewModel.updatePositionManually(
                          position,
                          _i18n.translate('your_current_location'),
                        );
                      },
                    );
                  },
                ),
                
                // Botão flutuante para centralizar na localização atual
                Positioned(
                  top: 16,
                  right: 16,
                  child: FloatingActionButton(
                    mini: true,
                    backgroundColor: Colors.white,
                    onPressed: () {
                      if (_viewModel.currentPosition != null && _mapController != null) {
                        _mapController!.animateCamera(
                          CameraUpdate.newCameraPosition(
                            CameraPosition(
                              target: _viewModel.currentPosition!,
                              zoom: 15,
                            ),
                          ),
                        );
                      }
                    },
                    child: const Icon(
                      Icons.my_location,
                      color: GlimpseColors.primary,
                    ),
                  ),
                ),
                
                // Botão GET LOCATION na posição padrão (bottom)
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: const BoxDecoration(
                      color: Colors.transparent,
                    ),
                    child: SafeArea(
                      child: GlimpseButton(
                        text: _i18n.translate('GET_LOCATION'),
                        onTap: _handleSaveLocation,
                        isProcessing: _isSaving,
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
    );
  }
}
