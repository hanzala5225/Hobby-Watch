import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
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
      }
    });
  }
}

// ── STEP 1: Choose — LIGHT THEME ───────────────────────────────────────────
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
            // Top bar
            Padding(
              padding: EdgeInsets.fromLTRB(8.w, 8.h, 20.w, 0),
              child: Row(
                children: [
                  IconButton(
                    icon: Icon(Icons.close, color: AppColors.textSecondary, size: 22.sp),
                    onPressed: Get.back,
                  ),
                  Text('Add Card',
                      style: GoogleFonts.inter(fontSize: 18.sp, fontWeight: FontWeight.w700, color: AppColors.primary)),
                ],
              ),
            ),

            Expanded(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 28.w),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Scan frame on light background
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(28.w),
                      decoration: BoxDecoration(
                        color: AppColors.bgCard,
                        borderRadius: BorderRadius.circular(20.r),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Column(
                        children: [
                          _AnimatedScanFrame(),
                          SizedBox(height: 20.h),
                          Text('Position your card in the frame',
                              style: GoogleFonts.inter(fontSize: 13.sp, color: AppColors.textMuted)),
                        ],
                      ),
                    ),

                    SizedBox(height: 32.h),

                    Text('How would you like to add?',
                        style: GoogleFonts.inter(fontSize: 16.sp, fontWeight: FontWeight.w700, color: AppColors.primary)),

                    SizedBox(height: 20.h),

                    // Camera button
                    _OptionButton(
                      icon: Icons.camera_alt_rounded,
                      label: 'Scan with Camera',
                      subtitle: 'Point at card — we read the text',
                      isPrimary: true,
                      onTap: c.takePhoto,
                    ),
                    SizedBox(height: 12.h),

                    // Gallery button
                    _OptionButton(
                      icon: Icons.photo_library_outlined,
                      label: 'Choose from Gallery',
                      subtitle: 'Pick an existing photo',
                      isPrimary: false,
                      onTap: c.pickFromGallery,
                    ),
                    SizedBox(height: 12.h),

                    // Manual entry
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
  final String label;
  final String subtitle;
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
        child: Row(
          children: [
            Container(
              width: 40.w, height: 40.w,
              decoration: BoxDecoration(
                color: isPrimary ? Colors.white.withOpacity(0.18) : AppColors.bgSurface,
                borderRadius: BorderRadius.circular(10.r),
              ),
              child: Icon(icon, color: isPrimary ? Colors.white : AppColors.primary, size: 20.sp),
            ),
            SizedBox(width: 14.w),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: GoogleFonts.inter(fontSize: 14.sp, fontWeight: FontWeight.w600, color: isPrimary ? Colors.white : AppColors.textPrimary)),
                SizedBox(height: 2.h),
                Text(subtitle, style: GoogleFonts.inter(fontSize: 11.sp, color: isPrimary ? Colors.white70 : AppColors.textMuted)),
              ],
            ),
            const Spacer(),
            Icon(Icons.arrow_forward_ios_rounded, size: 14.sp, color: isPrimary ? Colors.white60 : AppColors.textMuted),
          ],
        ),
      ),
    );
  }
}

// Animated scan frame
class _AnimatedScanFrame extends StatefulWidget {
  @override
  State<_AnimatedScanFrame> createState() => _AnimatedScanFrameState();
}
class _AnimatedScanFrameState extends State<_AnimatedScanFrame> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _line;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat(reverse: true);
    _line = Tween<double>(begin: 0, end: 1).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 220.w, height: 148.h,
      child: Stack(
        children: [
          CustomPaint(size: Size(220.w, 148.h), painter: _CornerPainter(color: AppColors.accent)),
          AnimatedBuilder(
            animation: _line,
            builder: (_, __) => Positioned(
              top: _line.value * 128.h + 10.h,
              left: 10.w, right: 10.w,
              child: Container(
                height: 2,
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [Colors.transparent, AppColors.accent.withOpacity(0.8), Colors.transparent]),
                ),
              ),
            ),
          ),
        ],
      ),
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
  @override
  bool shouldRepaint(covariant CustomPainter o) => false;
}

// ── STEP 2: Processing — LIGHT THEME ──────────────────────────────────────
class _ProcessingStep extends StatefulWidget {
  final ScanCardController c;
  const _ProcessingStep({required this.c});
  @override
  State<_ProcessingStep> createState() => _ProcessingStepState();
}
class _ProcessingStepState extends State<_ProcessingStep> with TickerProviderStateMixin {
  late AnimationController _pulse;
  late AnimationController _rotate;
  int _idx = 0;
  final _msgs = [
    'Reading card text...',
    'Identifying card details...',
    'Searching eBay listings...',
    'Calculating market price...',
  ];

  @override
  void initState() {
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

  @override
  void dispose() { _pulse.dispose(); _rotate.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgDark,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 28.w),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Pulsing icon
              ScaleTransition(
                scale: Tween(begin: 0.92, end: 1.0)
                    .animate(CurvedAnimation(parent: _pulse, curve: Curves.easeInOut)),
                child: Container(
                  width: 88.w, height: 88.w,
                  decoration: BoxDecoration(
                    gradient: AppColors.heroGradient,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withOpacity(0.22),
                        blurRadius: 28,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Icon(Icons.document_scanner_rounded, color: Colors.white, size: 38.sp),
                ),
              ),

              SizedBox(height: 40.h),

              // Card being fetched info
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(20.w),
                decoration: BoxDecoration(
                  color: AppColors.bgCard,
                  borderRadius: BorderRadius.circular(18.r),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  children: [
                    // Step dots
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(4, (i) => AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        margin: EdgeInsets.symmetric(horizontal: 4.w),
                        width: i == _idx % 4 ? 22.w : 8.w,
                        height: 8.h,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(4.r),
                          color: i == _idx % 4 ? AppColors.accent : AppColors.border,
                        ),
                      )),
                    ),
                    SizedBox(height: 16.h),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 350),
                      child: Text(
                        _msgs[_idx],
                        key: ValueKey(_idx),
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inter(
                          fontSize: 14.sp,
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    SizedBox(height: 6.h),
                    Text(
                      'Please wait a moment',
                      style: GoogleFonts.inter(fontSize: 12.sp, color: AppColors.textMuted),
                    ),
                  ],
                ),
              ),

              SizedBox(height: 32.h),

              // eBay data note
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.info_outline_rounded, color: AppColors.textMuted, size: 14.sp),
                  SizedBox(width: 6.w),
                  Text(
                    'Fetching live pricing from eBay',
                    style: GoogleFonts.inter(fontSize: 12.sp, color: AppColors.textMuted),
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

// ── STEP 3: Results ─────────────────────────────────────────────────────────
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
        title: Text('Select Card', style: GoogleFonts.inter(fontSize: 18.sp, fontWeight: FontWeight.w700, color: AppColors.primary)),
      ),
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(20.w, 4.h, 20.w, 12.h),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Search Query', style: GoogleFonts.inter(fontSize: 12.sp, fontWeight: FontWeight.w500, color: AppColors.textSecondary)),
                SizedBox(height: 6.h),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: c.searchQueryController,
                        style: GoogleFonts.inter(color: AppColors.textPrimary, fontSize: 13.sp),
                        decoration: InputDecoration(
                          hintText: 'e.g. 1996 Topps Michael Jordan',
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
                  ],
                ),
                Obx(() {
                  if (c.errorMessage.isEmpty) return const SizedBox();
                  return Padding(
                    padding: EdgeInsets.only(top: 8.h),
                    child: Text(c.errorMessage.value, style: GoogleFonts.inter(fontSize: 12.sp, color: AppColors.loss)),
                  );
                }),
                Obx(() {
                  final res = c.searchResponse.value;
                  if (res == null || res.avg30Day == null) return const SizedBox();
                  return Padding(
                    padding: EdgeInsets.only(top: 10.h),
                    child: Container(
                      padding: EdgeInsets.all(12.w),
                      decoration: BoxDecoration(color: AppColors.accent.withOpacity(0.08), borderRadius: BorderRadius.circular(12.r), border: Border.all(color: AppColors.accent.withOpacity(0.2))),
                      child: Row(children: [
                        Icon(Icons.price_check_rounded, color: AppColors.accent, size: 18.sp),
                        SizedBox(width: 8.w),
                        Text('Est. Market: ', style: GoogleFonts.inter(fontSize: 13.sp, color: AppColors.textSecondary)),
                        Text(fmt.format(res.avg30Day), style: GoogleFonts.inter(fontSize: 14.sp, fontWeight: FontWeight.w700, color: AppColors.accent)),
                        SizedBox(width: 6.w),
                        Expanded(child: Text('from ${res.totalResults} listings', style: GoogleFonts.inter(fontSize: 10.sp, color: AppColors.textMuted), overflow: TextOverflow.ellipsis)),
                      ]),
                    ),
                  );
                }),
              ],
            ),
          ),
          Expanded(
            child: Obx(() {
              if (c.ebayResults.isEmpty) {
                return Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24.w),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Illustration container
                      Container(
                        width: 96.w,
                        height: 96.w,
                        decoration: BoxDecoration(
                          color: AppColors.bgCard,
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.border, width: 1.5),
                        ),
                        child: Icon(Icons.search_off_rounded, size: 42.sp, color: AppColors.neutral),
                      ),

                      SizedBox(height: 24.h),

                      Text(
                        'No listings found',
                        style: GoogleFonts.inter(fontSize: 18.sp, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                      ),
                      SizedBox(height: 8.h),
                      Text(
                        'Try refining the search query above.\nMore specific searches give better results.',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inter(fontSize: 13.sp, color: AppColors.textSecondary, height: 1.6),
                      ),

                      SizedBox(height: 32.h),

                      // Tips card
                      Container(
                        width: double.infinity,
                        padding: EdgeInsets.all(16.w),
                        decoration: BoxDecoration(
                          color: AppColors.bgCard,
                          borderRadius: BorderRadius.circular(14.r),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(children: [
                              Icon(Icons.lightbulb_outline_rounded, color: AppColors.accent, size: 16.sp),
                              SizedBox(width: 8.w),
                              Text('Search tips', style: GoogleFonts.inter(fontSize: 12.sp, fontWeight: FontWeight.w700, color: AppColors.accent)),
                            ]),
                            SizedBox(height: 10.h),
                            _tip('Include year, brand and player name'),
                            _tip('Add card number if visible (e.g. #139)'),
                            _tip('Add grade if graded (e.g. PSA 10)'),
                          ],
                        ),
                      ),

                      SizedBox(height: 20.h),

                      // Manual add button
                      GestureDetector(
                        onTap: c.goManualAdd,
                        child: Container(
                          width: double.infinity,
                          padding: EdgeInsets.symmetric(vertical: 16.h),
                          decoration: BoxDecoration(
                            color: AppColors.bgCard,
                            borderRadius: BorderRadius.circular(14.r),
                            border: Border.all(color: AppColors.primary.withOpacity(0.4)),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.edit_outlined, color: AppColors.primary, size: 18.sp),
                              SizedBox(width: 10.w),
                              Text('Add card manually instead',
                                  style: GoogleFonts.inter(fontSize: 14.sp, fontWeight: FontWeight.w600, color: AppColors.primary)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }
              return ListView.separated(
                padding: EdgeInsets.fromLTRB(20.w, 0, 20.w, 80.h),
                itemCount: c.ebayResults.length,
                separatorBuilder: (_, __) => SizedBox(height: 10.h),
                itemBuilder: (_, i) {
                  final item = c.ebayResults[i];
                  return GestureDetector(
                    onTap: () => c.selectResult(item),
                    child: Container(
                      padding: EdgeInsets.all(14.w),
                      decoration: BoxDecoration(color: AppColors.bgCard, borderRadius: BorderRadius.circular(14.r), border: Border.all(color: AppColors.border)),
                      child: Row(
                        children: [
                          Container(
                            width: 46.w, height: 60.h,
                            decoration: BoxDecoration(gradient: AppColors.primaryGradient, borderRadius: BorderRadius.circular(8.r)),
                            child: Icon(Icons.style_rounded, color: Colors.white70, size: 20.sp),
                          ),
                          SizedBox(width: 12.w),
                          Expanded(
                            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Text(item.title, maxLines: 2, overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.inter(fontSize: 12.sp, fontWeight: FontWeight.w600, color: AppColors.textPrimary, height: 1.3)),
                              SizedBox(height: 4.h),
                              if (item.condition != null)
                                Text(item.condition!, style: GoogleFonts.inter(fontSize: 10.sp, color: AppColors.textMuted)),
                            ]),
                          ),
                          SizedBox(width: 10.w),
                          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                            Text(fmt.format(item.price), style: GoogleFonts.inter(fontSize: 15.sp, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
                            SizedBox(height: 4.h),
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
                              decoration: BoxDecoration(color: AppColors.accent.withOpacity(0.12), borderRadius: BorderRadius.circular(6.r)),
                              child: Text('Select', style: GoogleFonts.inter(fontSize: 11.sp, fontWeight: FontWeight.w600, color: AppColors.accent)),
                            ),
                          ]),
                        ],
                      ),
                    ),
                  );
                },
              );
            }),
          ),
        ],
      ),
    );
  }
}

// ── STEP 4: Confirm ──────────────────────────────────────────────────────────
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
            Container(
              padding: EdgeInsets.all(16.w),
              decoration: BoxDecoration(gradient: AppColors.heroGradient, borderRadius: BorderRadius.circular(20.r)),
              child: Row(
                children: [
                  Container(
                    width: 72.w, height: 96.h,
                    decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), borderRadius: BorderRadius.circular(10.r)),
                    child: Icon(Icons.style_rounded, color: Colors.white54, size: 30.sp),
                  ),
                  SizedBox(width: 16.w),
                  Expanded(child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(result?.title ?? '', maxLines: 3, overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(fontSize: 13.sp, fontWeight: FontWeight.w700, color: Colors.white, height: 1.3)),
                      SizedBox(height: 8.h),
                      if (result?.condition != null)
                        Text(result!.condition!, style: GoogleFonts.inter(fontSize: 11.sp, color: Colors.white60)),
                      SizedBox(height: 10.h),
                      Text('eBay Price', style: GoogleFonts.inter(fontSize: 11.sp, color: Colors.white54)),
                      Text(fmt.format(result?.price ?? 0), style: GoogleFonts.inter(fontSize: 22.sp, fontWeight: FontWeight.w800, color: Colors.white)),
                    ],
                  )),
                ],
              ),
            ),
            SizedBox(height: 24.h),
            Text('Card Details', style: GoogleFonts.inter(fontSize: 15.sp, fontWeight: FontWeight.w700, color: AppColors.primary)),
            SizedBox(height: 12.h),
            Container(
              padding: EdgeInsets.all(16.w),
              decoration: BoxDecoration(color: AppColors.bgCard, borderRadius: BorderRadius.circular(16.r), border: Border.all(color: AppColors.border)),
              child: Column(children: [
                _editRow('Player Name', c.playerNameController),
                Divider(color: AppColors.divider, height: 20.h),
                _editRow('Year', c.yearController),
                Divider(color: AppColors.divider, height: 20.h),
                _editRow('Set / Brand', c.setNameController),
              ]),
            ),
            SizedBox(height: 16.h),
            Container(
              padding: EdgeInsets.all(14.w),
              decoration: BoxDecoration(color: AppColors.accent.withOpacity(0.07), borderRadius: BorderRadius.circular(12.r), border: Border.all(color: AppColors.accent.withOpacity(0.2))),
              child: Row(children: [
                Icon(Icons.info_outline, color: AppColors.accent, size: 18.sp),
                SizedBox(width: 10.w),
                Expanded(child: Text('Set purchase price and target margin on the next screen.', style: GoogleFonts.inter(fontSize: 12.sp, color: AppColors.textSecondary, height: 1.4))),
              ]),
            ),
            SizedBox(height: 32.h),
            GestureDetector(
              onTap: c.confirmAndAddCard,
              child: Container(
                height: 54.h,
                decoration: BoxDecoration(gradient: AppColors.heroGradient, borderRadius: BorderRadius.circular(14.r),
                    boxShadow: [BoxShadow(color: AppColors.primary.withOpacity(0.28), blurRadius: 16, offset: const Offset(0, 5))]),
                child: Center(child: Text('Continue to Add Card',
                    style: GoogleFonts.inter(fontSize: 15.sp, fontWeight: FontWeight.w700, color: Colors.white))),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _editRow(String label, TextEditingController ctrl) {
    return Row(
      children: [
        SizedBox(width: 90.w, child: Text(label, style: GoogleFonts.inter(fontSize: 12.sp, color: AppColors.textMuted))),
        Expanded(
          child: TextFormField(
            controller: ctrl,
            style: GoogleFonts.inter(fontSize: 13.sp, color: AppColors.textPrimary, fontWeight: FontWeight.w600),
            decoration: const InputDecoration(
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

// Shared tip row widget
Widget _tip(String text) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(top: 5),
          child: Icon(Icons.circle, size: 5, color: Color(0xFFB2B2B2)),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(text,
              style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF5A6A8A), height: 1.5)),
        ),
      ],
    ),
  );
}