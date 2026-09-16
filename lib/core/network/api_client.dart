import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';

final dio = Dio(
  BaseOptions(
    baseUrl: _getBaseUrl(),
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 10),
    headers: {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    },
  ),
)..interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) async {
        final prefs = await SharedPreferences.getInstance();
        final token = prefs.getString('jwt_token');
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        return handler.next(options);
      },
    ),
  );

// Esta función debe llamarse al iniciar la app (en main.dart)
void configureDio() {
  if (!kIsWeb) {
    // Ignorar errores de certificado SSL en local (Emulador de Android)
    dio.httpClientAdapter = IOHttpClientAdapter(
      createHttpClient: () {
        final client = HttpClient();
        client.badCertificateCallback = (X509Certificate cert, String host, int port) => true;
        return client;
      },
    );
  }
}

String _getBaseUrl() {
  if (kIsWeb) {
    // En el navegador, localhost apunta al PC
    return 'https://localhost:7061/api';
  }
  // En el emulador de Android, 10.0.2.2 es la IP para acceder al localhost del PC
  return 'https://10.0.2.2:7061/api';
}
