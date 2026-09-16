import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/auth_repository.dart';

class AuthNotifier extends AsyncNotifier<bool> {
  @override
  Future<bool> build() async {
    // Al iniciar la app, comprueba si hay un token guardado en SharedPreferences
    return await authRepository.checkAuthStatus();
  }

  Future<void> login(String email, String password) async {
    state = const AsyncValue.loading();
    try {
      await authRepository.login(email, password);
      state = const AsyncValue.data(true);
    } catch (e, st) {
      // El error contiene el mensaje que configuramos en el repositorio
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> register(String name, String lastName, String email, String password) async {
    state = const AsyncValue.loading();
    try {
      await authRepository.register(name, lastName, email, password);
      // Tras un registro exitoso, hacemos login automáticamente
      await authRepository.login(email, password);
      state = const AsyncValue.data(true);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> logout() async {
    state = const AsyncValue.loading();
    await authRepository.logout();
    state = const AsyncValue.data(false);
  }
}

// Proveedor de estado global para la autenticación
final authProvider = AsyncNotifierProvider<AuthNotifier, bool>(AuthNotifier.new);
