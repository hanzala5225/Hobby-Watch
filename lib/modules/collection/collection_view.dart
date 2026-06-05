import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../app/theme/app_theme.dart';
import '../../data/models/card_model.dart';
import '../routes/app_routes.dart';
import 'collection_controller.dart';

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
                      decoration: BoxDecoration(color: AppColors.accent, shape: BoxShape.circle),
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
          Expanded(
            child: Obx(() {
              if (controller.isLoading.value) {
                return Center(child: CircularProgressIndicator(color: AppColors.accent, strokeWidth: 2.5));
              }
              final cards = controller.filteredCards;
              if (cards.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.style_outlined, size: 52.sp, color: AppColors.textMuted),
                      SizedBox(height: 16.h),
                      Text('No cards found', style: GoogleFonts.inter(fontSize: 16.sp, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
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
        return await Get.dialog<bool>(
          AlertDialog(
            backgroundColor: AppColors.bgCard,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
            title: Text('Delete Card?', style: GoogleFonts.inter(fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
            content: Text('Remove ${card.playerName} from your collection?', style: GoogleFonts.inter(color: AppColors.textSecondary)),
            actions: [
              TextButton(onPressed: () => Get.back(result: false), child: Text('Cancel', style: GoogleFonts.inter(color: AppColors.textSecondary))),
              TextButton(onPressed: () { Get.back(result: true); }, child: Text('Delete', style: GoogleFonts.inter(color: AppColors.loss, fontWeight: FontWeight.w600))),
            ],
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
                child: Icon(Icons.style_rounded, color: Colors.white, size: 22.sp),
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