import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../app_theme.dart';
import '../core/constants/api_endpoints.dart';
import '../core/network/api_client_provider.dart';
import '../data/providers/user_providers.dart';

class EmergencyContactScreen extends ConsumerStatefulWidget {
  final String userId;

  const EmergencyContactScreen({super.key, required this.userId});

  @override
  ConsumerState<EmergencyContactScreen> createState() =>
      _EmergencyContactScreenState();
}

class _EmergencyContactScreenState
    extends ConsumerState<EmergencyContactScreen> {
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  bool _loading = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _loadContact();
  }

  Future<void> _loadContact() async {
    setState(() => _loading = true);
    try {
      final client = ref.read(apiClientProvider);
      final data = await client.get(
        ApiEndpoints.emergencyContact(widget.userId),
      );
      _nameCtrl.text = data['emergency_contact_name'] ?? '';
      _phoneCtrl.text = data['emergency_contact_phone'] ?? '';
    } catch (_) {
      // Pas encore configuré — on laisse vide
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _save() async {
    final name = _nameCtrl.text.trim();
    final phone = _phoneCtrl.text.trim();
    if (name.isEmpty || phone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez remplir tous les champs')),
      );
      return;
    }
    if (name.length < 2 || name.length > 60) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Le nom doit contenir entre 2 et 60 caractères.')),
      );
      return;
    }
    final cleaned = phone.replaceAll(RegExp(r'[\s\-\(\)]'), '');
    final intl = RegExp(r'^\+?237[6-9]\d{8}$');
    final local = RegExp(r'^[6-9]\d{8}$');
    if (!intl.hasMatch(cleaned) && !local.hasMatch(cleaned)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Numéro invalide. Exemple : +237 6XX XXX XXX')),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      final client = ref.read(apiClientProvider);
      await client.put(
        ApiEndpoints.emergencyContact(widget.userId),
        data: {
          'emergency_contact_name': name,
          'emergency_contact_phone': phone,
        },
      );
      ref.invalidate(userProfileProvider(widget.userId));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Contact d\'urgence enregistré ✓')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur : $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Contact d\'urgence')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Explication ───────────────────────────────────
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.coral.withAlpha(25),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: AppColors.coral.withAlpha(80)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.security_rounded,
                            color: AppColors.coral, size: 28),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Ce contact recevra votre position GPS toutes les heures pendant vos trajets pour votre sécurité.',
                            style: TextStyle(
                              fontSize: 13,
                              color: cs.onSurface,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),

                  // ── Nom du contact ────────────────────────────────
                  Text('Nom du contact',
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: cs.onSurface)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _nameCtrl,
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(
                      hintText: 'Ex: Maman, Papa, Ami(e)...',
                      prefixIcon: Icon(Icons.person_rounded),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // ── Numéro de téléphone ───────────────────────────
                  Text('Numéro de téléphone',
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: cs.onSurface)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _phoneCtrl,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                      hintText: 'Ex: +237 6XX XXX XXX',
                      prefixIcon: Icon(Icons.phone_rounded),
                    ),
                  ),
                  const SizedBox(height: 40),

                  // ── Bouton sauvegarder ────────────────────────────
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: _saving ? null : _save,
                      icon: _saving
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white),
                            )
                          : const Icon(Icons.save_rounded),
                      label: Text(
                          _saving ? 'Enregistrement...' : 'Enregistrer'),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
