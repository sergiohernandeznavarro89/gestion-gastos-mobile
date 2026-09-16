import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../auth/presentation/auth_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/theme_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Administración'),
        centerTitle: true,
      ),
      body: ListView(
        children: [
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text('Finanzas', style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)),
          ),
          ListTile(
            leading: const Icon(Icons.account_balance_wallet_outlined),
            title: const Text('Mis Cuentas'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/settings/accounts'),
          ),
          ListTile(
            leading: const Icon(Icons.category_outlined),
            title: const Text('Categorías'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/settings/categories'),
          ),
          const Divider(),
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text('Apariencia', style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)),
          ),
          Consumer(
            builder: (context, ref, child) {
              final currentTheme = ref.watch(themeProvider);
              return ListTile(
                leading: const Icon(Icons.palette_outlined),
                title: const Text('Tema de la aplicación'),
                trailing: DropdownButton<ThemeMode>(
                  value: currentTheme,
                  underline: const SizedBox(),
                  onChanged: (ThemeMode? newMode) {
                    if (newMode != null) {
                      ref.read(themeProvider.notifier).setTheme(newMode);
                    }
                  },
                  items: const [
                    DropdownMenuItem(
                      value: ThemeMode.system,
                      child: Text('Sistema'),
                    ),
                    DropdownMenuItem(
                      value: ThemeMode.light,
                      child: Text('Claro'),
                    ),
                    DropdownMenuItem(
                      value: ThemeMode.dark,
                      child: Text('Oscuro'),
                    ),
                  ],
                ),
              );
            },
          ),
          const Divider(),
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text('Sesión', style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)),
          ),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text('Cerrar Sesión', style: TextStyle(color: Colors.red)),
            onTap: () {
              ref.read(authProvider.notifier).logout();
            },
          ),
        ],
      ),
    );
  }
}
