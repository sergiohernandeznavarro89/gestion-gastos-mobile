import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/account_repository.dart';
import '../domain/account_models.dart';
import '../../expenses/presentation/home_provider.dart';

class AccountsNotifier extends AsyncNotifier<List<Account>> {
  @override
  Future<List<Account>> build() async {
    return _fetchAccounts();
  }

  Future<List<Account>> _fetchAccounts() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getInt('user_id');
    if (userId == null) throw Exception('Usuario no autenticado');
    final accounts = await accountRepository.getAccountsByUser(userId);
    accounts.sort((a, b) => a.accountId.compareTo(b.accountId));
    return accounts;
  }

  Future<void> addAccount(String name, double amount) async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getInt('user_id');
    if (userId == null) throw Exception('Usuario no autenticado');

    await accountRepository.addAccount(userId, name, amount);
    _reload();
  }

  Future<void> updateAccount(int accountId, String name, double amount) async {
    await accountRepository.updateAccount(accountId, name, amount);
    _reload();
  }

  Future<void> deleteAccount(int accountId) async {
    final currentList = state.value ?? [];
    state = AsyncValue.data(currentList.where((a) => a.accountId != accountId).toList());
    try {
      await accountRepository.deleteAccount(accountId);
    } catch (e) {
      _reload();
      rethrow;
    }
  }

  void _reload() async {
    state = await AsyncValue.guard(() => _fetchAccounts());
    // Invalida también el homeDataProvider para que el dashboard refleje los cambios
    ref.invalidate(homeDataProvider);
  }
}

final accountsProvider = AsyncNotifierProvider<AccountsNotifier, List<Account>>(AccountsNotifier.new);
