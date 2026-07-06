import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../app/theme/app_theme.dart';
import 'card_detail_controller.dart';

class CardDetailView extends GetView<CardDetailController> {
  const CardDetailView({super.key});

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat.currency(symbol: '\$', decimalDigits: 2);
    return Scaffold(
      backgroundColor: AppColors.bgDark,
      body: Obx(() {
        final card = controller.card.value;
        final margin = card.currentMarginPercent ?? 0;
        final isProfit = margin >= 0;
        final isSold = card.isSold;

        return CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: isSold
                      ? const LinearGradient(colors: [Color(0xFF5A6A8A), Color(0xFF8A9AB2)], begin: Alignment.topLeft, end: Alignment.bottomRight)
                      : card.isTargetReached ? AppColors.profitGradient : AppColors.heroGradient,
                ),
                child: SafeArea(
                  bottom: false,
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(4.w, 4.h, 4.w, 18.h),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Back + actions row
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            IconButton(
                              icon: Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20.sp),
                              onPressed: Get.back,
                            ),
                            Row(children: [
                              if (!isSold)
                                Obx(() => controller.isRefreshing.value
                                    ? Padding(padding: EdgeInsets.all(14.w),
                                    child: SizedBox(width: 20.w, height: 20.w, child: const CircularProgressIndicator(color: Colors.white, strokeWidth: 2)))
                                    : IconButton(icon: Icon(Icons.refresh_rounded, color: Colors.white, size: 22.sp), onPressed: controller.refreshPrice)),
                              IconButton(
                                icon: Icon(Icons.delete_outline_rounded, color: Colors.white70, size: 22.sp),
                                onPressed: () => _showDeleteDialog(context, card.playerName),
                              ),
                            ]),
                          ],
                        ),
                        // Badge + name
                        Padding(
                          padding: EdgeInsets.fromLTRB(16.w, 4.h, 16.w, 0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (isSold)
                                _heroBadge('✅ SOLD', Colors.white.withOpacity(0.25))
                              else if (card.isTargetReached)
                                _heroBadge('🎯 TARGET REACHED', Colors.white.withOpacity(0.2)),
                              if (isSold || card.isTargetReached) SizedBox(height: 8.h),
                              Text(card.playerName,
                                  style: GoogleFonts.inter(fontSize: 22.sp, fontWeight: FontWeight.w800, color: Colors.white)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.all(20.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Price boxes ──────────────────────────────────────
                    Row(children: [
                      Expanded(child: _PriceBox(
                        label: isSold ? 'Sold For' : 'Market Price',
                        value: isSold
                            ? (card.soldPrice != null ? fmt.format(card.soldPrice!) : '—')
                            : (card.currentEbayAvg30 != null ? fmt.format(card.currentEbayAvg30!) : '—'),
                        accent: true,
                      )),
                      SizedBox(width: 10.w),
                      Expanded(child: _PriceBox(label: 'Paid', value: fmt.format(card.purchasePrice))),
                    ]),
                    SizedBox(height: 10.h),
                    Row(children: [
                      Expanded(child: _PriceBox(
                        label: 'Margin (after fees)',
                        value: '${isProfit ? "+" : ""}${margin.toStringAsFixed(1)}%',
                        color: card.isTargetReached ? AppColors.accent : isProfit ? AppColors.accent : AppColors.loss,
                      )),
                      SizedBox(width: 10.w),
                      Expanded(child: _PriceBox(
                        label: 'Profit / Loss',
                        value: card.profitDollar != null
                            ? '${card.profitDollar! >= 0 ? "+" : ""}${fmt.format(card.profitDollar!)}'
                            : '—',
                        color: (card.profitDollar ?? 0) >= 0 ? AppColors.accent : AppColors.loss,
                      )),
                    ]),

                    SizedBox(height: 20.h),

                    // ── SOLD BUTTON (only if not already sold) ───────────
                    if (!isSold) ...[
                      Obx(() => GestureDetector(
                        onTap: controller.isMarkingSold.value
                            ? null
                            : () => controller.showMarkSoldDialog(context),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          height: 54.h,
                          decoration: BoxDecoration(
                            gradient: card.isTargetReached
                                ? AppColors.profitGradient
                                : AppColors.heroGradient,
                            borderRadius: BorderRadius.circular(14.r),
                            boxShadow: [
                              BoxShadow(
                                color: (card.isTargetReached ? AppColors.accent : AppColors.primary).withOpacity(0.3),
                                blurRadius: 16, offset: const Offset(0, 5),
                              ),
                            ],
                            border: card.isTargetReached
                                ? Border.all(color: Colors.white.withOpacity(0.2), width: 1.5)
                                : null,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              if (controller.isMarkingSold.value)
                                const SizedBox(width: 20, height: 20,
                                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                              else ...[
                                Icon(Icons.sell_rounded, color: Colors.white, size: 20.sp),
                                SizedBox(width: 10.w),
                                Text(
                                  card.isTargetReached ? '🎯 Mark as Sold — Target Reached!' : 'Mark as Sold',
                                  style: GoogleFonts.inter(fontSize: 14.sp, fontWeight: FontWeight.w700, color: Colors.white),
                                ),
                              ],
                            ],
                          ),
                        ),
                      )),
                      SizedBox(height: 20.h),
                    ],

                    // ── Details ──────────────────────────────────────────
                    Text('Card Details',
                        style: GoogleFonts.inter(fontSize: 15.sp, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                    SizedBox(height: 12.h),
                    Container(
                      padding: EdgeInsets.all(16.w),
                      decoration: BoxDecoration(
                        color: AppColors.bgCard,
                        borderRadius: BorderRadius.circular(16.r),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Column(children: [
                        _detailRow('Target Margin', '${card.targetMarginPercent.toStringAsFixed(0)}%'),
                        _detailRow('eBay Fee', '${card.ebayFeePercent.toStringAsFixed(1)}%'),
                        _detailRow('Added Via', card.addedVia.capitalizeFirst ?? card.addedVia),
                        if (isSold && card.soldAt != null)
                          _detailRow('Sold On', DateFormat('MMM d, y').format(card.soldAt!.toLocal())),
                        _detailRow('Last Update',
                            card.lastPriceUpdate != null
                                ? DateFormat('MMM d, y h:mm a').format(card.lastPriceUpdate!.toLocal())
                                : 'Not yet refreshed'),
                        _detailRow('Added', DateFormat('MMM d, y').format(card.createdAt.toLocal())),
                      ]),
                    ),

                    SizedBox(height: 24.h),

                    // ── Price History ─────────────────────────────────────
                    Text('Price History',
                        style: GoogleFonts.inter(fontSize: 15.sp, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                    SizedBox(height: 12.h),
                    Obx(() {
                      if (controller.priceHistory.isEmpty) {
                        return Container(
                          padding: EdgeInsets.all(20.w),
                          decoration: BoxDecoration(
                            color: AppColors.bgCard,
                            borderRadius: BorderRadius.circular(16.r),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Center(child: Text('No history yet.',
                              style: GoogleFonts.inter(fontSize: 13.sp, color: AppColors.textMuted))),
                        );
                      }
                      return Container(
                        decoration: BoxDecoration(
                          color: AppColors.bgCard,
                          borderRadius: BorderRadius.circular(16.r),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Column(
                          children: controller.priceHistory.take(10).map((h) {
                            final avg = (h['avg30'] as num?)?.toDouble();
                            final m = (h['marginPercent'] as num?)?.toDouble() ?? 0;
                            final src = h['refreshSource'] ?? 'background';
                            final date = h['fetchedAt'] != null
                                ? DateTime.parse(h['fetchedAt']).toLocal()
                                : DateTime.now();
                            return Container(
                              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                              decoration: BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.divider))),
                              child: Row(children: [
                                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                  Text(DateFormat('MMM d, h:mm a').format(date),
                                      style: GoogleFonts.inter(fontSize: 12.sp, color: AppColors.textSecondary)),
                                  Text(src, style: GoogleFonts.inter(fontSize: 10.sp, color: AppColors.textMuted)),
                                ])),
                                Text(avg != null ? fmt.format(avg) : '—',
                                    style: GoogleFonts.inter(fontSize: 14.sp, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                                SizedBox(width: 8.w),
                                Text('${m >= 0 ? "+" : ""}${m.toStringAsFixed(1)}%',
                                    style: GoogleFonts.inter(fontSize: 12.sp, fontWeight: FontWeight.w600,
                                        color: m >= 0 ? AppColors.accent : AppColors.loss)),
                              ]),
                            );
                          }).toList(),
                        ),
                      );
                    }),

                    SizedBox(height: 100.h),
                  ],
                ),
              ),
            ),
          ],
        );
      }),
    );
  }

  Widget _heroBadge(String text, Color bg) {
    return Container(
      margin: EdgeInsets.only(bottom: 6.h),
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20.r)),
      child: Text(text, style: GoogleFonts.inter(fontSize: 11.sp, fontWeight: FontWeight.w700, color: Colors.white)),
    );
  }

  void _showDeleteDialog(BuildContext context, String playerName) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.bgCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
        title: Text('Remove Card?', style: GoogleFonts.inter(fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
        content: Text('Remove $playerName from your collection?',
            style: GoogleFonts.inter(color: AppColors.textSecondary)),
        actions: [
          TextButton(onPressed: Get.back,
              child: Text('Cancel', style: GoogleFonts.inter(color: AppColors.textSecondary))),
          TextButton(onPressed: controller.deleteCard,
              child: Text('Remove', style: GoogleFonts.inter(color: AppColors.loss, fontWeight: FontWeight.w600))),
        ],
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8.h),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(label, style: GoogleFonts.inter(fontSize: 13.sp, color: AppColors.textSecondary)),
        Text(value, style: GoogleFonts.inter(fontSize: 13.sp, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
      ]),
    );
  }
}

class _PriceBox extends StatelessWidget {
  final String label, value;
  final bool accent;
  final Color? color;
  const _PriceBox({required this.label, required this.value, this.accent = false, this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: accent ? AppColors.primary.withOpacity(0.06) : AppColors.bgCard,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: accent ? AppColors.primary.withOpacity(0.2) : AppColors.border),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: GoogleFonts.inter(fontSize: 11.sp, color: AppColors.textMuted)),
        SizedBox(height: 6.h),
        Text(value, style: GoogleFonts.inter(
            fontSize: 16.sp, fontWeight: FontWeight.w700,
            color: color ?? (accent ? AppColors.primary : AppColors.textPrimary))),
      ]),
    );
  }
}