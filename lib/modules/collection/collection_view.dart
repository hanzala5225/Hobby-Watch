import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../app/theme/app_theme.dart';
import '../../data/models/card_model.dart';
import '../routes/app_routes.dart';
import 'collection_controller.dart';
import 'package:cached_network_image/cached_network_image.dart';

class CollectionView extends GetView<CollectionController> {
  const CollectionView({super.key});

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat.currency(symbol: '\$', decimalDigits: 2);
    return Scaffold(
      backgroundColor: AppColors.bgDark,
      appBar: AppBar(
        backgroundColor: AppColors.bgDark,
        title: Text('My Collection', style: GoogleFonts.inter(fontSize: 18.sp, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
        leading: IconButton(icon: Icon(Icons.arrow_back_ios_new, color: AppColors.textPrimary, size: 20.sp), onPressed: Get.back),
        actions: [
          // Sold history button with badge
          Obx(() {
            final soldCount = controller.soldCards.length;
            return Stack(
              alignment: Alignment.topRight,
              children: [
                IconButton(
                  icon: Icon(Icons.sell_outlined, color: AppColors.accent, size: 22.sp),
                  tooltip: 'Sold History',
                  onPressed: () => Get.toNamed(AppRoutes.soldHistory),
                ),
                if (soldCount > 0)
                  Positioned(
                    top: 8.h, right: 6.w,
                    child: Container(
                      width: 16.w, height: 16.w,
                      decoration: const BoxDecoration(color: AppColors.accent, shape: BoxShape.circle),
                      child: Center(
                        child: Text('$soldCount',
                            style: GoogleFonts.inter(fontSize: 9.sp, fontWeight: FontWeight.w700, color: Colors.white)),
                      ),
                    ),
                  ),
              ],
            );
          }),
          IconButton(
            icon: Icon(Icons.add_rounded, color: AppColors.accent, size: 24.sp),
            onPressed: () => Get.toNamed(AppRoutes.scanCard),
          ),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: EdgeInsets.fromLTRB(20.w, 8.h, 20.w, 12.h),
            child: TextFormField(
              controller: controller.searchController,
              onChanged: controller.onSearchChanged,
              style: GoogleFonts.inter(color: AppColors.textPrimary, fontSize: 14.sp),
              decoration: InputDecoration(
                hintText: 'Search by player, set...',
                prefixIcon: Icon(Icons.search, color: AppColors.textMuted, size: 20.sp),
                contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
              ),
            ),
          ),
          Obx(() => Padding(
            padding: EdgeInsets.fromLTRB(20.w, 0, 20.w, 12.h),
            child: Row(children: [
              _filterChip('All', 'all'),
              SizedBox(width: 8.w),
              _filterChip('🎯 Ready to Sell', 'targetReached'),
            ]),
          )),
          Expanded(
            child: Obx(() {
              if (controller.isLoading.value) {
                return const Center(child: CircularProgressIndicator(color: AppColors.accent, strokeWidth: 2.5));
              }
              final cards = controller.filteredCards;
              if (cards.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.style_outlined, size: 52.sp, color: AppColors.textMuted),
                      SizedBox(height: 16.h),
                      Text(
                        controller.filterMode.value == 'targetReached'
                            ? 'No cards ready to sell yet'
                            : 'No cards found',
                        style: GoogleFonts.inter(fontSize: 16.sp, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                );
              }
              return RefreshIndicator(
                color: AppColors.accent,
                onRefresh: controller.loadCards,
                child: ListView.separated(
                  padding: EdgeInsets.fromLTRB(20.w, 0, 20.w, 100.h),
                  itemCount: cards.length,
                  separatorBuilder: (_, __) => SizedBox(height: 10.h),
                  itemBuilder: (_, i) => _CollectionCardTile(card: cards[i], onDelete: () => controller.deleteCard(cards[i].id), fmt: fmt),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _filterChip(String label, String value) {
    final isActive = controller.filterMode.value == value;
    return GestureDetector(
      onTap: () => controller.filterMode.value = value,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
        decoration: BoxDecoration(
          color: isActive ? AppColors.accent.withOpacity(0.15) : AppColors.bgCard,
          borderRadius: BorderRadius.circular(20.r),
          border: Border.all(color: isActive ? AppColors.accent : AppColors.border),
        ),
        child: Text(label, style: GoogleFonts.inter(fontSize: 12.sp, fontWeight: FontWeight.w600,
            color: isActive ? AppColors.accent : AppColors.textSecondary)),
      ),
    );
  }
}


class _CollectionCardTile extends StatelessWidget {
  final CardModel card;
  final VoidCallback onDelete;
  final NumberFormat fmt;
  const _CollectionCardTile({required this.card, required this.onDelete, required this.fmt});

  @override
  Widget build(BuildContext context) {
    final margin = card.currentMarginPercent ?? 0;
    final isProfit = margin >= 0;
    return Dismissible(
      key: Key(card.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: EdgeInsets.only(right: 20.w),
        decoration: BoxDecoration(color: AppColors.loss, borderRadius: BorderRadius.circular(14.r)),
        child: Icon(Icons.delete_outline_rounded, color: Colors.white, size: 24.sp),
      ),
      confirmDismiss: (_) async {
        final isProfitable = (card.currentMarginPercent ?? 0) > 0;
        final isTargetReached = card.isTargetReached;
        final fmt2 = NumberFormat.currency(symbol: '\$', decimalDigits: 2);

        return await showDialog<bool>(
          context: context,
          barrierColor: Colors.black.withOpacity(0.55),
          builder: (_) => BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Dialog(
              backgroundColor: Colors.transparent,
              insetPadding: EdgeInsets.symmetric(horizontal: 24.w),
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.bgCard,
                  borderRadius: BorderRadius.circular(24.r),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 32, offset: const Offset(0, 8))],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Header — red always, but extra warning if profitable
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(20.w),
                      decoration: BoxDecoration(
                        color: isTargetReached
                            ? AppColors.accent.withOpacity(0.08)
                            : AppColors.loss.withOpacity(0.06),
                        borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
                        border: Border(bottom: BorderSide(
                            color: isTargetReached
                                ? AppColors.accent.withOpacity(0.15)
                                : AppColors.loss.withOpacity(0.12))),
                      ),
                      child: Column(children: [
                        Container(
                          width: 52.w, height: 52.w,
                          decoration: BoxDecoration(
                            color: isTargetReached
                                ? AppColors.accent.withOpacity(0.12)
                                : AppColors.loss.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            isTargetReached ? Icons.emoji_events_rounded : Icons.delete_forever_rounded,
                            color: isTargetReached ? AppColors.accent : AppColors.loss,
                            size: 24.sp,
                          ),
                        ),
                        SizedBox(height: 10.h),
                        Text(
                          isTargetReached ? 'Wait — this card is hot! 🔥' : 'Delete Card?',
                          style: GoogleFonts.inter(
                              fontSize: 17.sp, fontWeight: FontWeight.w800,
                              color: isTargetReached ? AppColors.accent : AppColors.loss),
                          textAlign: TextAlign.center,
                        ),
                      ]),
                    ),

                    Padding(
                      padding: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, 20.h),
                      child: Column(children: [
                        // Card info
                        Container(
                          padding: EdgeInsets.all(12.w),
                          decoration: BoxDecoration(
                            color: AppColors.bgSurface,
                            borderRadius: BorderRadius.circular(12.r),
                          ),
                          child: Row(children: [
                            Container(
                              width: 38.w, height: 48.h,
                              decoration: BoxDecoration(
                                gradient: isTargetReached ? AppColors.profitGradient : AppColors.primaryGradient,
                                borderRadius: BorderRadius.circular(8.r),
                              ),
                              child: card.imageUrl != null
                                  ? ClipRRect(
                                borderRadius: BorderRadius.circular(8.r),
                                child: CachedNetworkImage(imageUrl: card.imageUrl!, fit: BoxFit.cover,
                                    errorWidget: (_, __, ___) => Icon(Icons.style_rounded, color: Colors.white, size: 18.sp)),
                              )
                                  : Icon(Icons.style_rounded, color: Colors.white, size: 18.sp),
                            ),
                            SizedBox(width: 12.w),
                            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Text(card.playerName,
                                  style: GoogleFonts.inter(fontSize: 13.sp, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                                  maxLines: 1, overflow: TextOverflow.ellipsis),
                              Text('${card.year} • ${card.setName ?? ""}',
                                  style: GoogleFonts.inter(fontSize: 11.sp, color: AppColors.textMuted)),
                            ])),
                            if (isProfitable)
                              Text('+${(card.currentMarginPercent ?? 0).toStringAsFixed(1)}%',
                                  style: GoogleFonts.inter(fontSize: 14.sp, fontWeight: FontWeight.w800,
                                      color: isTargetReached ? AppColors.accent : AppColors.accent)),
                          ]),
                        ),

                        SizedBox(height: 14.h),

                        // Warning message
                        if (isTargetReached) ...[
                          Container(
                            padding: EdgeInsets.all(12.w),
                            decoration: BoxDecoration(
                              color: AppColors.accent.withOpacity(0.06),
                              borderRadius: BorderRadius.circular(12.r),
                              border: Border.all(color: AppColors.accent.withOpacity(0.2)),
                            ),
                            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Icon(Icons.trending_up_rounded, color: AppColors.accent, size: 16.sp),
                              SizedBox(width: 8.w),
                              Expanded(child: Text(
                                  'This card has hit your target margin! Consider marking it as sold instead — you\'ll keep your profit record.',
                                  style: GoogleFonts.inter(fontSize: 12.sp, color: AppColors.textSecondary, height: 1.4))),
                            ]),
                          ),
                          SizedBox(height: 10.h),
                        ] else if (isProfitable) ...[
                          Container(
                            padding: EdgeInsets.all(12.w),
                            decoration: BoxDecoration(
                              color: AppColors.accent.withOpacity(0.06),
                              borderRadius: BorderRadius.circular(12.r),
                              border: Border.all(color: AppColors.accent.withOpacity(0.15)),
                            ),
                            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Icon(Icons.lightbulb_outline_rounded, color: AppColors.accent, size: 16.sp),
                              SizedBox(width: 8.w),
                              Expanded(child: Text(
                                  'This card is currently in profit. Deleting removes it permanently — no profit record saved.',
                                  style: GoogleFonts.inter(fontSize: 12.sp, color: AppColors.textSecondary, height: 1.4))),
                            ]),
                          ),
                          SizedBox(height: 10.h),
                        ] else ...[
                          Text('This card will be permanently removed from your collection.',
                              style: GoogleFonts.inter(fontSize: 13.sp, color: AppColors.textSecondary, height: 1.4),
                              textAlign: TextAlign.center),
                          SizedBox(height: 14.h),
                        ],

                        // Buttons
                        if (isTargetReached || isProfitable) ...[
                          // Primary: mark as sold
                          GestureDetector(
                            onTap: () => Navigator.pop(context, false),
                            child: Container(
                              width: double.infinity, height: 48.h,
                              decoration: BoxDecoration(
                                gradient: AppColors.profitGradient,
                                borderRadius: BorderRadius.circular(12.r),
                              ),
                              child: Center(child: Text('Mark as Sold Instead',
                                  style: GoogleFonts.inter(fontSize: 14.sp, fontWeight: FontWeight.w700, color: Colors.white))),
                            ),
                          ),
                          SizedBox(height: 8.h),
                          // Secondary: delete anyway
                          TextButton(
                            onPressed: () => Navigator.pop(context, true),
                            child: Text('Delete anyway',
                                style: GoogleFonts.inter(fontSize: 13.sp, color: AppColors.loss, fontWeight: FontWeight.w500)),
                          ),
                        ] else ...[
                          Row(children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () => Navigator.pop(context, false),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: AppColors.textSecondary,
                                  side: const BorderSide(color: AppColors.border),
                                  minimumSize: Size(0, 48.h),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                                ),
                                child: Text('Cancel', style: GoogleFonts.inter(fontSize: 14.sp, fontWeight: FontWeight.w600)),
                              ),
                            ),
                            SizedBox(width: 10.w),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () => Navigator.pop(context, true),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.loss,
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  minimumSize: Size(0, 48.h),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                                ),
                                child: Text('Delete', style: GoogleFonts.inter(fontSize: 14.sp, fontWeight: FontWeight.w700)),
                              ),
                            ),
                          ]),
                        ],
                      ]),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ) ?? false;
      },
      onDismissed: (_) => onDelete(),
      child: GestureDetector(
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
                width: 44.w, height: 56.h,
                decoration: BoxDecoration(
                  gradient: card.isTargetReached ? AppColors.accentGradient : AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(10.r),
                ),
                child: card.imageUrl != null
                    ? ClipRRect(
                  borderRadius: BorderRadius.circular(10.r),
                  child: CachedNetworkImage(imageUrl: card.imageUrl!, fit: BoxFit.cover,
                      errorWidget: (_, __, ___) => Icon(Icons.style_rounded, color: Colors.white, size: 22.sp)),
                )
                    : Icon(Icons.style_rounded, color: Colors.white, size: 22.sp),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(card.playerName, style: GoogleFonts.inter(fontSize: 14.sp, fontWeight: FontWeight.w600, color: AppColors.textPrimary), maxLines: 1, overflow: TextOverflow.ellipsis),
                    SizedBox(height: 2.h),
                    Text('${card.year} ${card.setName ?? ""}', style: GoogleFonts.inter(fontSize: 11.sp, color: AppColors.textMuted)),
                    SizedBox(height: 4.h),
                    Text('Paid: ${fmt.format(card.purchasePrice)}', style: GoogleFonts.inter(fontSize: 11.sp, color: AppColors.textSecondary)),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(card.currentEbayAvg30 != null ? fmt.format(card.currentEbayAvg30!) : '—',
                      style: GoogleFonts.inter(fontSize: 14.sp, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                  SizedBox(height: 4.h),
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
                  if (card.isTargetReached) ...[
                    SizedBox(height: 4.h),
                    Text('🎯 Sell now', style: GoogleFonts.inter(fontSize: 10.sp, fontWeight: FontWeight.w700, color: AppColors.accent)),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
