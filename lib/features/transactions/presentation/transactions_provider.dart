import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/transaction_repository.dart';
import '../domain/transaction_models.dart';

final transactionsProvider = FutureProvider.autoDispose<List<UnifiedPendingItem>>((ref) async {
  final prefs = await SharedPreferences.getInstance();
  final userId = prefs.getInt('user_id');
  if (userId == null) throw Exception('Usuario no autenticado en el dispositivo');

  final results = await Future.wait([
    transactionRepository.getAllItems(userId),
    transactionRepository.getAllTransfers(userId),
  ]);

  final items = results[0] as List<PendingPayItem>;
  final transfers = results[1] as List<PendingTransfer>;

  // Filtrar solo los movimientos recurrentes (periodTypeId != 1)
  final recurrentItems = items.where((i) => i.periodTypeId != 1).toList();
  final recurrentTransfers = transfers.where((t) => t.periodTypeId != 1).toList();

  final unified = <UnifiedPendingItem>[
    ...recurrentItems.map((i) => UnifiedPendingItem(
          id: i.itemId,
          name: i.itemName,
          startDate: i.startDate,
          desc: i.itemDesc,
          ammount: i.ammount,
          ammountTypeId: i.ammountTypeId,
          itemTypeId: i.itemTypeId,
          type: ItemType.item,
          accountDesc: i.accountName,
          periodTypeId: i.periodTypeId,
          categoryId: i.categoryId,
          subCategoryId: i.subCategoryId,
          periodity: i.periodity,
          endDate: i.endDate,
          accountId: i.accountId,
        )),
    ...recurrentTransfers.map((t) => UnifiedPendingItem(
          id: t.transferId,
          name: t.transferName,
          startDate: t.startDate,
          desc: t.transferDesc,
          ammount: t.ammount,
          ammountTypeId: 1, // En React era fijo a 1 (gasto)
          type: ItemType.transfer,
          accountDesc: '${t.originAccountName} -> ${t.destinationAccountName}',
          periodTypeId: t.periodTypeId,
          categoryId: t.categoryId,
          subCategoryId: t.subCategoryId,
          periodity: t.periodity,
          endDate: t.endDate,
          originAccountId: t.originAccountId,
          destinationAccountId: t.destinationAccountId,
        )),
  ];

  // Ordenar por fecha de creación o nombre (usaremos startDate por defecto)
  unified.sort((a, b) => b.startDate.compareTo(a.startDate));

  return unified;
});
