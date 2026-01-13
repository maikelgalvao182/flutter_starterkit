import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:partiu/core/utils/app_logger.dart';
import 'package:partiu/core/services/image_compress_service.dart';
import 'package:flutter/material.dart';

/// Service para upload de imagens para Firebase Storage
/// 
/// Responsabilidades:
/// - Selecionar imagens da galeria/câmera
/// - Fazer upload para Firebase Storage
/// - Gerenciar URLs de download
/// - Compressão básica (se necessário)
class ImageUploadService {
  final FirebaseStorage _storage;
  final ImagePicker _picker;
  final ImageCompressService _compressService;
  
  ImageUploadService({
    FirebaseStorage? storage,
    ImagePicker? picker,
    ImageCompressService? compressService,
  })  : _storage = storage ?? FirebaseStorage.instance,
        _picker = picker ?? ImagePicker(),
        _compressService = compressService ?? const ImageCompressService();
  
  static const String _tag = 'ImageUploadService';
  
  /// Seleciona uma imagem da galeria
  Future<XFile?> pickImageFromGallery() async {
    try {
      AppLogger.info('Picking image from gallery...', tag: _tag);
      debugPrint('[$_tag] 📸 Starting image picker from gallery');
      
      final image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
        maxWidth: 1920,
        maxHeight: 1920,
      );
      
      if (image != null) {
        debugPrint('[$_tag] ✅ Image selected: ${image.path}');
        debugPrint('[$_tag] 📏 Image size: ${await File(image.path).length()} bytes');
        AppLogger.info('Image selected: ${image.path}', tag: _tag);
      } else {
        debugPrint('[$_tag] ❌ No image selected (user cancelled)');
        AppLogger.info('No image selected (user cancelled)', tag: _tag);
      }
      
      return image;
    } catch (e, stackTrace) {
      debugPrint('[$_tag] 💥 Error picking image: $e');
      AppLogger.error(
        'Error picking image: $e',
        tag: _tag,
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }
  
  /// Seleciona uma imagem da câmera
  Future<XFile?> pickImageFromCamera() async {
    try {
      AppLogger.info('Picking image from camera...', tag: _tag);
      
      final image = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
        maxWidth: 1920,
        maxHeight: 1920,
      );
      
      if (image != null) {
        AppLogger.info('Image captured: ${image.path}', tag: _tag);
      }
      
      return image;
    } catch (e, stackTrace) {
      AppLogger.error(
        'Error capturing image: $e',
        tag: _tag,
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }
  
  /// Faz upload de uma imagem para o Firebase Storage
  /// Retorna a URL de download
  Future<String> uploadImage({
    required String userId,
    required String filePath,
    required String folder, // 'profile', 'gallery', 'videos'
    Function(double)? onProgress,
  }) async {
    try {
      debugPrint('[$_tag] 🚀 Starting upload - userId: $userId, folder: $folder');
      debugPrint('[$_tag] 📁 File path: $filePath');
      
      // Verificar autenticação Firebase
      final currentUser = FirebaseAuth.instance.currentUser;
      debugPrint('[$_tag] 🔐 Firebase Auth user: ${currentUser?.uid}');
      if (currentUser == null) {
        throw Exception('Firebase Auth: usuário não autenticado');
      }
      
      AppLogger.info('Uploading image to $folder...', tag: _tag);
      
      final file = File(filePath);
      if (!await file.exists()) {
        throw Exception('File does not exist: $filePath');
      }
      
      final fileSize = await file.length();
      debugPrint('[$_tag] 📏 File size: ${(fileSize / (1024 * 1024)).toStringAsFixed(2)}MB');
      
      final fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
      final storagePath = 'users/$userId/$folder/$fileName';
      debugPrint('[$_tag] 🗂️ Storage path: $storagePath');
      
      final ref = _storage.ref().child(storagePath);
      
      debugPrint('[$_tag] ⬆️ Starting Firebase upload...');
      final metadata = SettableMetadata(
        // ✅ Imagens são versionadas por nome (timestamp), então cache pode ser agressivo.
        cacheControl: 'private,max-age=31536000,immutable',
      );
      final uploadTask = ref.putFile(file, metadata);
      
      // Monitora progresso
      uploadTask.snapshotEvents.listen((snapshot) {
        final progress = snapshot.bytesTransferred / snapshot.totalBytes;
        debugPrint('[$_tag] 📊 Upload progress: ${(progress * 100).toStringAsFixed(1)}%');
        onProgress?.call(progress);
      });
      
      await uploadTask;
      debugPrint('[$_tag] ✅ Upload complete, getting download URL...');
      
      final downloadUrl = await ref.getDownloadURL();
      debugPrint('[$_tag] 🔗 Download URL: ${downloadUrl.substring(0, 100)}...');
      
      AppLogger.info('Image uploaded successfully: $downloadUrl', tag: _tag);
      return downloadUrl;
    } catch (e, stackTrace) {
      debugPrint('[$_tag] 💥 Upload error: $e');
      debugPrint('[$_tag] 📚 StackTrace: $stackTrace');
      AppLogger.error(
        'Error uploading image: $e',
        tag: _tag,
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// Faz upload de uma imagem de avatar comprimida
  /// Comprime a imagem antes do upload para otimizar o tamanho
  Future<String> uploadAvatarImage({
    required String userId,
    required String filePath,
    Function(double)? onProgress,
  }) async {
    try {
      debugPrint('[$_tag] 👤 uploadAvatarImage called - userId: $userId');
      debugPrint('[$_tag] 📁 File path: $filePath');
      
      // Debug: verificar autenticação
      final currentUser = FirebaseAuth.instance.currentUser;
      debugPrint('[$_tag] 🔐 Firebase Auth - currentUser: ${currentUser?.uid}, targetUser: $userId');
      debugPrint('[$_tag] 🔐 Firebase Auth - isAnonymous: ${currentUser?.isAnonymous}');
      debugPrint('[$_tag] 🔐 Firebase Auth - email: ${currentUser?.email}');
      debugPrint('[$_tag] 🔐 Firebase Auth - emailVerified: ${currentUser?.emailVerified}');
      
      if (currentUser == null) {
        throw Exception('Firebase Auth: usuário não autenticado');
      }
      
      if (currentUser.uid != userId) {
        debugPrint('[$_tag] ⚠️ User ID mismatch: auth=${currentUser.uid}, target=$userId');
      }
      
      AppLogger.info('Current user: ${currentUser.uid}, Target userId: $userId', tag: _tag);
      AppLogger.info('Uploading compressed avatar image...', tag: _tag);
      
      final file = File(filePath);
      
      if (!await file.exists()) {
        throw Exception('Avatar file does not exist: $filePath');
      }
      
      final originalSize = await file.length();
      debugPrint('[$_tag] 📏 Original file size: ${(originalSize / (1024 * 1024)).toStringAsFixed(2)}MB');
      
      debugPrint('[$_tag] 🗜️ Starting image compression...');
      // Comprime a imagem para avatar (800x800 é suficiente para perfis)
      final compressedBytes = await _compressService.compressFileToBytes(
        file,
        minWidth: 800,
        minHeight: 800,
        quality: 80,
      );
      
      debugPrint('[$_tag] ✅ Compression complete: $originalSize -> ${compressedBytes.length} bytes');
      AppLogger.info('Image compressed: ${file.lengthSync()} bytes -> ${compressedBytes.length} bytes', tag: _tag);
      
      final fileName = 'avatar_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final ref = _storage.ref().child('users/$userId/profile/$fileName');
      
      // Upload dos bytes comprimidos com metadata
      final metadata = SettableMetadata(
        contentType: 'image/jpeg',
        cacheControl: 'private,max-age=31536000,immutable',
        customMetadata: {
          'uploadedAt': DateTime.now().toIso8601String(),
          'compressed': 'true',
          'originalSize': file.lengthSync().toString(),
          'compressedSize': compressedBytes.length.toString(),
        },
      );
      
      final uploadTask = ref.putData(compressedBytes, metadata);
      
      // Monitora progresso
      uploadTask.snapshotEvents.listen((snapshot) {
        // Evita divisão por zero e valores inválidos (Infinity/NaN)
        if (snapshot.totalBytes > 0) {
          final progress = snapshot.bytesTransferred / snapshot.totalBytes;
          if (progress.isFinite) {
            onProgress?.call(progress);
          }
        }
      });
      
      await uploadTask;
      final downloadUrl = await ref.getDownloadURL();
      
      AppLogger.info('Compressed avatar uploaded successfully: $downloadUrl', tag: _tag);
      return downloadUrl;
    } catch (e, stackTrace) {
      AppLogger.error(
        'Error uploading compressed avatar: $e',
        tag: _tag,
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }
  
  /// Deleta uma imagem do Firebase Storage
  Future<void> deleteImage(String imageUrl) async {
    try {
      AppLogger.info('Deleting image: $imageUrl', tag: _tag);
      
      final ref = _storage.refFromURL(imageUrl);
      await ref.delete();
      
      AppLogger.info('Image deleted successfully', tag: _tag);
    } catch (e, stackTrace) {
      AppLogger.error(
        'Error deleting image: $e',
        tag: _tag,
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }
  
  /// Seleciona múltiplas imagens
  Future<List<XFile>> pickMultipleImages({int? limit}) async {
    try {
      AppLogger.info('Picking multiple images...', tag: _tag);
      
      final images = await _picker.pickMultiImage(
        imageQuality: 85,
        maxWidth: 1920,
        maxHeight: 1920,
      );
      
      if (limit != null && images.length > limit) {
        AppLogger.warning('Too many images selected, limiting to $limit', tag: _tag);
        return images.take(limit).toList();
      }
      
      AppLogger.info('${images.length} images selected', tag: _tag);
      return images;
    } catch (e, stackTrace) {
      AppLogger.error(
        'Error picking multiple images: $e',
        tag: _tag,
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }
}
