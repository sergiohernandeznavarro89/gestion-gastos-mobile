class Category {
  final int categoryId;
  final String categoryDesc;

  Category({
    required this.categoryId,
    required this.categoryDesc,
  });

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      categoryId: json['categoryId'],
      categoryDesc: json['categoryDesc'],
    );
  }
}

class SubCategory {
  final int subCategoryId;
  final String subCategoryDesc;
  final int categoryId;

  SubCategory({
    required this.subCategoryId,
    required this.subCategoryDesc,
    required this.categoryId,
  });

  factory SubCategory.fromJson(Map<String, dynamic> json) {
    return SubCategory(
      subCategoryId: json['subCategoryId'],
      subCategoryDesc: json['subCategoryDesc'],
      categoryId: json['categoryId'],
    );
  }
}
