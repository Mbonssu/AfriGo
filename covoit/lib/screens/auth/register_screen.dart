import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app_theme.dart';
import '../../core/errors/exceptions.dart';
import '../../data/providers/auth_providers.dart';
import '../driver/driver_home.dart';
import '../passenger/passenger_home.dart';
import 'login_screen.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _pageCtrl = PageController();
  final _step2FormKey = GlobalKey<FormState>();
  final _fullNameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmPasswordCtrl = TextEditingController();

  int _step = 0;
  String _role = 'passager';
  bool _isPrime = false;
  bool _loading = false;

  @override
  void dispose() {
    _pageCtrl.dispose();
    _fullNameCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmPasswordCtrl.dispose();
    super.dispose();
  }

  void _nextStep() {
    if (_step >= 2) return;
    setState(() => _step++);
    _pageCtrl.nextPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _nextFromStep2() {
    if (!_step2FormKey.currentState!.validate()) return;
    _nextStep();
  }

  Future<void> _submitRegistration() async {
    setState(() => _loading = true);

    try {
      final authRepository = ref.read(authRepositoryProvider);
      final session = await authRepository.register(
        email: _emailCtrl.text.trim(),
        password: _passwordCtrl.text,
        phone: _phoneCtrl.text.trim(),
        role: _role,
      );

      final nameParts = _fullNameCtrl.text.trim().split(RegExp(r'\s+'));
      final firstName = nameParts.isNotEmpty ? nameParts.first : '';
      final lastName =
          nameParts.length > 1 ? nameParts.sublist(1).join(' ') : '';

      try {
        await authRepository.updateUserProfile(
          userId: session.userId,
          firstName: firstName,
          lastName: lastName,
          phone: _phoneCtrl.text.trim(),
        );
      } catch (_) {
        // L'inscription doit rester réussie même si le profil enrichi échoue.
      }

      if (!mounted) return;

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (_) => session.isDriver
              ? const DriverHome()
              : const PassengerHome(startAuthenticated: true),
        ),
        (_) => false,
      );
    } on AppException catch (error) {
      _showError(error.message);
    } catch (_) {
      _showError('Inscription impossible pour le moment.');
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppColors.coral),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Inscription — Étape ${_step + 1}/3'),
        automaticallyImplyLeading: false,
        leading: _step > 0
            ? BackButton(
                onPressed: () {
                  setState(() => _step--);
                  _pageCtrl.previousPage(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                  );
                },
              )
            : null,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(4),
          child: LinearProgressIndicator(
            value: (_step + 1) / 3,
            backgroundColor: Colors.white.withValues(alpha: 0.24),
            valueColor: const AlwaysStoppedAnimation(Colors.white),
          ),
        ),
      ),
      body: PageView(
        controller: _pageCtrl,
        physics: const NeverScrollableScrollPhysics(),
        children: [
          _Step1(
            selectedRole: _role,
            isPrime: _isPrime,
            onRoleChanged: (role) => setState(() => _role = role),
            onPrimeChanged: (value) => setState(() => _isPrime = value),
            onNext: _nextStep,
          ),
          _Step2(
            formKey: _step2FormKey,
            fullNameCtrl: _fullNameCtrl,
            phoneCtrl: _phoneCtrl,
            emailCtrl: _emailCtrl,
            passwordCtrl: _passwordCtrl,
            confirmPasswordCtrl: _confirmPasswordCtrl,
            onNext: _nextFromStep2,
          ),
          _Step3(
            role: _role,
            isPrime: _isPrime,
            fullName: _fullNameCtrl.text.trim(),
            email: _emailCtrl.text.trim(),
            phone: _phoneCtrl.text.trim(),
            loading: _loading,
            onFinish: _submitRegistration,
          ),
        ],
      ),
    );
  }
}

class _Step1 extends StatelessWidget {
  final String selectedRole;
  final bool isPrime;
  final ValueChanged<String> onRoleChanged;
  final ValueChanged<bool> onPrimeChanged;
  final VoidCallback onNext;

  const _Step1({
    required this.selectedRole,
    required this.isPrime,
    required this.onRoleChanged,
    required this.onPrimeChanged,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Qui êtes-vous ?',
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w800,
              color: cs.onSurface,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Choisissez votre profil pour continuer.',
            style: TextStyle(color: cs.onSurfaceVariant, fontSize: 14),
          ),
          const SizedBox(height: 28),
          _ProfileCard(
            icon: Icons.person_rounded,
            title: 'Passager',
            subtitle: 'Recherchez et réservez des trajets',
            selected: selectedRole == 'passager',
            onTap: () {
              onRoleChanged('passager');
              onPrimeChanged(false);
            },
          ),
          const SizedBox(height: 12),
          _ProfileCard(
            icon: Icons.drive_eta_rounded,
            title: 'Chauffeur Simple',
            subtitle: 'Proposez des trajets — caution 500F/place requise',
            selected: selectedRole == 'chauffeur' && !isPrime,
            onTap: () {
              onRoleChanged('chauffeur');
              onPrimeChanged(false);
            },
            badge: 'GRATUIT',
            badgeColor: AppColors.green,
          ),
          const SizedBox(height: 12),
          _ProfileCard(
            icon: Icons.workspace_premium_rounded,
            title: 'Chauffeur Prime',
            subtitle: 'Visibilité maximale, forum exclusif, priorité dans les recherches',
            selected: selectedRole == 'chauffeur' && isPrime,
            onTap: () {
              onRoleChanged('chauffeur');
              onPrimeChanged(true);
            },
            badge: 'ABONNEMENT',
            badgeColor: AppColors.prime,
            highlight: true,
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onNext,
              child: const Text('Continuer'),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Déjà un compte ? ',
                style: TextStyle(color: cs.onSurfaceVariant),
              ),
              GestureDetector(
                onTap: () => Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                ),
                child: Text(
                  'Se connecter',
                  style: TextStyle(
                    color: cs.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Step2 extends StatefulWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController fullNameCtrl;
  final TextEditingController phoneCtrl;
  final TextEditingController emailCtrl;
  final TextEditingController passwordCtrl;
  final TextEditingController confirmPasswordCtrl;
  final VoidCallback onNext;

  const _Step2({
    required this.formKey,
    required this.fullNameCtrl,
    required this.phoneCtrl,
    required this.emailCtrl,
    required this.passwordCtrl,
    required this.confirmPasswordCtrl,
    required this.onNext,
  });

  @override
  State<_Step2> createState() => _Step2State();
}

class _Step2State extends State<_Step2> {
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: widget.formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Informations\npersonnelles',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w800,
                color: cs.onSurface,
                height: 1.2,
              ),
            ),
            const SizedBox(height: 24),
            const _FieldLabel('Nom complet'),
            const SizedBox(height: 8),
            TextFormField(
              controller: widget.fullNameCtrl,
              decoration: const InputDecoration(
                hintText: 'Jean Mbarga',
                prefixIcon: Icon(Icons.badge_rounded, size: 20),
              ),
              validator: (value) {
                final name = value?.trim() ?? '';
                if (name.isEmpty) return 'Entrez votre nom complet.';
                if (name.length < 3) return 'Le nom doit contenir au moins 3 caractères.';
                if (name.length > 60) return 'Nom trop long (max. 60 caractères).';
                if (!RegExp(r"^[a-zA-ZÀ-ÿ\s\-']+$").hasMatch(name)) {
                  return 'Le nom ne doit contenir que des lettres.';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            const _FieldLabel('Numéro de téléphone'),
            const SizedBox(height: 8),
            TextFormField(
              controller: widget.phoneCtrl,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                hintText: '+237 6XX XXX XXX',
                prefixIcon: Icon(Icons.phone_rounded, size: 20),
              ),
              validator: (value) {
                final phone = value?.trim() ?? '';
                if (phone.isEmpty) return 'Entrez votre numéro de téléphone.';
                final cleaned = phone.replaceAll(RegExp(r'[\s\-\(\)]'), '');
                final intl = RegExp(r'^\+?237[6-9]\d{8}$');
                final local = RegExp(r'^[6-9]\d{8}$');
                if (!intl.hasMatch(cleaned) && !local.hasMatch(cleaned)) {
                  return 'Format invalide. Exemple : +237 6XX XXX XXX';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            const _FieldLabel('Email'),
            const SizedBox(height: 8),
            TextFormField(
              controller: widget.emailCtrl,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                hintText: 'jean@email.com',
                prefixIcon: Icon(Icons.email_rounded, size: 20),
              ),
              validator: (value) {
                final email = value?.trim() ?? '';
                if (email.isEmpty) return 'Entrez votre adresse email.';
                final regex = RegExp(r'^[a-zA-Z0-9._%+\-]+@[a-zA-Z0-9.\-]+\.[a-zA-Z]{2,}$');
                if (!regex.hasMatch(email)) return 'Adresse email invalide.';
                return null;
              },
            ),
            const SizedBox(height: 16),
            const _FieldLabel('Mot de passe'),
            const SizedBox(height: 8),
            TextFormField(
              controller: widget.passwordCtrl,
              obscureText: _obscurePassword,
              decoration: InputDecoration(
                hintText: '••••••••',
                prefixIcon: const Icon(Icons.lock_rounded, size: 20),
                suffixIcon: IconButton(
                  onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                  icon: Icon(
                    _obscurePassword ? Icons.visibility_rounded : Icons.visibility_off_rounded,
                    size: 20,
                  ),
                ),
              ),
              validator: (value) {
                final pwd = value ?? '';
                if (pwd.length < 8) return 'Min. 8 caractères requis.';
                if (!pwd.contains(RegExp(r'[A-Z]'))) return 'Au moins 1 majuscule requise.';
                if (!pwd.contains(RegExp(r'[0-9]'))) return 'Au moins 1 chiffre requis.';
                if (!pwd.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>\-_]'))) {
                  return 'Au moins 1 caractère spécial requis (!@#\$...).';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            const _FieldLabel('Confirmer le mot de passe'),
            const SizedBox(height: 8),
            TextFormField(
              controller: widget.confirmPasswordCtrl,
              obscureText: _obscureConfirmPassword,
              decoration: InputDecoration(
                hintText: '••••••••',
                prefixIcon: const Icon(Icons.lock_outline_rounded, size: 20),
                suffixIcon: IconButton(
                  onPressed: () => setState(
                    () => _obscureConfirmPassword = !_obscureConfirmPassword,
                  ),
                  icon: Icon(
                    _obscureConfirmPassword
                        ? Icons.visibility_rounded
                        : Icons.visibility_off_rounded,
                    size: 20,
                  ),
                ),
              ),
              validator: (value) {
                if (value != widget.passwordCtrl.text) {
                  return 'Les mots de passe ne correspondent pas.';
                }
                return null;
              },
            ),
            const SizedBox(height: 28),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.greenLight,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.security_rounded, color: AppColors.green, size: 18),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Vos données sont protégées. Le compte est créé immédiatement puis enrichi avec votre profil.',
                      style: TextStyle(fontSize: 12, color: AppColors.greenDark, height: 1.5),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: widget.onNext,
                child: const Text('Continuer'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Step3 extends StatelessWidget {
  final String role;
  final bool isPrime;
  final String fullName;
  final String email;
  final String phone;
  final bool loading;
  final Future<void> Function() onFinish;

  const _Step3({
    required this.role,
    required this.isPrime,
    required this.fullName,
    required this.email,
    required this.phone,
    required this.loading,
    required this.onFinish,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDriver = role == 'chauffeur';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Vérification\nd\'identité',
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w800,
              color: cs.onSurface,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Dernière étape avant la création du compte.',
            style: TextStyle(color: cs.onSurfaceVariant, fontSize: 14),
          ),
          const SizedBox(height: 20),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Résumé du compte',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: cs.onSurface,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _SummaryRow(label: 'Profil', value: isDriver ? 'Chauffeur' : 'Passager'),
                  _SummaryRow(label: 'Nom', value: fullName),
                  _SummaryRow(label: 'Email', value: email),
                  _SummaryRow(label: 'Téléphone', value: phone),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          const _DocUploadTile(
            icon: Icons.badge_rounded,
            title: 'CNI / Passeport',
            subtitle: 'Recto + verso',
          ),
          const SizedBox(height: 12),
          const _DocUploadTile(
            icon: Icons.phone_android_rounded,
            title: 'Photo de profil',
            subtitle: 'Selfie clair et récent',
          ),
          if (isDriver) ...[
            const SizedBox(height: 12),
            const _DocUploadTile(
              icon: Icons.directions_car_rounded,
              title: 'Carte grise du véhicule',
              subtitle: 'Document officiel requis',
            ),
            const SizedBox(height: 12),
            const _DocUploadTile(
              icon: Icons.card_membership_rounded,
              title: 'Permis de conduire',
              subtitle: 'En cours de validité',
            ),
          ],
          if (isDriver && isPrime) ...[
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primeBg,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.prime.withValues(alpha: 0.4), width: 1),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.workspace_premium_rounded, color: AppColors.prime, size: 20),
                      SizedBox(width: 8),
                      Text(
                        'Abonnement Prime',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primeDark,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Le compte chauffeur sera créé maintenant. L’activation Prime pourra ensuite être finalisée via le paiement d’abonnement.',
                    style: TextStyle(fontSize: 12, color: AppColors.primeDark, height: 1.7),
                  ),
                ],
              ),
            ),
          ],
          if (!isDriver) ...[
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.coralLight,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.info_rounded, color: AppColors.coral, size: 18),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Caution de 500 FCFA par réservation requise. Elle est remboursée si le chauffeur annule.',
                      style: TextStyle(fontSize: 12, color: AppColors.coral, height: 1.5),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 28),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: loading ? null : onFinish,
              child: loading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : Text(
                      isPrime ? 'Créer le compte & poursuivre Prime' : 'Terminer l\'inscription',
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;
  final String? badge;
  final Color? badgeColor;
  final bool highlight;

  const _ProfileCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
    this.badge,
    this.badgeColor,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: selected
              ? (highlight
                  ? AppColors.prime.withValues(alpha: 0.08)
                  : AppColors.green.withValues(alpha: 0.06))
              : cs.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected
                ? (highlight ? AppColors.prime : AppColors.green)
                : cs.outline.withValues(alpha: 0.5),
            width: selected ? 2 : 0.5,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: selected
                    ? (highlight
                        ? AppColors.prime.withValues(alpha: 0.15)
                        : AppColors.greenLight)
                    : cs.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: selected
                    ? (highlight ? AppColors.prime : AppColors.green)
                    : cs.onSurfaceVariant,
                size: 24,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: cs.onSurface,
                        ),
                      ),
                      if (badge != null) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: badgeColor!.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            badge!,
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              color: badgeColor,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant, height: 1.4),
                  ),
                ],
              ),
            ),
            if (selected)
              Icon(
                Icons.check_circle_rounded,
                color: highlight ? AppColors.prime : AppColors.green,
                size: 22,
              ),
          ],
        ),
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  final String label;

  const _FieldLabel(this.label);

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: Theme.of(context).colorScheme.onSurface,
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;

  const _SummaryRow({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          SizedBox(
            width: 90,
            child: Text(
              label,
              style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
            ),
          ),
          Expanded(
            child: Text(
              value.isEmpty ? 'Non renseigné' : value,
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: cs.onSurface),
            ),
          ),
        ],
      ),
    );
  }
}

class _DocUploadTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _DocUploadTile({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cs.outline.withValues(alpha: 0.5), width: 0.8),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: cs.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: AppColors.green, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: cs.onSurface),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
                ),
              ],
            ),
          ),
          OutlinedButton(
            onPressed: () {},
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            child: const Text('Ajouter'),
          ),
        ],
      ),
    );
  }
}
