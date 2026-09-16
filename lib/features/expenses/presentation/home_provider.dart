import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../accounts/domain/account_models.dart';
import '../../accounts/presentation/accounts_provider.dart';
import '../../transactions/data/transaction_repository.dart';
import '../../transactions/domain/transaction_models.dart';

class HomeData {
  final List<Account> accounts;
  final List<UnifiedPendingItem> currentMonthItems;
  final List<UnifiedPendingItem> nextMonthItems;
  final List<UnifiedPendingItem> executedItems;
  final bool hasMoreData;

  HomeData({
    required this.accounts,
    required this.currentMonthItems,
    required this.nextMonthItems,
    required this.executedItems,
    this.hasMoreData = true,
  });
}

class HomeNotifier extends AsyncNotifier<HomeData> {
  final List<int> _visibleOffsets = [];
  int _nextPrefetchOffset = 2;
  List<UnifiedPendingItem> _prefetchedItems = [];
  bool _isFetchingBackground = false;

  @override
  Future<HomeData> build() async {
    _visibleOffsets.clear();
    _visibleOffsets.addAll([0, 1]); // Mostrar este mes y el anterior
    _nextPrefetchOffset = 2; // El tercero va a reserva
    _prefetchedItems.clear();
    _isFetchingBackground = false;

    return _fetchInitialData();
  }

  Future<HomeData> _fetchInitialData() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getInt('user_id');
    if (userId == null) throw Exception('Usuario no autenticado en el dispositivo');

    final accounts = await ref.watch(accountsProvider.future);

    final results = await Future.wait([
      transactionRepository.getPendingPayItems(userId),
      transactionRepository.getNextMonthPendingPayItems(userId),
      transactionRepository.getPendingPayTransfers(userId),
      transactionRepository.getNextMonthPendingPayTransfers(userId),
    ]);

    final pendingItems = results[0] as List<PendingPayItem>;
    final pendingNextItems = results[1] as List<PendingPayItem>;
    final pendingTransfers = results[2] as List<PendingTransfer>;
    final pendingNextTransfers = results[3] as List<PendingTransfer>;

    final currentUnified = <UnifiedPendingItem>[
      ...pendingItems.map((i) => _mapItem(i)),
      ...pendingTransfers.map((t) => _mapTransfer(t)),
    ]..sort((a, b) => a.startDate.compareTo(b.startDate));

    final nextUnified = <UnifiedPendingItem>[
      ...pendingNextItems.map((i) => _mapItem(i)),
      ...pendingNextTransfers.map((t) => _mapTransfer(t)),
    ]..sort((a, b) => a.startDate.compareTo(b.startDate));

    // Fetch 0 y 1 (visibles) y 2 (reserva)
    final executedFutures = <Future<dynamic>>[];
    for (final offset in [0, 1, 2]) {
      executedFutures.add(transactionRepository.getExecutedItems(userId, monthsOffset: offset));
      executedFutures.add(transactionRepository.getExecutedTransfers(userId, monthsOffset: offset));
    }
    
    final executedResults = await Future.wait(executedFutures);
    
    final executedUnified = <UnifiedPendingItem>[];

    for (int i = 0; i < executedResults.length; i += 2) {
      final items = executedResults[i] as List<PendingPayItem>;
      final transfers = executedResults[i+1] as List<PendingTransfer>;
      
      final validItems = items.where((x) => x.ammount > 0).toList();
      final validTransfers = transfers.where((x) => x.ammount > 0).toList();

      final mapped = <UnifiedPendingItem>[
        ...validItems.map((x) => _mapItem(x)),
        ...validTransfers.map((x) => _mapTransfer(x)),
      ];

      // i=0 (offset 0), i=2 (offset 1), i=4 (offset 2)
      if (i == 4) {
        _prefetchedItems = mapped;
      } else {
        executedUnified.addAll(mapped);
      }
    }
    executedUnified.sort((a, b) => b.startDate.compareTo(a.startDate)); // Descending sort

    return HomeData(
      accounts: accounts,
      currentMonthItems: currentUnified,
      nextMonthItems: nextUnified,
      executedItems: executedUnified,
      hasMoreData: _prefetchedItems.isNotEmpty,
    );
  }

  void loadMoreMonths() async {
    if (_isFetchingBackground) return;
    
    final currentState = state.value;
    if (currentState == null || _prefetchedItems.isEmpty) return;
    
    // 1. Volcado Inmediato Síncrono de la Reserva
    _visibleOffsets.add(_nextPrefetchOffset);
    final updatedExecuted = List<UnifiedPendingItem>.from(currentState.executedItems)..addAll(_prefetchedItems);
    updatedExecuted.sort((a, b) => b.startDate.compareTo(a.startDate));
    
    // Asumimos que puede haber más hasta que el prefetch demuestre lo contrario
    state = AsyncValue.data(HomeData(
      accounts: currentState.accounts,
      currentMonthItems: currentState.currentMonthItems,
      nextMonthItems: currentState.nextMonthItems,
      executedItems: updatedExecuted,
      hasMoreData: true, 
    ));

    _nextPrefetchOffset++;
    _prefetchedItems.clear(); // Vaciamos la reserva

    // 2. Petición en Background para la nueva reserva
    _isFetchingBackground = true;
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getInt('user_id');
      if (userId == null) return;

      final newItems = await transactionRepository.getExecutedItems(userId, monthsOffset: _nextPrefetchOffset);
      final newTransfers = await transactionRepository.getExecutedTransfers(userId, monthsOffset: _nextPrefetchOffset);
      
      final validItems = newItems.where((i) => i.ammount > 0).toList();
      final validTransfers = newTransfers.where((t) => t.ammount > 0).toList();

      _prefetchedItems = [
        ...validItems.map((i) => _mapItem(i)),
        ...validTransfers.map((t) => _mapTransfer(t)),
      ];

      // Actualizamos estado solo para actualizar el flag hasMoreData
      final newState = state.value;
      if (newState != null) {
        state = AsyncValue.data(HomeData(
          accounts: newState.accounts,
          currentMonthItems: newState.currentMonthItems,
          nextMonthItems: newState.nextMonthItems,
          executedItems: newState.executedItems, // Sin alterar
          hasMoreData: _prefetchedItems.isNotEmpty,
        ));
      }
    } finally {
      _isFetchingBackground = false;
    }
  }

  UnifiedPendingItem _mapItem(PendingPayItem i) {
    return UnifiedPendingItem(
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
    );
  }

  UnifiedPendingItem _mapTransfer(PendingTransfer t) {
    return UnifiedPendingItem(
      id: t.transferId,
      name: t.transferName,
      startDate: t.startDate,
      desc: t.transferDesc,
      ammount: t.ammount,
      ammountTypeId: 1,
      type: ItemType.transfer,
      accountDesc: '${t.originAccountName} -> ${t.destinationAccountName}',
      periodTypeId: t.periodTypeId,
    );
  }
}

final homeDataProvider = AsyncNotifierProvider.autoDispose<HomeNotifier, HomeData>(
  () => HomeNotifier(),
);
