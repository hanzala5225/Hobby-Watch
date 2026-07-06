import 'package:dio/dio.dart';
import 'package:get/get.dart' hide Response;
import 'package:logger/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../app/utils/app_constants.dart';
import '../models/auth_model.dart';
import '../models/card_model.dart';
import '../models/ebay_result_model.dart';

class ApiService extends GetxService {
  late final Dio _dio;
  final _log = Logger();

  @override
  void onInit() {
    super.onInit();
    _dio = Dio(BaseOptions(
      baseUrl: AppConstants.baseUrl,
      connectTimeout: const Duration(milliseconds: AppConstants.connectTimeout),
      receiveTimeout: const Duration(milliseconds: AppConstants.receiveTimeout),
      headers: {'Content-Type': 'application/json'},
    ));

    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final prefs = await SharedPreferences.getInstance();
        final token = prefs.getString(AppConstants.keyAccessToken);
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        return handler.next(options);
      },
      onError: (DioException e, handler) async {
        if (e.response?.statusCode == 401) {
          // Skip force-logout for these endpoints — pre-login or fire-and-forget
          final path = e.requestOptions.path;
          if (path.contains('/auth/fcm-token') ||
              path.contains('/auth/login') ||
              path.contains('/auth/register') ||
              path.contains('/auth/refresh') ||
              path.contains('/auth/reset-password')) {
            return handler.next(e);
          }

          // Try silent token refresh
          final refreshed = await _tryRefreshToken();
          if (refreshed) {
            final prefs = await SharedPreferences.getInstance();
            final newToken = prefs.getString(AppConstants.keyAccessToken);
            e.requestOptions.headers['Authorization'] = 'Bearer $newToken';
            try {
              final retried = await _dio.fetch(e.requestOptions);
              return handler.resolve(retried);
            } catch (_) {}
          }
          // Refresh failed — force logout
          final prefs = await SharedPreferences.getInstance();
          await prefs.clear();
          Get.offAllNamed('/login');
        }
        return handler.next(e);
      },
    ));
  }

  // ─── Token Refresh ────────────────────────────────────────────────────────

  Future<bool> _tryRefreshToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final refreshToken = prefs.getString(AppConstants.keyRefreshToken);
      if (refreshToken == null) return false;

      final res = await Dio().post(
        '${AppConstants.baseUrl}/auth/refresh',
        data: {'refreshToken': refreshToken},
        options: Options(headers: {'Content-Type': 'application/json'}),
      );

      if (res.statusCode == 200) {
        final auth = AuthResponse.fromJson(res.data);
        await prefs.setString(AppConstants.keyAccessToken, auth.accessToken);
        await prefs.setString(AppConstants.keyRefreshToken, auth.refreshToken);
        return true;
      }
    } catch (e) {
      _log.e('Token refresh failed: $e');
    }
    return false;
  }

  // ─── Auth ─────────────────────────────────────────────────────────────────

  Future<AuthResponse> login(String email, String password) async {
    final res = await _dio.post('/auth/login', data: {
      'email': email,
      'password': password,
    });
    return AuthResponse.fromJson(res.data);
  }

  Future<AuthResponse> register(String email, String password, String fullName) async {
    final res = await _dio.post('/auth/register', data: {
      'email': email,
      'password': password,
      'fullName': fullName,
    });
    return AuthResponse.fromJson(res.data);
  }

  Future<void> logout(String refreshToken) async {
    try {
      await _dio.post('/auth/logout', data: {'refreshToken': refreshToken});
    } catch (_) {}
  }

  Future<UserModel> getProfile() async {
    final res = await _dio.get('/auth/profile');
    return UserModel.fromJson(res.data['data'] ?? res.data);
  }

  Future<void> updateFcmToken(String fcmToken) async {
    try {
      await _dio.post('/auth/fcm-token', data: {'fcmToken': fcmToken});
    } catch (e) {
      _log.w('FCM token update failed: $e');
    }
  }

  Future<void> deleteAccount() async {
    await _dio.delete('/auth/account');
  }

  Future<UserModel> updateProfile(Map<String, dynamic> data) async {
    final res = await _dio.put('/auth/profile', data: data);
    return UserModel.fromJson(res.data['data'] ?? res.data);
  }

  Future<void> changePassword(String currentPassword, String newPassword) async {
    await _dio.post('/auth/change-password', data: {
      'currentPassword': currentPassword,
      'newPassword': newPassword,
    });
  }

  Future<void> resetPassword(String email, String newPassword) async {
    await _dio.post('/auth/reset-password', data: {
      'email': email,
      'newPassword': newPassword,
    });
  }

  // ─── Cards ────────────────────────────────────────────────────────────────

  Future<({List<CardModel> cards, PortfolioSummary summary})> getCards({
    int page = 1,
    int pageSize = 50,
    String? search,
    String? sortBy,
    bool includeSold = false,
  }) async {
    final res = await _dio.get('/cards', queryParameters: {
      'page': page,
      'pageSize': pageSize,
      if (search != null && search.isNotEmpty) 'search': search,
      if (sortBy != null) 'sortBy': sortBy,
      if (includeSold) 'includeSold': true,
    });

    final data = res.data['data'];
    final cards = (data['cards'] as List<dynamic>)
        .map((e) => CardModel.fromJson(e))
        .toList();
    final summary = PortfolioSummary.fromJson(data['summary'] ?? {});

    return (cards: cards, summary: summary);
  }

  Future<CardModel> addCard(Map<String, dynamic> data) async {
    final res = await _dio.post('/cards', data: data);
    return CardModel.fromJson(res.data['data'] ?? res.data);
  }

  Future<CardModel> getCard(String id) async {
    final res = await _dio.get('/cards/$id');
    return CardModel.fromJson(res.data['data'] ?? res.data);
  }

  Future<CardModel> updateCard(String id, Map<String, dynamic> data) async {
    final res = await _dio.put('/cards/$id', data: data);
    return CardModel.fromJson(res.data['data'] ?? res.data);
  }

  Future<void> deleteCard(String id) async {
    await _dio.delete('/cards/$id');
  }

  Future<CardModel> refreshCardPrice(String id) async {
    final res = await _dio.post('/cards/$id/refresh');
    return CardModel.fromJson(res.data['data'] ?? res.data);
  }

  Future<List<Map<String, dynamic>>> getPriceHistory(String id, {int limit = 30}) async {
    final res = await _dio.get('/cards/$id/history', queryParameters: {'limit': limit});
    final data = res.data['data'];
    return List<Map<String, dynamic>>.from(data['history'] ?? []);
  }

  Future<CardModel> markAsSold(String id, double soldPrice) async {
    final res = await _dio.post('/cards/$id/sold', data: {'soldPrice': soldPrice});
    return CardModel.fromJson(res.data['data'] ?? res.data);
  }

  // ─── eBay ─────────────────────────────────────────────────────────────────

  Future<EbaySearchResponse> searchEbay(String query) async {
    final res = await _dio.post('/ebay/search', data: {'query': query});
    return EbaySearchResponse.fromJson(res.data);
  }

  // ─── Notifications ────────────────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> getNotifications({int page = 1}) async {
    final res = await _dio.get(
      '/notifications',
      queryParameters: {'page': page, 'pageSize': 30},
    );
    final data = res.data['data'];
    return List<Map<String, dynamic>>.from(data['notifications'] ?? []);
  }
  Future<void> markNotificationRead(String id) async {       // ← ADD THIS
    await _dio.patch('/notifications/$id/read');
  }

  Future<void> markAllNotificationsRead() async {
    await _dio.post('/notifications/mark-all-read');
  }

  Future<void> saveReceivedNotification({
    required String title,
    required String body,
    String type = 'campaign',
    Map<String, dynamic> payload = const {},
    String? fcmMessageId,
  }) async {
    try {
      await _dio.post('/notifications/received', data: {
        'title': title,
        'body': body,
        'type': type,
        'payload': payload.map((k, v) => MapEntry(k, v.toString())),
        if (fcmMessageId != null) 'fcmMessageId': fcmMessageId,
      });
    } catch (e) {
      _log.w('saveReceivedNotification failed: $e');
    }
  }

  // ─── App Config ───────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> getAppConfig() async {
    final res = await _dio.get('/config');
    return res.data['data'] ?? {};
  }
}