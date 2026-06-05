/// Holds the result from Google ML Kit OCR processing
/// After scanning a card image, OCR extracts raw text
/// which is then cleaned into structured fields
class ScanResultModel {
  final String rawText;          // full OCR output
  final String? playerName;      // extracted player name
  final String? year;            // extracted year e.g. "1996"
  final String? brand;           // e.g. "Topps", "Panini"
  final String? setName;         // e.g. "Chrome", "Prizm"
  final String? cardNumber;      // e.g. "#57"
  final String? grade;           // e.g. "PSA 10", "BGS 9.5"
  final String searchQuery;      // cleaned query sent to eBay

  ScanResultModel({
    required this.rawText,
    this.playerName,
    this.year,
    this.brand,
    this.setName,
    this.cardNumber,
    this.grade,
    required this.searchQuery,
  });

  /// Build a clean eBay search query from extracted fields
  static String buildSearchQuery({
    String? playerName,
    String? year,
    String? brand,
    String? setName,
    String? cardNumber,
    String? grade,
  }) {
    final parts = [
      if (year != null && year.isNotEmpty) year,
      if (brand != null && brand.isNotEmpty) brand,
      if (setName != null && setName.isNotEmpty) setName,
      if (playerName != null && playerName.isNotEmpty) playerName,
      if (cardNumber != null && cardNumber.isNotEmpty) cardNumber,
      if (grade != null && grade.isNotEmpty) grade,
    ];
    return parts.join(' ').trim();
  }

  /// Dummy result for UI demo
  static ScanResultModel dummy() => ScanResultModel(
        rawText: 'Michael Jordan\n1996 Topps\n#57\nNear Mint',
        playerName: 'Michael Jordan',
        year: '1996',
        brand: 'Topps',
        setName: null,
        cardNumber: '#57',
        grade: null,
        searchQuery: '1996 Topps Michael Jordan #57',
      );

  @override
  String toString() => 'ScanResult($searchQuery)';
}
