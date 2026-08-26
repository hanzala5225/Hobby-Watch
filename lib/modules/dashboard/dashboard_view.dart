import 'dart:ui';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../app/theme/app_theme.dart';
import '../../data/models/card_model.dart';
import '../routes/app_routes.dart';
import 'dashboard_controller.dart';

class DashboardView extends GetView<DashboardController> {
  const DashboardView({super.key});

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) async {
        if (didPop) return;
        _showExitDialog(context);
      },
      child: Scaffold(
        backgroundColor: AppColors.bgDark,

        // IMPORTANT:
        // context is explicitly passed into the drawer.
        drawer: _buildDrawer(context),

        body: SafeArea(
          child: Obx(() {
            if (controller.isLoading.value) {
              return const Center(
                child: CircularProgressIndicator(
                  color: AppColors.accent,
                  strokeWidth: 2.5,
                ),
              );
            }

            return RefreshIndicator(
              color: AppColors.accent,
              onRefresh: controller.refreshPrices,
              child: CustomScrollView(
                physics: const BouncingScrollPhysics(
                  parent: AlwaysScrollableScrollPhysics(),
                ),
                slivers: [
                  _buildAppBar(),

                  SliverToBoxAdapter(
                    child: SizedBox(height: 8.h),
                  ),

                  SliverToBoxAdapter(
                    child: _buildPortfolioHero(),
                  ),

                  SliverToBoxAdapter(
                    child: SizedBox(height: 26.h),
                  ),

                  if (controller.targetReachedCards.isNotEmpty) ...[
                    SliverToBoxAdapter(
                      child: _sectionHeader(
                        'Ready to Sell',
                        controller.summary.value.cardsAtTarget,
                        showAll: true,
                        onViewAll: () {
                          Get.toNamed(
                            AppRoutes.collection,
                            arguments: {
                              'filter': 'targetReached',
                            },
                          );
                        },
                      ),
                    ),

                    SliverToBoxAdapter(
                      child: SizedBox(height: 12.h),
                    ),

                    SliverToBoxAdapter(
                      child: _buildAlertCards(),
                    ),

                    SliverToBoxAdapter(
                      child: SizedBox(height: 28.h),
                    ),
                  ],

                  SliverToBoxAdapter(
                    child: _sectionHeader(
                      'My Collection',
                      controller.cards.length,
                      showAll: true,
                    ),
                  ),

                  SliverToBoxAdapter(
                    child: SizedBox(height: 12.h),
                  ),

                  SliverToBoxAdapter(
                    child: _buildCollectionList(),
                  ),

                  SliverToBoxAdapter(
                    child: SizedBox(height: 110.h),
                  ),
                ],
              ),
            );
          }),
        ),

        floatingActionButton: _buildFAB(),

        bottomNavigationBar: _buildBottomNav(),
      ),
    );
  }

  // ===========================================================================
  // APP BAR
  // ===========================================================================

  Widget _buildAppBar() {
    return SliverAppBar(
      backgroundColor: AppColors.bgDark,
      surfaceTintColor: Colors.transparent,
      floating: true,
      snap: true,
      elevation: 0,
      automaticallyImplyLeading: false,
      toolbarHeight: 68.h,
      titleSpacing: 0,
      title: Padding(
        padding: EdgeInsets.symmetric(horizontal: 18.w),
        child: Row(
          children: [
            Builder(
              builder: (ctx) {
                return GestureDetector(
                  onTap: () => Scaffold.of(ctx).openDrawer(),
                  child: Container(
                    width: 42.w,
                    height: 42.w,
                    decoration: BoxDecoration(
                      color: AppColors.bgCard,
                      borderRadius: BorderRadius.circular(13.r),
                      border: Border.all(
                        color: AppColors.border,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withOpacity(0.05),
                          blurRadius: 14,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.menu_rounded,
                      color: AppColors.textPrimary,
                      size: 20.sp,
                    ),
                  ),
                );
              },
            ),

            SizedBox(width: 12.w),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Hobby Watch',
                    style: GoogleFonts.inter(
                      fontSize: 17.sp,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  SizedBox(height: 2.h),
                  Text(
                    'YOUR COLLECTION',
                    style: GoogleFonts.inter(
                      fontSize: 8.5.sp,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.35,
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),

            Obx(
                  () => controller.isRefreshing.value
                  ? Container(
                width: 38.w,
                height: 38.w,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.bgCard,
                  borderRadius: BorderRadius.circular(12.r),
                  border: Border.all(
                    color: AppColors.border,
                  ),
                ),
                child: const SizedBox(
                  width: 17,
                  height: 17,
                  child: CircularProgressIndicator(
                    color: AppColors.accent,
                    strokeWidth: 2,
                  ),
                ),
              )
                  : _appBarAction(
                icon: Icons.refresh_rounded,
                onTap: controller.refreshPrices,
              ),
            ),

            SizedBox(width: 7.w),

            _appBarAction(
              icon: Icons.settings_outlined,
              onTap: () => Get.toNamed(AppRoutes.settings),
            ),
          ],
        ),
      ),
    );
  }

  Widget _appBarAction({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 38.w,
        height: 38.w,
        decoration: BoxDecoration(
          color: AppColors.bgCard,
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(
            color: AppColors.border,
          ),
        ),
        child: Icon(
          icon,
          color: AppColors.textSecondary,
          size: 19.sp,
        ),
      ),
    );
  }

  // ===========================================================================
  // PORTFOLIO HERO
  // ===========================================================================

  Widget _buildPortfolioHero() {
    final fmt = NumberFormat.currency(
      symbol: '\$',
      decimalDigits: 2,
    );

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 18.w),
      child: Obx(() {
        final s = controller.summary.value;
        final isProfit = s.totalProfitLoss >= 0;

        return Container(
          decoration: BoxDecoration(
            gradient: AppColors.heroGradient,
            borderRadius: BorderRadius.circular(25.r),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withOpacity(0.18),
                blurRadius: 28,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Stack(
            children: [
              // Decorative circles
              Positioned(
                right: -35.w,
                top: -45.h,
                child: Container(
                  width: 145.w,
                  height: 145.w,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white.withOpacity(0.055),
                      width: 24,
                    ),
                  ),
                ),
              ),

              Positioned(
                right: 38.w,
                bottom: -65.h,
                child: Container(
                  width: 105.w,
                  height: 105.w,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.035),
                  ),
                ),
              ),

              Padding(
                padding: EdgeInsets.fromLTRB(
                  20.w,
                  20.h,
                  20.w,
                  18.h,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment:
                            CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    width: 7.w,
                                    height: 7.w,
                                    decoration: const BoxDecoration(
                                      color: AppColors.accentLight,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  SizedBox(width: 7.w),
                                  Text(
                                    'PORTFOLIO VALUE',
                                    style: GoogleFonts.inter(
                                      fontSize: 9.sp,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 1.3,
                                      color: Colors.white.withOpacity(
                                        0.68,
                                      ),
                                    ),
                                  ),
                                ],
                              ),

                              SizedBox(height: 8.h),

                              FittedBox(
                                fit: BoxFit.scaleDown,
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  fmt.format(s.totalCurrentValue),
                                  maxLines: 1,
                                  style: GoogleFonts.inter(
                                    fontSize: 31.sp,
                                    height: 1,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                    letterSpacing: -0.6,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        SizedBox(width: 12.w),

                        Container(
                          width: 47.w,
                          height: 47.w,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.10),
                            borderRadius: BorderRadius.circular(15.r),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.12),
                            ),
                          ),
                          child: Icon(
                            Icons.auto_graph_rounded,
                            color: Colors.white,
                            size: 22.sp,
                          ),
                        ),
                      ],
                    ),

                    SizedBox(height: 18.h),

                    Container(
                      width: double.infinity,
                      height: 1,
                      color: Colors.white.withOpacity(0.10),
                    ),

                    SizedBox(height: 15.h),

                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment:
                            CrossAxisAlignment.start,
                            children: [
                              Text(
                                'NET PROFIT',
                                style: GoogleFonts.inter(
                                  fontSize: 9.sp,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 1.1,
                                  color: Colors.white.withOpacity(0.58),
                                ),
                              ),
                              SizedBox(height: 5.h),
                              Row(
                                children: [
                                  Icon(
                                    isProfit
                                        ? Icons.trending_up_rounded
                                        : Icons.trending_down_rounded,
                                    color: isProfit
                                        ? AppColors.accentLight
                                        : AppColors.loss,
                                    size: 16.sp,
                                  ),
                                  SizedBox(width: 5.w),
                                  Flexible(
                                    child: FittedBox(
                                      fit: BoxFit.scaleDown,
                                      alignment:
                                      Alignment.centerLeft,
                                      child: Text(
                                        '${isProfit ? "+" : ""}${fmt.format(s.totalProfitLoss)}',
                                        maxLines: 1,
                                        style: GoogleFonts.inter(
                                          fontSize: 16.sp,
                                          fontWeight: FontWeight.w700,
                                          color: isProfit
                                              ? AppColors.accentLight
                                              : Colors.white,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        Container(
                          width: 1,
                          height: 35.h,
                          color: Colors.white.withOpacity(0.10),
                        ),

                        SizedBox(width: 16.w),

                        Column(
                          crossAxisAlignment:
                          CrossAxisAlignment.start,
                          children: [
                            Text(
                              'RETURN',
                              style: GoogleFonts.inter(
                                fontSize: 9.sp,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 1.1,
                                color: Colors.white.withOpacity(0.58),
                              ),
                            ),
                            SizedBox(height: 5.h),
                            Text(
                              '${s.totalProfitLossPercent.toStringAsFixed(1)}%',
                              style: GoogleFonts.inter(
                                fontSize: 16.sp,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),

                    SizedBox(height: 16.h),

                    Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: _heroStat(
                            label: 'INVESTED',
                            value: fmt.format(s.totalInvested),
                          ),
                        ),
                        SizedBox(width: 8.w),
                        Expanded(
                          flex: 2,
                          child: _heroStat(
                            label: 'CARDS',
                            value: '${s.totalCards}',
                          ),
                        ),
                        SizedBox(width: 8.w),
                        Expanded(
                          flex: 2,
                          child: _heroStat(
                            label: 'ALERTS',
                            value: '${s.cardsAtTarget}',
                            highlight: s.cardsAtTarget > 0,
                            onTap: () =>
                                Get.toNamed(AppRoutes.notifications),
                          ),
                        ),
                      ],
                    ),

                    if (controller.cardsAddedThisWeek > 0) ...[
                      SizedBox(height: 12.h),

                      Row(
                        children: [
                          Icon(
                            Icons.add_circle_outline_rounded,
                            color: Colors.white.withOpacity(0.65),
                            size: 14.sp,
                          ),
                          SizedBox(width: 5.w),
                          Expanded(
                            child: Text(
                              '${controller.cardsAddedThisWeek} card${controller.cardsAddedThisWeek == 1 ? '' : 's'} added this week · ${fmt.format(controller.investedThisWeek)} invested',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.inter(
                                fontSize: 10.sp,
                                color: Colors.white.withOpacity(0.62),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        );
      }),
    );
  }

  Widget _heroStat({
    required String label,
    required String value,
    bool highlight = false,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: 10.w,
          vertical: 9.h,
        ),
        decoration: BoxDecoration(
          color: highlight
              ? AppColors.accent.withOpacity(0.18)
              : Colors.white.withOpacity(0.075),
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(
            color: highlight
                ? AppColors.accent.withOpacity(0.18)
                : Colors.white.withOpacity(0.06),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                value,
                maxLines: 1,
                style: GoogleFonts.inter(
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
            SizedBox(height: 3.h),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.inter(
                fontSize: 8.sp,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.8,
                color: Colors.white.withOpacity(0.50),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ===========================================================================
  // SECTION HEADER
  // ===========================================================================

  Widget _sectionHeader(
      String title,
      int count, {
        bool showAll = false,
        VoidCallback? onViewAll,
      }) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 18.w),
      child: Row(
        children: [
          Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 15.sp,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),

          SizedBox(width: 8.w),

          Container(
            padding: EdgeInsets.symmetric(
              horizontal: 7.w,
              vertical: 3.h,
            ),
            decoration: BoxDecoration(
              color: AppColors.accent.withOpacity(0.09),
              borderRadius: BorderRadius.circular(8.r),
            ),
            child: Text(
              '$count',
              style: GoogleFonts.inter(
                fontSize: 10.sp,
                fontWeight: FontWeight.w700,
                color: AppColors.accent,
              ),
            ),
          ),

          const Spacer(),

          if (showAll)
            GestureDetector(
              onTap: onViewAll ??
                      () => Get.toNamed(AppRoutes.collection),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'View all',
                    style: GoogleFonts.inter(
                      fontSize: 11.sp,
                      fontWeight: FontWeight.w700,
                      color: AppColors.accent,
                    ),
                  ),
                  SizedBox(width: 3.w),
                  Icon(
                    Icons.arrow_forward_rounded,
                    color: AppColors.accent,
                    size: 14.sp,
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  // ===========================================================================
  // READY TO SELL
  // ===========================================================================

  Widget _buildAlertCards() {
    return SizedBox(
      height: 126.h,
      child: ListView.separated(
        physics: const BouncingScrollPhysics(),
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: 18.w),
        itemCount: controller.targetReachedCards.length,
        separatorBuilder: (_, __) => SizedBox(width: 11.w),
        itemBuilder: (_, i) {
          return _AlertCard(
            card: controller.targetReachedCards[i],
          );
        },
      ),
    );
  }

  // ===========================================================================
  // COLLECTION
  // ===========================================================================

  Widget _buildCollectionList() {
    if (controller.cards.isEmpty) {
      return Padding(
        padding: EdgeInsets.symmetric(horizontal: 18.w),
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.fromLTRB(
            24.w,
            28.h,
            24.w,
            26.h,
          ),
          decoration: BoxDecoration(
            color: AppColors.bgCard,
            borderRadius: BorderRadius.circular(20.r),
            border: Border.all(
              color: AppColors.border,
            ),
          ),
          child: Column(
            children: [
              Container(
                width: 58.w,
                height: 58.w,
                decoration: BoxDecoration(
                  color: AppColors.bgSurface,
                  borderRadius: BorderRadius.circular(17.r),
                ),
                child: Icon(
                  Icons.style_outlined,
                  size: 27.sp,
                  color: AppColors.textMuted,
                ),
              ),

              SizedBox(height: 15.h),

              Text(
                'Your collection is empty',
                style: GoogleFonts.inter(
                  fontSize: 15.sp,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),

              SizedBox(height: 6.h),

              Text(
                'Add your first sports card and start tracking its value and profit.',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 11.sp,
                  color: AppColors.textSecondary,
                  height: 1.45,
                ),
              ),

              SizedBox(height: 18.h),

              GestureDetector(
                onTap: () => Get.toNamed(AppRoutes.scanCard),
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 18.w,
                    vertical: 11.h,
                  ),
                  decoration: BoxDecoration(
                    gradient: AppColors.heroGradient,
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.add_rounded,
                        color: Colors.white,
                        size: 18.sp,
                      ),
                      SizedBox(width: 6.w),
                      Text(
                        'Add Your First Card',
                        style: GoogleFonts.inter(
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 18.w),
      child: Column(
        children: controller.recentCards
            .map(
              (card) => Padding(
            padding: EdgeInsets.only(bottom: 9.h),
            child: _CardRow(card: card),
          ),
        )
            .toList(),
      ),
    );
  }

  // ===========================================================================
  // FAB
  // ===========================================================================

  Widget _buildFAB() {
    return Container(
      decoration: BoxDecoration(
        gradient: AppColors.heroGradient,
        borderRadius: BorderRadius.circular(15.r),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.25),
            blurRadius: 18,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(15.r),
          onTap: () => Get.toNamed(AppRoutes.scanCard),
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: 18.w,
              vertical: 11.h,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.add_rounded,
                  color: Colors.white,
                  size: 19.sp,
                ),
                SizedBox(width: 7.w),
                Text(
                  'Add Card',
                  style: GoogleFonts.inter(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ===========================================================================
  // BOTTOM NAVIGATION
  // ===========================================================================

  Widget _buildBottomNav() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        border: const Border(
          top: BorderSide(
            color: AppColors.border,
            width: 1,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.04),
            blurRadius: 18,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            10.w,
            7.h,
            10.w,
            6.h,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              const _NavItem(
                icon: Icons.dashboard_rounded,
                label: 'Dashboard',
                isActive: true,
              ),

              _NavItem(
                icon: Icons.grid_view_rounded,
                label: 'Collection',
                isActive: false,
                onTap: () =>
                    Get.toNamed(AppRoutes.collection),
              ),

              Obx(
                    () => _NavItem(
                  icon: Icons.notifications_rounded,
                  label: 'Alerts',
                  isActive: false,
                  badgeCount: controller.unreadCount.value,
                  onTap: () =>
                      Get.toNamed(AppRoutes.notifications),
                ),
              ),

              _NavItem(
                icon: Icons.sell_rounded,
                label: 'Sold',
                isActive: false,
                onTap: () =>
                    Get.toNamed(AppRoutes.soldHistory),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ===========================================================================
  // DRAWER
  // ===========================================================================

  Widget _buildDrawer(BuildContext context) {
    final fmt = NumberFormat.currency(
      symbol: '\$',
      decimalDigits: 2,
    );

    return Drawer(
      backgroundColor: AppColors.bgCard,
      width: 320.w,
      child: Column(
        children: [
          Obx(() {
            final user = controller.user.value;
            final summary = controller.summary.value;

            return Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                gradient: AppColors.heroGradient,
              ),
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    20.w,
                    20.h,
                    20.w,
                    20.h,
                  ),
                  child: Column(
                    crossAxisAlignment:
                    CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 54.w,
                            height: 54.w,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.11),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.white.withOpacity(0.24),
                              ),
                            ),
                            child: Center(
                              child: Text(
                                user?.initials ?? '?',
                                style: GoogleFonts.inter(
                                  fontSize: 20.sp,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),

                          SizedBox(width: 12.w),

                          Expanded(
                            child: Column(
                              crossAxisAlignment:
                              CrossAxisAlignment.start,
                              children: [
                                Text(
                                  user?.displayName ??
                                      'Hobby Watch User',
                                  maxLines: 1,
                                  overflow:
                                  TextOverflow.ellipsis,
                                  style: GoogleFonts.inter(
                                    fontSize: 15.sp,
                                    fontWeight:
                                    FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                ),
                                SizedBox(height: 3.h),
                                Text(
                                  user?.email ?? '',
                                  maxLines: 1,
                                  overflow:
                                  TextOverflow.ellipsis,
                                  style: GoogleFonts.inter(
                                    fontSize: 10.sp,
                                    color: Colors.white
                                        .withOpacity(0.62),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          GestureDetector(
                            onTap: Get.back,
                            child: Container(
                              width: 32.w,
                              height: 32.w,
                              decoration: BoxDecoration(
                                color: Colors.white
                                    .withOpacity(0.09),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.close_rounded,
                                color: Colors.white
                                    .withOpacity(0.70),
                                size: 17.sp,
                              ),
                            ),
                          ),
                        ],
                      ),

                      SizedBox(height: 17.h),

                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 12.w,
                          vertical: 11.h,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.075),
                          borderRadius:
                          BorderRadius.circular(13.r),
                          border: Border.all(
                            color: Colors.white
                                .withOpacity(0.08),
                          ),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: _drawerStat(
                                'Cards',
                                '${summary.totalCards}',
                              ),
                            ),
                            _drawerDivider(),
                            Expanded(
                              child: _drawerStat(
                                'Value',
                                summary.totalCurrentValue > 0
                                    ? fmt.format(
                                  summary
                                      .totalCurrentValue,
                                )
                                    : '\$0',
                              ),
                            ),
                            _drawerDivider(),
                            Expanded(
                              child: _drawerStat(
                                'Alerts',
                                '${summary.cardsAtTarget}',
                                highlight:
                                summary.cardsAtTarget > 0,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),

          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: EdgeInsets.symmetric(
                horizontal: 14.w,
                vertical: 15.h,
              ),
              child: Column(
                crossAxisAlignment:
                CrossAxisAlignment.start,
                children: [
                  // Feedback
                  GestureDetector(
                    onTap: () {
                      Get.back();
                      _launchBugReportForm();
                    },
                    child: Container(
                      width: double.infinity,
                      padding: EdgeInsets.symmetric(
                        horizontal: 12.w,
                        vertical: 11.h,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.loss
                            .withOpacity(0.055),
                        borderRadius:
                        BorderRadius.circular(13.r),
                        border: Border.all(
                          color: AppColors.loss
                              .withOpacity(0.16),
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 35.w,
                            height: 35.w,
                            decoration: BoxDecoration(
                              color: AppColors.loss
                                  .withOpacity(0.10),
                              borderRadius:
                              BorderRadius.circular(10.r),
                            ),
                            child: Icon(
                              Icons.rate_review_outlined,
                              color: AppColors.loss,
                              size: 18.sp,
                            ),
                          ),

                          SizedBox(width: 11.w),

                          Expanded(
                            child: Column(
                              crossAxisAlignment:
                              CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Report a Bug / Share Feedback',
                                  style: GoogleFonts.inter(
                                    fontSize: 12.sp,
                                    fontWeight:
                                    FontWeight.w700,
                                    color:
                                    AppColors.textPrimary,
                                  ),
                                ),
                                SizedBox(height: 2.h),
                                Text(
                                  'Help us improve during beta',
                                  style: GoogleFonts.inter(
                                    fontSize: 9.sp,
                                    color:
                                    AppColors.textMuted,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          Icon(
                            Icons.arrow_outward_rounded,
                            color: AppColors.loss,
                            size: 16.sp,
                          ),
                        ],
                      ),
                    ),
                  ),

                  SizedBox(height: 21.h),

                  _drawerGroupLabel('MAIN'),

                  SizedBox(height: 7.h),

                  _drawerTile(
                    Icons.dashboard_rounded,
                    'Dashboard',
                    'Your portfolio overview',
                    AppColors.primary,
                        () => Get.back(),
                    selected: true,
                  ),

                  SizedBox(height: 6.h),

                  _drawerTile(
                    Icons.style_rounded,
                    'My Collection',
                    'All your tracked cards',
                    AppColors.accent,
                        () {
                      Get.back();
                      Get.toNamed(AppRoutes.collection);
                    },
                  ),

                  SizedBox(height: 6.h),

                  _drawerTile(
                    Icons.sell_outlined,
                    'Sold History',
                    'Cards you\'ve sold + P&L',
                    AppColors.textSecondary,
                        () {
                      Get.back();
                      Get.toNamed(
                        AppRoutes.soldHistory,
                      );
                    },
                  ),

                  SizedBox(height: 6.h),

                  _drawerTile(
                    Icons.bar_chart_rounded,
                    'Activity Report',
                    'Buying & selling by date range',
                    AppColors.textSecondary,
                        () {
                      Get.back();
                      Get.toNamed(
                        AppRoutes.activityReport,
                      );
                    },
                  ),

                  SizedBox(height: 6.h),

                  _drawerTile(
                    Icons.notifications_none_rounded,
                    'Notifications',
                    'Price alerts & updates',
                    AppColors.textSecondary,
                        () {
                      Get.back();
                      Get.toNamed(
                        AppRoutes.notifications,
                      );
                    },
                  ),

                  SizedBox(height: 21.h),

                  _drawerGroupLabel('ACCOUNT'),

                  SizedBox(height: 7.h),

                  _drawerTile(
                    Icons.settings_outlined,
                    'Settings',
                    'Profile, password & more',
                    AppColors.textSecondary,
                        () {
                      Get.back();
                      Get.toNamed(AppRoutes.settings);
                    },
                  ),

                  SizedBox(height: 6.h),

                  _drawerTile(
                    Icons.article_outlined,
                    'Terms & Conditions',
                    'Our terms of service',
                    AppColors.textSecondary,
                        () {
                      Get.back();
                      Get.toNamed(AppRoutes.terms);
                    },
                  ),

                  SizedBox(height: 6.h),

                  _drawerTile(
                    Icons.privacy_tip_outlined,
                    'Privacy Policy',
                    'How we use your data',
                    AppColors.textSecondary,
                        () {
                      Get.back();
                      Get.toNamed(AppRoutes.privacy);
                    },
                  ),

                  SizedBox(height: 20.h),

                  // SIGN OUT
                  GestureDetector(
                    onTap: () =>
                        _showSignOutDialog(context),
                    child: Container(
                      width: double.infinity,
                      padding: EdgeInsets.symmetric(
                        vertical: 13.h,
                        horizontal: 15.w,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.loss
                            .withOpacity(0.055),
                        borderRadius:
                        BorderRadius.circular(13.r),
                        border: Border.all(
                          color: AppColors.loss
                              .withOpacity(0.18),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.logout_rounded,
                            color: AppColors.loss,
                            size: 19.sp,
                          ),
                          SizedBox(width: 11.w),
                          Text(
                            'Sign Out',
                            style: GoogleFonts.inter(
                              fontSize: 13.sp,
                              fontWeight:
                              FontWeight.w700,
                              color: AppColors.loss,
                            ),
                          ),
                          const Spacer(),
                          Icon(
                            Icons.arrow_forward_ios_rounded,
                            color: AppColors.loss
                                .withOpacity(0.45),
                            size: 12.sp,
                          ),
                        ],
                      ),
                    ),
                  ),

                  SizedBox(height: 21.h),

                  Center(
                    child: Text(
                      'HOBBY WATCH',
                      style: GoogleFonts.inter(
                        fontSize: 9.sp,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.6,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ),

                  SizedBox(height: 3.h),

                  Center(
                    child: Text(
                      'Sports card profit tracking · v1.0.09',
                      style: GoogleFonts.inter(
                        fontSize: 9.sp,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ),

                  SizedBox(height: 10.h),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // DRAWER HELPERS
  // ===========================================================================

  Widget _drawerGroupLabel(String label) {
    return Padding(
      padding: EdgeInsets.only(left: 4.w),
      child: Text(
        label,
        style: GoogleFonts.inter(
          fontSize: 9.sp,
          fontWeight: FontWeight.w700,
          color: AppColors.textMuted,
          letterSpacing: 1.3,
        ),
      ),
    );
  }

  Widget _drawerTile(
      IconData icon,
      String label,
      String subtitle,
      Color iconColor,
      VoidCallback onTap, {
        bool selected = false,
      }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: 11.w,
          vertical: 9.h,
        ),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.primary.withOpacity(0.055)
              : AppColors.bgDark,
          borderRadius: BorderRadius.circular(13.r),
          border: Border.all(
            color: selected
                ? AppColors.primary.withOpacity(0.14)
                : AppColors.border,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 36.w,
              height: 36.w,
              decoration: BoxDecoration(
                color: iconColor.withOpacity(
                  selected ? 0.12 : 0.075,
                ),
                borderRadius:
                BorderRadius.circular(10.r),
              ),
              child: Icon(
                icon,
                color: iconColor,
                size: 18.sp,
              ),
            ),

            SizedBox(width: 11.w),

            Expanded(
              child: Column(
                crossAxisAlignment:
                CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  SizedBox(height: 2.h),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      fontSize: 9.sp,
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),

            Icon(
              selected
                  ? Icons.arrow_forward_ios_rounded
                  : Icons.chevron_right_rounded,
              color: selected
                  ? AppColors.primary.withOpacity(0.55)
                  : AppColors.border,
              size: selected ? 12.sp : 16.sp,
            ),
          ],
        ),
      ),
    );
  }

  Widget _drawerStat(
      String label,
      String value, {
        bool highlight = false,
      }) {
    return Column(
      children: [
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            value,
            maxLines: 1,
            style: GoogleFonts.inter(
              fontSize: 12.sp,
              fontWeight: FontWeight.w700,
              color: highlight
                  ? AppColors.accentLight
                  : Colors.white,
            ),
          ),
        ),
        SizedBox(height: 2.h),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 8.sp,
            color: Colors.white.withOpacity(0.55),
          ),
        ),
      ],
    );
  }

  Widget _drawerDivider() {
    return Container(
      width: 1,
      height: 25.h,
      color: Colors.white.withOpacity(0.12),
      margin: EdgeInsets.symmetric(horizontal: 7.w),
    );
  }

  // ===========================================================================
  // DIALOGS
  // ===========================================================================

  void _showExitDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.50),
      builder: (_) => _BlurDialog(
        icon: Icons.exit_to_app_rounded,
        iconColor: AppColors.primary,
        title: 'Exit App',
        message:
        'Are you sure you want to close Hobby Watch?\nYour collection is safe.',
        cancelLabel: 'Stay',
        confirmLabel: 'Exit',
        confirmColor: AppColors.primary,
        onConfirm: () => SystemNavigator.pop(),
      ),
    );
  }

  void _showSignOutDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.50),
      builder: (_) => _BlurDialog(
        icon: Icons.logout_rounded,
        iconColor: AppColors.loss,
        title: 'Sign Out',
        message:
        'You\'ll need to sign back in to access your collection.',
        cancelLabel: 'Stay',
        confirmLabel: 'Sign Out',
        confirmColor: AppColors.loss,
        onConfirm: () {
          Get.back();
          controller.logout();
        },
      ),
    );
  }

  // ===========================================================================
  // BUG REPORT
  // ===========================================================================

  Future<void> _launchBugReportForm() async {
    final uri = Uri.parse(
      'https://docs.google.com/forms/d/e/1FAIpQLSfI-39jzI3eyba04NK9DgsqQtRoQdaNyKadhSFzmz_TklAAFg/viewform',
    );

    try {
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );

      if (!launched) {
        throw Exception('launch returned false');
      }
    } catch (_) {
      Get.snackbar(
        'Could not open form',
        'Please check your internet connection and try again.',
        snackPosition: SnackPosition.BOTTOM,
        margin: const EdgeInsets.all(16),
        borderRadius: 12,
      );
    }
  }
}

// =============================================================================
// ALERT CARD
// =============================================================================

class _AlertCard extends StatelessWidget {
  final CardModel card;

  const _AlertCard({
    required this.card,
  });

  @override
  Widget build(BuildContext context) {
    final margin = card.currentMarginPercent ?? 0;

    final fmt = NumberFormat.currency(
      symbol: '\$',
      decimalDigits: 2,
    );

    return GestureDetector(
      onTap: () => Get.toNamed(
        AppRoutes.cardDetail,
        arguments: card,
      ),
      child: SizedBox(
        width: 224.w,
        height: 126.h,
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.bgCard,
            borderRadius: BorderRadius.circular(19.r),
            border: Border.all(
              color: AppColors.accent.withOpacity(0.22),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withOpacity(0.07),
                blurRadius: 18,
                offset: const Offset(0, 7),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(19.r),
            child: Stack(
              children: [
                // =============================================================
                // ACCENT STRIP
                // =============================================================
                Positioned(
                  left: 0,
                  top: 0,
                  bottom: 0,
                  child: Container(
                    width: 4.w,
                    decoration: const BoxDecoration(
                      gradient: AppColors.accentGradient,
                    ),
                  ),
                ),

                // =============================================================
                // DECORATIVE CIRCLE
                // =============================================================
                Positioned(
                  right: -32.w,
                  top: -35.h,
                  child: Container(
                    width: 95.w,
                    height: 95.w,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.accent.withOpacity(0.045),
                    ),
                  ),
                ),

                // =============================================================
                // CONTENT
                // =============================================================
                Padding(
                  padding: EdgeInsets.fromLTRB(
                    14.w,
                    8.h,
                    12.w,
                    7.h,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // =======================================================
                      // TOP ROW
                      // =======================================================
                      SizedBox(
                        height: 25.h,
                        child: Row(
                          children: [
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 7.w,
                                vertical: 3.h,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.accent.withOpacity(0.09),
                                borderRadius: BorderRadius.circular(7.r),
                                border: Border.all(
                                  color: AppColors.accent.withOpacity(0.13),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 5.w,
                                    height: 5.w,
                                    decoration: const BoxDecoration(
                                      color: AppColors.accent,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  SizedBox(width: 4.w),
                                  Text(
                                    'READY TO SELL',
                                    style: GoogleFonts.inter(
                                      fontSize: 7.sp,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 0.5,
                                      color: AppColors.accentDark,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            const Spacer(),

                            Container(
                              width: 25.w,
                              height: 25.w,
                              decoration: BoxDecoration(
                                color: AppColors.bgSurface,
                                borderRadius: BorderRadius.circular(8.r),
                              ),
                              child: Icon(
                                Icons.arrow_outward_rounded,
                                color: AppColors.textSecondary,
                                size: 13.sp,
                              ),
                            ),
                          ],
                        ),
                      ),

                      SizedBox(height: 5.h),

                      // =======================================================
                      // PLAYER NAME
                      // =======================================================
                      SizedBox(
                        height: 16.h,
                        child: Text(
                          card.playerName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(
                            fontSize: 12.5.sp,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                            letterSpacing: -0.15,
                            height: 1.0,
                          ),
                        ),
                      ),

                      SizedBox(height: 2.h),

                      // =======================================================
                      // YEAR / SET
                      // =======================================================
                      SizedBox(
                        height: 12.h,
                        child: Text(
                          '${card.year} • ${card.setName ?? ""}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(
                            fontSize: 8.5.sp,
                            fontWeight: FontWeight.w500,
                            color: AppColors.textMuted,
                            height: 1.0,
                          ),
                        ),
                      ),

                      SizedBox(height: 5.h),

                      // =======================================================
                      // DIVIDER
                      // =======================================================
                      Container(
                        width: double.infinity,
                        height: 1,
                        color: AppColors.divider,
                      ),

                      SizedBox(height: 4.h),

                      // =======================================================
                      // BOTTOM VALUES
                      // =======================================================
                      SizedBox(
                        height: 28.h,
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            // -------------------------------------------------
                            // CURRENT UPSIDE
                            // -------------------------------------------------
                            Expanded(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'CURRENT UPSIDE',
                                    maxLines: 1,
                                    style: GoogleFonts.inter(
                                      fontSize: 6.5.sp,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 0.45,
                                      color: AppColors.textMuted,
                                      height: 1.0,
                                    ),
                                  ),

                                  SizedBox(height: 2.h),

                                  SizedBox(
                                    height: 18.h,
                                    child: FittedBox(
                                      fit: BoxFit.scaleDown,
                                      alignment: Alignment.centerLeft,
                                      child: Text(
                                        '+${margin.toStringAsFixed(1)}%',
                                        maxLines: 1,
                                        style: GoogleFonts.inter(
                                          fontSize: 15.sp,
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.accent,
                                          letterSpacing: -0.4,
                                          height: 1.0,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            SizedBox(width: 8.w),

                            // -------------------------------------------------
                            // VALUE
                            // -------------------------------------------------
                            SizedBox(
                              width: 88.w,
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    'VALUE',
                                    maxLines: 1,
                                    style: GoogleFonts.inter(
                                      fontSize: 6.5.sp,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 0.45,
                                      color: AppColors.textMuted,
                                      height: 1.0,
                                    ),
                                  ),

                                  SizedBox(height: 2.h),

                                  SizedBox(
                                    height: 18.h,
                                    child: FittedBox(
                                      fit: BoxFit.scaleDown,
                                      alignment: Alignment.centerRight,
                                      child: Text(
                                        fmt.format(
                                          card.currentEbayAvg30 ??
                                              card.purchasePrice,
                                        ),
                                        maxLines: 1,
                                        style: GoogleFonts.inter(
                                          fontSize: 10.5.sp,
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.textPrimary,
                                          height: 1.0,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}



// =============================================================================
// COLLECTION CARD
// =============================================================================

class _CardRow extends StatelessWidget {
  final CardModel card;

  const _CardRow({
    required this.card,
  });

  @override
  Widget build(BuildContext context) {
    final margin = card.currentMarginPercent ?? 0;
    final isProfit = margin >= 0;

    final fmt = NumberFormat.currency(
      symbol: '\$',
      decimalDigits: 2,
    );

    return GestureDetector(
      onTap: () => Get.toNamed(
        AppRoutes.cardDetail,
        arguments: card,
      ),
      child: Container(
        padding: EdgeInsets.all(11.w),
        decoration: BoxDecoration(
          color: AppColors.bgCard,
          borderRadius: BorderRadius.circular(17.r),
          border: Border.all(
            color: card.isTargetReached
                ? AppColors.accent.withOpacity(0.26)
                : AppColors.border,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withOpacity(0.035),
              blurRadius: 14,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 48.w,
              height: 48.w,
              decoration: BoxDecoration(
                gradient: card.isTargetReached
                    ? AppColors.accentGradient
                    : AppColors.primaryGradient,
                borderRadius:
                BorderRadius.circular(13.r),
              ),
              child: card.imageUrl != null
                  ? ClipRRect(
                borderRadius:
                BorderRadius.circular(13.r),
                child: CachedNetworkImage(
                  imageUrl: card.imageUrl!,
                  fit: BoxFit.cover,
                  errorWidget: (_, __, ___) {
                    return Icon(
                      Icons.style_rounded,
                      color: Colors.white,
                      size: 21.sp,
                    );
                  },
                ),
              )
                  : Icon(
                Icons.style_rounded,
                color: Colors.white,
                size: 21.sp,
              ),
            ),

            SizedBox(width: 12.w),

            Expanded(
              child: Column(
                crossAxisAlignment:
                CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          card.playerName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(
                            fontSize: 13.sp,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),

                      if (card.isTargetReached) ...[
                        SizedBox(width: 5.w),
                        Container(
                          width: 7.w,
                          height: 7.w,
                          decoration: const BoxDecoration(
                            color: AppColors.accent,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ],
                    ],
                  ),

                  SizedBox(height: 3.h),

                  Text(
                    '${card.year} • ${card.setName ?? "—"}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      fontSize: 10.sp,
                      color: AppColors.textMuted,
                    ),
                  ),

                  SizedBox(height: 6.h),

                  Row(
                    children: [
                      Container(
                        width: 5.w,
                        height: 5.w,
                        decoration: BoxDecoration(
                          color: isProfit
                              ? AppColors.accent
                              : AppColors.loss,
                          shape: BoxShape.circle,
                        ),
                      ),
                      SizedBox(width: 5.w),
                      Text(
                        isProfit
                            ? 'Profit position'
                            : 'Below purchase price',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                          fontSize: 8.5.sp,
                          fontWeight: FontWeight.w600,
                          color: isProfit
                              ? AppColors.accent
                              : AppColors.loss,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            SizedBox(width: 10.w),

            Column(
              crossAxisAlignment:
              CrossAxisAlignment.end,
              children: [
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerRight,
                  child: Text(
                    fmt.format(
                      card.currentEbayAvg30 ??
                          card.purchasePrice,
                    ),
                    maxLines: 1,
                    style: GoogleFonts.inter(
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),

                SizedBox(height: 5.h),

                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 7.w,
                    vertical: 3.h,
                  ),
                  decoration: BoxDecoration(
                    color: card.isTargetReached
                        ? AppColors.accent
                        .withOpacity(0.12)
                        : isProfit
                        ? AppColors.accent
                        .withOpacity(0.07)
                        : AppColors.loss
                        .withOpacity(0.08),
                    borderRadius:
                    BorderRadius.circular(7.r),
                  ),
                  child: Text(
                    '${isProfit ? "+" : ""}${margin.toStringAsFixed(1)}%',
                    style: GoogleFonts.inter(
                      fontSize: 9.5.sp,
                      fontWeight: FontWeight.w700,
                      color: card.isTargetReached
                          ? AppColors.accent
                          : isProfit
                          ? AppColors.accent
                          : AppColors.loss,
                    ),
                  ),
                ),
              ],
            ),

            SizedBox(width: 3.w),

            Icon(
              Icons.chevron_right_rounded,
              color: AppColors.border,
              size: 19.sp,
            ),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// BOTTOM NAV ITEM
// =============================================================================

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback? onTap;
  final int badgeCount;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.isActive,
    this.onTap,
    this.badgeCount = 0,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 68.w,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                AnimatedContainer(
                  duration:
                  const Duration(milliseconds: 180),
                  width: 39.w,
                  height: 30.h,
                  decoration: BoxDecoration(
                    color: isActive
                        ? AppColors.primary
                        .withOpacity(0.07)
                        : Colors.transparent,
                    borderRadius:
                    BorderRadius.circular(10.r),
                  ),
                  alignment: Alignment.center,
                  child: Icon(
                    icon,
                    color: isActive
                        ? AppColors.primary
                        : AppColors.textMuted,
                    size: 21.sp,
                  ),
                ),

                if (badgeCount > 0)
                  Positioned(
                    right: -2,
                    top: -4,
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 4.w,
                        vertical: 1.h,
                      ),
                      constraints: BoxConstraints(
                        minWidth: 15.w,
                        minHeight: 15.w,
                      ),
                      decoration: const BoxDecoration(
                        color: AppColors.loss,
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        badgeCount > 9
                            ? '9+'
                            : '$badgeCount',
                        style: GoogleFonts.inter(
                          fontSize: 8.sp,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
              ],
            ),

            SizedBox(height: 3.h),

            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.inter(
                fontSize: 9.sp,
                color: isActive
                    ? AppColors.primary
                    : AppColors.textMuted,
                fontWeight:
                isActive ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// BLURRED DIALOG
// =============================================================================

class _BlurDialog extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String message;
  final String cancelLabel;
  final String confirmLabel;
  final Color confirmColor;
  final VoidCallback onConfirm;

  const _BlurDialog({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.message,
    required this.cancelLabel,
    required this.confirmLabel,
    required this.confirmColor,
    required this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    return BackdropFilter(
      filter: ImageFilter.blur(
        sigmaX: 10,
        sigmaY: 10,
      ),
      child: Dialog(
        backgroundColor: Colors.transparent,
        insetPadding:
        EdgeInsets.symmetric(horizontal: 28.w),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.bgCard,
            borderRadius: BorderRadius.circular(22.r),
            border: Border.all(
              color: AppColors.border,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.14),
                blurRadius: 30,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          padding: EdgeInsets.all(22.w),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 56.w,
                height: 56.w,
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.09),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  color: iconColor,
                  size: 26.sp,
                ),
              ),

              SizedBox(height: 15.h),

              Text(
                title,
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),

              SizedBox(height: 7.h),

              Text(
                message,
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 12.sp,
                  color: AppColors.textSecondary,
                  height: 1.5,
                ),
              ),

              SizedBox(height: 22.h),

              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () =>
                          Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        foregroundColor:
                        AppColors.textSecondary,
                        side: const BorderSide(
                          color: AppColors.border,
                        ),
                        minimumSize:
                        Size(0, 46.h),
                        shape:
                        RoundedRectangleBorder(
                          borderRadius:
                          BorderRadius.circular(11.r),
                        ),
                      ),
                      child: Text(
                        cancelLabel,
                        style: GoogleFonts.inter(
                          fontSize: 13.sp,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),

                  SizedBox(width: 10.w),

                  Expanded(
                    child: ElevatedButton(
                      onPressed: onConfirm,
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                        confirmColor,
                        foregroundColor:
                        Colors.white,
                        elevation: 0,
                        minimumSize:
                        Size(0, 46.h),
                        shape:
                        RoundedRectangleBorder(
                          borderRadius:
                          BorderRadius.circular(11.r),
                        ),
                      ),
                      child: Text(
                        confirmLabel,
                        style: GoogleFonts.inter(
                          fontSize: 13.sp,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}