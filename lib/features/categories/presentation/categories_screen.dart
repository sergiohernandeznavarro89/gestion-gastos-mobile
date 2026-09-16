import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'category_providers.dart';
import 'widgets/category_form_dialog.dart';
import 'widgets/subcategory_form_dialog.dart';

class CategoriesScreen extends ConsumerWidget {
  const CategoriesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoriesAsync = ref.watch(categoryProvider);
    final subcategoriesAsync = ref.watch(subCategoryProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Categorías'),
      ),
      body: categoriesAsync.when(
        data: (categories) {
          if (categories.isEmpty) {
            return const Center(child: Text('No existen categorías'));
          }

          final allSubcategories = subcategoriesAsync.value ?? [];

          return ListView.builder(
            itemCount: categories.length,
            itemBuilder: (context, index) {
              final cat = categories[index];
              final mySubcategories = allSubcategories.where((s) => s.categoryId == cat.categoryId).toList();

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: ExpansionTile(
                  leading: const CircleAvatar(child: Icon(Icons.category)),
                  title: Text(cat.categoryDesc, style: const TextStyle(fontWeight: FontWeight.bold)),
                  childrenPadding: const EdgeInsets.only(left: 16, right: 16, bottom: 8),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.blue),
                        onPressed: () => _showCategoryDialog(context, cat),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _confirmDeleteCategory(context, ref, cat.categoryId),
                      ),
                      const Icon(Icons.expand_more), // The default expand icon for ExpansionTile
                    ],
                  ),
                  children: [
                    if (mySubcategories.isEmpty)
                      const Padding(
                        padding: EdgeInsets.all(8.0),
                        child: Text('No hay subcategorías', style: TextStyle(fontStyle: FontStyle.italic)),
                      ),
                    ...mySubcategories.map((sub) => ListTile(
                          leading: const Icon(Icons.subdirectory_arrow_right),
                          title: Text(sub.subCategoryDesc),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit, color: Colors.blue, size: 20),
                                onPressed: () => _showSubcategoryDialog(context, cat.categoryId, sub),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                                onPressed: () => _confirmDeleteSubcategory(context, ref, sub.subCategoryId),
                              ),
                            ],
                          ),
                        )),
                    const SizedBox(height: 8),
                    TextButton.icon(
                      onPressed: () => _showSubcategoryDialog(context, cat.categoryId, null),
                      icon: const Icon(Icons.add),
                      label: const Text('Añadir Subcategoría'),
                    ),
                  ],
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCategoryDialog(context, null),
        tooltip: 'Añadir Categoría',
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showCategoryDialog(BuildContext context, dynamic cat) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => CategoryFormDialog(categoryToEdit: cat),
    );
  }

  void _showSubcategoryDialog(BuildContext context, int categoryId, dynamic sub) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => SubCategoryFormDialog(categoryId: categoryId, subCategoryToEdit: sub),
    );
  }

  void _confirmDeleteCategory(BuildContext context, WidgetRef ref, int id) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Borrar Categoría'),
        content: const Text('¿Eliminar esta categoría?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              Navigator.pop(ctx);
              ref.read(categoryProvider.notifier).deleteCategory(id);
            },
            child: const Text('Borrar'),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteSubcategory(BuildContext context, WidgetRef ref, int id) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Borrar Subcategoría'),
        content: const Text('¿Eliminar esta subcategoría?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              Navigator.pop(ctx);
              ref.read(subCategoryProvider.notifier).deleteSubCategory(id);
            },
            child: const Text('Borrar'),
          ),
        ],
      ),
    );
  }
}
