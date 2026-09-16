import '../../../core/network/api_client.dart';
import '../domain/account_models.dart';

class AccountRepository {
  Future<List<Account>> getAccountsByUser(int userId) async {
    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final response = await dio.get('/Account/GetAccountsByUser?userId=$userId&_t=$timestamp');
      final List<dynamic> data = response.data;
      return data.map((json) => Account.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Error al obtener las cuentas: $e');
    }
  }

  Future<void> addAccount(int userId, String name, double amount) async {
    try {
      await dio.post('/Account/AddAccount', data: {
        'userId': userId,
        'accountName': name,
        'ammount': amount,
      });
    } catch (e) {
      throw Exception('Error al crear la cuenta: $e');
    }
  }

  Future<void> updateAccount(int accountId, String name, double amount) async {
    try {
      await dio.put('/Account/UpdateAccount', data: {
        'accountId': accountId,
        'accountName': name,
        'ammount': amount,
      });
    } catch (e) {
      throw Exception('Error al actualizar la cuenta: $e');
    }
  }

  Future<void> deleteAccount(int accountId) async {
    try {
      await dio.delete('/Account/DeleteAccount?accountId=$accountId');
    } catch (e) {
      throw Exception('Error al eliminar la cuenta: $e');
    }
  }
}

final accountRepository = AccountRepository();
