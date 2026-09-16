import '../../../core/network/api_client.dart';
import '../domain/transaction_models.dart';

class TransactionRepository {
  Future<List<PendingPayItem>> getPendingPayItems(int userId) async {
    try {
      final response = await dio.get('/Item/GetPendingPayItems?userId=$userId');
      final List<dynamic> data = response.data;
      return data.map((json) => PendingPayItem.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Error al obtener gastos pendientes: $e');
    }
  }

  Future<List<PendingPayItem>> getNextMonthPendingPayItems(int userId) async {
    try {
      final response = await dio.get('/Item/GetNextMonthPendingPayItems?userId=$userId');
      final List<dynamic> data = response.data;
      return data.map((json) => PendingPayItem.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Error al obtener gastos del mes siguiente: $e');
    }
  }

  Future<List<PendingTransfer>> getPendingPayTransfers(int userId) async {
    try {
      final response = await dio.get('/Transfer/pendingPay?userId=$userId');
      final List<dynamic> data = response.data;
      return data.map((json) => PendingTransfer.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Error al obtener transferencias pendientes: $e');
    }
  }

  Future<List<PendingTransfer>> getNextMonthPendingPayTransfers(int userId) async {
    try {
      final response = await dio.get('/Transfer/nextMonthPendingPay?userId=$userId');
      final List<dynamic> data = response.data;
      return data.map((json) => PendingTransfer.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Error al obtener transferencias del mes siguiente: $e');
    }
  }

  Future<List<PendingPayItem>> getExecutedItems(int userId, {int monthsOffset = 0}) async {
    try {
      final response = await dio.get('/Item/GetExecutedItems?userId=$userId&monthsOffset=$monthsOffset');
      final List<dynamic> data = response.data;
      return data.map((json) => PendingPayItem.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Error al obtener gastos ejecutados: $e');
    }
  }

  Future<List<PendingTransfer>> getExecutedTransfers(int userId, {int monthsOffset = 0}) async {
    try {
      final response = await dio.get('/Transfer/executed?userId=$userId&monthsOffset=$monthsOffset');
      final List<dynamic> data = response.data;
      return data.map((json) => PendingTransfer.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Error al obtener transferencias ejecutadas: $e');
    }
  }

  Future<List<PendingPayItem>> getAllItems(int userId) async {
    try {
      final response = await dio.get('/Item/GetAllItems?userId=$userId');
      final List<dynamic> data = response.data;
      return data.map((json) => PendingPayItem.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Error al obtener todos los movimientos: $e');
    }
  }

  Future<List<PendingTransfer>> getAllTransfers(int userId) async {
    try {
      final response = await dio.get('/Transfer/all?userId=$userId');
      final List<dynamic> data = response.data;
      return data.map((json) => PendingTransfer.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Error al obtener todas las transferencias: $e');
    }
  }

  Future<void> addItem(Map<String, dynamic> data) async {
    try {
      final response = await dio.post('/Item/AddItem', data: data);
      if (response.data != null && response.data['success'] == false) {
        throw Exception(response.data['message'] ?? 'Error desconocido en la API');
      }
    } catch (e) {
      throw Exception('Error al registrar transacción: $e');
    }
  }

  Future<void> updateItem(Map<String, dynamic> data) async {
    try {
      final response = await dio.put('/Item/UpdateItem', data: data);
      if (response.data != null && response.data['success'] == false) {
        throw Exception(response.data['message'] ?? 'Error desconocido en la API');
      }
    } catch (e) {
      throw Exception('Error al actualizar transacción: $e');
    }
  }

  Future<void> deleteItem(int itemId) async {
    try {
      final response = await dio.delete('/Item/DeleteItem/$itemId');
      if (response.data != null && response.data['success'] == false) {
        throw Exception(response.data['message'] ?? 'Error desconocido en la API');
      }
    } catch (e) {
      throw Exception('Error al eliminar transacción: $e');
    }
  }

  Future<void> addTransfer(Map<String, dynamic> data) async {
    try {
      await dio.post('/Transfer/add', data: data);
    } catch (e) {
      throw Exception('Error al registrar transferencia: $e');
    }
  }

  Future<void> updateTransfer(Map<String, dynamic> data) async {
    try {
      await dio.put('/Transfer/update', data: data);
    } catch (e) {
      throw Exception('Error al actualizar transferencia: $e');
    }
  }

  Future<void> deleteTransfer(int transferId) async {
    try {
      await dio.delete('/Transfer/delete?transferId=$transferId');
    } catch (e) {
      throw Exception('Error al eliminar transferencia: $e');
    }
  }

  Future<void> addItemPayment(int itemId, double amount) async {
    try {
      await dio.post('/ItemPayment/AddItemPayment?itemId=$itemId&ammount=$amount');
    } catch (e) {
      throw Exception('Error al pagar movimiento: $e');
    }
  }

  Future<void> addTransferPayment(int transferId, double amount, DateTime paymentDate) async {
    try {
      final data = {
        'transferId': transferId,
        'ammount': amount,
        'paymentDate': paymentDate.toIso8601String(),
      };
      await dio.post('/Transfer/addPayment', data: data);
    } catch (e) {
      throw Exception('Error al procesar transferencia: $e');
    }
  }
}

final transactionRepository = TransactionRepository();
