import 'package:dio/dio.dart';
import 'package:sport_platform/core/config/app_config.dart';

class KeyFormatInterceptor extends Interceptor {
  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    if (response.data != null && AppConfig.apiKeyFormat == ApiKeyFormat.snakeCase) {
      response.data = _normalize(response.data);
    }
    handler.next(response);
  }

  dynamic _normalize(dynamic data) {
    if (data is Map<String, dynamic>) {
      return data.map((key, value) => MapEntry(_toCamelCase(key), _normalize(value)));
    }
    if (data is List) {
      return data.map(_normalize).toList();
    }
    return data;
  }

  String _toCamelCase(String key) => key.replaceAllMapped(
        RegExp(r'_([a-zA-Z0-9])'),
        (m) => m.group(1)!.toUpperCase(),
      );
}
