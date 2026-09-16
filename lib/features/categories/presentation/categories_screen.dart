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
        centerTitle: true,
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

              return _CategoryItem(
                category: cat,
                subcategories: mySubcategories,
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            builder: (context) => const CategoryFormDialog(categoryToEdit: null),
          );
        },
        tooltip: 'Añadir Categoría',
        child: const Icon(Icons.add),
      ),
    );
  }

}

class _CategoryItem extends ConsumerStatefulWidget {
  final dynamic category;
  final List<dynamic> subcategories;

  const _CategoryItem({
    required this.category,
    required this.subcategories,
  });

  @override
  ConsumerState<_CategoryItem> createState() => _CategoryItemState();
}

class _CategoryItemState extends ConsumerState<_CategoryItem> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: ValueKey('cat_${widget.category.categoryId}'),
      direction: DismissDirection.horizontal,
      background: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.blue,
          borderRadius: BorderRadius.circular(16),
        ),
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: const Icon(Icons.edit, color: Colors.white),
      ),
      secondaryBackground: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.red,
          borderRadius: BorderRadius.circular(16),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.startToEnd) {
          // Swipe hacia la derecha: Editar
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            builder: (context) => CategoryFormDialog(categoryToEdit: widget.category),
          );
          return false; // No ocultar el elemento de la lista
        } else {
          // Swipe hacia la izquierda: Borrar
          return await showDialog<bool>(
            context: context,
            builder: (ctx) => AlertDialog(
              title: const Text('Borrar Categoría'),
              content: const Text('¿Eliminar esta categoría?'),
              actions: [
                TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
                FilledButton(
                  style: FilledButton.styleFrom(backgroundColor: Colors.red),
                  onPressed: () => Navigator.pop(ctx, true),
                  child: const Text('Borrar'),
                ),
              ],
            ),
          );
        }
      },
      onDismissed: (direction) {
        if (direction == DismissDirection.endToStart) {
          ref.read(categoryProvider.notifier).deleteCategory(widget.category.categoryId);
        }
      },
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Column(
          children: [
            ListTile(
              onTap: () {
                setState(() {
                  _isExpanded = !_isExpanded;
                });
              },
              leading: CircleAvatar(
                backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                child: Icon(Icons.category, color: Theme.of(context).colorScheme.primary),
              ),
              title: Text(widget.category.categoryDesc, style: const TextStyle(fontWeight: FontWeight.bold)),
              trailing: Icon(_isExpanded ? Icons.expand_less : Icons.expand_more),
            ),
            if (_isExpanded) ...[
              const Divider(height: 1),
              if (widget.subcategories.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text('No hay subcategorías', style: TextStyle(fontStyle: FontStyle.italic)),
                ),
              ...widget.subcategories.map((sub) => Dismissible(
                    key: ValueKey('sub_${sub.subCategoryId}'),
                    direction: DismissDirection.endToStart,
                    background: Container(
                      color: Colors.red,
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.symmetric(horizontal: 24.0),
                      child: const Icon(Icons.delete, color: Colors.white),
                    ),
                    confirmDismiss: (direction) async {
                      return await showDialog<bool>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text('Borrar Subcategoría'),
                          content: const Text('¿Eliminar esta subcategoría?'),
                          actions: [
                            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
                            FilledButton(
                              style: FilledButton.styleFrom(backgroundColor: Colors.red),
                              onPressed: () => Navigator.pop(ctx, true),
                              child: const Text('Borrar'),
                            ),
                          ],
                        ),
                      );
                    },
                    onDismissed: (direction) {
                      ref.read(subCategoryProvider.notifier).deleteSubCategory(sub.subCategoryId);
                    },
                    child: ListTile(
                      onTap: () {
                        showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          builder: (context) => SubCategoryFormDialog(categoryId: widget.category.categoryId, subCategoryToEdit: sub),
                        );
                      },
                      contentPadding: const EdgeInsets.only(left: 72, right: 16),
                      leading: const Icon(Icons.subdirectory_arrow_right, color: Colors.grey),
                      title: Text(sub.subCategoryDesc),
                    ),
                  )),
              Padding(
                padding: const EdgeInsets.only(bottom: 8.0, top: 8.0),
                child: TextButton.icon(
                  onPressed: () {
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      builder: (context) => SubCategoryFormDialog(categoryId: widget.category.categoryId, subCategoryToEdit: null),
                    );
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('Añadir Subcategoría'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
