class ScanResultModel {
  final String rawText;
  final String? playerName;
  final String? year;
  final String? brand;
  final String? setName;
  final String? cardNumber;
  final String? grade;
  final String searchQuery;

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
