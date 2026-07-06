class AppConstants {
  static const String appName    = 'Hobby Watch';
  static const String appVersion = '1.0.0';

  // ── API BASE URL ──────────────────────────────────────────────────────────
  static const String baseUrl = 'https://hobby-watch-apis.onrender.com/api';

  // ── Storage keys ──────────────────────────────────────────────────────────
  static const String keyAccessToken  = 'access_token';
  static const String keyRefreshToken = 'refresh_token';
  static const String keyUser         = 'user_data';
  static const String keyOnboarded    = 'onboarded';

  // ── Business logic ────────────────────────────────────────────────────────
  static const double ebayFeePercent      = 12.9;
  static const double defaultTargetMargin = 30.0;

  // ── Timeouts ─────────────────────────────────────────────────────────────
  static const int connectTimeout = 30000;
  static const int receiveTimeout = 30000;
}

class AppStrings {
  static const String tagline      = 'Know when to sell. Every time.';
  static const String noCards      = 'No cards yet.\nTap + to add your first card.';
  static const String targetReached = '🎯 Target reached! Time to sell.';
}
