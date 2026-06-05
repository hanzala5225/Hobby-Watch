class EbaySearchResponse {
  final String searchQuery;
  final double? avg30Day;
  final double? avg60Day;
  final double? avg90Day;
  final double? lowestPrice;
  final double? highestPrice;
  final int totalResults;
  final bool fromCache;
  final String? dataNote;
  final List<EbayListingItem> listings;

  EbaySearchResponse({
    required this.searchQuery,
    this.avg30Day,
    this.avg60Day,
    this.avg90Day,
    this.lowestPrice,
    this.highestPrice,
    this.totalResults = 0,
    this.fromCache = false,
    this.dataNote,
    this.listings = const [],
  });

  factory EbaySearchResponse.fromJson(Map<String, dynamic> json) {
    final data = json['data'] ?? json;
    return EbaySearchResponse(
      searchQuery:  data['searchQuery'] ?? '',
      avg30Day:     (data['avg30Day'] as num?)?.toDouble(),
      avg60Day:     (data['avg60Day'] as num?)?.toDouble(),
      avg90Day:     (data['avg90Day'] as num?)?.toDouble(),
      lowestPrice:  (data['lowestPrice'] as num?)?.toDouble(),
      highestPrice: (data['highestPrice'] as num?)?.toDouble(),
      totalResults: data['totalResults'] ?? 0,
      fromCache:    data['fromCache'] ?? false,
      dataNote:     data['dataNote'],
      listings:     (data['listings'] as List<dynamic>?)
          ?.map((e) => EbayListingItem.fromJson(e))
          .toList() ?? [],
    );
  }
}

class EbayListingItem {
  final String itemId;
  final String title;
  final double price;
  final String currency;
  final String? imageUrl;
  final String? itemUrl;
  final String? condition;

  EbayListingItem({
    required this.itemId,
    required this.title,
    required this.price,
    this.currency = 'USD',
    this.imageUrl,
    this.itemUrl,
    this.condition,
  });

  factory EbayListingItem.fromJson(Map<String, dynamic> json) => EbayListingItem(
    itemId:    json['itemId'] ?? '',
    title:     json['title'] ?? '',
    price:     (json['price'] as num?)?.toDouble() ?? 0.0,
    currency:  json['currency'] ?? 'USD',
    imageUrl:  json['imageUrl'],
    itemUrl:   json['itemUrl'],
    condition: json['condition'],
  );
}
