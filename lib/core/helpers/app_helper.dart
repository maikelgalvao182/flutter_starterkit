import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:geolocator/geolocator.dart';

/// Helper para funcionalidades gerais do app
class AppHelper {
  
  /// Verifica e solicita permissão de localização
  Future<void> checkLocationPermission({
    required VoidCallback onGpsDisabled,
    required VoidCallback onDenied,
    required VoidCallback onGranted,
  }) async {
    if (!(await Geolocator.isLocationServiceEnabled())) {
      onGpsDisabled();
      return Future.value();
    } else {
      /// Obtém status da permissão
      var permission = await Geolocator.checkPermission();

      // Estado inicial no Android e iOS
      if (permission == LocationPermission.denied) {
        /// Solicita permissão
        permission = await Geolocator.requestPermission();
        // Verifica o resultado
        if (permission == LocationPermission.denied) {
          onDenied();
          return Future.value();
        }
      }

      // Permissões de localização negadas permanentemente
      if (permission == LocationPermission.deniedForever) {
        onDenied();
        return Future.value();
      }

      // Permissões concedidas
      if (permission == LocationPermission.whileInUse ||
          permission == LocationPermission.always) {
        onGranted();
        return Future.value();
      }
    }
  }

  /// Obtém localização atual do usuário
  Future<void> getUserCurrentLocation({
    required Function(Position) onSuccess,
    required Function(Object) onFail,
    required Function(TimeoutException) onTimeoutException,
  }) async {
    try {
      final position = await Geolocator.getCurrentPosition();
      onSuccess(position);
    } on TimeoutException catch (e) {
      onTimeoutException(e);
    } catch (e) {
      onFail(e);
    }
  }

  /// Compartilha o app
  Future<void> shareApp({BuildContext? context}) async {
    const String appUrl = 'https://play.google.com/store/apps/details?id=com.partiu.app';
    const String message = 'Conheça o Partiu! O app para encontros e relacionamentos. $appUrl';
    
    try {
      await SharePlus.instance.share(ShareParams(text: message));
    } catch (e) {
      debugPrint('Erro ao compartilhar: $e');
    }
  }

  /// Abre página de avaliação do app
  Future<void> reviewApp() async {
    try {
      final Uri url;
      if (Platform.isAndroid) {
        url = Uri.parse('https://play.google.com/store/apps/details?id=com.partiu.app');
      } else {
        url = Uri.parse('https://apps.apple.com/app/partiu/id123456789');
      }
      
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      debugPrint('Erro ao abrir página de avaliação: $e');
    }
  }

  /// Abre política de privacidade
  Future<void> openPrivacyPage() async {
    try {
      final url = Uri.parse('https://partiu.app/privacy');
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      debugPrint('Erro ao abrir política de privacidade: $e');
    }
  }

  /// Abre termos de serviço
  Future<void> openTermsPage() async {
    try {
      final url = Uri.parse('https://partiu.app/terms');
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      debugPrint('Erro ao abrir termos de serviço: $e');
    }
  }


}