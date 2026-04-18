/// Constantes globales de l'application AfriGo.
/// Toutes les valeurs fixes non-réseau sont ici.
class AppConstants {
  AppConstants._();

  // ── Nom de l'app ──────────────────────────────────────────────────────────
  static const String appName = 'AfriGo';

  // ── Stockage sécurisé — clés ──────────────────────────────────────────────
  static const String keyAccessToken  = 'access_token';
  static const String keyRefreshToken = 'refresh_token';
  static const String keyUserRole     = 'user_role';   // 'passager' | 'chauffeur'
  static const String keyUserId       = 'user_id';

  // ── SharedPreferences — clés ──────────────────────────────────────────────
  static const String keyOnboardingDone = 'onboarding_done';
  static const String keyThemeMode      = 'theme_mode';

  // ── Réseau ────────────────────────────────────────────────────────────────
  static const Duration connectTimeout = Duration(seconds: 15);
  static const Duration receiveTimeout = Duration(seconds: 30);
  static const int     maxRetries      = 2;

  // ── Caution ───────────────────────────────────────────────────────────────
  static const int cautionAmountFcfa = 500;

  // ── Pagination ────────────────────────────────────────────────────────────
  static const int defaultPageSize = 20;

  // ── Villes du Cameroun (autocomplete local, fallback si offline) ──────────
  static const List<String> cameroonCities = [
    'Douala', 'Yaoundé', 'Bafoussam', 'Bamenda', 'Limbé',
    'Kribi', 'Bertoua', 'Ngaoundéré', 'Garoua', 'Maroua',
    'Kumba', 'Buéa', 'Edéa', 'Nkongsamba', 'Ebolowa',
    'Dschang', 'Foumban', 'Bafang', 'Mbouda', 'Mbalmayo',
  ];
}
