import 'package:flutter/material.dart';
import '../../../accounts/domain/account_models.dart';
import '../../../transactions/presentation/widgets/payment_form_dialog.dart';
import '../../../transactions/presentation/widgets/transfer_form_dialog.dart';

class AccountSlider extends StatelessWidget {
  final List<Account> accounts;

  const AccountSlider({super.key, required this.accounts});

  @override
  Widget build(BuildContext context) {
    if (accounts.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(16.0),
        child: Center(child: Text('No hay cuentas configuradas.')),
      );
    }

    return SizedBox(
      height: 220,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: accounts.length,
        itemBuilder: (context, index) {
          final account = accounts[index];
          return Container(
            width: 280,
            margin: const EdgeInsets.only(right: 16),
            child: Card(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              color: Theme.of(context).colorScheme.primaryContainer,
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Icon(Icons.account_balance, size: 28),
                        Text(
                          'ID: ${account.accountId}',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                    const Spacer(),
                    Text(
                      account.accountName,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${account.currentAmmount.toStringAsFixed(2)} €',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          onPressed: () => showModalBottomSheet(context: context, isScrollControlled: true, builder: (_) => PaymentFormDialog(accountId: account.accountId, itemType: 1)),
                          icon: const Icon(Icons.arrow_circle_down, color: Colors.green, size: 32),
                          tooltip: 'Ingreso',
                        ),
                        IconButton(
                          onPressed: () => showModalBottomSheet(context: context, isScrollControlled: true, builder: (_) => PaymentFormDialog(accountId: account.accountId, itemType: 2)),
                          icon: const Icon(Icons.arrow_circle_up, color: Colors.red, size: 32),
                          tooltip: 'Gasto',
                        ),
                        IconButton(
                          onPressed: () => showModalBottomSheet(context: context, isScrollControlled: true, builder: (_) => TransferFormDialog(originAccountId: account.accountId)),
                          icon: const Icon(Icons.compare_arrows, color: Colors.blue, size: 32),
                          tooltip: 'Transferencia',
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
