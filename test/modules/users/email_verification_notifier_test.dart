import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sport_platform/modules/users/data/datasource/account_service.dart';
import 'package:sport_platform/modules/users/presentation/providers/email_verification_notifier.dart';

class _FakeAccountService extends AccountService {
  bool verified = false;
  bool failRead = false;
  Object? resendFailure;
  Object? verifyFailure;
  final List<String> verifiedTokens = [];

  @override
  Future<bool> isEmailVerified() async {
    if (failRead) throw Exception('sin red');
    return verified;
  }

  @override
  Future<void> resendEmailVerification() async {
    if (resendFailure != null) throw resendFailure!;
  }

  @override
  Future<void> verifyEmail(String token) async {
    if (verifyFailure != null) throw verifyFailure!;
    verifiedTokens.add(token);
    verified = true;
  }
}

DioException _failure(int status, Map<String, dynamic> body) {
  final request = RequestOptions(path: '/x');
  return DioException(
    requestOptions: request,
    response: Response(requestOptions: request, statusCode: status, data: body),
  );
}

void main() {
  late _FakeAccountService service;
  late EmailVerificationNotifier notifier;

  setUp(() {
    service = _FakeAccountService();
    notifier = EmailVerificationNotifier(service);
  });

  tearDown(() => notifier.dispose());

  test('no avisa de nada mientras no sabe si el correo está confirmado', () {
    expect(notifier.needsVerification, isFalse);
  });

  test('avisa solo cuando el backend dice que aún no está confirmado', () async {
    await notifier.load();
    expect(notifier.needsVerification, isTrue);

    service.verified = true;
    await notifier.load();
    expect(notifier.needsVerification, isFalse);
  });

  test('sin conexión se queda con lo que sabía y no inventa un aviso', () async {
    service.failRead = true;

    await notifier.load();

    expect(notifier.needsVerification, isFalse);
  });

  test('reenviar responde la clave de «te enviamos un enlace»', () async {
    expect(await notifier.resend(), 'verify_email.resent');
  });

  test('reenviar demasiadas veces responde la clave de demasiados intentos', () async {
    service.resendFailure = _failure(429, {'message': 'Too many requests'});

    expect(await notifier.resend(), 'account.errors.TOO_MANY_REQUESTS');
  });

  test('«ya lo confirmé» vuelve a leer y dice si sigue pendiente', () async {
    await notifier.load();

    expect(await notifier.checkAgain(), 'verify_email.still_pending');

    service.verified = true;
    expect(await notifier.checkAgain(), 'verify_email.confirmed');
    expect(notifier.needsVerification, isFalse);
  });

  test('confirmar con el token del enlace confirma y apaga el aviso', () async {
    await notifier.load();

    final result = await notifier.confirmWithToken('abc');

    expect(result, 'verify_email.confirmed');
    expect(service.verifiedTokens, ['abc']);
    expect(notifier.needsVerification, isFalse);
  });

  test('un enlace vencido responde su motivo y deja el aviso', () async {
    await notifier.load();
    service.verifyFailure = _failure(400, {
      'data': {'token': 'INVALID_OR_EXPIRED'},
    });

    expect(await notifier.confirmWithToken('viejo'), 'account.errors.INVALID_OR_EXPIRED');
    expect(notifier.needsVerification, isTrue);
  });

  test('al cerrar la sesión olvida lo del usuario anterior', () async {
    await notifier.load();

    notifier.clear();

    expect(notifier.needsVerification, isFalse);
  });
}
