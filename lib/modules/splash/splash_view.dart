import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../app/theme/app_theme.dart';
import 'splash_controller.dart';

class SplashView extends GetView<SplashController> {
  const SplashView({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Color(0xFFF5F7FA),
      body: _SplashBody(),
    );
  }
}

class _SplashBody extends StatefulWidget {
  const _SplashBody();

  @override
  State<_SplashBody> createState() => _SplashBodyState();
}

class _SplashBodyState extends State<_SplashBody> with TickerProviderStateMixin {
  late AnimationController _logoCtrl;
  late AnimationController _textCtrl;
  late AnimationController _pulseCtrl;
  late AnimationController _shimmerCtrl;

  late Animation<double>  _logoScale;
  late Animation<double>  _logoFade;
  late Animation<double>  _logoSlide;
  late Animation<double>  _textFade;
  late Animation<double>  _textSlide;
  late Animation<double>  _taglineFade;
  late Animation<double>  _pulse;
  late Animation<double>  _shimmer;

  @override
  void initState() {
    super.initState();

    // Logo: bounces in from below
    _logoCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    _logoScale = Tween<double>(begin: 0.5, end: 1.0).animate(
        CurvedAnimation(parent: _logoCtrl, curve: Curves.elasticOut));
    _logoFade  = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: _logoCtrl, curve: const Interval(0, 0.5, curve: Curves.easeOut)));
    _logoSlide = Tween<double>(begin: 40, end: 0).animate(
        CurvedAnimation(parent: _logoCtrl, curve: Curves.easeOut));

    // Text: fades up after logo
    _textCtrl  = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _textFade  = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: _textCtrl, curve: const Interval(0, 0.7, curve: Curves.easeOut)));
    _textSlide = Tween<double>(begin: 20, end: 0).animate(
        CurvedAnimation(parent: _textCtrl, curve: Curves.easeOut));
    _taglineFade = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: _textCtrl, curve: const Interval(0.3, 1.0, curve: Curves.easeOut)));

    // Continuous gentle pulse on icon
    _pulseCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 2000))
      ..repeat(reverse: true);
    _pulse = Tween<double>(begin: 1.0, end: 1.06).animate(
        CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));

    // Shimmer on the loader dots
    _shimmerCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))
      ..repeat();
    _shimmer = Tween<double>(begin: 0.0, end: 1.0).animate(_shimmerCtrl);

    // Sequence: logo first, then text
    _logoCtrl.forward();
    Future.delayed(const Duration(milliseconds: 400), () {
      if (mounted) _textCtrl.forward();
    });
  }

  @override
  void dispose() {
    _logoCtrl.dispose();
    _textCtrl.dispose();
    _pulseCtrl.dispose();
    _shimmerCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox.expand(
      child: Column(
        children: [
          // ── Main centered content ───────────────────────────────────────
          Expanded(
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Logo with pulse + entrance animation
                  AnimatedBuilder(
                    animation: Listenable.merge([_logoCtrl, _pulseCtrl]),
                    builder: (_, __) => FadeTransition(
                      opacity: _logoFade,
                      child: Transform.translate(
                        offset: Offset(0, _logoSlide.value),
                        child: ScaleTransition(
                          scale: _logoScale,
                          child: ScaleTransition(
                            scale: _pulse,
                            child: Container(
                              width: 104.w,
                              height: 104.w,
                              decoration: BoxDecoration(
                                gradient: AppColors.heroGradient,
                                borderRadius: BorderRadius.circular(28.r),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.primary.withOpacity(0.18),
                                    blurRadius: 32,
                                    offset: const Offset(0, 12),
                                    spreadRadius: 2,
                                  ),
                                  BoxShadow(
                                    color: AppColors.accent.withOpacity(0.14),
                                    blurRadius: 20,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Icon(
                                Icons.style_rounded,
                                color: Colors.white,
                                size: 50.sp,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                  SizedBox(height: 36.h),

                  // App name
                  AnimatedBuilder(
                    animation: _textCtrl,
                    builder: (_, __) => FadeTransition(
                      opacity: _textFade,
                      child: Transform.translate(
                        offset: Offset(0, _textSlide.value),
                        child: Text(
                          'Hobby Watch',
                          style: GoogleFonts.inter(
                            fontSize: 38.sp,
                            fontWeight: FontWeight.w800,
                            color: AppColors.primary,
                            letterSpacing: -1.2,
                          ),
                        ),
                      ),
                    ),
                  ),

                  SizedBox(height: 10.h),

                  // Tagline — slightly delayed
                  AnimatedBuilder(
                    animation: _textCtrl,
                    builder: (_, __) => FadeTransition(
                      opacity: _taglineFade,
                      child: Text(
                        'Know when to sell. Every time.',
                        style: GoogleFonts.inter(
                          fontSize: 15.sp,
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w400,
                          letterSpacing: 0.1,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Bottom loader ───────────────────────────────────────────────
          AnimatedBuilder(
            animation: _textCtrl,
            builder: (_, __) => FadeTransition(
              opacity: _taglineFade,
              child: Padding(
                padding: EdgeInsets.only(bottom: 52.h),
                child: Column(
                  children: [
                    _AnimatedDots(shimmer: _shimmer),
                    SizedBox(height: 14.h),
                    Text(
                      'Loading your collection...',
                      style: GoogleFonts.inter(
                        fontSize: 12.sp,
                        color: AppColors.textMuted,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Three animated dots loader — nicer than a spinner
class _AnimatedDots extends StatelessWidget {
  final Animation<double> shimmer;
  const _AnimatedDots({required this.shimmer});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: shimmer,
      builder: (_, __) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (i) {
            final offset = i / 3.0;
            final t = ((shimmer.value - offset) % 1.0 + 1.0) % 1.0;
            final scale = 1.0 + 0.6 * (1.0 - (t * 2 - 1).abs());
            final opacity = 0.3 + 0.7 * (1.0 - (t * 2 - 1).abs());
            return Container(
              margin: EdgeInsets.symmetric(horizontal: 4.w),
              child: Transform.scale(
                scale: scale,
                child: Container(
                  width: 7.w,
                  height: 7.w,
                  decoration: BoxDecoration(
                    color: AppColors.accent.withOpacity(opacity),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            );
          }),
        );
      },
    );
  }
}