import 'dart:ui' as ui;
import 'package:apple_maps_flutter/apple_maps_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:partiu/features/home/presentation/widgets/helpers/marker_color_helper.dart';

/// Helper para gerar BitmapDescriptors para markers do mapa
class MarkerBitmapGenerator {
  /// Gera bitmap de um emoji com cor dinâmica
  /// 
  /// Parâmetros:
  /// - [emoji]: Emoji a ser renderizado
  /// - [eventId]: ID do evento (usado para gerar cor consistente)
  /// - [size]: Tamanho do container
  static Future<BitmapDescriptor> generateEmojiPin(
    String emoji, {
    String? eventId,
    int size = 230,
  }) async {
    try {
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);
      
      // Cor dinâmica baseada no eventId
      final backgroundColor = eventId != null
          ? MarkerColorHelper.getColorForId(eventId)
          : const Color(0xFFFFFFFF); // Branco como fallback
      
      // Desenhar sombra PRIMEIRO (embaixo)
      final shadowPaint = Paint()
        ..color = Colors.black.withOpacity(0.25)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
      canvas.drawCircle(
        Offset(size / 2, size / 2 + 3),
        size / 2,
        shadowPaint,
      );
      
      // Desenhar borda branca
      final borderPaint = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.fill;
      canvas.drawCircle(
        Offset(size / 2, size / 2),
        size / 2,
        borderPaint,
      );
      
      // Desenhar círculo colorido de fundo (menor que a borda)
      final borderWidth = 10.0;
      final paint = Paint()..color = backgroundColor;
      canvas.drawCircle(
        Offset(size / 2, size / 2),
        (size / 2) - borderWidth,
        paint,
      );

      // Desenhar emoji
      final textPainter = TextPainter(
        text: TextSpan(
          text: emoji,
          style: TextStyle(fontSize: size * 0.5),
        ),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(
          (size - textPainter.width) / 2,
          (size - textPainter.height) / 2,
        ),
      );

      final picture = recorder.endRecording();
      final img = await picture.toImage(size, size);
      final byteData = await img.toByteData(format: ui.ImageByteFormat.png);
      final uint8list = byteData!.buffer.asUint8List();

      return BitmapDescriptor.fromBytes(uint8list);
    } catch (e) {
      debugPrint('❌ Erro ao gerar emoji pin: $e');
      return await _generateDefaultAvatarPin(size);
    }
  }

  /// Gera bitmap circular de um avatar a partir de URL
  static Future<BitmapDescriptor> generateAvatarPin(
    String url, {
    int size = 100,
  }) async {
    try {
      // Se for URL placeholder ou inválida, usar fallback direto
      if (url.contains('placeholder.com') || url.isEmpty) {
        return _generateDefaultAvatarPin(size);
      }

      // Baixar imagem com timeout
      final response = await http
          .get(Uri.parse(url))
          .timeout(const Duration(seconds: 3));
      
      if (response.statusCode != 200) {
        return _generateDefaultAvatarPin(size);
      }

      // Decodificar imagem SEM redimensionar (para evitar achatamento)
      final codec = await ui.instantiateImageCodec(response.bodyBytes);
      final frame = await codec.getNextFrame();
      final image = frame.image;

      // Criar canvas circular
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);

      // Desenhar sombra
      final shadowPaint = Paint()
        ..color = Colors.black.withOpacity(0.3)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);
      canvas.drawCircle(
        Offset(size / 2, size / 2 + 1),
        size / 2,
        shadowPaint,
      );

      // Desenhar borda branca mais grossa (6px)
      final borderPaint = Paint()..color = Colors.white;
      canvas.drawCircle(
        Offset(size / 2, size / 2),
        size / 2,
        borderPaint,
      );

      // Criar clip circular para o avatar
      final borderWidth = 6.0;
      final clipPath = Path()
        ..addOval(Rect.fromCircle(
          center: Offset(size / 2, size / 2),
          radius: (size / 2) - borderWidth,
        ));
      canvas.clipPath(clipPath);

      // Calcular dimensões para BoxFit.cover (preencher sem achatar)
      final availableSize = size - (borderWidth * 2);
      final imageWidth = image.width.toDouble();
      final imageHeight = image.height.toDouble();
      final imageAspect = imageWidth / imageHeight;
      
      Rect srcRect;
      Rect dstRect;
      
      if (imageAspect > 1) {
        // Imagem horizontal - usar altura total, cortar largura
        final scaledWidth = imageHeight; // usar altura como base (quadrado)
        final cropX = (imageWidth - scaledWidth) / 2;
        srcRect = Rect.fromLTWH(cropX, 0, scaledWidth, imageHeight);
      } else if (imageAspect < 1) {
        // Imagem vertical - usar largura total, cortar altura
        final scaledHeight = imageWidth; // usar largura como base (quadrado)
        final cropY = (imageHeight - scaledHeight) / 2;
        srcRect = Rect.fromLTWH(0, cropY, imageWidth, scaledHeight);
      } else {
        // Imagem quadrada - usar tudo
        srcRect = Rect.fromLTWH(0, 0, imageWidth, imageHeight);
      }
      
      // Destino: preencher todo o espaço disponível
      dstRect = Rect.fromLTWH(
        borderWidth,
        borderWidth,
        availableSize,
        availableSize,
      );

      // Desenhar avatar (cover - preenche sem distorcer)
      canvas.drawImageRect(
        image,
        srcRect,
        dstRect,
        Paint(),
      );

      final picture = recorder.endRecording();
      final img = await picture.toImage(size, size);
      final byteData = await img.toByteData(format: ui.ImageByteFormat.png);
      final uint8list = byteData!.buffer.asUint8List();

      return BitmapDescriptor.fromBytes(uint8list);
    } catch (e) {
      // Falha silenciosa - usar fallback
      return _generateDefaultAvatarPin(size);
    }
  }

  /// Gera pin padrão quando não há avatar
  static Future<BitmapDescriptor> _generateDefaultAvatarPin(int size) async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);

    // Círculo cinza
    final paint = Paint()..color = Colors.grey[400]!;
    canvas.drawCircle(
      Offset(size / 2, size / 2),
      size / 2,
      paint,
    );

    // Ícone de pessoa
    final iconPainter = TextPainter(
      text: const TextSpan(
        text: '👤',
        style: TextStyle(fontSize: 24),
      ),
      textDirection: TextDirection.ltr,
    );
    iconPainter.layout();
    iconPainter.paint(
      canvas,
      Offset(
        (size - iconPainter.width) / 2,
        (size - iconPainter.height) / 2,
      ),
    );

    final picture = recorder.endRecording();
    final img = await picture.toImage(size, size);
    final byteData = await img.toByteData(format: ui.ImageByteFormat.png);
    final uint8list = byteData!.buffer.asUint8List();

    return BitmapDescriptor.fromBytes(uint8list);
  }
}
