import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../app/theme/app_theme.dart';
import '../../data/models/ebay_result_model.dart';
import 'scan_card_controller.dart';

class ScanCardView extends GetView<ScanCardController> {
  const ScanCardView({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      switch (controller.currentStep.value) {
        case ScanStep.choose:     return _ChooseStep(c: controller);
        case ScanStep.processing: return _ProcessingStep(c: controller);
        case ScanStep.results:    return _ResultsStep(c: controller);
        case ScanStep.confirm:    return _ConfirmStep(c: controller);
        case ScanStep.manual:     return _ManualStep(c: controller);
      }
    });
  }
}

// ── STEP 1: Choose ──────────────────────────────────────────────────────────
class _ChooseStep extends StatelessWidget {
  final ScanCardController c;
  const _ChooseStep({required this.c});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgDark,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(8.w, 8.h, 20.w, 0),
              child: Row(children: [
                IconButton(
                  icon: Icon(Icons.close, color: AppColors.textSecondary, size: 22.sp),
                  onPressed: Get.back,
                ),
                Text('Add Card',
                    style: GoogleFonts.inter(fontSize: 18.sp, fontWeight: FontWeight.w700, color: AppColors.primary)),
              ]),
            ),
            Expanded(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 28.w),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(28.w),
                      decoration: BoxDecoration(
                        color: AppColors.bgCard,
                        borderRadius: BorderRadius.circular(20.r),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Column(children: [
                        _AnimatedScanFrame(),
                        SizedBox(height: 16.h),
                        Text('Position your card in the frame',
                            style: GoogleFonts.inter(fontSize: 13.sp, color: AppColors.textMuted)),
                      ]),
                    ),
                    SizedBox(height: 32.h),
                    Text('How would you like to add?',
                        style: GoogleFonts.inter(fontSize: 16.sp, fontWeight: FontWeight.w700, color: AppColors.primary)),
                    SizedBox(height: 20.h),
                    _OptionButton(icon: Icons.camera_alt_rounded, label: 'Scan with Camera',
                        subtitle: 'Point at card — we read the text', isPrimary: true, onTap: c.takePhoto),
                    SizedBox(height: 12.h),
                    _OptionButton(icon: Icons.photo_library_outlined, label: 'Choose from Gallery',
                        subtitle: 'Pick an existing photo', isPrimary: false, onTap: c.pickFromGallery),
                    SizedBox(height: 12.h),
                    GestureDetector(
                      onTap: c.enterManually,
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 10.h),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.edit_outlined, color: AppColors.textMuted, size: 16.sp),
                            SizedBox(width: 8.w),
                            Text('Enter card details manually',
                                style: GoogleFonts.inter(fontSize: 13.sp, color: AppColors.textSecondary)),
                          ],
                        ),
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
}

class _OptionButton extends StatelessWidget {
  final IconData icon;
  final String label, subtitle;
  final bool isPrimary;
  final VoidCallback onTap;
  const _OptionButton({required this.icon, required this.label, required this.subtitle, required this.isPrimary, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 14.h),
        decoration: BoxDecoration(
          gradient: isPrimary ? AppColors.heroGradient : null,
          color: isPrimary ? null : AppColors.bgCard,
          borderRadius: BorderRadius.circular(14.r),
          border: isPrimary ? null : Border.all(color: AppColors.border),
          boxShadow: isPrimary ? [BoxShadow(color: AppColors.primary.withOpacity(0.22), blurRadius: 14, offset: const Offset(0, 5))] : [],
        ),
        child: Row(children: [
          Container(
            width: 40.w, height: 40.w,
            decoration: BoxDecoration(
              color: isPrimary ? Colors.white.withOpacity(0.18) : AppColors.bgSurface,
              borderRadius: BorderRadius.circular(10.r),
            ),
            child: Icon(icon, color: isPrimary ? Colors.white : AppColors.primary, size: 20.sp),
          ),
          SizedBox(width: 14.w),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label, style: GoogleFonts.inter(fontSize: 14.sp, fontWeight: FontWeight.w600, color: isPrimary ? Colors.white : AppColors.textPrimary)),
            SizedBox(height: 2.h),
            Text(subtitle, style: GoogleFonts.inter(fontSize: 11.sp, color: isPrimary ? Colors.white70 : AppColors.textMuted)),
          ]),
          const Spacer(),
          Icon(Icons.arrow_forward_ios_rounded, size: 14.sp, color: isPrimary ? Colors.white60 : AppColors.textMuted),
        ]),
      ),
    );
  }
}

class _AnimatedScanFrame extends StatefulWidget {
  @override State<_AnimatedScanFrame> createState() => _AnimatedScanFrameState();
}
class _AnimatedScanFrameState extends State<_AnimatedScanFrame> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _line;
  @override void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat(reverse: true);
    _line = Tween<double>(begin: 0, end: 1).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }
  @override void dispose() { _ctrl.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 220.w, height: 148.h,
      child: Stack(children: [
        CustomPaint(size: Size(220.w, 148.h), painter: _CornerPainter(color: AppColors.accent)),
        AnimatedBuilder(
          animation: _line,
          builder: (_, __) => Positioned(
            top: _line.value * 128.h + 10.h, left: 10.w, right: 10.w,
            child: Container(height: 2, decoration: BoxDecoration(
                gradient: LinearGradient(colors: [Colors.transparent, AppColors.accent.withOpacity(0.8), Colors.transparent]))),
          ),
        ),
      ]),
    );
  }
}

class _CornerPainter extends CustomPainter {
  final Color color;
  const _CornerPainter({required this.color});
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()..color = color..strokeWidth = 2.5..style = PaintingStyle.stroke..strokeCap = StrokeCap.round;
    const l = 24.0, r = 10.0;
    canvas.drawLine(Offset(r, 0), Offset(l, 0), p);
    canvas.drawArc(Rect.fromLTWH(0, 0, r*2, r*2), -1.57, -1.57, false, p);
    canvas.drawLine(Offset(0, r), Offset(0, l), p);
    canvas.drawLine(Offset(size.width-l, 0), Offset(size.width-r, 0), p);
    canvas.drawArc(Rect.fromLTWH(size.width-r*2, 0, r*2, r*2), -1.57, 1.57, false, p);
    canvas.drawLine(Offset(size.width, r), Offset(size.width, l), p);
    canvas.drawLine(Offset(0, size.height-l), Offset(0, size.height-r), p);
    canvas.drawArc(Rect.fromLTWH(0, size.height-r*2, r*2, r*2), 3.14, -1.57, false, p);
    canvas.drawLine(Offset(r, size.height), Offset(l, size.height), p);
    canvas.drawLine(Offset(size.width, size.height-l), Offset(size.width, size.height-r), p);
    canvas.drawArc(Rect.fromLTWH(size.width-r*2, size.height-r*2, r*2, r*2), 0, 1.57, false, p);
    canvas.drawLine(Offset(size.width-l, size.height), Offset(size.width-r, size.height), p);
  }
  @override bool shouldRepaint(covariant CustomPainter o) => false;
}

// ── STEP 2: Processing ─────────────────────────────────────────────────────
class _ProcessingStep extends StatefulWidget {
  final ScanCardController c;
  const _ProcessingStep({required this.c});
  @override State<_ProcessingStep> createState() => _ProcessingStepState();
}
class _ProcessingStepState extends State<_ProcessingStep> with TickerProviderStateMixin {
  late AnimationController _pulse;
  late AnimationController _rotate;
  int _idx = 0;
  final _msgs = ['Reading card text...', 'Identifying card details...', 'Searching eBay listings...', 'Calculating market price...'];
  @override void initState() {
    super.initState();
    _pulse = AnimationController(vsync: this, duration: const Duration(milliseconds: 1400))..repeat(reverse: true);
    _rotate = AnimationController(vsync: this, duration: const Duration(seconds: 3))..repeat();
    Future.doWhile(() async {
      await Future.delayed(const Duration(milliseconds: 950));
      if (!mounted) return false;
      setState(() => _idx = (_idx + 1) % _msgs.length);
      return widget.c.isProcessing.value;
    });
  }
  @override void dispose() { _pulse.dispose(); _rotate.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgDark,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 28.w),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            ScaleTransition(
              scale: Tween(begin: 0.92, end: 1.0).animate(CurvedAnimation(parent: _pulse, curve: Curves.easeInOut)),
              child: Container(
                width: 88.w, height: 88.w,
                decoration: BoxDecoration(gradient: AppColors.heroGradient, shape: BoxShape.circle,
                    boxShadow: [BoxShadow(color: AppColors.primary.withOpacity(0.22), blurRadius: 28, offset: const Offset(0, 8))]),
                child: Icon(Icons.document_scanner_rounded, color: Colors.white, size: 38.sp),
              ),
            ),
            SizedBox(height: 40.h),
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(20.w),
              decoration: BoxDecoration(color: AppColors.bgCard, borderRadius: BorderRadius.circular(18.r), border: Border.all(color: AppColors.border)),
              child: Column(children: [
                Row(mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(4, (i) => AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      margin: EdgeInsets.symmetric(horizontal: 4.w),
                      width: i == _idx % 4 ? 22.w : 8.w, height: 8.h,
                      decoration: BoxDecoration(borderRadius: BorderRadius.circular(4.r),
                          color: i == _idx % 4 ? AppColors.accent : AppColors.border),
                    ))),
                SizedBox(height: 16.h),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 350),
                  child: Text(_msgs[_idx], key: ValueKey(_idx), textAlign: TextAlign.center,
                      style: GoogleFonts.inter(fontSize: 14.sp, color: AppColors.textPrimary, fontWeight: FontWeight.w600)),
                ),
                SizedBox(height: 6.h),
                Text('Please wait a moment', style: GoogleFonts.inter(fontSize: 12.sp, color: AppColors.textMuted)),
              ]),
            ),
            SizedBox(height: 32.h),
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(Icons.info_outline_rounded, color: AppColors.textMuted, size: 14.sp),
              SizedBox(width: 6.w),
              Text('Fetching live pricing from eBay', style: GoogleFonts.inter(fontSize: 12.sp, color: AppColors.textMuted)),
            ]),
          ]),
        ),
      ),
    );
  }
}

// ── STEP 3: Results — IMAGE GRID ────────────────────────────────────────────
class _ResultsStep extends StatelessWidget {
  final ScanCardController c;
  const _ResultsStep({required this.c});

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat.currency(symbol: '\$', decimalDigits: 2);
    return Scaffold(
      backgroundColor: AppColors.bgDark,
      appBar: AppBar(
        backgroundColor: AppColors.bgDark,
        leading: IconButton(icon: Icon(Icons.arrow_back_ios_new, color: AppColors.primary, size: 20.sp), onPressed: c.goBack),
        title: Text('Select Your Card', style: GoogleFonts.inter(fontSize: 18.sp, fontWeight: FontWeight.w700, color: AppColors.primary)),
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: EdgeInsets.fromLTRB(20.w, 4.h, 20.w, 0),
            child: Row(children: [
              Expanded(
                child: TextFormField(
                  controller: c.searchQueryController,
                  style: GoogleFonts.inter(color: AppColors.textPrimary, fontSize: 13.sp),
                  decoration: InputDecoration(
                    hintText: 'e.g. 2018 Panini Lamar Jackson PSA 10',
                    prefixIcon: Icon(Icons.search, color: AppColors.textMuted, size: 18.sp),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
                  ),
                ),
              ),
              SizedBox(width: 10.w),
              GestureDetector(
                onTap: c.retrySearch,
                child: Container(
                  padding: EdgeInsets.all(12.w),
                  decoration: BoxDecoration(gradient: AppColors.heroGradient, borderRadius: BorderRadius.circular(12.r)),
                  child: Icon(Icons.search, color: Colors.white, size: 20.sp),
                ),
              ),
            ]),
          ),

          // Est. market price + error
          Obx(() {
            final res = c.searchResponse.value;
            final err = c.errorMessage.value;
            if (err.isNotEmpty) return Padding(
              padding: EdgeInsets.fromLTRB(20.w, 8.h, 20.w, 0),
              child: Text(err, style: GoogleFonts.inter(fontSize: 12.sp, color: AppColors.loss)),
            );
            if (res == null || res.avg30Day == null) return const SizedBox();
            return Padding(
              padding: EdgeInsets.fromLTRB(20.w, 8.h, 20.w, 0),
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
                decoration: BoxDecoration(color: AppColors.accent.withOpacity(0.08), borderRadius: BorderRadius.circular(12.r), border: Border.all(color: AppColors.accent.withOpacity(0.2))),
                child: Row(children: [
                  Icon(Icons.price_check_rounded, color: AppColors.accent, size: 18.sp),
                  SizedBox(width: 8.w),
                  Text('Est. Market: ', style: GoogleFonts.inter(fontSize: 13.sp, color: AppColors.textSecondary)),
                  Text(fmt.format(res.avg30Day), style: GoogleFonts.inter(fontSize: 14.sp, fontWeight: FontWeight.w700, color: AppColors.accent)),
                  SizedBox(width: 6.w),
                  Expanded(child: Text('from ${res.totalResults} active listings',
                      style: GoogleFonts.inter(fontSize: 10.sp, color: AppColors.textMuted), overflow: TextOverflow.ellipsis)),
                ]),
              ),
            );
          }),

          // Tip text
          Padding(
            padding: EdgeInsets.fromLTRB(20.w, 10.h, 20.w, 8.h),
            child: Text('Tap a card to see full details, then confirm it\'s yours.',
                style: GoogleFonts.inter(fontSize: 11.sp, color: AppColors.textMuted)),
          ),

          // Grid or empty state
          Expanded(
            child: Obx(() {
              if (c.ebayResults.isEmpty) return _EmptyState(c: c);
              return GridView.builder(
                padding: EdgeInsets.fromLTRB(16.w, 4.h, 16.w, 80.h),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12.w,
                  mainAxisSpacing: 12.h,
                  childAspectRatio: 0.62,
                ),
                itemCount: c.ebayResults.length,
                itemBuilder: (_, i) => _EbayCardGridItem(
                  item: c.ebayResults[i],
                  fmt: fmt,
                  onTap: () => _showCardDetail(context, c.ebayResults[i], c, fmt),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  void _showCardDetail(BuildContext context, EbayListingItem item, ScanCardController c, NumberFormat fmt) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _CardDetailSheet(item: item, c: c, fmt: fmt),
    );
  }
}

// ── eBay Grid Card ──────────────────────────────────────────────────────────
class _EbayCardGridItem extends StatelessWidget {
  final EbayListingItem item;
  final NumberFormat fmt;
  final VoidCallback onTap;
  const _EbayCardGridItem({required this.item, required this.fmt, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final gradeInfo = _parseGrade(item.condition ?? '');
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.bgCard,
          borderRadius: BorderRadius.circular(14.r),
          border: Border.all(color: AppColors.border),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Card image
            ClipRRect(
              borderRadius: BorderRadius.vertical(top: Radius.circular(14.r)),
              child: AspectRatio(
                aspectRatio: 0.88,
                child: item.imageUrl != null
                    ? CachedNetworkImage(
                  imageUrl: item.imageUrl!,
                  fit: BoxFit.cover,
                  placeholder: (_, __) => Container(color: AppColors.bgSurface,
                      child: Center(child: Icon(Icons.style_rounded, color: AppColors.textMuted, size: 32.sp))),
                  errorWidget: (_, __, ___) => Container(
                      color: AppColors.bgSurface,
                      child: Center(child: Icon(Icons.broken_image_outlined, color: AppColors.textMuted, size: 28.sp))),
                )
                    : Container(color: AppColors.bgSurface,
                    child: Center(child: Icon(Icons.style_rounded, color: AppColors.textMuted, size: 32.sp))),
              ),
            ),

            // Info
            Expanded(
              child: Padding(
                padding: EdgeInsets.fromLTRB(8.w, 6.h, 8.w, 6.h),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Text(item.title, maxLines: 2, overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(fontSize: 10.sp, fontWeight: FontWeight.w600, color: AppColors.textPrimary, height: 1.3)),
                    const Spacer(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Grade badge
                        Flexible(
                          child: gradeInfo != null
                              ? Container(
                              padding: EdgeInsets.symmetric(horizontal: 5.w, vertical: 2.h),
                              decoration: BoxDecoration(color: _gradeColor(gradeInfo).withOpacity(0.12), borderRadius: BorderRadius.circular(5.r)),
                              child: Text(gradeInfo, style: GoogleFonts.inter(fontSize: 9.sp, fontWeight: FontWeight.w700, color: _gradeColor(gradeInfo)),
                                  overflow: TextOverflow.ellipsis))
                              : Text(item.condition ?? 'Raw', style: GoogleFonts.inter(fontSize: 9.sp, color: AppColors.textMuted),
                              overflow: TextOverflow.ellipsis),
                        ),
                        SizedBox(width: 4.w),
                        Text(fmt.format(item.price),
                            style: GoogleFonts.inter(fontSize: 12.sp, fontWeight: FontWeight.w800, color: AppColors.primary)),
                      ],
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

  String? _parseGrade(String condition) {
    final gradeRegex = RegExp(r'(PSA|BGS|SGC|CGC)\s*(\d+(?:\.\d+)?)', caseSensitive: false);
    final match = gradeRegex.firstMatch(condition);
    if (match != null) return '${match.group(1)!.toUpperCase()} ${match.group(2)}';
    if (condition.toLowerCase().contains('psa')) return 'PSA';
    if (condition.toLowerCase().contains('bgs')) return 'BGS';
    return null;
  }

  Color _gradeColor(String grade) {
    if (grade.startsWith('PSA 10') || grade.startsWith('BGS 10') || grade.startsWith('CGC 10')) return const Color(0xFF2ECC71);
    if (grade.contains('9.5') || grade.contains('9')) return AppColors.accent;
    return AppColors.textSecondary;
  }
}

// ── Card Detail Bottom Sheet ────────────────────────────────────────────────
class _CardDetailSheet extends StatelessWidget {
  final EbayListingItem item;
  final ScanCardController c;
  final NumberFormat fmt;
  const _CardDetailSheet({required this.item, required this.c, required this.fmt});

  @override
  Widget build(BuildContext context) {
    final gradeInfo = _parseGrade(item.condition ?? '');

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      maxChildSize: 0.95,
      minChildSize: 0.5,
      builder: (_, scrollCtrl) => Container(
        decoration: BoxDecoration(
          color: AppColors.bgCard,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
        ),
        child: Column(
          children: [
            // Handle
            Container(
              width: 40.w, height: 4.h, margin: EdgeInsets.only(top: 12.h),
              decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2.r)),
            ),
            Expanded(
              child: SingleChildScrollView(
                controller: scrollCtrl,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: 16.h),

                    // Large card image
                    if (item.imageUrl != null)
                      Center(
                        child: Container(
                          margin: EdgeInsets.symmetric(horizontal: 40.w),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16.r),
                            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.12), blurRadius: 20, offset: const Offset(0, 6))],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(16.r),
                            child: CachedNetworkImage(
                              imageUrl: item.imageUrl!,
                              fit: BoxFit.contain,
                              placeholder: (_, __) => Container(height: 220.h, color: AppColors.bgSurface,
                                  child: Center(child: CircularProgressIndicator(color: AppColors.accent, strokeWidth: 2))),
                              errorWidget: (_, __, ___) => Container(height: 220.h, color: AppColors.bgSurface,
                                  child: Icon(Icons.broken_image_outlined, size: 48.sp, color: AppColors.textMuted)),
                            ),
                          ),
                        ),
                      ),

                    Padding(
                      padding: EdgeInsets.fromLTRB(20.w, 20.h, 20.w, 0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Title
                          Text(item.title,
                              style: GoogleFonts.inter(fontSize: 15.sp, fontWeight: FontWeight.w700, color: AppColors.textPrimary, height: 1.4)),
                          SizedBox(height: 16.h),

                          // Price box — full width, clean
                          Container(
                            width: double.infinity,
                            padding: EdgeInsets.all(16.w),
                            decoration: BoxDecoration(gradient: AppColors.heroGradient, borderRadius: BorderRadius.circular(14.r)),
                            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Text('eBay Price', style: GoogleFonts.inter(fontSize: 11.sp, color: Colors.white70)),
                              SizedBox(height: 4.h),
                              Text(fmt.format(item.price),
                                  style: GoogleFonts.inter(fontSize: 26.sp, fontWeight: FontWeight.w800, color: Colors.white)),
                              if (item.hasBestOffer)
                                Text('Best Offer also accepted', style: GoogleFonts.inter(fontSize: 10.sp, color: Colors.white70)),
                            ]),
                          ),

                          SizedBox(height: 16.h),

                          // What this means for graded cards
                          if (gradeInfo != null) ...[
                            Container(
                              padding: EdgeInsets.all(14.w),
                              decoration: BoxDecoration(
                                color: _gradeColor(gradeInfo).withOpacity(0.06),
                                borderRadius: BorderRadius.circular(12.r),
                                border: Border.all(color: _gradeColor(gradeInfo).withOpacity(0.2)),
                              ),
                              child: Row(children: [
                                Icon(Icons.verified_rounded, color: _gradeColor(gradeInfo), size: 18.sp),
                                SizedBox(width: 10.w),
                                Expanded(child: Text(_gradeExplanation(gradeInfo),
                                    style: GoogleFonts.inter(fontSize: 12.sp, color: AppColors.textSecondary, height: 1.4))),
                              ]),
                            ),
                            SizedBox(height: 16.h),
                          ],

                          // ── Info rows ─────────────────────────────────
                          Container(
                            decoration: BoxDecoration(
                              color: AppColors.bgDark,
                              borderRadius: BorderRadius.circular(14.r),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: Column(children: [
                              _detailRow(
                                Icons.local_shipping_outlined, 'Shipping',
                                item.isFreeShipping ? 'Free'
                                    : item.shippingCostType == 'FIXED' && item.shippingCost != null
                                    ? '\$${item.shippingCost!.toStringAsFixed(2)}'
                                    : 'Calculated at checkout',
                                valueColor: item.isFreeShipping ? const Color(0xFF2ECC71) : null,
                              ),
                              if (item.hasBestOffer) ...[
                                Divider(height: 1, color: AppColors.divider, indent: 14.w, endIndent: 14.w),
                                _detailRow(Icons.handshake_outlined, 'Best Offer', 'Available'),
                              ],
                              if (item.sellerUsername != null) ...[
                                Divider(height: 1, color: AppColors.divider, indent: 14.w, endIndent: 14.w),
                                _detailRow(Icons.storefront_outlined, 'Seller', item.sellerUsername!),
                              ],
                              if (item.sellerFeedbackPct != null) ...[
                                Divider(height: 1, color: AppColors.divider, indent: 14.w, endIndent: 14.w),
                                _detailRow(Icons.star_rounded, 'Feedback',
                                  '${item.sellerFeedbackPct!.toStringAsFixed(1)}%'
                                      '${item.sellerFeedbackScore != null ? " (${item.sellerFeedbackScore})" : ""}',
                                  valueColor: item.sellerFeedbackPct! >= 99 ? const Color(0xFF2ECC71) : null,
                                ),
                              ],
                              if (item.topRatedSeller) ...[
                                Divider(height: 1, color: AppColors.divider, indent: 14.w, endIndent: 14.w),
                                _detailRow(Icons.verified_rounded, 'Badge', 'Top Rated Seller',
                                    valueColor: const Color(0xFF2ECC71)),
                              ],
                              if (item.country != null) ...[
                                Divider(height: 1, color: AppColors.divider, indent: 14.w, endIndent: 14.w),
                                _detailRow(Icons.location_on_outlined, 'Ships from', item.country!),
                              ],
                            ]),
                          ),

                          SizedBox(height: 8.h),

                          // eBay disclaimer
                          Text('Price from active eBay listing — not a sold price. Estimated market value based on current supply.',
                              style: GoogleFonts.inter(fontSize: 10.sp, color: AppColors.textMuted, height: 1.5)),

                          SizedBox(height: 24.h),

                          // "This is my card" button
                          GestureDetector(
                            onTap: () {
                              Navigator.pop(context);
                              c.selectResult(item);
                            },
                            child: Container(
                              height: 54.h,
                              decoration: BoxDecoration(
                                gradient: AppColors.heroGradient,
                                borderRadius: BorderRadius.circular(14.r),
                                boxShadow: [BoxShadow(color: AppColors.primary.withOpacity(0.28), blurRadius: 14, offset: const Offset(0, 5))],
                              ),
                              child: Center(
                                child: Row(mainAxisSize: MainAxisSize.min, children: [
                                  Icon(Icons.check_circle_outline_rounded, color: Colors.white, size: 20.sp),
                                  SizedBox(width: 10.w),
                                  Text('This is my card — Continue',
                                      style: GoogleFonts.inter(fontSize: 14.sp, fontWeight: FontWeight.w700, color: Colors.white)),
                                ]),
                              ),
                            ),
                          ),

                          SizedBox(height: 8.h),

                          // View on eBay link
                          if (item.itemUrl != null)
                            Center(
                              child: TextButton.icon(
                                onPressed: () {}, // url_launcher can open this
                                icon: Icon(Icons.open_in_new, size: 14.sp, color: AppColors.accent),
                                label: Text('View on eBay', style: GoogleFonts.inter(fontSize: 12.sp, color: AppColors.accent)),
                              ),
                            ),

                          SizedBox(height: 20.h),
                        ],
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

  Widget _detailRow(IconData icon, String label, String value, {Color? valueColor}) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 11.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(icon, color: AppColors.textMuted, size: 15.sp),
          SizedBox(width: 10.w),
          SizedBox(
            width: 80.w,
            child: Text(label,
                style: GoogleFonts.inter(fontSize: 12.sp, color: AppColors.textSecondary)),
          ),
          SizedBox(width: 8.w),
          Expanded(
            child: Text(value,
                style: GoogleFonts.inter(fontSize: 12.sp, fontWeight: FontWeight.w600,
                    color: valueColor ?? AppColors.textPrimary),
                overflow: TextOverflow.ellipsis),
          ),
        ],
      ),
    );
  }

  String? _parseGrade(String condition) {
    final gradeRegex = RegExp(r'(PSA|BGS|SGC|CGC)\s*(\d+(?:\.\d+)?)', caseSensitive: false);
    final match = gradeRegex.firstMatch(condition);
    if (match != null) return '${match.group(1)!.toUpperCase()} ${match.group(2)}';
    return null;
  }

  Color _gradeColor(String grade) {
    if (grade.contains('10') && !grade.contains('100')) return const Color(0xFF2ECC71);
    if (grade.contains('9.5') || grade.contains(' 9')) return AppColors.accent;
    if (grade.contains('8') || grade.contains('7')) return AppColors.warning;
    return AppColors.textSecondary;
  }

  String _gradeExplanation(String grade) {
    if (grade.contains('PSA')) {
      if (grade.contains('10')) return 'PSA 10 — Gem Mint. Highest grade. Commands premium prices, typically 3–10x raw card value.';
      if (grade.contains('9')) return 'PSA 9 — Mint. Excellent condition with minor imperfections. Significant value above raw.';
      if (grade.contains('8')) return 'PSA 8 — Near Mint-Mint. Very good condition with slight wear.';
      return 'PSA graded card — professionally authenticated and graded by PSA.';
    }
    if (grade.contains('BGS')) {
      if (grade.contains('10')) return 'BGS 10 Pristine — Extremely rare. Often valued above PSA 10.';
      if (grade.contains('9.5')) return 'BGS 9.5 Gem Mint — Very desirable grade from Beckett.';
      return 'BGS graded card — professionally authenticated and graded by Beckett.';
    }
    if (grade.contains('SGC')) return 'SGC graded card — authenticated by SGC. Popular for vintage cards.';
    if (grade.contains('CGC')) return 'CGC graded card — CGC recently expanded to trading cards.';
    return 'Professionally graded card with verified authenticity.';
  }
}

// ── Empty state ─────────────────────────────────────────────────────────────
class _EmptyState extends StatelessWidget {
  final ScanCardController c;
  const _EmptyState({required this.c});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 24.w),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 96.w, height: 96.w,
            decoration: BoxDecoration(color: AppColors.bgCard, shape: BoxShape.circle, border: Border.all(color: AppColors.border, width: 1.5)),
            child: Icon(Icons.search_off_rounded, size: 42.sp, color: AppColors.neutral),
          ),
          SizedBox(height: 24.h),
          Text('No listings found', style: GoogleFonts.inter(fontSize: 18.sp, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
          SizedBox(height: 8.h),
          Text('Try refining the search query above.\nMore specific searches give better results.',
              textAlign: TextAlign.center, style: GoogleFonts.inter(fontSize: 13.sp, color: AppColors.textSecondary, height: 1.6)),
          SizedBox(height: 28.h),
          Container(
            width: double.infinity, padding: EdgeInsets.all(16.w),
            decoration: BoxDecoration(color: AppColors.bgCard, borderRadius: BorderRadius.circular(14.r), border: Border.all(color: AppColors.border)),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Icon(Icons.lightbulb_outline_rounded, color: AppColors.accent, size: 16.sp),
                SizedBox(width: 8.w),
                Text('Search tips', style: GoogleFonts.inter(fontSize: 12.sp, fontWeight: FontWeight.w700, color: AppColors.accent)),
              ]),
              SizedBox(height: 10.h),
              _tip('Include year, brand and player name'),
              _tip('Add card number if visible (e.g. #139)'),
              _tip('Add grade company + score (e.g. PSA 10)'),
            ]),
          ),
          SizedBox(height: 16.h),
          GestureDetector(
            onTap: c.goManualAdd,
            child: Container(
              width: double.infinity, padding: EdgeInsets.symmetric(vertical: 16.h),
              decoration: BoxDecoration(color: AppColors.bgCard, borderRadius: BorderRadius.circular(14.r), border: Border.all(color: AppColors.primary.withOpacity(0.4))),
              child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                Icon(Icons.edit_outlined, color: AppColors.primary, size: 18.sp),
                SizedBox(width: 10.w),
                Text('Add card manually instead', style: GoogleFonts.inter(fontSize: 14.sp, fontWeight: FontWeight.w600, color: AppColors.primary)),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

// ── STEP 4: Confirm — pre-filled + editable ──────────────────────────────────
class _ConfirmStep extends StatelessWidget {
  final ScanCardController c;
  const _ConfirmStep({required this.c});

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat.currency(symbol: '\$', decimalDigits: 2);
    final result = c.selectedResult.value;
    return Scaffold(
      backgroundColor: AppColors.bgDark,
      appBar: AppBar(
        backgroundColor: AppColors.bgDark,
        leading: IconButton(icon: Icon(Icons.arrow_back_ios_new, color: AppColors.primary, size: 20.sp), onPressed: c.goBack),
        title: Text('Confirm Card', style: GoogleFonts.inter(fontSize: 18.sp, fontWeight: FontWeight.w700, color: AppColors.primary)),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Selected card preview
            Container(
              padding: EdgeInsets.all(16.w),
              decoration: BoxDecoration(gradient: AppColors.heroGradient, borderRadius: BorderRadius.circular(20.r)),
              child: Row(children: [
                // Image
                ClipRRect(
                  borderRadius: BorderRadius.circular(10.r),
                  child: SizedBox(
                    width: 72.w, height: 96.h,
                    child: result?.imageUrl != null
                        ? CachedNetworkImage(imageUrl: result!.imageUrl!, fit: BoxFit.cover,
                        errorWidget: (_, __, ___) => Container(color: Colors.white.withOpacity(0.15),
                            child: Icon(Icons.style_rounded, color: Colors.white54, size: 28.sp)))
                        : Container(color: Colors.white.withOpacity(0.15),
                        child: Icon(Icons.style_rounded, color: Colors.white54, size: 28.sp)),
                  ),
                ),
                SizedBox(width: 14.w),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(result?.title ?? '', maxLines: 3, overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(fontSize: 12.sp, fontWeight: FontWeight.w700, color: Colors.white, height: 1.3)),
                  SizedBox(height: 8.h),
                  if (result?.condition != null)
                    Text(result!.condition!, style: GoogleFonts.inter(fontSize: 11.sp, color: Colors.white60)),
                  SizedBox(height: 8.h),
                  Text('eBay Price', style: GoogleFonts.inter(fontSize: 10.sp, color: Colors.white54)),
                  Text(fmt.format(result?.price ?? 0),
                      style: GoogleFonts.inter(fontSize: 20.sp, fontWeight: FontWeight.w800, color: Colors.white)),
                ])),
              ]),
            ),

            SizedBox(height: 24.h),

            // Editable card details
            Row(children: [
              Text('Card Details', style: GoogleFonts.inter(fontSize: 15.sp, fontWeight: FontWeight.w700, color: AppColors.primary)),
              SizedBox(width: 8.w),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
                decoration: BoxDecoration(color: AppColors.accent.withOpacity(0.1), borderRadius: BorderRadius.circular(8.r)),
                child: Text('Edit if needed', style: GoogleFonts.inter(fontSize: 10.sp, color: AppColors.accent, fontWeight: FontWeight.w600)),
              ),
            ]),
            SizedBox(height: 10.h),

            Container(
              padding: EdgeInsets.all(16.w),
              decoration: BoxDecoration(color: AppColors.bgCard, borderRadius: BorderRadius.circular(16.r), border: Border.all(color: AppColors.border)),
              child: Column(children: [
                _editableField('Player Name', c.playerNameController, Icons.person_outline, 'e.g. Lamar Jackson'),
                Divider(color: AppColors.divider, height: 20.h),
                _editableField('Year', c.yearController, Icons.calendar_today_outlined, 'e.g. 2018'),
                Divider(color: AppColors.divider, height: 20.h),
                _editableField('Brand / Set', c.setNameController, Icons.layers_outlined, 'e.g. Panini Donruss Optic'),
              ]),
            ),

            SizedBox(height: 16.h),

            // Grade info box
            Container(
              padding: EdgeInsets.all(14.w),
              decoration: BoxDecoration(
                color: AppColors.bgCard,
                borderRadius: BorderRadius.circular(12.r),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Icon(Icons.verified_outlined, color: AppColors.accent, size: 16.sp),
                  SizedBox(width: 8.w),
                  Text('Grade / Condition', style: GoogleFonts.inter(fontSize: 12.sp, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                ]),
                SizedBox(height: 8.h),
                Text(result?.condition ?? 'Ungraded',
                    style: GoogleFonts.inter(fontSize: 13.sp, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
                SizedBox(height: 4.h),
                Text('You can update the grade on the next screen when setting your price.',
                    style: GoogleFonts.inter(fontSize: 11.sp, color: AppColors.textMuted)),
              ]),
            ),

            SizedBox(height: 16.h),

            Container(
              padding: EdgeInsets.all(12.w),
              decoration: BoxDecoration(color: AppColors.accent.withOpacity(0.06), borderRadius: BorderRadius.circular(12.r), border: Border.all(color: AppColors.accent.withOpacity(0.15))),
              child: Row(children: [
                Icon(Icons.info_outline, color: AppColors.accent, size: 16.sp),
                SizedBox(width: 10.w),
                Expanded(child: Text('Next screen: set what you paid and your target profit margin.',
                    style: GoogleFonts.inter(fontSize: 11.sp, color: AppColors.textSecondary, height: 1.4))),
              ]),
            ),

            SizedBox(height: 28.h),

            GestureDetector(
              onTap: c.confirmAndAddCard,
              child: Container(
                height: 54.h,
                decoration: BoxDecoration(gradient: AppColors.heroGradient, borderRadius: BorderRadius.circular(14.r),
                    boxShadow: [BoxShadow(color: AppColors.primary.withOpacity(0.28), blurRadius: 16, offset: const Offset(0, 5))]),
                child: Center(child: Text('Continue to Set Price',
                    style: GoogleFonts.inter(fontSize: 15.sp, fontWeight: FontWeight.w700, color: Colors.white))),
              ),
            ),
            SizedBox(height: 20.h),
          ],
        ),
      ),
    );
  }

  Widget _editableField(String label, TextEditingController ctrl, IconData icon, String hint) {
    return Row(
      children: [
        Icon(icon, color: AppColors.textMuted, size: 16.sp),
        SizedBox(width: 10.w),
        SizedBox(width: 80.w, child: Text(label, style: GoogleFonts.inter(fontSize: 12.sp, color: AppColors.textMuted))),
        Expanded(
          child: TextFormField(
            controller: ctrl,
            style: GoogleFonts.inter(fontSize: 13.sp, color: AppColors.textPrimary, fontWeight: FontWeight.w600),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: GoogleFonts.inter(fontSize: 12.sp, color: AppColors.border),
              border: InputBorder.none, enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none, filled: false,
              isCollapsed: true, contentPadding: EdgeInsets.zero,
            ),
          ),
        ),
      ],
    );
  }
}

// ── STEP: Manual Entry ───────────────────────────────────────────────────────
class _ManualStep extends StatelessWidget {
  final ScanCardController c;
  const _ManualStep({required this.c});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgDark,
      appBar: AppBar(
        backgroundColor: AppColors.bgDark,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, color: AppColors.primary, size: 20.sp),
          onPressed: c.goBack,
        ),
        title: Text('Add Card Manually',
            style: GoogleFonts.inter(fontSize: 18.sp, fontWeight: FontWeight.w700, color: AppColors.primary)),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Info banner
            Container(
              padding: EdgeInsets.all(14.w),
              decoration: BoxDecoration(
                color: AppColors.accent.withOpacity(0.07),
                borderRadius: BorderRadius.circular(12.r),
                border: Border.all(color: AppColors.accent.withOpacity(0.2)),
              ),
              child: Row(children: [
                Icon(Icons.edit_note_rounded, color: AppColors.accent, size: 20.sp),
                SizedBox(width: 10.w),
                Expanded(child: Text(
                  'Fill in what you know. The more detail you add, the better the eBay price estimate.',
                  style: GoogleFonts.inter(fontSize: 12.sp, color: AppColors.textSecondary, height: 1.4),
                )),
              ]),
            ),

            SizedBox(height: 24.h),

            _sectionLabel('Card Identity'),
            SizedBox(height: 10.h),

            Container(
              padding: EdgeInsets.all(16.w),
              decoration: BoxDecoration(
                color: AppColors.bgCard,
                borderRadius: BorderRadius.circular(16.r),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(children: [
                _field('Player Name', c.playerNameController, Icons.person_outline_rounded, 'e.g. Michael Jordan', TextInputType.text),
                Divider(color: AppColors.divider, height: 20.h),
                _field('Year', c.yearController, Icons.calendar_today_outlined, 'e.g. 1996', TextInputType.number),
                Divider(color: AppColors.divider, height: 20.h),
                _field('Brand / Set', c.setNameController, Icons.layers_outlined, 'e.g. Topps Chrome', TextInputType.text),
              ]),
            ),

            SizedBox(height: 32.h),

            // Two options: search eBay or go straight to add
            Text('What would you like to do next?',
                style: GoogleFonts.inter(fontSize: 14.sp, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
            SizedBox(height: 12.h),

            // Search eBay button
            GestureDetector(
              onTap: () {
                final q = [
                  c.yearController.text.trim(),
                  c.setNameController.text.trim(),
                  c.playerNameController.text.trim(),
                ].where((s) => s.isNotEmpty).join(' ');
                if (q.isEmpty) {
                  Get.snackbar('Fill in details', 'Add at least a player name to search.',
                      snackPosition: SnackPosition.BOTTOM, margin: const EdgeInsets.all(16), borderRadius: 12);
                  return;
                }
                c.searchQueryController.text = q;
                c.retrySearch();
              },
              child: Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(vertical: 15.h),
                decoration: BoxDecoration(
                  gradient: AppColors.heroGradient,
                  borderRadius: BorderRadius.circular(14.r),
                  boxShadow: [BoxShadow(color: AppColors.primary.withOpacity(0.25), blurRadius: 14, offset: const Offset(0, 5))],
                ),
                child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Icon(Icons.search_rounded, color: Colors.white, size: 20.sp),
                  SizedBox(width: 10.w),
                  Text('Search eBay for price estimate',
                      style: GoogleFonts.inter(fontSize: 14.sp, fontWeight: FontWeight.w700, color: Colors.white)),
                ]),
              ),
            ),

            SizedBox(height: 12.h),

            // Skip straight to add
            GestureDetector(
              onTap: c.goManualAdd,
              child: Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(vertical: 15.h),
                decoration: BoxDecoration(
                  color: AppColors.bgCard,
                  borderRadius: BorderRadius.circular(14.r),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Icon(Icons.add_circle_outline_rounded, color: AppColors.primary, size: 20.sp),
                  SizedBox(width: 10.w),
                  Text('Skip search — set price manually',
                      style: GoogleFonts.inter(fontSize: 14.sp, fontWeight: FontWeight.w600, color: AppColors.primary)),
                ]),
              ),
            ),

            SizedBox(height: 40.h),
          ],
        ),
      ),
    );
  }

  Widget _sectionLabel(String text) => Text(text,
      style: GoogleFonts.inter(fontSize: 11.sp, fontWeight: FontWeight.w700,
          color: AppColors.textMuted, letterSpacing: 0.8));

  Widget _field(String label, TextEditingController ctrl, IconData icon, String hint, TextInputType type) {
    return Row(children: [
      Icon(icon, color: AppColors.textMuted, size: 17.sp),
      SizedBox(width: 10.w),
      SizedBox(width: 80.w, child: Text(label, style: GoogleFonts.inter(fontSize: 12.sp, color: AppColors.textMuted))),
      Expanded(
        child: TextFormField(
          controller: ctrl,
          keyboardType: type,
          style: GoogleFonts.inter(fontSize: 13.sp, color: AppColors.textPrimary, fontWeight: FontWeight.w600),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.inter(fontSize: 12.sp, color: AppColors.border),
            border: InputBorder.none, enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none, filled: false,
            isCollapsed: true, contentPadding: EdgeInsets.zero,
          ),
        ),
      ),
    ]);
  }
}


Widget _tip(String text) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Padding(padding: EdgeInsets.only(top: 5),
          child: Icon(Icons.circle, size: 5, color: Color(0xFFB2B2B2))),
      const SizedBox(width: 8),
      Expanded(child: Text(text, style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF5A6A8A), height: 1.5))),
    ]),
  );
}