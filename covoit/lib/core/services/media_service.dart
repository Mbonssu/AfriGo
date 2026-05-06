import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/material.dart';

/// Service de gestion des photos
class MediaService {
  final ImagePicker _picker = ImagePicker();

  /// Prendre une photo avec la caméra
  Future<File?> takePhoto() async {
    try {
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (photo != null) {
        return File(photo.path);
      }
      return null;
    } catch (e) {
      debugPrint('Erreur lors de la prise de photo: $e');
      return null;
    }
  }

  /// Choisir une image depuis une source (caméra ou galerie)
  Future<File?> pickImage({required ImageSource source}) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (image != null) {
        return File(image.path);
      }
      return null;
    } catch (e) {
      debugPrint('Erreur lors de la sélection d\'image: $e');
      return null;
    }
  }

  /// Choisir une photo depuis la galerie
  Future<File?> pickImageFromGallery() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (image != null) {
        return File(image.path);
      }
      return null;
    } catch (e) {
      debugPrint('Erreur lors de la sélection d\'image: $e');
      return null;
    }
  }

  /// Prendre plusieurs photos
  Future<List<File>> takeMultiplePhotos({int maxImages = 5}) async {
    try {
      final List<XFile> images = await _picker.pickMultiImage(
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (images.length > maxImages) {
        return images.take(maxImages).map((xFile) => File(xFile.path)).toList();
      }

      return images.map((xFile) => File(xFile.path)).toList();
    } catch (e) {
      debugPrint('Erreur lors de la sélection multiple: $e');
      return [];
    }
  }

  /// Obtenir le répertoire temporaire pour stocker les photos
  Future<Directory> getTempDirectory() async {
    return await getTemporaryDirectory();
  }

  /// Obtenir le répertoire de l'application pour stocker les photos
  Future<Directory> getAppDirectory() async {
    return await getApplicationDocumentsDirectory();
  }

  /// Afficher un dialogue de choix (Caméra ou Galerie)
  Future<File?> showPhotoSourceDialog(
    BuildContext context, {
    String title = 'Choisir une photo',
  }) async {
    final source = await showDialog<ImageSource>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt_rounded),
              title: const Text('Prendre une photo'),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_rounded),
              title: const Text('Choisir depuis la galerie'),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
        ],
      ),
    );

    if (source == null) return null;

    if (source == ImageSource.camera) {
      return await takePhoto();
    } else {
      return await pickImageFromGallery();
    }
  }
}

