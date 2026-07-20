import 'dart:ui';
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
        drawer: _buildDrawer(),
        body: SafeArea(
          child: Obx(() {
            if (controller.isLoading.value) {
              return const Center(child: CircularProgressIndicator(color: AppColors.accent, strokeWidth: 2.5));
            }
            return RefreshIndicator(
              color: AppColors.accent,
              onRefresh: controller.refreshPrices,
              child: CustomScrollView(
                slivers: [
                  _buildAppBar(),
                  SliverToBoxAdapter(child: SizedBox(height: 16.h)),
                  SliverToBoxAdapter(child: _buildPortfolioHero()),
                  SliverToBoxAdapter(child: SizedBox(height: 24.h)),
                  if (controller.targetReachedCards.isNotEmpty) ...[
                    SliverToBoxAdapter(child: _sectionHeader('🎯 Ready to Sell', controller.targetReachedCards.length)),
                    SliverToBoxAdapter(child: SizedBox(height: 12.h)),
                    SliverToBoxAdapter(child: _buildAlertCards()),
                    SliverToBoxAdapter(child: SizedBox(height: 24.h)),
                  ],
                  SliverToBoxAdapter(child: _sectionHeader('My Collection', controller.cards.length, showAll: true)),
                  SliverToBoxAdapter(child: SizedBox(height: 12.h)),
                  SliverToBoxAdapter(child: _buildCollectionList()),
                  SliverToBoxAdapter(child: SizedBox(height: 120.h)),
                ],
              ),
            );
          }),
        ),
        floatingActionButton: _buildFAB(),
        bottomNavigationBar: _buildBottomNav(),
      ),  // Scaffold
    );  // PopScope
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      backgroundColor: AppColors.bgDark,
      floating: true,
      elevation: 0,
      automaticallyImplyLeading: false,
      title: Padding(
        padding: EdgeInsets.symmetric(horizontal: 4.w),
        child: Row(
          children: [
            Builder(builder: (ctx) => GestureDetector(
              onTap: () => Scaffold.of(ctx).openDrawer(),
              child: Container(
                width: 38.w, height: 38.w,
                decoration: BoxDecoration(
                  gradient: AppColors.heroGradient,
                  borderRadius: BorderRadius.circular(11.r),
                ),
                child: Icon(Icons.menu_rounded, color: Colors.white, size: 20.sp),
              ),
            )),
            SizedBox(width: 10.w),
            Text('Hobby Watch', style: GoogleFonts.inter(fontSize: 18.sp, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
            const Spacer(),
            Obx(() => controller.isRefreshing.value
                ? SizedBox(width: 18.w, height: 18.w, child: const CircularProgressIndicator(color: AppColors.accent, strokeWidth: 2))
                : IconButton(icon: Icon(Icons.refresh_rounded, color: AppColors.textSecondary, size: 22.sp), onPressed: controller.refreshPrices)),
            Obx(() => Stack(clipBehavior: Clip.none, children: [
              IconButton(
                icon: Icon(Icons.notifications_outlined, color: AppColors.textSecondary, size: 22.sp),
                onPressed: () => Get.toNamed(AppRoutes.notifications),
              ),
              if (controller.unreadCount.value > 0)
                Positioned(
                  right: 4,
                  top: 4,
                  child: IgnorePointer(
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 5.w, vertical: 1.h),
                      constraints: BoxConstraints(minWidth: 16.w, minHeight: 16.w),
                      decoration: const BoxDecoration(color: AppColors.loss, shape: BoxShape.circle),
                      alignment: Alignment.center,
                      child: Text(
                        controller.unreadCount.value > 9 ? '9+' : '${controller.unreadCount.value}',
                        style: GoogleFonts.inter(fontSize: 9.sp, fontWeight: FontWeight.w700, color: Colors.white),
                      ),
                    ),
                  ),
                ),
            ])),
          ],
        ),
      ),
    );
  }

  Widget _buildPortfolioHero() {
    final fmt = NumberFormat.currency(symbol: '\$', decimalDigits: 2);
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.w),
      child: Obx(() {
        final s = controller.summary.value;
        final isProfit = s.totalProfitLoss >= 0;
        return Container(
          padding: EdgeInsets.all(20.w),
          decoration: BoxDecoration(
            gradient: AppColors.heroGradient,
            borderRadius: BorderRadius.circular(24.r),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Portfolio Value', style: GoogleFonts.inter(fontSize: 12.sp, color: Colors.white70, fontWeight: FontWeight.w500)),
                      SizedBox(height: 6.h),
                      Text(fmt.format(s.totalCurrentValue),
                          style: GoogleFonts.inter(fontSize: 32.sp, height: 1, fontWeight: FontWeight.w800, color: Colors.white)),
                    ],
                  ),
                  Container(
                    width: 50.w, height: 50.w,
                    decoration: BoxDecoration(borderRadius: BorderRadius.circular(14.r), color: Colors.white.withOpacity(0.15)),
                    child: Icon(Icons.auto_graph_rounded, color: Colors.white, size: 24.sp),
                  ),
                ],
              ),
              SizedBox(height: 12.h),
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20.r),
                      color: isProfit ? const Color(0xFF009286).withOpacity(0.25) : const Color(0xFFD63031).withOpacity(0.25),
                    ),
                    child: Row(children: [
                      Icon(isProfit ? Icons.trending_up_rounded : Icons.trending_down_rounded,
                          color: isProfit ? const Color(0xFF4CD6C5) : const Color(0xFFFF6B6B), size: 14.sp),
                      SizedBox(width: 4.w),
                      Text('${isProfit ? "+" : ""}${fmt.format(s.totalProfitLoss)}',
                          style: GoogleFonts.inter(fontSize: 12.sp, fontWeight: FontWeight.w700,
                              color: isProfit ? const Color(0xFF4CD6C5) : const Color(0xFFFF6B6B))),
                    ]),
                  ),
                  SizedBox(width: 8.w),
                  Text('${s.totalProfitLossPercent.toStringAsFixed(1)}% overall',
                      style: GoogleFonts.inter(fontSize: 12.sp, color: Colors.white60)),
                ],
              ),
              SizedBox(height: 16.h),
              Row(children: [
                _miniStat('Invested', fmt.format(s.totalInvested)),
                SizedBox(width: 8.w),
                _miniStat('Cards', '${s.totalCards}'),
                SizedBox(width: 8.w),
                _miniStat('Alerts', '${s.cardsAtTarget}', highlight: s.cardsAtTarget > 0),
              ]),
            ],
          ),
        );
      }),
    );
  }

  Widget _miniStat(String label, String value, {bool highlight = false}) {
    return Expanded(
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14.r),
          color: highlight ? AppColors.accent.withOpacity(0.25) : Colors.white.withOpacity(0.12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(value, style: GoogleFonts.inter(fontSize: 15.sp, fontWeight: FontWeight.w700, color: Colors.white)),
            SizedBox(height: 3.h),
            Text(label, style: GoogleFonts.inter(fontSize: 10.sp, color: Colors.white60)),
          ],
        ),
      ),
    );
  }

  Widget _sectionHeader(String title, int count, {bool showAll = false}) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.w),
      child: Row(
        children: [
          Text(title, style: GoogleFonts.inter(fontSize: 15.sp, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
          SizedBox(width: 8.w),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
            decoration: BoxDecoration(color: AppColors.accent.withOpacity(0.12), borderRadius: BorderRadius.circular(20.r)),
            child: Text('$count', style: GoogleFonts.inter(fontSize: 11.sp, fontWeight: FontWeight.w600, color: AppColors.accent)),
          ),
          const Spacer(),
          if (showAll) GestureDetector(
            onTap: () => Get.toNamed(AppRoutes.collection),
            child: Text('View all', style: GoogleFonts.inter(fontSize: 13.sp, color: AppColors.accent, fontWeight: FontWeight.w500)),
          ),
        ],
      ),
    );
  }

  Widget _buildAlertCards() {
    return SizedBox(
      height: 120.h,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: 20.w),
        itemCount: controller.targetReachedCards.length,
        separatorBuilder: (_, __) => SizedBox(width: 12.w),
        itemBuilder: (_, i) => _AlertCard(card: controller.targetReachedCards[i]),
      ),
    );
  }

  Widget _buildCollectionList() {
    if (controller.cards.isEmpty) {
      return Padding(
        padding: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, 0),
        child: Container(
          padding: EdgeInsets.all(32.w),
          decoration: BoxDecoration(color: AppColors.bgCard, borderRadius: BorderRadius.circular(20.r), border: Border.all(color: AppColors.border)),
          child: Column(
            children: [
              Container(
                width: 64.w, height: 64.w,
                decoration: BoxDecoration(color: AppColors.bgSurface, borderRadius: BorderRadius.circular(18.r)),
                child: Icon(Icons.style_outlined, size: 30.sp, color: AppColors.textMuted),
              ),
              SizedBox(height: 16.h),
              Text('No cards yet', style: GoogleFonts.inter(fontSize: 16.sp, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
              SizedBox(height: 8.h),
              Text('Tap + to add your first card\nand start tracking profits.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(fontSize: 13.sp, color: AppColors.textMuted, height: 1.5)),
            ],
          ),
        ),
      );
    }
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.w),
      child: Column(
        children: controller.recentCards.map((c) => Padding(
          padding: EdgeInsets.only(bottom: 10.h),
          child: _CardRow(card: c),
        )).toList(),
      ),
    );
  }

  Widget _buildFAB() {
    return Container(
      decoration: BoxDecoration(gradient: AppColors.heroGradient, borderRadius: BorderRadius.circular(16.r),
          boxShadow: [BoxShadow(color: AppColors.primary.withOpacity(0.3), blurRadius: 16, offset: const Offset(0, 6))]),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16.r),
          onTap: () => Get.toNamed(AppRoutes.scanCard),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.add_rounded, color: Colors.white, size: 20.sp),
                SizedBox(width: 8.w),
                Text('Add Card', style: GoogleFonts.inter(fontSize: 14.sp, fontWeight: FontWeight.w600, color: Colors.white)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBottomNav() {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.bgCard,
        border: Border(top: BorderSide(color: AppColors.border, width: 1)),
      ),
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 8.h),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              const _NavItem(icon: Icons.dashboard_rounded, label: 'Dashboard', isActive: true),
              _NavItem(icon: Icons.grid_view_rounded, label: 'Collection', isActive: false, onTap: () => Get.toNamed(AppRoutes.collection)),
              Obx(() => _NavItem(
                icon: Icons.notifications_rounded,
                label: 'Alerts',
                isActive: false,
                badgeCount: controller.unreadCount.value,
                onTap: () => Get.toNamed(AppRoutes.notifications),
              )),
              _NavItem(icon: Icons.settings_rounded, label: 'Settings', isActive: false, onTap: () => Get.toNamed(AppRoutes.settings)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDrawer() {
    final fmt = NumberFormat.currency(symbol: '\$', decimalDigits: 2);
    return Drawer(
      backgroundColor: AppColors.bgCard,
      child: Column(
        children: [
          // ── Hero header ────────────────────────────────────────────────
          Obx(() {
            final u = controller.user.value;
            final s = controller.summary.value;
            return Container(
              width: double.infinity,
              decoration: const BoxDecoration(gradient: AppColors.heroGradient),
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: EdgeInsets.fromLTRB(20.w, 20.h, 20.w, 20.h),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Container(
                            width: 56.w, height: 56.w,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Colors.white24, Colors.white10],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white.withOpacity(0.5), width: 2),
                            ),
                            child: Center(
                              child: Text(u?.initials ?? '?',
                                  style: GoogleFonts.inter(fontSize: 22.sp, fontWeight: FontWeight.w800, color: Colors.white)),
                            ),
                          ),
                          GestureDetector(
                            onTap: Get.back,
                            child: Container(
                              width: 32.w, height: 32.w,
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.12),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(Icons.close, color: Colors.white70, size: 16.sp),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 14.h),
                      Text(u?.displayName ?? 'Hobby Watch User',
                          style: GoogleFonts.inter(fontSize: 17.sp, fontWeight: FontWeight.w700, color: Colors.white),
                          maxLines: 1, overflow: TextOverflow.ellipsis),
                      SizedBox(height: 3.h),
                      Text(u?.email ?? '',
                          style: GoogleFonts.inter(fontSize: 12.sp, color: Colors.white70),
                          maxLines: 1, overflow: TextOverflow.ellipsis),
                      /*SizedBox(height: 10.h),*/
                      // Portfolio mini-stats strip
                      /* Container(
                        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(14.r),
                          border: Border.all(color: Colors.white.withOpacity(0.15)),
                        ),
                        child: Row(children: [
                          _drawerStat('Cards', '${s.totalCards}'),
                          _drawerDivider(),
                          _drawerStat('Value', s.totalCurrentValue > 0 ? fmt.format(s.totalCurrentValue) : '\$0'),
                          _drawerDivider(),
                          _drawerStat('Alerts', '${s.cardsAtTarget}',
                              highlight: s.cardsAtTarget > 0),
                        ]),
                      ),*/
                    ],
                  ),
                ),
              ),
            );
          }),

          // ── Menu ──────────────────────────────────────────────────────
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Beta feedback — kept first/obvious per client request ──
                  GestureDetector(
                    onTap: () { Get.back(); _launchBugReportForm(); },
                    child: Container(
                      width: double.infinity,
                      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.h),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFF6B57).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12.r),
                        border: Border.all(color: const Color(0xFFFF6B57).withOpacity(0.4)),
                      ),
                      child: Row(children: [
                        Container(
                          width: 36.w, height: 36.w,
                          decoration: BoxDecoration(
                            color: const Color(0xFFFF6B57).withOpacity(0.15),
                            borderRadius: BorderRadius.circular(9.r),
                          ),
                          child: Icon(Icons.bug_report_rounded, color: const Color(0xFFFF6B57), size: 18.sp),
                        ),
                        SizedBox(width: 12.w),
                        Expanded(child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Report a Bug / Share Feedback',
                                style: GoogleFonts.inter(fontSize: 13.sp, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                            Text('Help us improve during beta',
                                style: GoogleFonts.inter(fontSize: 10.sp, color: AppColors.textMuted)),
                          ],
                        )),
                        Icon(Icons.open_in_new_rounded, color: const Color(0xFFFF6B57), size: 16.sp),
                      ]),
                    ),
                  ),
                  SizedBox(height: 18.h),

                  _drawerGroupLabel('MAIN'),
                  SizedBox(height: 6.h),
                  _drawerTile(Icons.dashboard_rounded,     'Dashboard',       'Your portfolio overview',    AppColors.primary,  () { Get.back(); }),
                  SizedBox(height: 6.h),
                  _drawerTile(Icons.style_rounded,         'My Collection',   'All your tracked cards',     AppColors.accent,   () { Get.back(); Get.toNamed(AppRoutes.collection); }),
                  SizedBox(height: 6.h),
                  _drawerTile(Icons.sell_rounded,          'Sold History',    'Cards you\'ve sold + P&L',   AppColors.textSecondary, () { Get.back(); Get.toNamed(AppRoutes.soldHistory); }),
                  SizedBox(height: 6.h),
                  _drawerTile(Icons.notifications_rounded, 'Notifications',   'Price alerts & updates',     AppColors.textSecondary, () { Get.back(); Get.toNamed(AppRoutes.notifications); }),

                  SizedBox(height: 18.h),
                  _drawerGroupLabel('ACCOUNT'),
                  SizedBox(height: 6.h),
                  _drawerTile(Icons.settings_rounded,      'Settings',        'Profile, password & more',   AppColors.textSecondary, () { Get.back(); Get.toNamed(AppRoutes.settings); }),
                  SizedBox(height: 6.h),
                  _drawerTile(Icons.article_outlined,      'Terms & Conditions', 'Our terms of service',   AppColors.textSecondary, () { Get.back(); Get.toNamed(AppRoutes.terms); }),
                  SizedBox(height: 6.h),
                  _drawerTile(Icons.privacy_tip_outlined,  'Privacy Policy',  'How we use your data',       AppColors.textSecondary, () { Get.back(); Get.toNamed(AppRoutes.privacy); }),

                  SizedBox(height: 18.h),
                  Builder(
                    builder: (ctx) => GestureDetector(
                      onTap: () => _showSignOutDialog(ctx),
                      child: Container(
                        width: double.infinity,
                        padding: EdgeInsets.symmetric(vertical: 13.h, horizontal: 16.w),
                        decoration: BoxDecoration(
                          color: AppColors.loss.withOpacity(0.07),
                          borderRadius: BorderRadius.circular(12.r),
                          border: Border.all(color: AppColors.loss.withOpacity(0.25)),
                        ),
                        child: Row(children: [
                          Icon(Icons.logout_rounded, color: AppColors.loss, size: 20.sp),
                          SizedBox(width: 12.w),
                          Text('Sign Out', style: GoogleFonts.inter(fontSize: 14.sp, fontWeight: FontWeight.w600, color: AppColors.loss)),
                          const Spacer(),
                          Icon(Icons.arrow_forward_ios_rounded, color: AppColors.loss.withOpacity(0.5), size: 13.sp),
                        ]),
                      ),
                    ),
                  ), // Builder
                  SizedBox(height: 20.h),

                  // Version footer
                  Center(child: Text('Hobby Watch v1.0.0',
                      style: GoogleFonts.inter(fontSize: 11.sp, color: AppColors.textMuted))),
                  SizedBox(height: 4.h),
                  Center(child: Text('Sports card profit tracking',
                      style: GoogleFonts.inter(fontSize: 10.sp, color: AppColors.textMuted))),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Exit App Dialog ──────────────────────────────────────────────────────
  void _showExitDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.5),
      builder: (_) => _BlurDialog(
        icon: Icons.exit_to_app_rounded,
        iconColor: AppColors.primary,
        title: 'Exit App',
        message: 'Are you sure you want to close Hobby Watch?\nYour collection is safe.',
        cancelLabel: 'Stay',
        confirmLabel: 'Exit',
        confirmColor: AppColors.primary,
        onConfirm: () => SystemNavigator.pop(),
      ),
    );
  }

  // ── Sign Out Dialog ───────────────────────────────────────────────────────
  void _showSignOutDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.5),
      builder: (_) => _BlurDialog(
        icon: Icons.logout_rounded,
        iconColor: AppColors.loss,
        title: 'Sign Out',
        message: 'You\'ll need to sign back in to access your collection.',
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

  Widget _drawerGroupLabel(String label) {
    return Padding(
      padding: EdgeInsets.only(left: 4.w),
      child: Text(label,
          style: GoogleFonts.inter(fontSize: 10.sp, fontWeight: FontWeight.w700,
              color: AppColors.textMuted, letterSpacing: 1.2)),
    );
  }

  Widget _drawerTile(IconData icon, String label, String subtitle, Color iconColor, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
        decoration: BoxDecoration(
          color: AppColors.bgDark,
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(children: [
          Container(
            width: 36.w, height: 36.w,
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(9.r),
            ),
            child: Icon(icon, color: iconColor, size: 18.sp),
          ),
          SizedBox(width: 12.w),
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: GoogleFonts.inter(fontSize: 13.sp, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
              Text(subtitle, style: GoogleFonts.inter(fontSize: 10.sp, color: AppColors.textMuted)),
            ],
          )),
          Icon(Icons.chevron_right_rounded, color: AppColors.border, size: 16.sp),
        ]),
      ),
    );
  }

  Widget _drawerStat(String label, String value, {bool highlight = false}) {
    return Expanded(child: Column(children: [
      Text(value,
          style: GoogleFonts.inter(fontSize: 13.sp, fontWeight: FontWeight.w800,
              color: highlight ? const Color(0xFF4CD6C5) : Colors.white),
          maxLines: 1, overflow: TextOverflow.ellipsis),
      SizedBox(height: 2.h),
      Text(label, style: GoogleFonts.inter(fontSize: 10.sp, color: Colors.white60)),
    ]));
  }

  Future<void> _launchBugReportForm() async {
    final uri = Uri.parse(
      'https://docs.google.com/forms/d/e/1FAIpQLSfI-39jzI3eyba04NK9DgsqQtRoQdaNyKadhSFzmz_TklAAFg/viewform',
    );
    try {
      final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!launched) throw Exception('launch returned false');
    } catch (_) {
      Get.snackbar('Could not open form', 'Please check your internet connection and try again.',
          snackPosition: SnackPosition.BOTTOM, margin: const EdgeInsets.all(16), borderRadius: 12);
    }
  }

  Widget _drawerDivider() {
    return Container(width: 1, height: 28.h, color: Colors.white.withOpacity(0.15),
        margin: EdgeInsets.symmetric(horizontal: 8.w));
  }
}

// ── Alert Card ─────────────────────────────────────────────────────────────
class _AlertCard extends StatelessWidget {
  final CardModel card;
  const _AlertCard({required this.card});

  @override
  Widget build(BuildContext context) {
    final margin = card.currentMarginPercent ?? 0;
    return GestureDetector(
      onTap: () => Get.toNamed(AppRoutes.cardDetail, arguments: card),
      child: Container(
        width: 190.w,
        padding: EdgeInsets.all(14.w),
        decoration: BoxDecoration(
          gradient: AppColors.profitGradient,
          borderRadius: BorderRadius.circular(16.r),
          boxShadow: [BoxShadow(color: AppColors.accent.withOpacity(0.25), blurRadius: 12, offset: const Offset(0, 4))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
              decoration: BoxDecoration(color: Colors.white.withOpacity(0.18), borderRadius: BorderRadius.circular(20.r)),
              child: Text('🎯 SELL NOW', style: GoogleFonts.inter(fontSize: 10.sp, fontWeight: FontWeight.w700, color: Colors.white)),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(card.playerName, style: GoogleFonts.inter(fontSize: 13.sp, fontWeight: FontWeight.w700, color: Colors.white), maxLines: 1, overflow: TextOverflow.ellipsis),
                Text('${card.year} • ${card.setName ?? ""}', style: GoogleFonts.inter(fontSize: 11.sp, color: Colors.white70), maxLines: 1, overflow: TextOverflow.ellipsis),
                SizedBox(height: 4.h),
                Text('+${margin.toStringAsFixed(1)}% profit', style: GoogleFonts.inter(fontSize: 15.sp, fontWeight: FontWeight.w700, color: Colors.white)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── Card Row ───────────────────────────────────────────────────────────────
class _CardRow extends StatelessWidget {
  final CardModel card;
  const _CardRow({required this.card});

  @override
  Widget build(BuildContext context) {
    final margin = card.currentMarginPercent ?? 0;
    final isProfit = margin >= 0;
    final fmt = NumberFormat.currency(symbol: '\$', decimalDigits: 2);

    return GestureDetector(
      onTap: () => Get.toNamed(AppRoutes.cardDetail, arguments: card),
      child: Container(
        padding: EdgeInsets.all(14.w),
        decoration: BoxDecoration(
          color: card.isTargetReached ? AppColors.accent.withOpacity(0.05) : AppColors.bgCard,
          borderRadius: BorderRadius.circular(14.r),
          border: Border.all(color: card.isTargetReached ? AppColors.accent.withOpacity(0.3) : AppColors.border),
        ),
        child: Row(
          children: [
            Container(
              width: 42.w, height: 42.w,
              decoration: BoxDecoration(
                gradient: card.isTargetReached ? AppColors.accentGradient : AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(10.r),
              ),
              child: Icon(Icons.style_rounded, color: Colors.white, size: 20.sp),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(card.playerName, style: GoogleFonts.inter(fontSize: 14.sp, fontWeight: FontWeight.w600, color: AppColors.textPrimary), maxLines: 1, overflow: TextOverflow.ellipsis),
                  SizedBox(height: 2.h),
                  Text('${card.year} • ${card.setName ?? "—"}', style: GoogleFonts.inter(fontSize: 11.sp, color: AppColors.textMuted), maxLines: 1, overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
            SizedBox(width: 8.w),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(fmt.format(card.currentEbayAvg30 ?? card.purchasePrice),
                    style: GoogleFonts.inter(fontSize: 14.sp, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                SizedBox(height: 3.h),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 7.w, vertical: 2.h),
                  decoration: BoxDecoration(
                    color: card.isTargetReached ? AppColors.accent.withOpacity(0.15) : isProfit ? AppColors.accent.withOpacity(0.08) : AppColors.loss.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6.r),
                  ),
                  child: Text(
                    '${isProfit ? "+" : ""}${margin.toStringAsFixed(1)}%',
                    style: GoogleFonts.inter(fontSize: 11.sp, fontWeight: FontWeight.w600,
                        color: card.isTargetReached ? AppColors.accent : isProfit ? AppColors.accent : AppColors.loss),
                  ),
                ),
              ],
            ),
            if (card.isTargetReached) ...[
              SizedBox(width: 6.w),
              Icon(Icons.circle_notifications_rounded, color: AppColors.accent, size: 18.sp),
            ],
          ],
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback? onTap;
  final int badgeCount;
  const _NavItem({required this.icon, required this.label, required this.isActive, this.onTap, this.badgeCount = 0});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(clipBehavior: Clip.none, children: [
            Icon(icon, color: isActive ? AppColors.primary : AppColors.textMuted, size: 22.sp),
            if (badgeCount > 0)
              Positioned(
                right: -6,
                top: -4,
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 5.w, vertical: 1.h),
                  constraints: BoxConstraints(minWidth: 16.w, minHeight: 16.w),
                  decoration: const BoxDecoration(color: AppColors.loss, shape: BoxShape.circle),
                  alignment: Alignment.center,
                  child: Text(
                    badgeCount > 9 ? '9+' : '$badgeCount',
                    style: GoogleFonts.inter(fontSize: 9.sp, fontWeight: FontWeight.w700, color: Colors.white),
                  ),
                ),
              ),
          ]),
          SizedBox(height: 4.h),
          Text(label, style: GoogleFonts.inter(fontSize: 10.sp, color: isActive ? AppColors.primary : AppColors.textMuted, fontWeight: isActive ? FontWeight.w600 : FontWeight.w400)),
        ],
      ),
    );
  }
}

// ── Reusable blurred dialog ───────────────────────────────────────────────────
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
      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
      child: Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: EdgeInsets.symmetric(horizontal: 28.w),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.bgCard,
            borderRadius: BorderRadius.circular(24.r),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 32, offset: const Offset(0, 8)),
            ],
          ),
          padding: EdgeInsets.all(24.w),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Icon
              Container(
                width: 60.w, height: 60.w,
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: iconColor, size: 28.sp),
              ),
              SizedBox(height: 16.h),

              Text(title,
                  style: GoogleFonts.inter(fontSize: 18.sp, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                  textAlign: TextAlign.center),
              SizedBox(height: 8.h),
              Text(message,
                  style: GoogleFonts.inter(fontSize: 13.sp, color: AppColors.textSecondary, height: 1.5),
                  textAlign: TextAlign.center),

              SizedBox(height: 24.h),

              Row(children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.textSecondary,
                      side: const BorderSide(color: AppColors.border),
                      minimumSize: Size(0, 48.h),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                    ),
                    child: Text(cancelLabel,
                        style: GoogleFonts.inter(fontSize: 14.sp, fontWeight: FontWeight.w600)),
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: ElevatedButton(
                    onPressed: onConfirm,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: confirmColor,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      minimumSize: Size(0, 48.h),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                    ),
                    child: Text(confirmLabel,
                        style: GoogleFonts.inter(fontSize: 14.sp, fontWeight: FontWeight.w700)),
                  ),
                ),
              ]),
            ],
          ),
        ),
      ),
    );
  }
}