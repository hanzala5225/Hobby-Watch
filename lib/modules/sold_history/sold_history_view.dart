import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../app/theme/app_theme.dart';
import '../../data/models/card_model.dart';
import '../routes/app_routes.dart';
import 'sold_history_controller.dart';

class SoldHistoryView extends GetView<SoldHistoryController> {
  const SoldHistoryView({super.key});

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat.currency(symbol: '\$', decimalDigits: 2);

    return Scaffold(
      backgroundColor: AppColors.bgDark,
      appBar: AppBar(
        backgroundColor: AppColors.bgDark,
        title: Text('Sold Cards',
            style: GoogleFonts.inter(fontSize: 18.sp, fontWeight: FontWeight.w700, color: AppColors.primary)),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, color: AppColors.primary, size: 20.sp),
          onPressed: Get.back,
        ),
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator(color: AppColors.accent, strokeWidth: 2.5));
        }

        return RefreshIndicator(
          color: AppColors.accent,
          onRefresh: controller.loadSoldCards,
          child: CustomScrollView(
            slivers: [
              // ── Lifetime P&L Stats ─────────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(20.w, 8.h, 20.w, 0),
                  child: Obx(() {
                    final profit = controller.totalProfit;
                    final isPositive = profit >= 0;
                    final margin = controller.avgMargin;

                    return Container(
                      padding: EdgeInsets.all(18.w),
                      decoration: BoxDecoration(
                        gradient: isPositive ? AppColors.profitGradient : AppColors.heroGradient,
                        borderRadius: BorderRadius.circular(20.r),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(children: [
                            Icon(Icons.emoji_events_rounded, color: Colors.white70, size: 16.sp),
                            SizedBox(width: 6.w),
                            Text('Lifetime Results',
                                style: GoogleFonts.inter(fontSize: 12.sp, color: Colors.white70, fontWeight: FontWeight.w500)),
                          ]),
                          SizedBox(height: 10.h),

                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              // Total profit number
                              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                Text(
                                  '${isPositive ? "+" : ""}${fmt.format(profit)}',
                                  style: GoogleFonts.inter(fontSize: 30.sp, fontWeight: FontWeight.w800,
                                      color: Colors.white, height: 1),
                                ),
                                SizedBox(height: 4.h),
                                Text('Total profit / loss',
                                    style: GoogleFonts.inter(fontSize: 11.sp, color: Colors.white60)),
                              ]),
                              // Card count bubble
                              Container(
                                width: 54.w, height: 54.w,
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(14.r),
                                ),
                                child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                                  Text('${controller.soldCards.length}',
                                      style: GoogleFonts.inter(fontSize: 20.sp, fontWeight: FontWeight.w800, color: Colors.white)),
                                  Text('sold', style: GoogleFonts.inter(fontSize: 10.sp, color: Colors.white70)),
                                ]),
                              ),
                            ],
                          ),

                          SizedBox(height: 14.h),

                          // Stats row
                          Row(children: [
                            _statChip('Invested', fmt.format(controller.totalInvested)),
                            SizedBox(width: 8.w),
                            _statChip('Earned', fmt.format(controller.totalSoldFor)),
                            SizedBox(width: 8.w),
                            _statChip('Avg Margin', '${margin >= 0 ? "+" : ""}${margin.toStringAsFixed(1)}%',
                                highlight: margin >= 0),
                          ]),
                        ],
                      ),
                    );
                  }),
                ),
              ),

              SliverToBoxAdapter(child: SizedBox(height: 20.h)),

              // ── List header ────────────────────────────────────────────
              if (controller.soldCards.isNotEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20.w),
                    child: Row(children: [
                      Text('Sold Cards',
                          style: GoogleFonts.inter(fontSize: 15.sp, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                      SizedBox(width: 8.w),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
                        decoration: BoxDecoration(
                          color: AppColors.accent.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(20.r),
                        ),
                        child: Text('${controller.soldCards.length}',
                            style: GoogleFonts.inter(fontSize: 11.sp, fontWeight: FontWeight.w600, color: AppColors.accent)),
                      ),
                    ]),
                  ),
                ),

              SliverToBoxAdapter(child: SizedBox(height: 10.h)),

              // ── Cards list or empty state ───────────────────────────────
              if (controller.soldCards.isEmpty)
                SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 80.w, height: 80.w,
                          decoration: BoxDecoration(color: AppColors.bgCard, shape: BoxShape.circle,
                              border: Border.all(color: AppColors.border)),
                          child: Icon(Icons.sell_outlined, size: 36.sp, color: AppColors.textMuted),
                        ),
                        SizedBox(height: 20.h),
                        Text('No sold cards yet',
                            style: GoogleFonts.inter(fontSize: 17.sp, fontWeight: FontWeight.w700, color: AppColors.textSecondary)),
                        SizedBox(height: 8.h),
                        Text('When you mark a card as sold,\nit will appear here.',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.inter(fontSize: 13.sp, color: AppColors.textMuted, height: 1.5)),
                      ],
                    ),
                  ),
                )
              else
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                        (_, i) {
                      final c = controller.soldCards[i];
                      return Padding(
                        padding: EdgeInsets.fromLTRB(20.w, 0, 20.w, 10.h),
                        child: _SoldCardTile(card: c, fmt: fmt),
                      );
                    },
                    childCount: controller.soldCards.length,
                  ),
                ),

              SliverToBoxAdapter(child: SizedBox(height: 40.h)),
            ],
          ),
        );
      }),
    );
  }

  Widget _statChip(String label, String value, {bool highlight = false}) {
    return Expanded(
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 8.h),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.12),
          borderRadius: BorderRadius.circular(10.r),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(value,
              style: GoogleFonts.inter(fontSize: 12.sp, fontWeight: FontWeight.w800,
                  color: highlight ? const Color(0xFF4CD6C5) : Colors.white),
              maxLines: 1, overflow: TextOverflow.ellipsis),
          SizedBox(height: 2.h),
          Text(label, style: GoogleFonts.inter(fontSize: 10.sp, color: Colors.white60)),
        ]),
      ),
    );
  }
}

// ── Sold Card Tile ────────────────────────────────────────────────────────────
class _SoldCardTile extends StatelessWidget {
  final CardModel card;
  final NumberFormat fmt;
  const _SoldCardTile({required this.card, required this.fmt});

  @override
  Widget build(BuildContext context) {
    final soldPrice = card.soldPrice ?? 0;
    final combined = soldPrice + card.shippingCharge;
    final feePercent = card.soldOutsideEbay ? 0.0 : card.ebayFeePercent;
    final afterFees = combined * (1 - feePercent / 100);
    final profit = afterFees - card.purchasePrice;
    final marginPct = card.purchasePrice > 0 ? (profit / card.purchasePrice) * 100 : 0.0;
    final isProfit = profit >= 0;

    return GestureDetector(
      onTap: () => Get.toNamed(AppRoutes.cardDetail, arguments: card),
      child: Container(
        padding: EdgeInsets.all(14.w),
        decoration: BoxDecoration(
          color: AppColors.bgCard,
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Card icon
                Container(
                  width: 44.w, height: 54.h,
                  decoration: BoxDecoration(
                    color: AppColors.bgSurface,
                    borderRadius: BorderRadius.circular(10.r),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: card.imageUrl != null
                      ? ClipRRect(
                    borderRadius: BorderRadius.circular(10.r),
                    child: CachedNetworkImage(imageUrl: card.imageUrl!, fit: BoxFit.cover,
                        errorWidget: (_, __, ___) => Icon(Icons.style_rounded, color: AppColors.textMuted, size: 22.sp)),
                  )
                      : Icon(Icons.style_rounded, color: AppColors.textMuted, size: 22.sp),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(card.playerName,
                          style: GoogleFonts.inter(fontSize: 14.sp, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                          maxLines: 1, overflow: TextOverflow.ellipsis),
                      SizedBox(height: 2.h),
                      Text('${card.year}  •  ${card.setName ?? "—"}',
                          style: GoogleFonts.inter(fontSize: 11.sp, color: AppColors.textMuted)),
                      if (card.soldAt != null) ...[
                        SizedBox(height: 2.h),
                        Text('Sold ${DateFormat("MMM d, y").format(card.soldAt!.toLocal())}',
                            style: GoogleFonts.inter(fontSize: 10.sp, color: AppColors.textMuted)),
                      ],
                    ],
                  ),
                ),
                // Profit/loss badge
                Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                    decoration: BoxDecoration(
                      color: isProfit ? AppColors.accent.withOpacity(0.12) : AppColors.loss.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                    child: Text(
                      '${isProfit ? "+" : ""}${marginPct.toStringAsFixed(1)}%',
                      style: GoogleFonts.inter(fontSize: 12.sp, fontWeight: FontWeight.w700,
                          color: isProfit ? AppColors.accent : AppColors.loss),
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    '${isProfit ? "+" : ""}${fmt.format(profit)}',
                    style: GoogleFonts.inter(fontSize: 13.sp, fontWeight: FontWeight.w600,
                        color: isProfit ? AppColors.accent : AppColors.loss),
                  ),
                ]),
              ],
            ),
            SizedBox(height: 12.h),
            // Price breakdown row
            Container(
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
              decoration: BoxDecoration(color: AppColors.bgSurface, borderRadius: BorderRadius.circular(10.r)),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _priceCol('Bought for', fmt.format(card.purchasePrice), AppColors.textSecondary),
                  _divider(),
                  _priceCol('Sold for', fmt.format(soldPrice), AppColors.textPrimary),
                  _divider(),
                  _priceCol('After fees', fmt.format(afterFees), isProfit ? AppColors.accent : AppColors.loss),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _priceCol(String label, String value, Color color) {
    return Column(children: [
      Text(value, style: GoogleFonts.inter(fontSize: 12.sp, fontWeight: FontWeight.w700, color: color)),
      SizedBox(height: 2.h),
      Text(label, style: GoogleFonts.inter(fontSize: 9.sp, color: AppColors.textMuted)),
    ]);
  }

  Widget _divider() => Container(width: 1, height: 28.h, color: AppColors.border);
}