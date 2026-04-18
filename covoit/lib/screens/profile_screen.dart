import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../app_theme.dart';
import '../main.dart';
import '../data/providers/user_providers.dart';
import '../data/providers/journey_providers.dart';
import '../data/providers/auth_providers.dart';
import 'auth/login_screen.dart';
import 'caution_screen.dart';
import 'driver/subscription_screen.dart';
import 'driver/driver_stats_screen.dart';
import 'emergency_contact_screen.dart';
import 'identity_verification_screen.dart';

class ProfileScreen extends ConsumerWidget {
  final bool isPassenger;
  const ProfileScreen({super.key, this.isPassenger = true});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final userIdAsync = ref.watch(currentUserIdProvider);
    final userId = userIdAsync.valueOrNull;
    final profileAsync = userId != null && userId.isNotEmpty
        ? ref.watch(userProfileProvider(userId))
        : null;
    final profile = profileAsync?.valueOrNull;

    final driverAsync = userId != null && userId.isNotEmpty && !isPassenger
        ? ref.watch(driverProfileProvider(userId))
        : null;
    final isPrime = driverAsync?.valueOrNull?.isPrime ?? false;

    final displayName = profile?.fullName ?? 'Utilisateur';
    final initials = profile?.initials ?? '?';
    final phone = profile?.phone ?? '';
    final rating = profile?.rating ?? 0.0;
    final totalReviews = profile?.totalReviews ?? 0;

    return Scaffold(
      appBar: AppBar(title: const Text('Mon profil')),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header
            Container(
              color: AppColors.green,
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 28),
              child: Column(
                children: [
                  Stack(
                    alignment: Alignment.bottomRight,
                    children: [
                      CircleAvatar(
                        radius: 44,
                        backgroundColor: Colors.white24,
                        child: Text(initials,
                            style: const TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.w800,
                                color: Colors.white)),
                      ),
                      Container(
                        width: 28, height: 28,
                        decoration: const BoxDecoration(
                            color: Colors.white, shape: BoxShape.circle),
                        child: const Icon(Icons.camera_alt_rounded,
                            size: 14, color: AppColors.green),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(displayName,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w700)),
                  const SizedBox(height: 4),
                  Text(phone,
                      style: const TextStyle(color: Colors.white70, fontSize: 13)),
                  const SizedBox(height: 12),
                  if (!isPassenger && isPrime)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.prime.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color: AppColors.prime.withValues(alpha: 0.5), width: 1),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.workspace_premium_rounded,
                              size: 14, color: AppColors.prime),
                          SizedBox(width: 6),
                          Text('Chauffeur Prime',
                              style: TextStyle(
                                  color: AppColors.prime,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13)),
                        ],
                      ),
                    )
                  else if (!isPassenger && !isPrime)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                                color: Colors.white.withValues(alpha: 0.3), width: 1),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.directions_car_rounded,
                                  size: 14, color: Colors.white),
                              SizedBox(width: 6),
                              Text('Chauffeur',
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 13)),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        if (rating > 0) ...[
                          const Icon(Icons.star_rounded,
                              size: 16, color: AppColors.prime),
                          const SizedBox(width: 4),
                          Text(rating.toStringAsFixed(1),
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14)),
                        ],
                      ],
                    )
                  else
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.star_rounded,
                            size: 16, color: AppColors.prime),
                        const SizedBox(width: 4),
                        Text(rating > 0 ? rating.toStringAsFixed(1) : '-',
                            style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 14)),
                        const SizedBox(width: 4),
                        Text('· $totalReviews voyages',
                            style: const TextStyle(
                                color: Colors.white70, fontSize: 13)),
                      ],
                    ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // ── Apparence ──────────────────────────────────────
                  _SectionCard(
                    title: 'Apparence',
                    child: Column(
                      children: [
                        _ThemeTile(
                          label: 'Clair',
                          icon: Icons.light_mode_rounded,
                          selected: themeMode == ThemeMode.light,
                          onTap: () => ref.read(themeModeProvider.notifier).setThemeMode(ThemeMode.light),
                        ),
                        const Divider(height: 0),
                        _ThemeTile(
                          label: 'Sombre',
                          icon: Icons.dark_mode_rounded,
                          selected: themeMode == ThemeMode.dark,
                          onTap: () => ref.read(themeModeProvider.notifier).setThemeMode(ThemeMode.dark),
                        ),
                        const Divider(height: 0),
                        _ThemeTile(
                          label: 'Automatique (système)',
                          icon: Icons.brightness_auto_rounded,
                          selected: themeMode == ThemeMode.system,
                          onTap: () => ref.read(themeModeProvider.notifier).setThemeMode(ThemeMode.system),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  // ── Compte ─────────────────────────────────────────
                  _SectionCard(
                    title: 'Mon compte',
                    child: Column(
                      children: [
                        _MenuTile(
                            icon: Icons.person_rounded,
                            label: 'Informations personnelles',
                            onTap: () => _showInfoDialog(context, profile)),
                        const Divider(height: 0),
                        _MenuTile(
                            icon: Icons.verified_user_rounded,
                            label: 'Vérification d\'identité',
                            trailing: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: profile?.kycStatus == 'verified'
                                    ? AppColors.greenLight
                                    : profile?.kycStatus == 'pending'
                                        ? AppColors.primeBg
                                        : AppColors.coralLight,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                  profile?.kycStatus == 'verified'
                                      ? 'Vérifié'
                                      : profile?.kycStatus == 'pending'
                                          ? 'En cours'
                                          : 'Non vérifié',
                                  style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      color: profile?.kycStatus == 'verified'
                                          ? AppColors.greenDark
                                          : profile?.kycStatus == 'pending'
                                              ? AppColors.primeDark
                                              : AppColors.coral)),
                            ),
                            onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (_) =>
                                        const IdentityVerificationScreen()))),
                        const Divider(height: 0),
                        _MenuTile(
                            icon: Icons.notifications_rounded,
                            label: 'Préférences de notifications',
                            onTap: () => _showNotifPrefsSheet(context)),
                        const Divider(height: 0),
                        _MenuTile(
                            icon: Icons.lock_rounded,
                            label: 'Sécurité & mot de passe',
                            onTap: () => _showSecuritySheet(context)),
                        const Divider(height: 0),
                        _MenuTile(
                            icon: Icons.emergency_rounded,
                            label: 'Contact d\'urgence',
                            trailing: (profile?.emergencyContactPhone != null &&
                                    profile!.emergencyContactPhone!.isNotEmpty)
                                ? const Icon(Icons.check_circle,
                                    color: AppColors.green, size: 18)
                                : null,
                            onTap: () {
                              if (userId != null && userId.isNotEmpty) {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => EmergencyContactScreen(userId: userId),
                                  ),
                                );
                              }
                            }),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  // ── Paiements ──────────────────────────────────────
                  _SectionCard(
                    title: 'Paiements',
                    child: Column(
                      children: [
                        _MenuTile(
                            icon: Icons.account_balance_wallet_rounded,
                            label: 'Mes moyens de paiement',
                            onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Gestion des moyens de paiement bientôt disponible')))),
                        const Divider(height: 0),
                        _MenuTile(
                            icon: Icons.receipt_rounded,
                            label: 'Historique des paiements',
                            onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Historique des paiements bientôt disponible')))),
                        const Divider(height: 0),
                        _MenuTile(
                            icon: Icons.shield_rounded,
                            label: 'Cautions & remboursements',
                            onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (_) =>
                                        const CautionScreen()))),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  // ── Prime (chauffeurs seulement) ───────────────────
                  if (!isPassenger) ...[
                    _SectionCard(
                      title: 'Abonnement',
                      child: Column(
                        children: [
                          _MenuTile(
                              icon: Icons.workspace_premium_rounded,
                              label: 'Gérer mon abonnement Prime',
                              trailing: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: AppColors.primeBg,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: const Text('Actif',
                                    style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.primeDark)),
                              ),
                              onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (_) =>
                                          const SubscriptionScreen()))),
                          const Divider(height: 0),
                          _MenuTile(
                              icon: Icons.bar_chart_rounded,
                              label: 'Mes statistiques',
                              onTap: () => Navigator.push(context,
                                  MaterialPageRoute(builder: (_) => const DriverStatsScreen()))),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                  ],

                  // ── Support ────────────────────────────────────────
                  _SectionCard(
                    title: 'Support',
                    child: Column(
                      children: [
                        _MenuTile(
                            icon: Icons.help_rounded,
                            label: 'Aide & FAQ',
                            onTap: () => _showAboutSheet(context, faq: true)),
                        const Divider(height: 0),
                        _MenuTile(
                            icon: Icons.flag_rounded,
                            label: 'Signaler un problème',
                            onTap: () => _showReportSheet(context)),
                        const Divider(height: 0),
                        _MenuTile(
                            icon: Icons.info_rounded,
                            label: 'À propos de 237COVOIT',
                            onTap: () => _showAboutSheet(context)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () => _showLogoutDialog(context),
                      icon: const Icon(Icons.logout_rounded,
                          color: AppColors.coral),
                      label: const Text('Se déconnecter',
                          style: TextStyle(color: AppColors.coral)),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(
                            color: AppColors.coral.withValues(alpha: 0.4)),
                        padding:
                            const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showInfoDialog(BuildContext context, dynamic profile) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Informations personnelles'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Nom : ${profile?.lastName ?? '—'}'),
            const SizedBox(height: 8),
            Text('Prénom : ${profile?.firstName ?? '—'}'),
            const SizedBox(height: 8),
            Text('Téléphone : ${profile?.phone ?? '—'}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }

  void _showNotifPrefsSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Préférences de notifications',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('Notifications push'),
              value: true,
              onChanged: (_) {},
            ),
            SwitchListTile(
              title: const Text('Alertes par e-mail'),
              value: false,
              onChanged: (_) {},
            ),
            SwitchListTile(
              title: const Text('Rappels de trajet'),
              value: true,
              onChanged: (_) {},
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  void _showSecuritySheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Sécurité',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.lock_rounded),
              title: const Text('Changer le mot de passe'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Fonctionnalité bientôt disponible')),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.security_rounded),
              title: const Text('Authentification à 2 facteurs'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Fonctionnalité bientôt disponible')),
                );
              },
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  void _showReportSheet(BuildContext context) {
    final controller = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(ctx).viewInsets.bottom + 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Signaler un problème',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              maxLines: 4,
              decoration: const InputDecoration(
                hintText: 'Décrivez le problème rencontré...',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Signalement envoyé, merci !')),
                  );
                },
                child: const Text('Envoyer'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAboutSheet(BuildContext context, {bool faq = false}) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(faq ? 'Aide & FAQ' : 'À propos de 237COVOIT',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 16),
            if (faq) ...[
              const ExpansionTile(
                title: Text('Comment réserver un trajet ?'),
                children: [Padding(
                  padding: EdgeInsets.all(12),
                  child: Text('Recherchez un trajet, choisissez-en un et appuyez sur \"Réserver\".'),
                )],
              ),
              const ExpansionTile(
                title: Text('Comment annuler une réservation ?'),
                children: [Padding(
                  padding: EdgeInsets.all(12),
                  child: Text('Allez dans \"Mes trajets\" et appuyez sur \"Annuler\".'),
                )],
              ),
              const ExpansionTile(
                title: Text('Comment contacter le support ?'),
                children: [Padding(
                  padding: EdgeInsets.all(12),
                  child: Text('Via la section Support de votre profil ou par e-mail à support@237covoit.cm'),
                )],
              ),
            ] else ...[
              const Text('237COVOIT — Covoiturage au Cameroun'),
              const SizedBox(height: 8),
              const Text('Version 1.0.0'),
              const SizedBox(height: 8),
              const Text('© 2026 237COVOIT. Tous droits réservés.'),
            ],
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Se déconnecter ?'),
        content: const Text('Votre session sera fermée et le token révoqué.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Annuler')),
          Consumer(
            builder: (context, ref, _) => ElevatedButton(
              onPressed: () async {
                final authRepo = ref.read(authRepositoryProvider);
                await authRepo.logout();
                if (context.mounted) {
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                    (route) => false,
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.coral),
              child: const Text('Déconnecter'),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Widgets helpers ──────────────────────────────────────────────────────────

class _SectionCard extends StatelessWidget {
  final String title;
  final Widget child;
  const _SectionCard({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(title,
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: cs.onSurfaceVariant)),
        ),
        Card(child: child),
      ],
    );
  }
}

class _ThemeTile extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;
  const _ThemeTile(
      {required this.label, required this.icon,
       required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return ListTile(
      onTap: onTap,
      leading: Icon(icon,
          color: selected ? AppColors.green : cs.onSurfaceVariant, size: 20),
      title: Text(label,
          style: TextStyle(
              fontSize: 14,
              fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
              color: selected ? AppColors.green : cs.onSurface)),
      trailing: selected
          ? const Icon(Icons.check_circle_rounded,
              color: AppColors.green, size: 20)
          : null,
      dense: true,
    );
  }
}

class _MenuTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Widget? trailing;
  const _MenuTile(
      {required this.icon, required this.label,
       required this.onTap, this.trailing});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return ListTile(
      onTap: onTap,
      leading: Icon(icon, color: cs.onSurfaceVariant, size: 20),
      title: Text(label,
          style: TextStyle(fontSize: 14, color: cs.onSurface)),
      trailing: trailing ??
          Icon(Icons.chevron_right_rounded,
              color: cs.onSurfaceVariant, size: 20),
      dense: true,
    );
  }
}
