import 'package:dio/dio.dart';

class SerinusClient {
  SerinusClient._();

  factory SerinusClient() {
    return _instance;
  }

  final Dio base = Dio();

  static final _instance = SerinusClient._();

  Future<T> get<T>(
    String url, {
    Map<String, dynamic> queryParameters = const {},
  }) async {
    final response = await base.get(url, queryParameters: queryParameters);
    return response.data;
  }
}
