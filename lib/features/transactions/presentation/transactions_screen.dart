import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'transactions_provider.dart';
import '../data/transaction_repository.dart';
import '../domain/transaction_models.dart';
import 'widgets/transfer_form_dialog.dart';
import 'package:intl/intl.dart';
import 'widgets/item_form_dialog.dart';

enum TransactionFilter { todos, gastos, ingresos, transferencias }

class TransactionsScreen extends ConsumerStatefulWidget {
  const TransactionsScreen({super.key});

  @override
  ConsumerState<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends ConsumerState<TransactionsScreen> {
  TransactionFilter _currentFilter = TransactionFilter.todos;
  final Set<String> _deletedIds = {};

  @override
  Widget build(BuildContext context) {
    final asyncTransactions = ref.watch(transactionsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Movimientos Recurrentes'),
        centerTitle: true,
        scrolledUnderElevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(transactionsProvider),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildFilters(),
          Expanded(
            child: asyncTransactions.when(
              data: (items) {
                final filteredItems = _filterItems(items);
                
                if (filteredItems.isEmpty) {
                  return const Center(
                    child: Text('No hay movimientos de este tipo.', style: TextStyle(color: Colors.grey)),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () async {
                    ref.invalidate(transactionsProvider);
                    try {
                      await ref.read(transactionsProvider.future);
                    } catch (_) {}
                  },
                  child: ListView.separated(
                    itemCount: filteredItems.length,
                    separatorBuilder: (context, index) => const Divider(indent: 24, endIndent: 24),
                    itemBuilder: (context, index) {
                      final item = filteredItems[index];
                      return _buildListItem(context, item);
                    },
                  ),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, st) => Center(child: Text('Error: $e')),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddOptions(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildFilters() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        children: [
          _buildChip('Todos', TransactionFilter.todos),
          const SizedBox(width: 8),
          _buildChip('Gastos', TransactionFilter.gastos),
          const SizedBox(width: 8),
          _buildChip('Ingresos', TransactionFilter.ingresos),
          const SizedBox(width: 8),
          _buildChip('Transferencias', TransactionFilter.transferencias),
        ],
      ),
    );
  }

  Widget _buildChip(String label, TransactionFilter filter) {
    return ChoiceChip(
      label: Text(label),
      selected: _currentFilter == filter,
      onSelected: (selected) {
        if (selected) {
          setState(() {
            _currentFilter = filter;
          });
        }
      },
    );
  }

  List<UnifiedPendingItem> _filterItems(List<UnifiedPendingItem> items) {
    final nonDeleted = items.where((i) => !_deletedIds.contains('${i.type}_${i.id}')).toList();

    switch (_currentFilter) {
      case TransactionFilter.todos:
        return nonDeleted;
      case TransactionFilter.gastos:
        return nonDeleted.where((i) => i.type == ItemType.item && i.itemTypeId == 1).toList();
      case TransactionFilter.ingresos:
        return nonDeleted.where((i) => i.type == ItemType.item && i.itemTypeId == 2).toList();
      case TransactionFilter.transferencias:
        return nonDeleted.where((i) => i.type == ItemType.transfer).toList();
    }
  }

  Widget _buildListItem(BuildContext context, UnifiedPendingItem item) {
    final isTransfer = item.type == ItemType.transfer;
    final isIncome = item.itemTypeId == 2;
    
    Color color;
    if (isTransfer) {
      color = Colors.blue;
    } else {
      color = isIncome ? Colors.green : Colors.red;
    }

    IconData icon;
    if (isTransfer) {
      icon = Icons.swap_horiz;
    } else {
      icon = isIncome ? Icons.arrow_downward : Icons.arrow_upward;
    }

    String prefix = isTransfer ? '+' : (isIncome ? '+' : '-');
    final isVariable = item.type == ItemType.item && item.ammountTypeId == 2;
    final amountText = isVariable ? '- €' : '$prefix${item.ammount.toStringAsFixed(2)} €';

    return Dismissible(
      key: ValueKey('${item.type}_${item.id}'),
      direction: DismissDirection.endToStart,
      confirmDismiss: (direction) async {
        return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Eliminar Movimiento'),
            content: Text('¿Estás seguro de que deseas eliminar "${item.name}"? Esta acción no se puede deshacer.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancelar'),
              ),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: FilledButton.styleFrom(backgroundColor: Colors.red),
                child: const Text('Eliminar'),
              ),
            ],
          ),
        );
      },
      onDismissed: (direction) async {
        final uniqueId = '${item.type}_${item.id}';
        setState(() {
          _deletedIds.add(uniqueId);
        });

        try {
          if (isTransfer) {
            await transactionRepository.deleteTransfer(item.id);
          } else {
            await transactionRepository.deleteItem(item.id);
          }
          ref.invalidate(transactionsProvider);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Movimiento eliminado con éxito.')),
            );
          }
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Error al eliminar: $e')),
            );
          }
        }
      },
      background: Container(
        color: Colors.red,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 24.0),
        leading: CircleAvatar(
          backgroundColor: color.withOpacity(0.1),
          child: Icon(icon, color: color),
        ),
        title: Text(item.name, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(item.accountDesc, style: const TextStyle(fontSize: 12)),
            const SizedBox(height: 2),
            Text(
              '${DateFormat('dd/MM/yy').format(item.startDate)} - ${item.endDate != null ? DateFormat('dd/MM/yy').format(item.endDate!) : 'Sin fin'}',
              style: const TextStyle(fontSize: 11, color: Colors.grey),
            ),
          ],
        ),
        trailing: Text(
          amountText,
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        onTap: () {
          if (isTransfer) {
            showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              builder: (context) => TransferFormDialog(item: item, isRecurring: true),
            );
          } else {
            showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              builder: (context) => ItemFormDialog(
                item: item, 
                isIncome: isIncome,
              ),
            );
          }
        },
      ),
    );
  }

  void _showAddOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Text('Nuevo Movimiento', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ),
              ListTile(
                leading: const CircleAvatar(backgroundColor: Colors.redAccent, child: Icon(Icons.arrow_upward, color: Colors.white)),
                title: const Text('Nuevo Gasto'),
                onTap: () {
                  Navigator.pop(context);
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    builder: (context) => const ItemFormDialog(isIncome: false),
                  );
                },
              ),
              ListTile(
                leading: const CircleAvatar(backgroundColor: Colors.green, child: Icon(Icons.arrow_downward, color: Colors.white)),
                title: const Text('Nuevo Ingreso'),
                onTap: () {
                  Navigator.pop(context);
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    builder: (context) => const ItemFormDialog(isIncome: true),
                  );
                },
              ),
              ListTile(
                leading: const CircleAvatar(backgroundColor: Colors.blue, child: Icon(Icons.swap_horiz, color: Colors.white)),
                title: const Text('Nueva Transferencia'),
                onTap: () {
                  Navigator.pop(context);
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    builder: (context) => const TransferFormDialog(isRecurring: true),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
