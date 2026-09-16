class Account {
  final int accountId;
  final String accountName;
  final String accountDesc;
  final double currentAmmount;
  final String? cardImg;

  Account({
    required this.accountId,
    required this.accountName,
    required this.accountDesc,
    required this.currentAmmount,
    this.cardImg,
  });

  factory Account.fromJson(Map<String, dynamic> json) {
    return Account(
      accountId: json['accountId'] ?? 0,
      accountName: json['accountName'] ?? '',
      accountDesc: json['accountDesc'] ?? '',
      currentAmmount: (json['ammount'] ?? 0.0).toDouble(),
      cardImg: json['cardImg'],
    );
  }
}
