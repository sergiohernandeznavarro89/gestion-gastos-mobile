import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../transactions/domain/transaction_models.dart';
import '../../../transactions/data/transaction_repository.dart';
import '../home_provider.dart';
import '../../../accounts/presentation/accounts_provider.dart';
import '../../../transactions/presentation/transactions_provider.dart';

class PendingItemsList extends ConsumerStatefulWidget {
  final List<UnifiedPendingItem> currentMonthItems;
  final List<UnifiedPendingItem> nextMonthItems;
  final bool hideNextMonth;

  const PendingItemsList({
    super.key,
    required this.currentMonthItems,
    required this.nextMonthItems,
    this.hideNextMonth = false,
  });

  @override
  ConsumerState<PendingItemsList> createState() => _PendingItemsListState();
}

class _PendingItemsListState extends ConsumerState<PendingItemsList> {
  final Set<String> _processedIds = {};

  @override
  Widget build(BuildContext context) {
    return SliverMainAxisGroup(
      slivers: [
        if (!widget.hideNextMonth)
          SliverToBoxAdapter(child: _buildSectionTitle(context, 'Pendientes Este Mes')),
        ..._buildGroupedSlivers(context, widget.currentMonthItems, isCurrentMonth: true),
        if (!widget.hideNextMonth) ...[
          const SliverToBoxAdapter(child: SizedBox(height: 24)),
          SliverToBoxAdapter(child: _buildSectionTitle(context, 'Próximo Mes')),
          ..._buildGroupedSlivers(context, widget.nextMonthItems, isCurrentMonth: false),
        ],
        const SliverToBoxAdapter(child: SizedBox(height: 40)),
      ],
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  String _formatDateString(DateTime date) {
    const months = ['Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio', 'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre'];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  List<Widget> _buildGroupedSlivers(BuildContext context, List<UnifiedPendingItem> items, {required bool isCurrentMonth}) {
    final displayItems = items.where((i) => !_processedIds.contains('${i.type}_${i.id}')).toList();

    if (displayItems.isEmpty) {
      return [
        const SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
            child: Text('No hay transacciones pendientes.', style: TextStyle(color: Colors.grey)),
          ),
        )
      ];
    }

    final Map<String, List<UnifiedPendingItem>> grouped = {};
    for (final item in displayItems) {
      final dateStr = _formatDateString(item.startDate);
      grouped.putIfAbsent(dateStr, () => []).add(item);
    }

    final slivers = <Widget>[];
    for (final entry in grouped.entries) {
      final dateStr = entry.key;
      final groupItems = entry.value;

      slivers.add(
        SliverMainAxisGroup(
          slivers: [
            SliverPersistentHeader(
              pinned: true,
              delegate: _StickyHeaderDelegate(dateStr),
            ),
            SliverList.separated(
              itemCount: groupItems.length,
              separatorBuilder: (context, index) => const Divider(indent: 24, endIndent: 24),
              itemBuilder: (context, index) {
                final item = groupItems[index];
                return _buildItemTile(context, item, isCurrentMonth);
              },
            ),
          ],
        ),
      );
    }
    return slivers;
  }

  Widget _buildItemTile(BuildContext context, UnifiedPendingItem item, bool isCurrentMonth) {
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
    final isHistoryList = widget.hideNextMonth;
    final amountText = (isVariable && !isHistoryList) ? '- €' : '$prefix${item.ammount.toStringAsFixed(2)} €';

    // Ahora solo mostramos la hora en el subtítulo
    final timeStr = '${item.startDate.hour.toString().padLeft(2, '0')}:${item.startDate.minute.toString().padLeft(2, '0')}';

    final allowSwipe = isCurrentMonth && !widget.hideNextMonth;

    final tile = ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 24.0),
      leading: CircleAvatar(
        backgroundColor: color.withValues(alpha: 0.1),
        child: Icon(icon, color: color),
      ),
      title: Text(item.name, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text('${item.accountDesc} • $timeStr', style: const TextStyle(fontSize: 12)),
      trailing: Text(
        amountText,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: 16,
        ),
      ),
    );

    if (!allowSwipe) return tile;

    return Dismissible(
      key: ValueKey('${item.type}_${item.id}'),
      direction: DismissDirection.horizontal,
      background: Container(
        color: Colors.green,
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: const Icon(Icons.check, color: Colors.white),
      ),
      secondaryBackground: Container(
        color: Colors.grey[800],
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: const Icon(Icons.visibility_off, color: Colors.white),
      ),
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.endToStart) {
          // Swipe izquierda: Ignorar (importe 0)
          final confirm = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Ignorar Pago'),
              content: const Text('¿Estás seguro de que deseas ignorar este pago? Se registrará con importe 0.'),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
                FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Ignorar')),
              ],
            ),
          );
          if (confirm == true) {
            await _processPayment(item, 0.0);
            return true;
          }
          return false;
        } else {
          // Swipe derecha: Pagar
          if (item.type == ItemType.item && item.ammountTypeId == 2) {
            // Es importe variable, pedir cantidad
            final amount = await _showVariableAmountDialog(context, item);
            if (amount != null) {
              await _processPayment(item, amount);
              return true;
            }
            return false;
          } else {
            // Es fijo o transferencia, pagar directamente
            await _processPayment(item, item.ammount);
            return true;
          }
        }
      },
      onDismissed: (direction) {
        setState(() {
          _processedIds.add('${item.type}_${item.id}');
        });
      },
      child: tile,
    );
  }

  Future<void> _processPayment(UnifiedPendingItem item, double amount) async {
    try {
      if (item.type == ItemType.transfer) {
        await transactionRepository.addTransferPayment(item.id, amount, DateTime.now());
      } else {
        await transactionRepository.addItemPayment(item.id, amount);
      }
      ref.invalidate(homeDataProvider);
      ref.invalidate(accountsProvider);
      ref.invalidate(transactionsProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Operación realizada con éxito'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<double?> _showVariableAmountDialog(BuildContext context, UnifiedPendingItem item) async {
    double? enteredAmount;
    final formKey = GlobalKey<FormState>();
    final controller = TextEditingController();

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 24,
            right: 24,
            top: 24,
          ),
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Indicar Importe',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text('El movimiento "${item.name}" es de importe variable.'),
                const SizedBox(height: 16),
                TextFormField(
                  controller: controller,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'Importe (€) *',
                    prefixIcon: Icon(Icons.euro),
                  ),
                  autofocus: true,
                  validator: (val) {
                    if (val == null || val.isEmpty) return 'Requerido';
                    final num = double.tryParse(val.replaceAll(',', '.'));
                    if (num == null) return 'Número inválido';
                    if (num <= 0) return 'El importe debe ser mayor que 0';
                    return null;
                  },
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancelar'),
                    ),
                    const SizedBox(width: 8),
                    FilledButton(
                      onPressed: () {
                        if (formKey.currentState!.validate()) {
                          enteredAmount = double.parse(controller.text.replaceAll(',', '.'));
                          Navigator.pop(context);
                        }
                      },
                      child: const Text('Aplicar'),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        );
      },
    );

    return enteredAmount;
  }
}

class _StickyHeaderDelegate extends SliverPersistentHeaderDelegate {
  final String title;

  _StickyHeaderDelegate(this.title);

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    final theme = Theme.of(context);
    return Container(
      color: theme.scaffoldBackgroundColor, // Mismo fondo que la app para ocultar las tarjetas
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      alignment: Alignment.centerLeft,
      child: Text(
        title,
        style: theme.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.bold,
          color: theme.colorScheme.primary,
        ),
      ),
    );
  }

  @override
  double get maxExtent => 48.0;

  @override
  double get minExtent => 48.0;

  @override
  bool shouldRebuild(covariant _StickyHeaderDelegate oldDelegate) {
    return title != oldDelegate.title;
  }
}
