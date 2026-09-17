import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import '../../../../core/widgets/custom_spinner.dart';
import '../../../categories/presentation/category_providers.dart';
import '../../data/transaction_repository.dart';
import '../../../expenses/presentation/home_provider.dart';
import '../../../accounts/presentation/accounts_provider.dart';

class PaymentFormDialog extends ConsumerStatefulWidget {
  final int accountId;
  final int itemType; // 1: Ingreso, 2: Gasto

  const PaymentFormDialog({
    super.key,
    required this.accountId,
    required this.itemType,
  });

  @override
  ConsumerState<PaymentFormDialog> createState() => _PaymentFormDialogState();
}

class _PaymentFormDialogState extends ConsumerState<PaymentFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descController = TextEditingController();
  final _amountController = TextEditingController();
  
  DateTime _selectedDate = DateTime.now();
  int? _selectedCategoryId;
  int? _selectedSubCategoryId;
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCategoryId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('La categoría es obligatoria'), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getInt('user_id');
      
      final data = {
        'itemName': _nameController.text.trim(),
        'itemDesc': _descController.text.trim(),
        'ammount': double.parse(_amountController.text.trim().replaceAll(',', '.')),
        'periodity': null,
        'startDate': _selectedDate.toIso8601String(),
        'endDate': _selectedDate.toIso8601String(),
        'cancelled': false,
        'categoryId': _selectedCategoryId,
        'subCategoryId': _selectedSubCategoryId,
        'itemTypeId': widget.itemType,
        'ammountTypeId': 1, // Fijo
        'periodTypeId': 1, // Exporadico
        'accountId': widget.accountId,
        'userId': userId,
      };

      await transactionRepository.addItem(data);
      ref.invalidate(homeDataProvider);
      ref.invalidate(accountsProvider);

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.itemType == 1 ? 'Ingreso registrado' : 'Gasto registrado'),
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
    final categoriesAsync = ref.watch(categoryProvider);
    final subcategoriesAsync = ref.watch(subCategoryProvider);
    final title = widget.itemType == 1 ? 'Nuevo Ingreso (Único)' : 'Nuevo Gasto (Único)';
    final color = widget.itemType == 1 ? Colors.green : Colors.red;

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
              Text(title, style: TextStyle(color: color, fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 24),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Nombre *', prefixIcon: Icon(Icons.title)),
                validator: (val) => val == null || val.isEmpty ? 'Requerido' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descController,
                decoration: const InputDecoration(labelText: 'Descripción (Opcional)', prefixIcon: Icon(Icons.notes)),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _amountController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(labelText: 'Importe (€) *', prefixIcon: Icon(Icons.euro)),
                validator: (val) {
                  if (val == null || val.isEmpty) return 'Requerido';
                  if (double.tryParse(val.replaceAll(',', '.')) == null) return 'Número inválido';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              InkWell(
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: _selectedDate,
                    firstDate: DateTime(2000),
                    lastDate: DateTime(2100),
                  );
                  if (date != null) {
                    setState(() => _selectedDate = date);
                  }
                },
                child: InputDecorator(
                  decoration: const InputDecoration(labelText: 'Fecha', prefixIcon: Icon(Icons.calendar_today)),
                  child: Text(DateFormat('dd/MM/yyyy').format(_selectedDate)),
                ),
              ),
              const SizedBox(height: 16),
              categoriesAsync.when(
                data: (categories) => DropdownButtonFormField<int>(
                  value: _selectedCategoryId,
                  decoration: const InputDecoration(labelText: 'Categoría *', prefixIcon: Icon(Icons.category)),
                  items: categories.map((c) => DropdownMenuItem(value: c.categoryId, child: Text(c.categoryDesc))).toList(),
                  onChanged: (val) {
                    setState(() {
                      _selectedCategoryId = val;
                      _selectedSubCategoryId = null; // Reset subcategory when category changes
                    });
                  },
                  validator: (val) => val == null ? 'Requerido' : null,
                ),
                loading: () => const Center(child: CustomSpinner()),
                error: (error, stack) => Center(child: Text('Error: $error')),
              ),
              const SizedBox(height: 16),
              if (_selectedCategoryId != null)
                subcategoriesAsync.when(
                  data: (subcategories) {
                    final filtered = subcategories.where((s) => s.categoryId == _selectedCategoryId).toList();
                    return DropdownButtonFormField<int>(
                      value: _selectedSubCategoryId,
                      decoration: const InputDecoration(labelText: 'Subcategoría (Opcional)', prefixIcon: Icon(Icons.account_tree)),
                      items: filtered.map((s) => DropdownMenuItem(value: s.subCategoryId, child: Text(s.subCategoryDesc))).toList(),
                      onChanged: (val) => setState(() => _selectedSubCategoryId = val),
                    );
                  },
                  loading: () => const SizedBox(),
                  error: (_, __) => const SizedBox(),
                ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: _isLoading ? null : () => Navigator.pop(context), 
                    child: const Text('Cancelar')
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    style: FilledButton.styleFrom(backgroundColor: color),
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
