class CardModel {
  final String id;
  final String userId;
  final String name;
  final String playerName;
  final String year;
  final String? setName;
  final String? parallel;
  final String? brand;
  final String? cardNumber;
  final String? grade;
  final String? condition;
  final String sport;
  final String? imageUrl;
  final String addedVia;
  final double purchasePrice;
  final double targetMarginPercent;
  final double ebayFeePercent;
  final double? currentEbayAvg30;
  final double? currentEbayAvg60;
  final double? currentEbayAvg90;
  final DateTime? lastPriceUpdate;
  final double? currentMarginPercent;
  final double? profitDollar;
  final bool isTargetReached;
  final bool isProfitable;
  final bool isSold;
  final double? soldPrice;
  final bool soldOutsideEbay;
  final double shippingCharge;
  final double? ebayFeeAmount;
  final DateTime? soldAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  CardModel({
    required this.id,
    required this.userId,
    required this.name,
    required this.playerName,
    required this.year,
    this.setName,
    this.parallel,
    this.brand,
    this.cardNumber,
    this.grade,
    this.condition,
    this.sport = 'Basketball',
    this.imageUrl,
    this.addedVia = 'manual',
    required this.purchasePrice,
    this.targetMarginPercent = 30.0,
    this.ebayFeePercent = 13.25,
    this.currentEbayAvg30,
    this.currentEbayAvg60,
    this.currentEbayAvg90,
    this.lastPriceUpdate,
    this.currentMarginPercent,
    this.profitDollar,
    this.isTargetReached = false,
    this.isProfitable = false,
    this.isSold = false,
    this.soldPrice,
    this.soldOutsideEbay = false,
    this.shippingCharge = 0,
    this.ebayFeeAmount,
    this.soldAt,
    required this.createdAt,
    required this.updatedAt,
  });

  factory CardModel.fromJson(Map<String, dynamic> json) => CardModel(
    id:                   json['id'] ?? '',
    userId:               json['userId'] ?? '',
    name:                 json['name'] ?? '',
    playerName:           json['playerName'] ?? '',
    year:                 json['year'] ?? '',
    setName:              json['setName'],
    parallel:             json['parallel'],
    brand:                json['brand'],
    cardNumber:           json['cardNumber'],
    grade:                json['grade'],
    condition:            json['condition'],
    sport:                json['sport'] ?? 'Basketball',
    imageUrl:             json['imageUrl'],
    addedVia:             json['addedVia'] ?? 'manual',
    purchasePrice:        (json['purchasePrice'] as num?)?.toDouble() ?? 0.0,
    targetMarginPercent:  (json['targetMarginPercent'] as num?)?.toDouble() ?? 30.0,
    ebayFeePercent:       (json['ebayFeePercent'] as num?)?.toDouble() ?? 13.25,
    currentEbayAvg30:     (json['currentEbayAvg30'] as num?)?.toDouble(),
    currentEbayAvg60:     (json['currentEbayAvg60'] as num?)?.toDouble(),
    currentEbayAvg90:     (json['currentEbayAvg90'] as num?)?.toDouble(),
    lastPriceUpdate:      json['lastPriceUpdate'] != null
        ? DateTime.parse(json['lastPriceUpdate'])
        : null,
    currentMarginPercent: (json['currentMarginPercent'] as num?)?.toDouble(),
    profitDollar:         (json['profitDollar'] as num?)?.toDouble(),
    isTargetReached:      json['isTargetReached'] ?? false,
    isProfitable:         json['isProfitable'] ?? false,
    isSold:               json['isSold'] ?? false,
    soldPrice:            (json['soldPrice'] as num?)?.toDouble(),
    soldOutsideEbay:      json['soldOutsideEbay'] ?? false,
    shippingCharge:       (json['shippingCharge'] as num?)?.toDouble() ?? 0,
    ebayFeeAmount:        (json['ebayFeeAmount'] as num?)?.toDouble(),
    soldAt:               json['soldAt'] != null ? DateTime.parse(json['soldAt']) : null,
    createdAt:            json['createdAt'] != null
        ? DateTime.parse(json['createdAt'])
        : DateTime.now(),
    updatedAt:            json['updatedAt'] != null
        ? DateTime.parse(json['updatedAt'])
        : DateTime.now(),
  );

  String get displayName => '$playerName${year.isNotEmpty ? " ($year)" : ""} ${setName ?? ""}'.trim();
}

// Portfolio summary from GET /api/cards
class PortfolioSummary {
  final int totalCards;
  final int cardsAtTarget;
  final int profitableCards;
  final double totalInvested;
  final double totalCurrentValue;
  final double totalProfitLoss;
  final double totalProfitLossPercent;

  PortfolioSummary({
    this.totalCards = 0,
    this.cardsAtTarget = 0,
    this.profitableCards = 0,
    this.totalInvested = 0,
    this.totalCurrentValue = 0,
    this.totalProfitLoss = 0,
    this.totalProfitLossPercent = 0,
  });

  factory PortfolioSummary.fromJson(Map<String, dynamic> json) => PortfolioSummary(
    totalCards:            json['totalCards'] ?? 0,
    cardsAtTarget:         json['cardsAtTarget'] ?? 0,
    profitableCards:       json['profitableCards'] ?? 0,
    totalInvested:         (json['totalInvested'] as num?)?.toDouble() ?? 0,
    totalCurrentValue:     (json['totalCurrentValue'] as num?)?.toDouble() ?? 0,
    totalProfitLoss:       (json['totalProfitLoss'] as num?)?.toDouble() ?? 0,
    totalProfitLossPercent:(json['totalProfitLossPercent'] as num?)?.toDouble() ?? 0,
  );

  static PortfolioSummary empty() => PortfolioSummary();
}