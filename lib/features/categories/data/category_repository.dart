import '../../../core/network/api_client.dart';
import '../domain/category_models.dart';

class CategoryRepository {
  // --- Categorías ---
  Future<List<Category>> getCategoriesByUser(int userId) async {
    try {
      final response = await dio.get('/Category/GetCategoriesByUser?userId=$userId');
      final List<dynamic> data = response.data;
      return data.map((json) => Category.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Error al obtener categorías: $e');
    }
  }

  Future<void> addCategory(int userId, String desc) async {
    try {
      await dio.post('/Category/AddCategory', data: {
        'userId': userId,
        'categoryDesc': desc,
      });
    } catch (e) {
      throw Exception('Error al crear categoría: $e');
    }
  }

  Future<void> updateCategory(int categoryId, String desc) async {
    try {
      await dio.put('/Category/UpdateCategory', data: {
        'categoryId': categoryId,
        'categoryDesc': desc,
      });
    } catch (e) {
      throw Exception('Error al actualizar categoría: $e');
    }
  }

  Future<void> deleteCategory(int categoryId) async {
    try {
      await dio.delete('/Category/DeleteCategory?categoryId=$categoryId');
    } catch (e) {
      throw Exception('Error al eliminar categoría: $e');
    }
  }

  // --- Subcategorías ---
  Future<List<SubCategory>> getSubCategoriesByUser(int userId) async {
    try {
      final response = await dio.get('/SubCategory/GetSubCategoriesByUser?userId=$userId');
      final List<dynamic> data = response.data;
      return data.map((json) => SubCategory.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Error al obtener subcategorías: $e');
    }
  }

  Future<void> addSubCategory(int userId, int categoryId, String desc) async {
    try {
      await dio.post('/SubCategory/AddSubCategory', data: {
        'userId': userId,
        'categoryId': categoryId,
        'subCategoryDesc': desc,
      });
    } catch (e) {
      throw Exception('Error al crear subcategoría: $e');
    }
  }

  Future<void> updateSubCategory(int subCategoryId, int categoryId, String desc) async {
    try {
      await dio.put('/SubCategory/UpdateSubCategory', data: {
        'subCategoryId': subCategoryId,
        'categoryId': categoryId,
        'subCategoryDesc': desc,
      });
    } catch (e) {
      throw Exception('Error al actualizar subcategoría: $e');
    }
  }

  Future<void> deleteSubCategory(int subCategoryId) async {
    try {
      await dio.delete('/SubCategory/DeleteSubCategory?subCategoryId=$subCategoryId');
    } catch (e) {
      throw Exception('Error al eliminar subcategoría: $e');
    }
  }
}

final categoryRepository = CategoryRepository();
