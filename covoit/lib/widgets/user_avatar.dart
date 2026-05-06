import 'package:flutter/material.dart';
import '../app_theme.dart';
import '../core/constants/api_endpoints.dart';

/// Widget réutilisable pour afficher l'avatar d'un utilisateur
/// Affiche la photo de profil si disponible, sinon les initiales
class UserAvatar extends StatelessWidget {
  final String? photoUrl;
  final String initials;
  final double radius;
  final Color? backgroundColor;
  final Color? textColor;
  final VoidCallback? onTap;
  final Widget? badge;

  const UserAvatar({
    super.key,
    this.photoUrl,
    required this.initials,
    this.radius = 20,
    this.backgroundColor,
    this.textColor,
    this.onTap,
    this.badge,
  });

  @override
  Widget build(BuildContext context) {
    // Construire l'URL complète en ajoutant le préfixe /api/users si nécessaire
    String? imageUrl;
    if (photoUrl != null && photoUrl!.isNotEmpty) {
      // Si l'URL commence par /uploads/, ajouter le préfixe /api/users
      if (photoUrl!.startsWith('/uploads/')) {
        imageUrl = '${ApiEndpoints.gatewayUrl}/api/users$photoUrl';
      } else if (photoUrl!.startsWith('http://') || photoUrl!.startsWith('https://')) {
        // URL complète déjà fournie
        imageUrl = photoUrl;
      } else {
        // Autre cas: ajouter le gateway URL
        imageUrl = '${ApiEndpoints.gatewayUrl}$photoUrl';
      }
    }

    final avatar = CircleAvatar(
      radius: radius,
      backgroundColor: backgroundColor ?? AppColors.greenLight,
      backgroundImage: imageUrl != null
          ? NetworkImage(imageUrl)
          : null,
      onBackgroundImageError: imageUrl != null
          ? (exception, stackTrace) {
              debugPrint('⚠️ Erreur chargement avatar: $imageUrl');
            }
          : null,
      child: photoUrl == null || photoUrl!.isEmpty
          ? Text(
              initials,
              style: TextStyle(
                fontSize: radius * 0.6,
                fontWeight: FontWeight.w800,
                color: textColor ?? AppColors.green,
              ),
            )
          : null,
    );

    if (badge != null) {
      return GestureDetector(
        onTap: onTap,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            avatar,
            Positioned(
              right: -2,
              bottom: -2,
              child: badge!,
            ),
          ],
        ),
      );
    }

    if (onTap != null) {
      return GestureDetector(
        onTap: onTap,
        child: avatar,
      );
    }

    return avatar;
  }
}

/// Widget pour afficher un avatar avec un badge de vérification
class VerifiedUserAvatar extends StatelessWidget {
  final String? photoUrl;
  final String initials;
  final double radius;
  final bool isVerified;
  final VoidCallback? onTap;

  const VerifiedUserAvatar({
    super.key,
    this.photoUrl,
    required this.initials,
    this.radius = 20,
    this.isVerified = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return UserAvatar(
      photoUrl: photoUrl,
      initials: initials,
      radius: radius,
      onTap: onTap,
      badge: isVerified
          ? Container(
              padding: const EdgeInsets.all(2),
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.verified_rounded,
                size: radius * 0.4,
                color: AppColors.green,
              ),
            )
          : null,
    );
  }
}

/// Widget pour afficher un avatar avec un badge Prime
class PrimeUserAvatar extends StatelessWidget {
  final String? photoUrl;
  final String initials;
  final double radius;
  final bool isPrime;
  final VoidCallback? onTap;

  const PrimeUserAvatar({
    super.key,
    this.photoUrl,
    required this.initials,
    this.radius = 20,
    this.isPrime = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return UserAvatar(
      photoUrl: photoUrl,
      initials: initials,
      radius: radius,
      onTap: onTap,
      badge: isPrime
          ? Container(
              padding: const EdgeInsets.all(2),
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.workspace_premium_rounded,
                size: radius * 0.4,
                color: AppColors.prime,
              ),
            )
          : null,
    );
  }
}
