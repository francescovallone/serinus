import 'package:dio/dio.dart';

import 'controllers/app_controller.dart';

class SerinusClient {
  SerinusClient._();

  factory SerinusClient() {
    return _instance;
  }

  final Dio base = Dio();

  final String baseUrl = 'http://localhost:3000';

  static final _instance = SerinusClient._();

  Future<T> get<T>(
    String url, {
    Map<String, dynamic> queryParameters = const {},
    Object? data,
  }) async {
    final response = await base.get(
      '$baseUrl$url',
      queryParameters: queryParameters,
      data: data,
    );
    return response.data;
  }

  Future<T> post<T>(
    String url, {
    Map<String, dynamic> queryParameters = const {},
    Object? data,
  }) async {
    final response = await base.post(
      '$baseUrl$url',
      queryParameters: queryParameters,
      data: data,
    );
    return response.data;
  }

  Future<T> put<T>(
    String url, {
    Map<String, dynamic> queryParameters = const {},
    Object? data,
  }) async {
    final response = await base.put(
      '$baseUrl$url',
      queryParameters: queryParameters,
      data: data,
    );
    return response.data;
  }

  Future<T> patch<T>(
    String url, {
    Map<String, dynamic> queryParameters = const {},
    Object? data,
  }) async {
    final response = await base.patch(
      '$baseUrl$url',
      queryParameters: queryParameters,
      data: data,
    );
    return response.data;
  }

  Future<T> delete<T>(
    String url, {
    Map<String, dynamic> queryParameters = const {},
    Object? data,
  }) async {
    final response = await base.delete(
      '$baseUrl$url',
      queryParameters: queryParameters,
      data: data,
    );
    return response.data;
  }
}

class Serinus {
  Serinus._();

  factory Serinus() {
    return _instance;
  }

  static final _instance = Serinus._();

  final SerinusClient client = SerinusClient();

  bool _isInitialized = false;

  Dio get adapter => client.base;

  void init() {
    if (_isInitialized) {
      return;
    }
    _isInitialized = true;
// Add your initialization code here
  }

  AppController get appController => AppController(client);
}
