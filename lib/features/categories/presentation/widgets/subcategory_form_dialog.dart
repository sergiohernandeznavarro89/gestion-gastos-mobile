import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/widgets/custom_spinner.dart';
import '../../domain/category_models.dart';
import '../category_providers.dart';

class SubCategoryFormDialog extends ConsumerStatefulWidget {
  final int categoryId;
  final SubCategory? subCategoryToEdit;

  const SubCategoryFormDialog({
    super.key,
    required this.categoryId,
    this.subCategoryToEdit,
  });

  @override
  ConsumerState<SubCategoryFormDialog> createState() => _SubCategoryFormDialogState();
}

class _SubCategoryFormDialogState extends ConsumerState<SubCategoryFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _descController;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _descController = TextEditingController(text: widget.subCategoryToEdit?.subCategoryDesc ?? '');
  }

  @override
  void dispose() {
    _descController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final desc = _descController.text.trim();

      if (widget.subCategoryToEdit == null) {
        await ref.read(subCategoryProvider.notifier).addSubCategory(widget.categoryId, desc);
      } else {
        await ref.read(subCategoryProvider.notifier).updateSubCategory(widget.subCategoryToEdit!.subCategoryId, widget.categoryId, desc);
      }

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.subCategoryToEdit == null ? 'Subcategoría creada' : 'Subcategoría actualizada'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.subCategoryToEdit != null;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 16,
        right: 16,
        top: 24,
      ),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(isEditing ? 'Editar Subcategoría' : 'Nueva Subcategoría', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 24),
              TextFormField(
                controller: _descController,
                decoration: const InputDecoration(
                  labelText: 'Descripción',
                  prefixIcon: Icon(Icons.account_tree),
                ),
                validator: (value) => value == null || value.isEmpty ? 'Requerido' : null,
                enabled: !_isLoading,
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
                    child: const Text('Cancelar'),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: _isLoading ? null : _submit,
                    child: _isLoading 
                      ? const SizedBox(width: 16, height: 16, child: CustomSpinner(size: 16, color: Colors.white))
                      : const Text('Guardar'),
                  ),
                ],
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
