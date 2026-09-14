class BookQuery {
  final String search;
  final int? genreId;
  final int? publisherId;
  final int? yearFrom;
  final int? yearTo;
  final String sortField;
  final bool sortAscending;
  final int page;
  final int size;
  final bool includeDeleted;
  final int? delay;
  final int? fail;

  const BookQuery({
    this.search = '',
    this.genreId,
    this.publisherId,
    this.yearFrom,
    this.yearTo,
    this.sortField = 'title',
    this.sortAscending = true,
    this.page = 1,
    this.size = 10,
    this.includeDeleted = false,
    this.delay,
    this.fail,
  });

  bool get sortAsc => sortAscending;
  bool get showDeleted => includeDeleted;

  BookQuery copyWith({
    String? search,
    int? genreId,
    int? publisherId,
    int? yearFrom,
    int? yearTo,
    String? sortField,
    bool? sortAscending,
    bool? sortAsc,
    int? page,
    int? size,
    bool? includeDeleted,
    bool? showDeleted,
    int? delay,
    int? fail,
  }) {
    return BookQuery(
      search: search ?? this.search,
      genreId: genreId ?? this.genreId,
      publisherId: publisherId ?? this.publisherId,
      yearFrom: yearFrom ?? this.yearFrom,
      yearTo: yearTo ?? this.yearTo,
      sortField: sortField ?? this.sortField,
      sortAscending: sortAscending ?? sortAsc ?? this.sortAscending,
      page: page ?? this.page,
      size: size ?? this.size,
      includeDeleted: includeDeleted ?? showDeleted ?? this.includeDeleted,
      delay: delay ?? this.delay,
      fail: fail ?? this.fail,
    );
  }

  Map<String, dynamic> toQueryParams() {
    final params = <String, dynamic>{
      'sort': '$sortField,${sortAscending ? "asc" : "desc"}',
      'page': page,
      'size': size,
    };
    if (search.trim().isNotEmpty) {
      params['search'] = search.trim();
    }
    if (genreId != null) params['genreId'] = genreId;
    if (publisherId != null) params['publisherId'] = publisherId;
    if (yearFrom != null) params['yearFrom'] = yearFrom;
    if (yearTo != null) params['yearTo'] = yearTo;
    if (includeDeleted) params['deleted'] = 'true';
    if (delay != null && delay! > 0) params['__delay'] = delay;
    if (fail != null && fail! > 0) params['__fail'] = fail;
    return params;
  }
}