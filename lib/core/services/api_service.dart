import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../config/app_config.dart';
import '../constants/api_constants.dart';
import 'storage_service.dart';

class ApiService {
  ApiService(this._storage);

  final StorageService _storage;
  late Dio dio;
  bool _isRefreshing = false;

  Future<ApiService> init() async {
    dio = Dio(BaseOptions(
      baseUrl: AppConfig.apiBaseUrl,
      connectTimeout: const Duration(seconds: 20),
      receiveTimeout: const Duration(seconds: 20),
      headers: {'Content-Type': 'application/json', 'Accept': 'application/json'},
    ));

    dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) {
        final token = _storage.accessToken;
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        _logRequest(options);
        handler.next(options);
      },
      onResponse: (response, handler) {
        _logResponse(response);
        handler.next(response);
      },
      onError: (error, handler) async {
        _logError(error);
        if (error.response?.statusCode == 401 && !_isRefreshing) {
          final refreshed = await _tryRefreshToken();
          if (refreshed) {
            final opts = error.requestOptions;
            opts.headers['Authorization'] = 'Bearer ${_storage.accessToken}';
            try {
              final response = await dio.fetch(opts);
              return handler.resolve(response);
            } catch (e) {
              return handler.next(error);
            }
          }
        }
        handler.next(error);
      },
    ));
    return this;
  }

  Future<bool> _tryRefreshToken() async {
    final refreshToken = _storage.refreshToken;
    if (refreshToken == null) return false;

    _isRefreshing = true;
    try {
      debugPrint('[API] → POST ${AppConfig.apiBaseUrl}${ApiConstants.refresh}');
      final response = await Dio(BaseOptions(
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
      )).post(
        '${AppConfig.apiBaseUrl}${ApiConstants.refresh}',
        data: {'refreshToken': refreshToken},
      );
      final data = response.data['data'] as Map<String, dynamic>?;
      if (data == null) return false;
      await _storage.saveTokens(
        accessToken: data['accessToken'] as String,
        refreshToken: data['refreshToken'] as String,
      );
      debugPrint('[API] ← POST ${ApiConstants.refresh} ${response.statusCode}');
      return true;
    } catch (e) {
      debugPrint('[API] ✗ POST ${ApiConstants.refresh} $e');
      await _storage.clearSession();
      return false;
    } finally {
      _isRefreshing = false;
    }
  }

  Future<Map<String, dynamic>> get(String path, {Map<String, dynamic>? query}) async {
    final response = await dio.get(path, queryParameters: query);
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> post(String path, {dynamic data}) async {
    final response = await dio.post(path, data: data);
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> postAuth(String path, {dynamic data}) async {
    const authTimeout = Duration(seconds: 35);
    const delays = [Duration.zero, Duration(seconds: 2)];

    Object? lastError;
    for (var i = 0; i < delays.length; i++) {
      if (delays[i] > Duration.zero) {
        await Future<void>.delayed(delays[i]);
        debugPrint('[API] retry ${i + 1} POST $path');
      }
      try {
        final response = await dio.post(
          path,
          data: data,
          options: Options(
            sendTimeout: authTimeout,
            receiveTimeout: authTimeout,
            connectTimeout: authTimeout,
          ),
        );
        return response.data as Map<String, dynamic>;
      } catch (e) {
        lastError = e;
        if (!_shouldRetryAuth(e) || i == delays.length - 1) rethrow;
      }
    }
    throw lastError ?? Exception('Login request failed');
  }

  bool _shouldRetryAuth(Object error) {
    if (error is! DioException) return false;
    return error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.receiveTimeout ||
        error.type == DioExceptionType.sendTimeout ||
        error.type == DioExceptionType.connectionError;
  }

  Future<Map<String, dynamic>> put(String path, {dynamic data}) async {
    final response = await dio.put(path, data: data);
    return response.data as Map<String, dynamic>;
  }

  void _logRequest(RequestOptions options) {
    final query = options.queryParameters.isEmpty ? '' : ' query=${options.queryParameters}';
    final body = options.data == null ? '' : ' body=${options.data}';
    debugPrint('[API] → ${options.method} ${options.uri}$query$body');
  }

  void _logResponse(Response<dynamic> response) {
    debugPrint('[API] ← ${response.requestOptions.method} ${response.requestOptions.uri} ${response.statusCode}');
  }

  void _logError(DioException error) {
    final status = error.response?.statusCode;
    debugPrint('[API] ✗ ${error.requestOptions.method} ${error.requestOptions.uri} ${status ?? '—'} ${error.message}');
  }

  String errorMessage(dynamic error) {
    if (error is DioException) {
      if (error.type == DioExceptionType.connectionError ||
          (error.message?.contains('Failed host lookup') ?? false) ||
          (error.message?.contains('Network is unreachable') ?? false)) {
        return 'No internet or server unreachable. Check Wi‑Fi/mobile data and try again.';
      }
      final data = error.response?.data;
      if (data is Map && data['message'] != null) {
        final msg = data['message'];
        if (msg is List) return msg.join(', ');
        return msg.toString();
      }
      return error.message ?? 'Network error';
    }
    return error.toString();
  }
}
