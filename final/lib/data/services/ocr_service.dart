import 'dart:io';
import 'package:get/get.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:logger/logger.dart';

class OcrService extends GetxService {
  final _log = Logger();
  late final TextRecognizer _recognizer;

  @override
  void onInit() {
    super.onInit();
    _recognizer = TextRecognizer(script: TextRecognitionScript.latin);
  }

  @override
  void onClose() {
    _recognizer.close();
    super.onClose();
  }

  /// Scans an image file and extracts card information using Google ML Kit.
  /// Returns a structured [ScanResult] with extracted fields + a search query.
  Future<ScanResult> scanCard(File imageFile) async {
    try {
      final inputImage = InputImage.fromFile(imageFile);
      final recognized = await _recognizer.processImage(inputImage);
      final rawText = recognized.text;

      _log.i('OCR raw text:\n$rawText');

      return _parseCardText(rawText);
    } catch (e) {
      _log.e('OCR failed: $e');
      return ScanResult(rawText: '', searchQuery: '');
    }
  }

  ScanResult _parseCardText(String text) {
    final lines = text
        .split('\n')
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty)
        .toList();

    String? playerName;
    String? year;
    String? brand;
    String? setName;
    String? cardNumber;
    String? grade;

    // ── Year detection (4-digit number 1950–2030) ─────────────────────────
    final yearRegex = RegExp(r'\b(19[5-9]\d|20[0-2]\d)\b');
    for (final line in lines) {
      final match = yearRegex.firstMatch(line);
      if (match != null) {
        year = match.group(0);
        break;
      }
    }

    // ── Card number (#XX or No. XX) ────────────────────────────────────────
    final cardNumRegex = RegExp(r'#(\w+)|No\.\s*(\w+)', caseSensitive: false);
    for (final line in lines) {
      final match = cardNumRegex.firstMatch(line);
      if (match != null) {
        cardNumber = match.group(1) ?? match.group(2);
        break;
      }
    }

    // ── Grade detection (PSA, BGS, SGC) ───────────────────────────────────
    final gradeRegex = RegExp(r'(PSA|BGS|SGC)\s*(\d+(?:\.\d+)?)', caseSensitive: false);
    for (final line in lines) {
      final match = gradeRegex.firstMatch(line);
      if (match != null) {
        grade = '${match.group(1)} ${match.group(2)}';
        break;
      }
    }

    // ── Brand/Set detection ────────────────────────────────────────────────
    final knownBrands = [
      'Topps', 'Panini', 'Upper Deck', 'Bowman', 'Fleer',
      'Donruss', 'Score', 'Prizm', 'Chrome', 'Mosaic', 'Select',
      'Optic', 'Contenders', 'Hoops', 'Stadium Club',
    ];
    for (final line in lines) {
      for (final b in knownBrands) {
        if (line.toLowerCase().contains(b.toLowerCase())) {
          brand ??= b;
          setName ??= line.length < 60 ? line : null;
          break;
        }
      }
      if (brand != null) break;
    }

    // ── Player name: longest ALL-CAPS or title-case line (heuristic) ──────
    for (final line in lines) {
      if (line.length < 3 || line.length > 40) continue;
      // Skip lines that look like years, card numbers, brands
      if (yearRegex.hasMatch(line)) continue;
      if (cardNumRegex.hasMatch(line)) continue;
      if (line.contains(RegExp(r'^\d+$'))) continue;

      // Prefer lines that are all caps or look like names
      final words = line.split(' ');
      if (words.length >= 2 && words.length <= 5) {
        final isNameLike = words.every((w) =>
          w.isNotEmpty && (w[0] == w[0].toUpperCase()));
        if (isNameLike && playerName == null) {
          playerName = line;
        }
      }
    }

    // ── Build search query ─────────────────────────────────────────────────
    final parts = <String>[];
    if (year != null) parts.add(year!);
    if (brand != null) parts.add(brand!);
    if (setName != null && setName != brand) parts.add(setName!);
    if (playerName != null) parts.add(playerName!);
    if (grade != null) parts.add(grade!);
    if (cardNumber != null) parts.add('#$cardNumber');

    final searchQuery = parts.isNotEmpty
        ? parts.join(' ')
        : lines.take(3).join(' ');

    return ScanResult(
      rawText:    text,
      playerName: playerName,
      year:       year,
      brand:      brand,
      setName:    setName,
      cardNumber: cardNumber,
      grade:      grade,
      searchQuery: searchQuery.trim(),
    );
  }
}

class ScanResult {
  final String rawText;
  final String? playerName;
  final String? year;
  final String? brand;
  final String? setName;
  final String? cardNumber;
  final String? grade;
  final String searchQuery;

  ScanResult({
    required this.rawText,
    this.playerName,
    this.year,
    this.brand,
    this.setName,
    this.cardNumber,
    this.grade,
    required this.searchQuery,
  });
}
