import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/category_repository.dart';
import '../domain/category_models.dart';

// --- Category Provider ---
class CategoryNotifier extends AsyncNotifier<List<Category>> {
  @override
  Future<List<Category>> build() async {
    return _fetch();
  }

  Future<List<Category>> _fetch() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getInt('user_id');
    if (userId == null) throw Exception('Usuario no autenticado');
    return await categoryRepository.getCategoriesByUser(userId);
  }

  Future<void> addCategory(String desc) async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getInt('user_id');
    if (userId == null) throw Exception('Usuario no autenticado');

    await categoryRepository.addCategory(userId, desc);
    _reload();
  }

  Future<void> updateCategory(int id, String desc) async {
    await categoryRepository.updateCategory(id, desc);
    _reload();
  }

  Future<void> deleteCategory(int id) async {
    final currentList = state.value ?? [];
    state = AsyncValue.data(currentList.where((c) => c.categoryId != id).toList());
    try {
      await categoryRepository.deleteCategory(id);
    } catch (e) {
      _reload(); // Revert on error
      rethrow;
    }
  }

  void _reload() async {
    state = await AsyncValue.guard(() => _fetch());
  }
}

final categoryProvider = AsyncNotifierProvider<CategoryNotifier, List<Category>>(CategoryNotifier.new);


// --- SubCategory Provider ---
class SubCategoryNotifier extends AsyncNotifier<List<SubCategory>> {
  @override
  Future<List<SubCategory>> build() async {
    return _fetch();
  }

  Future<List<SubCategory>> _fetch() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getInt('user_id');
    if (userId == null) throw Exception('Usuario no autenticado');
    return await categoryRepository.getSubCategoriesByUser(userId);
  }

  Future<void> addSubCategory(int categoryId, String desc) async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getInt('user_id');
    if (userId == null) throw Exception('Usuario no autenticado');

    await categoryRepository.addSubCategory(userId, categoryId, desc);
    _reload();
  }

  Future<void> updateSubCategory(int id, int categoryId, String desc) async {
    await categoryRepository.updateSubCategory(id, categoryId, desc);
    _reload();
  }

  Future<void> deleteSubCategory(int id) async {
    final currentList = state.value ?? [];
    state = AsyncValue.data(currentList.where((s) => s.subCategoryId != id).toList());
    try {
      await categoryRepository.deleteSubCategory(id);
    } catch (e) {
      _reload(); // Revert on error
      rethrow;
    }
  }

  void _reload() async {
    state = await AsyncValue.guard(() => _fetch());
  }
}

final subCategoryProvider = AsyncNotifierProvider<SubCategoryNotifier, List<SubCategory>>(SubCategoryNotifier.new);
