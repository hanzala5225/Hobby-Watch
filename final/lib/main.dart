import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'app/theme/app_theme.dart';
import 'data/services/api_service.dart';
import 'data/services/ocr_service.dart';
import 'modules/routes/app_pages.dart';

// ── Firebase: uncomment after setting up Firebase ─────────────────────────
import 'package:firebase_core/firebase_core.dart';
import 'data/services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
  ));

  // ── Firebase init (uncomment after adding google-services.json / GoogleService-Info.plist) ──
  await Firebase.initializeApp();

  // Register global services
  Get.put(ApiService());
  Get.put(OcrService());

  // ── Firebase notifications (uncomment after Firebase init) ────────────────
  Get.put(NotificationService());

  runApp(const HobbyWatchApp());
}

class HobbyWatchApp extends StatelessWidget {
  const HobbyWatchApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(390, 844),
      minTextAdapt: true,
      splitScreenMode: false,
      builder: (context, child) {
        return GetMaterialApp(
          title: 'Hobby Watch',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          initialRoute: AppPages.initial,
          getPages: AppPages.routes,
          defaultTransition: Transition.fadeIn,
          builder: (context, widget) {
            return MediaQuery(
              data: MediaQuery.of(context)
                  .copyWith(textScaler: TextScaler.noScaling),
              child: widget!,
            );
          },
        );
      },
    );
  }
}
