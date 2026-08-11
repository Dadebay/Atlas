class CategoryModel {
  final int id;
  final int? parentId;
  final Map<String, String> name;
  final int sortOrder;
  final String imageLarge;
  final String imageSmall;
  final List<CategoryModel> children;

  const CategoryModel({
    required this.id,
    this.parentId,
    required this.name,
    required this.sortOrder,
    required this.imageLarge,
    required this.imageSmall,
    required this.children,
  });

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    final rawName = json['name'];
    final Map<String, String> nameMap = rawName is Map
        ? rawName.map((k, v) => MapEntry(k.toString(), v.toString()))
        : {'tk': rawName?.toString() ?? '', 'ru': rawName?.toString() ?? ''};

    final rawChildren = json['children'];
    final List<CategoryModel> childList = (rawChildren is List)
        ? rawChildren
            .whereType<Map<String, dynamic>>()
            .map((e) => CategoryModel.fromJson(e))
            .toList()
        : [];

    return CategoryModel(
      id: json['id'] as int,
      parentId: json['parent_id'] as int?,
      name: nameMap,
      sortOrder: json['sort_order'] as int? ?? 0,
      imageLarge: json['image_large']?.toString() ?? '',
      imageSmall: json['image_small']?.toString() ?? '',
      children: childList,
    );
  }

  String localName(String lang) =>
      name[lang] ?? name['tk'] ?? name['ru'] ?? '';
}
