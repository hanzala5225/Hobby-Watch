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

      final result = _parseCardText(rawText);
      _log.i('Parsed → year: ${result.year}, brand: ${result.brand}, '
          'setName: ${result.setName}, playerName: ${result.playerName}, '
          'grade: ${result.grade}, cardNumber: ${result.cardNumber}');
      _log.i('Final search query: "${result.searchQuery}"');
      return result;
    } catch (e) {
      _log.e('OCR failed: $e');
      return ScanResult(rawText: '', searchQuery: '');
    }
  }

  // Common NFL/NBA/MLB team names — excluded from player-name detection
  // since they're 2-3 word, title-case lines that otherwise look identical
  // to a real player name to the heuristic below.
  static const _teamNames = [
    'Arizona Cardinals', 'Atlanta Falcons', 'Baltimore Ravens', 'Buffalo Bills',
    'Carolina Panthers', 'Chicago Bears', 'Cincinnati Bengals', 'Cleveland Browns',
    'Dallas Cowboys', 'Denver Broncos', 'Detroit Lions', 'Green Bay Packers',
    'Houston Texans', 'Indianapolis Colts', 'Jacksonville Jaguars', 'Kansas City Chiefs',
    'Las Vegas Raiders', 'Los Angeles Chargers', 'Los Angeles Rams', 'Miami Dolphins',
    'Minnesota Vikings', 'New England Patriots', 'New Orleans Saints', 'New York Giants',
    'New York Jets', 'Philadelphia Eagles', 'Pittsburgh Steelers', 'San Francisco 49Ers',
    'Seattle Seahawks', 'Tampa Bay Buccaneers', 'Tennessee Titans', 'Washington Commanders',
  ];

  // Common stat-table / card-back header words that pass the name heuristic
  // (single word, no digits, capitalized) but are never actually a name.
  static const _headerWords = [
    'Year', 'Team', 'Rec', 'Yds', 'Avg', 'Td', 'Ncaa', 'Totals',
    'Authentic', 'Super', 'Seat', 'Row', 'Section', 'Rookie', 'Ticket',
    'Nfl', 'Nflpa', 'Nba', 'Mlb', 'Nhl', 'Nfc', 'Afc',
  ];

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
    String? modelCode;

    // ── Year detection (4-digit number 1950–2030) ─────────────────────────
    // Prefer a year found on the same line as the brand/product (e.g.
    // "2024 PANINI - CONTENDERS FOOTBALL"), since that's the card's actual
    // print year — a year mentioned inside a stat paragraph (e.g. "...17
    // touchdowns in 2023") is a player stat, not the card year.
    final yearRegex = RegExp(r'\b(19[5-9]\d|20[0-2]\d)\b');
    for (final line in lines) {
      final match = yearRegex.firstMatch(line);
      if (match != null) {
        year = match.group(0);
        break;
      }
    }

    // ── Card number (#XX or No. XX) — keeps hyphens, e.g. "RTS-BTJ" ────────
    final cardNumRegex = RegExp(r'#([\w-]+)|No\.\s*([\w-]+)', caseSensitive: false);
    for (final line in lines) {
      final match = cardNumRegex.firstMatch(line);
      if (match != null) {
        cardNumber = match.group(1) ?? match.group(2);
        break;
      }
    }

    // ── Grade detection (PSA, BGS, SGC, CGC) ───────────────────────────────
    final gradeRegex = RegExp(r'(PSA|BGS|SGC|CGC)\s*(\d+(?:\.\d+)?)', caseSensitive: false);
    for (final line in lines) {
      final match = gradeRegex.firstMatch(line);
      if (match != null) {
        grade = '${match.group(1)} ${match.group(2)}';
        break;
      }
    }

    // ── Model code detection (e.g. "CRJ-900", "F-150", "GT500") ────────────
    final modelCodeRegex = RegExp(r'^[A-Za-z]{1,5}-?\d{2,4}[A-Za-z]?$');
    for (final line in lines) {
      if (modelCodeRegex.hasMatch(line.trim())) {
        modelCode = line.trim();
        break;
      }
    }

    // ── Brand/Set detection ────────────────────────────────────────────────
    final knownBrands = [
      'Topps', 'Panini', 'Upper Deck', 'Bowman', 'Fleer',
      'Donruss', 'Score', 'Prizm', 'Chrome', 'Mosaic', 'Select',
      'Optic', 'Contenders', 'Hoops', 'Stadium Club',
      'Bombardier', 'Delta', 'Boeing', 'Airbus', // non-sport collectible brands
    ];
    String? brandLine;
    for (final line in lines) {
      for (final b in knownBrands) {
        if (line.toLowerCase().contains(b.toLowerCase())) {
          brand ??= b;
          setName ??= line.length < 60 ? line : null;
          brandLine ??= line;
          break;
        }
      }
      if (brand != null) break;
    }

    // If the brand line itself contains a year, prefer that over whatever
    // generic year we found first (see comment above).
    if (brandLine != null) {
      final brandYearMatch = yearRegex.firstMatch(brandLine);
      if (brandYearMatch != null) year = brandYearMatch.group(0);
    }

    // ── Player name / title: title-case line with no digits or specs ──────
    for (final line in lines) {
      if (line.length < 3 || line.length > 40) continue;
      if (yearRegex.hasMatch(line)) continue;
      if (cardNumRegex.hasMatch(line)) continue;

      if (line.contains(RegExp(r'[0-9]'))) continue;
      if (line.contains(':')) continue;

      if (_teamNames.any((t) => line.toLowerCase() == t.toLowerCase())) continue;
      if (_headerWords.any((h) => line.toLowerCase() == h.toLowerCase())) continue;

      final words = line.split(' ').where((w) => w.isNotEmpty).toList();
      if (words.isEmpty || words.length > 5) continue;

      final isNameLike = words.every((w) {
        final firstLetter = w.replaceAll(RegExp(r'[^a-zA-Z]'), '');
        if (firstLetter.isEmpty) return false; // pure punctuation, reject
        return firstLetter[0] == firstLetter[0].toUpperCase();
      });

      if (isNameLike && playerName == null) {
        playerName = line;
      }
    }

    // ── Build search query ─────────────────────────────────────────────────
    // Deduplicated case-insensitively so the same word doesn't repeat.
    final parts = <String>[];
    final seen = <String>{};
    void addPart(String? value) {
      if (value == null) return;
      final key = value.toLowerCase().trim();
      if (key.isEmpty || seen.contains(key)) return;
      seen.add(key);
      parts.add(value);
    }

    addPart(year);
    addPart(brand);
    addPart(modelCode);
    if (setName != brand) addPart(setName);
    addPart(playerName);
    addPart(grade);
    if (cardNumber != null) addPart('#$cardNumber');

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