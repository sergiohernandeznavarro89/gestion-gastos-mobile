import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import '../../../../core/widgets/custom_spinner.dart';
import '../../../categories/presentation/category_providers.dart';
import '../../../accounts/presentation/accounts_provider.dart';
import '../../data/transaction_repository.dart';
import '../../../expenses/presentation/home_provider.dart';
import '../transactions_provider.dart';

import '../../domain/transaction_models.dart';

class ItemFormDialog extends ConsumerStatefulWidget {
  final UnifiedPendingItem? item; // Si es nulo, es creación
  final bool isIncome;

  const ItemFormDialog({
    super.key,
    this.item,
    required this.isIncome,
  });

  @override
  ConsumerState<ItemFormDialog> createState() => _ItemFormDialogState();
}

class _ItemFormDialogState extends ConsumerState<ItemFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descController = TextEditingController();
  final _amountController = TextEditingController();
  
  DateTime _startDate = DateTime.now();
  late DateTime _endDate;
  int? _selectedCategoryId;
  int? _selectedSubCategoryId;
  int? _accountId;
  int _ammountTypeId = 1; // 1 Fijo, 2 Variable
  int _periodity = 1; // 1 Mensual, 2 Bimensual, 3 Trimestral, 12 Anual
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.item != null) {
      final i = widget.item!;
      _nameController.text = i.name;
      _descController.text = i.desc;
      _amountController.text = i.ammount.toString();
      _startDate = i.startDate;
      _endDate = i.endDate ?? DateTime(_startDate.year + 30, _startDate.month, _startDate.day);
      _selectedCategoryId = i.categoryId;
      _selectedSubCategoryId = i.subCategoryId;
      _accountId = i.accountId;
      _ammountTypeId = i.ammountTypeId;
      _periodity = i.periodity ?? 1;
    } else {
      _endDate = DateTime(_startDate.year + 30, _startDate.month, _startDate.day);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isLoading = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getInt('user_id');
      
      final data = {
        'itemName': _nameController.text.trim(),
        'itemDesc': _descController.text.trim(),
        'ammount': _ammountTypeId == 1 ? double.parse(_amountController.text.trim().replaceAll(',', '.')) : 0.0,
        'periodity': _periodity,
        'startDate': _startDate.toIso8601String(),
        'endDate': _endDate.toIso8601String(),
        'categoryId': _selectedCategoryId,
        'subCategoryId': _selectedSubCategoryId,
        'itemTypeId': widget.isIncome ? 1 : 2,
        'ammountTypeId': _ammountTypeId,
        'periodTypeId': 2, // 2 = Recurrente
        'accountId': _accountId,
        'userId': userId,
      };

      if (widget.item != null) {
        data['itemId'] = widget.item!.id;
        await transactionRepository.updateItem(data);
      } else {
        await transactionRepository.addItem(data);
      }
      
      ref.invalidate(homeDataProvider);
      ref.invalidate(transactionsProvider);
      ref.invalidate(accountsProvider); 

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.item == null ? 'Movimiento registrado' : 'Movimiento actualizado'),
            backgroundColor: Colors.green
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
    final accountsAsync = ref.watch(accountsProvider);
    
    final color = widget.isIncome ? Colors.green : Colors.red;
    final title = widget.item == null 
      ? (widget.isIncome ? 'Nuevo Ingreso' : 'Nuevo Gasto')
      : (widget.isIncome ? 'Editar Ingreso' : 'Editar Gasto');

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
              Text(
                title, 
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)
              ),
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
              DropdownButtonFormField<int>(
                value: _ammountTypeId,
                decoration: const InputDecoration(labelText: 'Tipo Importe', prefixIcon: Icon(Icons.merge_type)),
                items: const [
                  DropdownMenuItem(value: 1, child: Text('Fijo')),
                  DropdownMenuItem(value: 2, child: Text('Variable')),
                ],
                onChanged: (val) {
                  setState(() {
                    _ammountTypeId = val!;
                    if (val == 2) _amountController.clear(); // Clear amount if variable
                  });
                },
              ),
              const SizedBox(height: 16),
              if (_ammountTypeId == 1) ...[
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
              ],
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: _startDate,
                          firstDate: DateTime(2000),
                          lastDate: DateTime(2100),
                        );
                        if (date != null) {
                          setState(() {
                            final now = DateTime.now();
                            _startDate = DateTime(date.year, date.month, date.day, now.hour, now.minute, now.second);
                            // Optionally update end date to keep 30 years diff if desired, 
                            // but usually just init is fine, though we'll update it to be safe
                            _endDate = DateTime(date.year + 30, date.month, date.day);
                          });
                        }
                      },
                      child: InputDecorator(
                        decoration: const InputDecoration(labelText: 'Fecha Inicio', prefixIcon: Icon(Icons.calendar_today)),
                        child: Text(DateFormat('dd/MM/yyyy').format(_startDate)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: InkWell(
                      onTap: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: _endDate,
                          firstDate: _startDate,
                          lastDate: DateTime(2100),
                        );
                        if (date != null) {
                          setState(() => _endDate = date);
                        }
                      },
                      child: InputDecorator(
                        decoration: const InputDecoration(labelText: 'Fecha Fin', prefixIcon: Icon(Icons.event)),
                        child: Text(DateFormat('dd/MM/yyyy').format(_endDate)),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<int>(
                      value: _periodity,
                      decoration: const InputDecoration(labelText: 'Periodicidad'),
                      items: const [
                        DropdownMenuItem(value: 1, child: Text('Mensual')),
                        DropdownMenuItem(value: 2, child: Text('Bimensual')),
                        DropdownMenuItem(value: 3, child: Text('Trimestral')),
                        DropdownMenuItem(value: 12, child: Text('Anual')),
                      ],
                      onChanged: (val) => setState(() => _periodity = val!),
                    ),
                  )
                ],
              ),
              const SizedBox(height: 16),
              accountsAsync.when(
                data: (accounts) {
                  return DropdownButtonFormField<int>(
                    value: _accountId,
                    decoration: const InputDecoration(labelText: 'Cuenta *', prefixIcon: Icon(Icons.account_balance_wallet)),
                    items: accounts.map((a) => DropdownMenuItem(value: a.accountId, child: Text(a.accountName))).toList(),
                    onChanged: (val) => setState(() => _accountId = val),
                    validator: (val) => val == null ? 'Requerido' : null,
                  );
                },
                loading: () => const Center(child: CustomSpinner()),
                error: (error, stack) => Center(child: Text('Error: $error')),
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
                      _selectedSubCategoryId = null; 
                    });
                  },
                  validator: (val) => val == null ? 'Requerido' : null,
                ),
                loading: () => const SizedBox(),
                error: (e, _) => const SizedBox(),
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
              const SizedBox(height: 24), // Extra bottom padding
            ],
          ),
        ),
      ),
    );
  }
}
