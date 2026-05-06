/// Contrat d'URL vers le backend AfriGo (architecture microservices).
///
/// ┌─────────────────────────────────────────────────────────────────────┐
/// │  Flutter → API Gateway (localhost:8000)                             │
/// │                                                                     │
/// │  /api/auth/*     → proxy → auth-service:8001                        │
/// │  /api/users/*    → proxy → user-service:8002                        │
/// │  /api/trips/*    → proxy → trip-service:8003                        │
/// │  /api/bookings/* → proxy → booking-service:8004                     │
/// │  /api/payments/* → proxy → payment-service:8006                     │
/// └─────────────────────────────────────────────────────────────────────┘
///
/// Flutter ne parle QU'AU GATEWAY sur le port 8000.
/// Les ports 8001–8006 sont internes à Docker (communication inter-services).
/// En prod, le gateway est derrière un reverse proxy (nginx/caddy) avec SSL.
///
/// Environnements :
///   dev  → `flutter run`                                  → localhost:8000
///   prod → `flutter build apk --dart-define=PROD=true`   → api.afrigo.cm
class ApiEndpoints {
  ApiEndpoints._();

  static const String _prodGatewayUrl = 'https://api.AfriGo.cm';
  static const String _devGatewayUrl = 'http://192.168.45.54:8000';

  // ── Gateway base URL ──────────────────────────────────────────────────────
  static const String gatewayUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: bool.fromEnvironment('PROD') ? _prodGatewayUrl : _devGatewayUrl,
  );

  // ── Préfixes par microservice (tels que définis dans gateway/app/main.py) ─
  // app.include_router(auth.router,     prefix="/api/auth")
  // app.include_router(users.router,    prefix="/api/users")
  // app.include_router(trips.router,    prefix="/api/trips")
  // app.include_router(bookings.router, prefix="/api/bookings")
  // app.include_router(payments.router, prefix="/api/payments")
  static const String _auth     = '/api/auth';
  static const String _users    = '/api/users';
  static const String _trips    = '/api/trips';
  static const String _bookings = '/api/bookings';
  static const String _payments = '/api/payments';

  // ═══════════════════════════════════════════════════════════════════════════
  // AUTH SERVICE  (gateway → auth-service:8001)
  // ═══════════════════════════════════════════════════════════════════════════
  // POST   $_auth/login          → connexion (email + password)
  // POST   $_auth/register       → inscription
  // POST   $_auth/logout         → révocation token (blacklist Redis)
  // POST   $_auth/refresh        → obtenir un nouvel access token
  // GET    $_auth/me             → profil de l'utilisateur connecté
  // POST   $_auth/forgot-password → demande de réinitialisation de mot de passe
  // POST   $_auth/reset-password  → réinitialisation du mot de passe avec token
  static const String login           = '$_auth/login';
  static const String register        = '$_auth/register';
  static const String logout          = '$_auth/logout';
  static const String refreshToken    = '$_auth/refresh';
  static const String me              = '$_auth/me';
  static const String forgotPassword  = '$_auth/forgot-password';
  static const String resetPassword   = '$_auth/reset-password';

  // ═══════════════════════════════════════════════════════════════════════════
  // USER SERVICE  (gateway → user-service:8002)
  // ═══════════════════════════════════════════════════════════════════════════
  // Gateway actuel :
  // GET/PATCH $_users/profile/{id}        → profil public / mise à jour
  // PUT       $_users/profile/{id}        → mise à jour avec photo
  // POST      $_users/profile/{id}/photo  → upload photo de profil
  // GET       $_users/profile/{id}/driver → fiche chauffeur publique
  static String userProfile(String id) => '$_users/profile/$id';
  static String updateProfile(String id) => '$_users/profile/$id';
  static String uploadProfilePhoto(String id) => '$_users/profile/$id/photo';
  static String userById(String id) => '$_users/profile/$id';
  static String driverPublicProfile(String id) => '$_users/profile/$id/driver';

  // ── Vehicles ──────────────────────────────────────────────────────────────
  static String vehicles(String userId) => '$_users/profile/$userId/vehicles';
  static String vehicleById(String userId, String vehicleId) =>
      '$_users/profile/$userId/vehicles/$vehicleId';
  static String vehiclePhotos(String userId, String vehicleId) =>
      '$_users/profile/$userId/vehicles/$vehicleId/photos';
  static String vehiclePhotoById(String userId, String vehicleId, String photoId) =>
      '$_users/profile/$userId/vehicles/$vehicleId/photos/$photoId';
  static String vehiclePhotoFile(String filename) =>
      '$_users/uploads/vehicles/$filename';

  // ── Contact d'urgence ─────────────────────────────────────────────────────
  static String emergencyContact(String userId) =>
      '$_users/profile/$userId/emergency-contact';

  // ── KYC — Vérification d'identité ────────────────────────────────────────
  static String kycStatus(String userId) => '$_users/profile/$userId/kyc';
  static String verifyKYC(String userId) => '$_users/profile/$userId/kyc/verify';

  // ── Uploads — Servir les fichiers uploadés ───────────────────────────────
  static String profilePhotoFile(String filename) => '$_users/uploads/profiles/$filename';
  static String kycPhotoFile(String filename) => '$_users/uploads/kyc/$filename';

  // ═══════════════════════════════════════════════════════════════════════════
  // TRIP SERVICE  (gateway → trip-service:8003)
  // ═══════════════════════════════════════════════════════════════════════════
  // GET    $_trips                       → liste paginée (accès public)
  // GET    $_trips/search?from=&to=&date= → recherche (accès public)
  // POST   $_trips                       → publier un trajet (chauffeur)
  // GET    $_trips/mine                  → mes trajets publiés (chauffeur)
  // GET    $_trips/{id}                  → détail (accès public)
  // PUT    $_trips/{id}                  → modifier un trajet
  // DELETE $_trips/{id}                  → supprimer
  // POST   $_trips/{id}/cancel           → annuler
  // GET    $_trips/{id}/passengers       → passagers d'un trajet
  static const String trips           = _trips;
  static const String searchTrips     = '$_trips/search';
  static const String myDriverTrips   = '$_trips/mine';
  static String driverTrips(String driverId) => '$_trips/driver/$driverId';
  static String tripById(String id)          => '$_trips/$id';
  static String cancelTrip(String id)        => '$_trips/$id/cancel';
  static String tripPassengers(String id)    => '$_trips/$id/passengers';
  static const String popularRoutes          = '$_trips/popular';

  // ═══════════════════════════════════════════════════════════════════════════
  // BOOKING SERVICE  (gateway → booking-service:8004)
  // ═══════════════════════════════════════════════════════════════════════════
  // POST   $_bookings                    → créer une réservation (passager)
  // GET    $_bookings/mine               → mes réservations (passager)
  // GET    $_bookings/{id}               → détail réservation
  // POST   $_bookings/{id}/cancel        → annuler une réservation
  // POST   $_bookings/{id}/confirm       → chauffeur confirme un passager
  // POST   $_bookings/{id}/rate          → noter après le trajet
  static const String bookings           = _bookings;
  static String passengerBookings(String passengerId) => '$_bookings/passenger/$passengerId';
  static String tripBookings(String tripId) => '$_bookings/trip/$tripId';
  static String bookingById(String id)   => '$_bookings/$id';
  static String cancelBooking(String id) => '$_bookings/$id/cancel';
  static String confirmBooking(String id)=> '$_bookings/$id/confirm';
  static String acceptBooking(String id) => '$_bookings/$id/accept';
  static String rejectBooking(String id) => '$_bookings/$id/reject';
  static String rateBooking(String id)   => '$_bookings/$id/rate';

  // ── Boarding / Vérification embarquement ──────────────────────────────
  static String boardingCode(String bookingId) => '$_bookings/$bookingId/boarding-code';
  static String verifyBoarding(String bookingId) => '$_bookings/$bookingId/verify-boarding';
  static String tripBoardingStatus(String tripId) => '$_bookings/trip/$tripId/boarding-status';

  // ═══════════════════════════════════════════════════════════════════════════
  // PAYMENT SERVICE  (gateway → payment-service:8006)
  // ═══════════════════════════════════════════════════════════════════════════
  // POST   $_payments/initiate           → déclencher paiement MTN/Orange
  // POST   $_payments/verify             → vérifier statut après callback
  // GET    $_payments/history            → historique paiements
  // GET    $_payments/{id}/status        → statut d'un paiement spécifique
  static const String initPayment        = '$_payments/initiate';
  static const String verifyPayment      = '$_payments/verify';
  static const String paymentHistory     = '$_payments/history';
  static String paymentStatus(String id) => '$_payments/$id/status';

  // ═══════════════════════════════════════════════════════════════════════════
  // NOTIFICATION SERVICE  (gateway → notification-service:8005)
  // ═══════════════════════════════════════════════════════════════════════════
  static const String _notifications = '/api/notifications';
  static String userNotifications(String userId) => '$_notifications/user/$userId';
  static const String createNotification = _notifications;
  static String markNotificationRead(String id) => '$_notifications/$id/read';
  static String markAllNotificationsRead(String userId) => '$_notifications/user/$userId/read-all';

  // ═══════════════════════════════════════════════════════════════════════════
  // CHAT SERVICE  (gateway → chat-service:8007)
  // ═══════════════════════════════════════════════════════════════════════════
  static const String _chat = '/api/chat';
  static String chatRoom(String tripId, String user1, String user2) =>
      '$_chat/room/trip/$tripId/users/$user1/$user2';
  static String chatMessages(String roomId) => '$_chat/room/$roomId/messages';
  static String sendChatMessage(String roomId) => '$_chat/room/$roomId/messages';
  static String markChatRead(String roomId, String userId) => '$_chat/room/$roomId/read/$userId';
  static String userChatRooms(String userId) => '$_chat/user/$userId/rooms';

  // ═══════════════════════════════════════════════════════════════════════════
  // SUBSCRIPTION SERVICE  (gateway → subscription-service:8008)
  // ═══════════════════════════════════════════════════════════════════════════
  static const String _subscriptions = '/api/subscriptions';
  static const String subscriptionPlans = '$_subscriptions/plans';
  static const String subscribe = '$_subscriptions/subscribe';
  static String userSubscription(String userId) => '$_subscriptions/user/$userId';
  static String subscriptionHistory(String userId) => '$_subscriptions/user/$userId/history';
  static String cancelSubscription(String userId) => '$_subscriptions/user/$userId/cancel';

  // ═══════════════════════════════════════════════════════════════════════════
  // CAUTION SERVICE  (gateway → caution-service:8009)
  // ═══════════════════════════════════════════════════════════════════════════
  static const String _cautions = '/api/cautions';
  static String userCautions(String userId) => '$_cautions/user/$userId';
  static String cautionSummary(String userId) => '$_cautions/user/$userId/summary';
  static const String createCaution = _cautions;
  static String refundCaution(String id) => '$_cautions/$id/refund';
  static String retainCaution(String id) => '$_cautions/$id/retain';

  // ═══════════════════════════════════════════════════════════════════════════
  // FORUM SERVICE  (gateway → forum-service:8010)
  // ═══════════════════════════════════════════════════════════════════════════
  static const String _forum = '/api/forum';
  static const String forumPosts = '$_forum/posts';
  static String forumPostById(String id) => '$_forum/posts/$id';
  static String forumPostComments(String postId) => '$_forum/posts/$postId/comments';
  static String forumPostLike(String postId) => '$_forum/posts/$postId/like';

  // ═══════════════════════════════════════════════════════════════════════════
  // TRACKING SERVICE  (gateway → tracking-service:8011)
  // ═══════════════════════════════════════════════════════════════════════════
  static const String _tracking = '/api/tracking';
  static const String startTracking = '$_tracking/start';
  static String tripTracking(String tripId) => '$_tracking/trip/$tripId';
  static String updateTrackingPosition(String tripId) => '$_tracking/trip/$tripId/position';
  static String updateTrackingStep(String tripId, String stepId) => '$_tracking/trip/$tripId/step/$stepId';
  static String completeTracking(String tripId) => '$_tracking/trip/$tripId/complete';
  static String safetyLocation(String tripId) => '$_tracking/trip/$tripId/safety-location';

  // ═══════════════════════════════════════════════════════════════════════════
  // GATEWAY — Routes directes (pas de proxy microservice)
  // ═══════════════════════════════════════════════════════════════════════════
  static const String healthCheck = '/health';

  // ═══════════════════════════════════════════════════════════════════════════
  // WEBSOCKET — Temps réel (chat, tracking, notifications)
  // ═══════════════════════════════════════════════════════════════════════════
  static const String _wsDevUrl  = 'ws://192.168.45.54:8000';
  static const String _wsProdUrl = 'wss://api.AfriGo.cm';
  static const String wsBaseUrl = String.fromEnvironment(
    'WS_BASE_URL',
    defaultValue: bool.fromEnvironment('PROD') ? _wsProdUrl : _wsDevUrl,
  );

  static String wsChat(String roomId, String token) =>
      '$wsBaseUrl/ws/chat/$roomId?token=$token';
  static String wsTracking(String tripId, String token) =>
      '$wsBaseUrl/ws/tracking/$tripId?token=$token';
  static String wsNotifications(String token) =>
      '$wsBaseUrl/ws/notifications?token=$token';

  // ── Routes publiques (pas besoin de JWT) ─────────────────────────────────
  /// Ces routes ne reçoivent PAS d'Authorization header (voir AuthInterceptor).
  static const Set<String> publicRoutes = {
    login,
    register,
    refreshToken,
    forgotPassword,
    resetPassword,
    trips,
    searchTrips,
    healthCheck,
  };
}
