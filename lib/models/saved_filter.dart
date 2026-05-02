class SavedFilter {
  const SavedFilter({
    required this.id,
    required this.name,
    required this.searchQuery,
    required this.tagFilters,
    required this.typeKeys,
    required this.favoritesOnly,
    required this.sortModeKey,
  });

  factory SavedFilter.fromJson(Map<String, Object?> json) {
    return SavedFilter(
      id: _readString(json, 'id'),
      name: _readString(json, 'name'),
      searchQuery: _readString(json, 'searchQuery'),
      tagFilters: _readStringList(json, 'tagFilters'),
      typeKeys: _readStringList(json, 'typeKeys'),
      favoritesOnly: json['favoritesOnly'] == true,
      sortModeKey: _readString(json, 'sortModeKey'),
    );
  }

  final String id;
  final String name;
  final String searchQuery;
  final List<String> tagFilters;
  final List<String> typeKeys;
  final bool favoritesOnly;
  final String sortModeKey;

  Map<String, Object?> toJson() {
    return {
      'id': id,
      'name': name,
      'searchQuery': searchQuery,
      'tagFilters': tagFilters,
      'typeKeys': typeKeys,
      'favoritesOnly': favoritesOnly,
      'sortModeKey': sortModeKey,
    };
  }

  static String _readString(Map<String, Object?> json, String field) {
    final value = json[field];
    return value is String ? value : '';
  }

  static List<String> _readStringList(Map<String, Object?> json, String field) {
    final value = json[field];
    if (value is! List) {
      return const [];
    }
    return [
      for (final item in value)
        if (item is String) item,
    ];
  }
}
