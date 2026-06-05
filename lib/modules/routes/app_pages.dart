import 'package:get/get.dart';
import '../auth/login/login_binding.dart';
import '../auth/login/login_view.dart';
import '../auth/signup/signup_binding.dart';
import '../auth/signup/signup_view.dart';
import '../dashboard/dashboard_binding.dart';
import '../dashboard/dashboard_view.dart';
import '../collection/collection_binding.dart';
import '../collection/collection_view.dart';
import '../add_card/add_card_binding.dart';
import '../add_card/add_card_view.dart';
import '../card_detail/card_detail_binding.dart';
import '../card_detail/card_detail_view.dart';
import '../splash/splash_binding.dart';
import '../splash/splash_view.dart';
import '../notifications/notifications_binding.dart';
import '../notifications/notifications_view.dart';
import '../scan_card/scan_card_binding.dart';
import '../scan_card/scan_card_view.dart';
import '../settings/settings_view.dart';
import '../settings/settings_binding.dart';
import '../legal/terms_view.dart';
import '../legal/privacy_view.dart';
import '../sold_history/sold_history_binding.dart';
import '../sold_history/sold_history_view.dart';
import 'app_routes.dart';

class AppPages {
  static const initial = AppRoutes.splash;

  static final routes = [
    GetPage(name: AppRoutes.splash,        page: () => const SplashView(),        binding: SplashBinding(),        transition: Transition.fadeIn),
    GetPage(name: AppRoutes.login,         page: () => const LoginView(),         binding: LoginBinding(),         transition: Transition.fadeIn),
    GetPage(name: AppRoutes.signup,        page: () => const SignupView(),        binding: SignupBinding(),        transition: Transition.rightToLeft),
    GetPage(name: AppRoutes.dashboard,     page: () => const DashboardView(),     binding: DashboardBinding(),     transition: Transition.fadeIn),
    GetPage(name: AppRoutes.collection,    page: () => const CollectionView(),    binding: CollectionBinding(),    transition: Transition.rightToLeft),
    GetPage(name: AppRoutes.addCard,       page: () => const AddCardView(),       binding: AddCardBinding(),       transition: Transition.downToUp),
    GetPage(name: AppRoutes.cardDetail,    page: () => const CardDetailView(),    binding: CardDetailBinding(),    transition: Transition.rightToLeft),
    GetPage(name: AppRoutes.notifications, page: () => const NotificationsView(), binding: NotificationsBinding(), transition: Transition.rightToLeft),
    GetPage(name: AppRoutes.scanCard,      page: () => const ScanCardView(),      binding: ScanCardBinding(),      transition: Transition.downToUp),
    GetPage(name: AppRoutes.settings,      page: () => const SettingsView(),      binding: SettingsBinding(),      transition: Transition.rightToLeft),
    GetPage(name: AppRoutes.terms,         page: () => const TermsView(),         transition: Transition.rightToLeft),
    GetPage(name: AppRoutes.privacy,       page: () => const PrivacyView(),       transition: Transition.rightToLeft),
    GetPage(name: AppRoutes.soldHistory,   page: () => const SoldHistoryView(),   binding: SoldHistoryBinding(),   transition: Transition.rightToLeft),
  ];
}