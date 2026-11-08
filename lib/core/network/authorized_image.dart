import 'package:sport_platform/core/network/auth_token_interceptor.dart';

/// Cómo pedir una imagen de la red: su dirección completa y las cabeceras que lleva.
class AuthorizedImage {
  final String url;
  final Map<String, String> headers;

  const AuthorizedImage({required this.url, this.headers = const {}});
}

/// Resuelve [url] para pedirla con `Image.network`.
///
/// Una dirección relativa es de nuestro propio API (la foto de un jugador): se completa con [apiBaseUrl] y se pide con
/// el token de la sesión, porque el backend no sirve fotos sin sesión. Una dirección completa que no es del API (el
/// logo que el organizador pegó de otro sitio) se pide tal cual y **nunca lleva el token**: sería entregárselo a un
/// tercero.
AuthorizedImage resolveNetworkImage(
  String url, {
  required String apiBaseUrl,
  String? token,
}) {
  final apiRoot = apiBaseUrl.endsWith('/')
      ? apiBaseUrl.substring(0, apiBaseUrl.length - 1)
      : apiBaseUrl;
  final isAbsolute = Uri.tryParse(url)?.hasScheme ?? false;
  final resolved = isAbsolute
      ? url
      : '$apiRoot/${url.startsWith('/') ? url.substring(1) : url}';
  final isOwnApi = resolved.startsWith('$apiRoot/');
  final canAuthorize = isOwnApi && token != null && token.isNotEmpty;
  return AuthorizedImage(
    url: resolved,
    headers: {
      if (canAuthorize)
        AuthTokenInterceptor.authorizationHeader: AuthTokenInterceptor.bearerValue(token),
    },
  );
}
