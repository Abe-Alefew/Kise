class TransactionQueryFilter {
  final String? type;
  final String? category;
  final String? from;
  final String? to;
  final String? searchQuery;
  final String sort;
  final int page;
  final int limit;
  final int offset;

  const TransactionQueryFilter({
    this.type,
    this.category,
    this.from,
    this.to,
    this.searchQuery,
    this.sort = 'date_desc',
    this.page = 1,
    this.limit = 50,
    this.offset = 0,
  });

  TransactionQueryFilter copyWith({
    String? type,
    String? category,
    String? from,
    String? to,
    String? searchQuery,
    String? sort,
    int? page,
    int? limit,
    int? offset,
  }) {
    return TransactionQueryFilter(
      type: type ?? this.type,
      category: category ?? this.category,
      from: from ?? this.from,
      to: to ?? this.to,
      searchQuery: searchQuery ?? this.searchQuery,
      sort: sort ?? this.sort,
      page: page ?? this.page,
      limit: limit ?? this.limit,
      offset: offset ?? this.offset,
    );
  }

  Map<String, dynamic> toQueryParameters() {
    final effectivePage = offset > 0 ? (offset ~/ limit) + 1 : page;

    return {
      if (type != null && type!.isNotEmpty && type != 'All') 'type': type,
      if (category != null && category!.isNotEmpty) 'category': category,
      if (from != null && from!.isNotEmpty) 'from': from,
      if (to != null && to!.isNotEmpty) 'to': to,
      if (searchQuery != null && searchQuery!.trim().isNotEmpty)
        'q': searchQuery!.trim(),
      'sort': sort,
      'page': effectivePage,
      'limit': limit,
    };
  }
}