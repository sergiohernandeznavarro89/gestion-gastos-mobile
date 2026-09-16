import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/network/api_client.dart';
import '../domain/auth_models.dart';

class AuthRepository {
  Future<AuthResponse> login(String email, String password) async {
    try {
      final response = await dio.post('/auth/login', data: {
        'email': email,
        'password': password,
      });

      final authResponse = AuthResponse.fromJson(response.data);
      
      // Guardar el token JWT y el userId localmente
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('jwt_token', authResponse.token);
      await prefs.setInt('user_id', authResponse.user.userId);
      
      return authResponse;
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        throw Exception('Usuario o contraseña incorrectos');
      }
      throw Exception('Error de conexión con el servidor');
    }
  }

  Future<void> register(String name, String lastName, String email, String password) async {
    try {
      await dio.post('/auth/register', data: {
        'userName': name,
        'userLastName': lastName,
        'email': email,
        'password': password,
      });
    } on DioException catch (e) {
      if (e.response?.statusCode == 400) {
        throw Exception(e.response?.data?.toString() ?? 'Error en el registro. Quizás el email ya existe.');
      }
      throw Exception('Error al conectar con el servidor');
    }
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('jwt_token');
  }

  Future<bool> checkAuthStatus() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('jwt_token') != null;
  }
}

final authRepository = AuthRepository();
