class AuthorQuery {
  final String search;
  final String? country;
  final String sortField;
  final bool sortAscending;
  final int page;
  final int size;
  final bool includeDeleted;

  const AuthorQuery({
    this.search = '',
    this.country,
    this.sortField = 'lastName',
    this.sortAscending = true,
    this.page = 1,
    this.size = 10,
    this.includeDeleted = false,
  });

  AuthorQuery copyWith({
    String? search,
    Object? country = _unset,
    String? sortField,
    bool? sortAscending,
    int? page,
    int? size,
    bool? includeDeleted,
  }) {
    return AuthorQuery(
      search: search ?? this.search,
      country: country == _unset ? this.country : country as String?,
      sortField: sortField ?? this.sortField,
      sortAscending: sortAscending ?? this.sortAscending,
      page: page ?? 1,
      size: size ?? this.size,
      includeDeleted: includeDeleted ?? this.includeDeleted,
    );
  }

  static const _unset = Object();

  Map<String, String> toQueryParams() {
    final params = <String, String>{};
    if (search.trim().isNotEmpty) params['search'] = search.trim();
    if (country != null && country!.isNotEmpty) params['country'] = country!;
    params['sort'] = '$sortField,${sortAscending ? 'asc' : 'desc'}';
    if (page > 1) params['page'] = page.toString();
    if (size != 10) params['size'] = size.toString();
    if (includeDeleted) params['includeDeleted'] = 'true';
    return params;
  }

  factory AuthorQuery.fromQueryParams(Map<String, String> params) {
    final sortRaw = params['sort'] ?? 'lastName,asc';
    final sortParts = sortRaw.split(',');
    return AuthorQuery(
      search: params['search'] ?? '',
      country: params['country'],
      sortField: sortParts.isNotEmpty ? sortParts[0] : 'lastName',
      sortAscending: sortParts.length > 1 ? sortParts[1] != 'desc' : true,
      page: int.tryParse(params['page'] ?? '1') ?? 1,
      size: int.tryParse(params['size'] ?? '10') ?? 10,
      includeDeleted: params['includeDeleted'] == 'true',
    );
  }
}
