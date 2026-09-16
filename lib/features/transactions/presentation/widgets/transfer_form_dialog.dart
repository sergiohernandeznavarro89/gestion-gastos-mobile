import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import '../../../categories/presentation/category_providers.dart';
import '../../../accounts/presentation/accounts_provider.dart';
import '../../data/transaction_repository.dart';
import '../../../expenses/presentation/home_provider.dart';
import '../transactions_provider.dart';

import '../../domain/transaction_models.dart';

class TransferFormDialog extends ConsumerStatefulWidget {
  final int? originAccountId;
  final UnifiedPendingItem? item;
  final bool isRecurring;

  const TransferFormDialog({
    super.key,
    this.originAccountId,
    this.item,
    this.isRecurring = false,
  });

  @override
  ConsumerState<TransferFormDialog> createState() => _TransferFormDialogState();
}

class _TransferFormDialogState extends ConsumerState<TransferFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descController = TextEditingController();
  final _amountController = TextEditingController();
  
  DateTime _startDate = DateTime.now();
  late DateTime _endDate;
  int? _selectedCategoryId;
  int? _selectedSubCategoryId;
  int? _destinationAccountId;
  int? _originAccountId;
  int _periodity = 1; // Default Mensual
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _originAccountId = widget.originAccountId;
    if (widget.item != null) {
      final t = widget.item!;
      _nameController.text = t.name;
      _descController.text = t.desc;
      _amountController.text = t.ammount.toString();
      _startDate = t.startDate;
      _endDate = t.endDate ?? DateTime(_startDate.year + 30, _startDate.month, _startDate.day);
      _selectedCategoryId = t.categoryId;
      _selectedSubCategoryId = t.subCategoryId;
      _originAccountId = t.originAccountId;
      _destinationAccountId = t.destinationAccountId;
      _periodity = t.periodity ?? 1;
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
    
    if (_destinationAccountId == widget.originAccountId) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('La cuenta destino no puede ser la misma que la origen'), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getInt('user_id');
      
      final data = {
        'transferName': _nameController.text.trim(),
        'transferDesc': _descController.text.trim(),
        'ammount': double.parse(_amountController.text.trim().replaceAll(',', '.')),
        'periodity': widget.isRecurring ? _periodity : null,
        'startDate': _startDate.toIso8601String(),
        'endDate': widget.isRecurring ? _endDate.toIso8601String() : _startDate.toIso8601String(),
        'categoryId': _selectedCategoryId,
        'subCategoryId': _selectedSubCategoryId,
        'originAccountId': _originAccountId,
        'destinationAccountId': _destinationAccountId,
        'periodTypeId': widget.isRecurring ? 2 : 1,
        'userId': userId,
      };

      if (widget.item != null) {
        data['transferId'] = widget.item!.id;
        await transactionRepository.updateTransfer(data);
      } else {
        await transactionRepository.addTransfer(data);
      }
      
      ref.invalidate(homeDataProvider);
      ref.invalidate(transactionsProvider);
      ref.invalidate(accountsProvider); // Refrescar cuentas para actualizar saldos

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.item == null ? 'Transferencia registrada' : 'Transferencia actualizada'), 
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
              Text(widget.item == null ? 'Nueva Transferencia' : 'Editar Transferencia', style: const TextStyle(color: Colors.blue, fontSize: 20, fontWeight: FontWeight.bold)),
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
              if (widget.isRecurring)
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
                )
              else
                InkWell(
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
                      });
                    }
                  },
                  child: InputDecorator(
                    decoration: const InputDecoration(labelText: 'Fecha', prefixIcon: Icon(Icons.calendar_today)),
                    child: Text(DateFormat('dd/MM/yyyy').format(_startDate)),
                  ),
                ),
              const SizedBox(height: 16),
              if (widget.originAccountId == null) ...[
                accountsAsync.when(
                  data: (accounts) => DropdownButtonFormField<int>(
                    value: _originAccountId,
                    decoration: const InputDecoration(labelText: 'Cuenta Origen *', prefixIcon: Icon(Icons.account_balance_wallet_outlined)),
                    items: accounts.map((a) => DropdownMenuItem(value: a.accountId, child: Text(a.accountName))).toList(),
                    onChanged: (val) {
                       setState(() {
                         _originAccountId = val;
                         if (_destinationAccountId == val) _destinationAccountId = null;
                       });
                    },
                    validator: (val) => val == null ? 'Requerido' : null,
                  ),
                  loading: () => const SizedBox(),
                  error: (e, _) => const SizedBox(),
                ),
                const SizedBox(height: 16),
              ],
              accountsAsync.when(
                data: (accounts) {
                  final destinationAccounts = accounts.where((a) => a.accountId != _originAccountId).toList();
                  return DropdownButtonFormField<int>(
                    value: _destinationAccountId,
                    decoration: const InputDecoration(labelText: 'Cuenta Destino *', prefixIcon: Icon(Icons.account_balance_wallet)),
                    items: destinationAccounts.map((a) => DropdownMenuItem(value: a.accountId, child: Text(a.accountName))).toList(),
                    onChanged: (val) => setState(() => _destinationAccountId = val),
                    validator: (val) => val == null ? 'Requerido' : null,
                  );
                },
                loading: () => const CircularProgressIndicator(),
                error: (e, _) => Text('Error: $e'),
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
              if (widget.isRecurring) ...[
                const SizedBox(height: 16),
                DropdownButtonFormField<int>(
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
              ],
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
                    style: FilledButton.styleFrom(backgroundColor: Colors.blue),
                    onPressed: _isLoading ? null : _submit,
                    child: _isLoading 
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) 
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
