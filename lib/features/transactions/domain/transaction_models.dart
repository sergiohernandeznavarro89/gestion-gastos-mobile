enum ItemType { item, transfer }

class UnifiedPendingItem {
  final int id;
  final String name;
  final DateTime startDate;
  final String desc;
  final double ammount;
  final int ammountTypeId; // 1 = Gasto (Rojo), 2 = Ingreso (Verde)
  final int? itemTypeId;
  final ItemType type;
  final String accountDesc;
  final int periodTypeId;
  
  // Extra fields for editing
  final int? categoryId;
  final int? subCategoryId;
  final int? periodity;
  final DateTime? endDate;
  final int? accountId;
  final int? originAccountId;
  final int? destinationAccountId;

  UnifiedPendingItem({
    required this.id,
    required this.name,
    required this.startDate,
    required this.desc,
    required this.ammount,
    required this.ammountTypeId,
    this.itemTypeId,
    required this.type,
    required this.accountDesc,
    required this.periodTypeId,
    this.categoryId,
    this.subCategoryId,
    this.periodity,
    this.endDate,
    this.accountId,
    this.originAccountId,
    this.destinationAccountId,
  });
}

class PendingPayItem {
  final int itemId;
  final String itemName;
  final DateTime startDate;
  final String itemDesc;
  final double ammount;
  final int ammountTypeId;
  final int itemTypeId;
  final String accountName;
  final int periodTypeId;
  
  final int? categoryId;
  final int? subCategoryId;
  final int? periodity;
  final DateTime? endDate;
  final int? accountId;

  PendingPayItem({
    required this.itemId,
    required this.itemName,
    required this.startDate,
    required this.itemDesc,
    required this.ammount,
    required this.ammountTypeId,
    required this.itemTypeId,
    required this.accountName,
    required this.periodTypeId,
    this.categoryId,
    this.subCategoryId,
    this.periodity,
    this.endDate,
    this.accountId,
  });

  factory PendingPayItem.fromJson(Map<String, dynamic> json) {
    return PendingPayItem(
      itemId: json['itemId'] ?? 0,
      itemName: json['itemName'] ?? '',
      startDate: DateTime.parse(json['startDate'] ?? DateTime.now().toIso8601String()),
      itemDesc: json['itemDesc'] ?? '',
      ammount: (json['ammount'] ?? 0.0).toDouble(),
      ammountTypeId: json['ammountTypeId'] ?? 1,
      itemTypeId: json['itemTypeId'] ?? 1,
      accountName: json['accountName'] ?? '',
      periodTypeId: json['periodTypeId'] ?? 1,
      categoryId: json['categoryId'],
      subCategoryId: json['subCategoryId'],
      periodity: json['periodity'],
      endDate: json['endDate'] != null ? DateTime.parse(json['endDate']) : null,
      accountId: json['accountId'],
    );
  }
}

class PendingTransfer {
  final int transferId;
  final String transferName;
  final DateTime startDate;
  final String transferDesc;
  final double ammount;
  final String originAccountName;
  final String destinationAccountName;
  final int periodTypeId;

  final int? categoryId;
  final int? subCategoryId;
  final int? periodity;
  final DateTime? endDate;
  final int? originAccountId;
  final int? destinationAccountId;

  PendingTransfer({
    required this.transferId,
    required this.transferName,
    required this.startDate,
    required this.transferDesc,
    required this.ammount,
    required this.originAccountName,
    required this.destinationAccountName,
    required this.periodTypeId,
    this.categoryId,
    this.subCategoryId,
    this.periodity,
    this.endDate,
    this.originAccountId,
    this.destinationAccountId,
  });

  factory PendingTransfer.fromJson(Map<String, dynamic> json) {
    return PendingTransfer(
      transferId: json['transferId'] ?? 0,
      transferName: json['transferName'] ?? '',
      startDate: DateTime.parse(json['startDate'] ?? DateTime.now().toIso8601String()),
      transferDesc: json['transferDesc'] ?? '',
      ammount: (json['ammount'] ?? 0.0).toDouble(),
      originAccountName: json['originAccountName'] ?? '',
      destinationAccountName: json['destinationAccountName'] ?? '',
      periodTypeId: json['periodTypeId'] ?? 1,
      categoryId: json['categoryId'],
      subCategoryId: json['subCategoryId'],
      periodity: json['periodity'],
      endDate: json['endDate'] != null ? DateTime.parse(json['endDate']) : null,
      originAccountId: json['originAccountId'],
      destinationAccountId: json['destinationAccountId'],
    );
  }
}
