import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sport_platform/core/constants/app_constants.dart';
import 'package:sport_platform/core/network/api_error_codes.dart';
import 'package:sport_platform/modules/events/event_types/leagues/data/models/player_model.dart';
import 'package:sport_platform/modules/users/data/datasource/player_photo_service.dart';
import 'package:sport_platform/modules/users/domain/profile_photo_picker.dart';
import 'package:sport_platform/modules/users/domain/profile_photo_rules.dart';
import 'package:sport_platform/modules/users/presentation/providers/profile_photo_notifier.dart';

class _FakePicker implements ProfilePhotoPicker {
  final Future<PickedPhoto?> Function(PhotoSource source) onPick;
  PhotoSource? pickedFrom;

  _FakePicker(this.onPick);

  @override
  Future<PickedPhoto?> pick(PhotoSource source) {
    pickedFrom = source;
    return onPick(source);
  }
}

class _FakeService extends PlayerPhotoService {
  final Future<PlayerModel> Function() onUpload;
  final Future<PlayerModel> Function() onRemove;
  int uploads = 0;
  String? uploadedFileName;

  _FakeService({Future<PlayerModel> Function()? upload, Future<PlayerModel> Function()? remove})
      : onUpload = upload ?? (() async => _withPhoto),
        onRemove = remove ?? (() async => _withoutPhoto);

  @override
  Future<PlayerModel> upload({required Uint8List bytes, required String fileName}) {
    uploads++;
    uploadedFileName = fileName;
    return onUpload();
  }

  @override
  Future<PlayerModel> remove() => onRemove();
}

const _withoutPhoto = PlayerModel(id: 'ana', firstName: 'Ana', lastName: 'Pérez', email: 'ana@email.com');
final _withPhoto = _withoutPhoto.copyWith(profilePhotoUrl: 'players/ana/photo?v=1');

PickedPhoto _photo({String name = 'foto.jpg', int size = 1000}) =>
    PickedPhoto(bytes: Uint8List(size), fileName: name);

DioException _rejection(int status, {String? message, Map<String, String>? data}) => DioException(
      requestOptions: RequestOptions(path: '/players/me/photo'),
      response: Response(
        requestOptions: RequestOptions(path: '/players/me/photo'),
        statusCode: status,
        data: {'message': ?message, 'data': ?data},
      ),
    );

ProfilePhotoNotifier _notifier({_FakePicker? picker, _FakeService? service}) => ProfilePhotoNotifier(
      service: service ?? _FakeService(),
      picker: picker ?? _FakePicker((_) async => _photo()),
    );

void main() {
  group('imageMimeTypeOf', () {
    test('reconoce los tipos que acepta el backend sin distinguir mayúsculas', () {
      expect(imageMimeTypeOf('a.jpg'), 'image/jpeg');
      expect(imageMimeTypeOf('a.JPEG'), 'image/jpeg');
      expect(imageMimeTypeOf('mi foto.final.png'), 'image/png');
      expect(imageMimeTypeOf('a.webp'), 'image/webp');
    });

    test('lo demás no es una foto aceptada', () {
      expect(imageMimeTypeOf('a.gif'), isNull);
      expect(imageMimeTypeOf('a.heic'), isNull);
      expect(imageMimeTypeOf('sin_extension'), isNull);
      expect(imageMimeTypeOf('termina_en_punto.'), isNull);
    });
  });

  group('checkProfilePhoto', () {
    test('una foto normal sirve', () {
      expect(checkProfilePhoto(fileName: 'a.jpg', sizeBytes: 500000), isNull);
    });

    test('un archivo vacío no sirve', () {
      expect(checkProfilePhoto(fileName: 'a.jpg', sizeBytes: 0), ProfilePhotoProblem.empty);
    });

    test('un tipo que no se acepta no sirve', () {
      expect(checkProfilePhoto(fileName: 'a.gif', sizeBytes: 100), ProfilePhotoProblem.unsupportedType);
    });

    test('lo que pesa más del máximo no sirve, y justo el máximo sí', () {
      final limit = AppConstants.profilePhotoMaxBytes;

      expect(checkProfilePhoto(fileName: 'a.jpg', sizeBytes: limit), isNull);
      expect(checkProfilePhoto(fileName: 'a.jpg', sizeBytes: limit + 1), ProfilePhotoProblem.tooLarge);
    });
  });

  group('ProfilePhotoProblem.fromBackend', () {
    test('lee el código de un rechazo del campo del archivo', () {
      final codes = ApiErrorCodes.of(_rejection(400, data: {'file': 'FILE_TOO_LARGE'}));

      expect(ProfilePhotoProblem.fromBackend(codes), ProfilePhotoProblem.tooLarge);
    });

    test('un rechazo por otra causa no es un problema de la foto', () {
      final codes = ApiErrorCodes.of(_rejection(500));

      expect(ProfilePhotoProblem.fromBackend(codes), isNull);
    });
  });

  group('ProfilePhotoNotifier', () {
    test('elegir una foto buena la sube y devuelve al jugador con su foto', () async {
      final service = _FakeService();
      final picker = _FakePicker((_) async => _photo(name: 'yo.png'));
      final notifier = _notifier(picker: picker, service: service);

      final outcome = await notifier.choose(PhotoSource.gallery);

      expect(picker.pickedFrom, PhotoSource.gallery);
      expect(service.uploadedFileName, 'yo.png');
      expect(outcome.isSuccess, isTrue);
      expect(outcome.messageKey, 'mobile.profile.photo.updated');
      expect(outcome.player?.profilePhotoUrl, 'players/ana/photo?v=1');
      expect(notifier.isWorking, isFalse);
    });

    test('cerrar el selector sin elegir no hace nada ni dice nada', () async {
      final service = _FakeService();
      final notifier = _notifier(picker: _FakePicker((_) async => null), service: service);

      final outcome = await notifier.choose(PhotoSource.camera);

      expect(outcome.player, isNull);
      expect(outcome.messageKey, isNull);
      expect(service.uploads, 0);
    });

    test('una foto que no sirve se rechaza antes de subirla', () async {
      final service = _FakeService();
      final notifier = _notifier(
        picker: _FakePicker((_) async => _photo(name: 'animada.gif')),
        service: service,
      );

      final outcome = await notifier.choose(PhotoSource.gallery);

      expect(outcome.isSuccess, isFalse);
      expect(outcome.messageKey, 'mobile.profile.photo.error_type');
      expect(service.uploads, 0);
    });

    test('si el selector falla (p. ej. permiso negado) avisa que no se pudo guardar', () async {
      final notifier = _notifier(picker: _FakePicker((_) => Future.error(Exception('permiso negado'))));

      final outcome = await notifier.choose(PhotoSource.camera);

      expect(outcome.messageKey, 'mobile.profile.photo.error_save');
    });

    test('explica el rechazo del backend con su código', () async {
      final service = _FakeService(
        upload: () => Future.error(_rejection(400, data: {'file': 'FILE_TOO_LARGE'})),
      );
      final notifier = _notifier(service: service);

      final outcome = await notifier.choose(PhotoSource.gallery);

      expect(outcome.messageKey, 'mobile.profile.photo.error_too_large');
      expect(outcome.player, isNull);
    });

    test('un 404 es que la cuenta aún no tiene jugador', () async {
      final service = _FakeService(upload: () => Future.error(_rejection(404)));
      final notifier = _notifier(service: service);

      final outcome = await notifier.choose(PhotoSource.gallery);

      expect(outcome.messageKey, 'mobile.profile.photo.error_no_player');
    });

    test('un fallo sin explicación dice la frase general', () async {
      final service = _FakeService(upload: () => Future.error(_rejection(500)));
      final notifier = _notifier(service: service);

      final outcome = await notifier.choose(PhotoSource.gallery);

      expect(outcome.messageKey, 'mobile.profile.photo.error_save');
    });

    test('quitar la foto devuelve al jugador sin ella', () async {
      final notifier = _notifier();

      final outcome = await notifier.remove();

      expect(outcome.isSuccess, isTrue);
      expect(outcome.messageKey, 'mobile.profile.photo.removed');
      expect(outcome.player?.profilePhotoUrl, isNull);
    });

    test('un fallo al quitarla dice su propia frase', () async {
      final notifier = _notifier(service: _FakeService(remove: () => Future.error(_rejection(500))));

      final outcome = await notifier.remove();

      expect(outcome.messageKey, 'mobile.profile.photo.error_remove');
    });

    test('mientras sube no acepta otro cambio', () async {
      final service = _FakeService(upload: () => Future.delayed(const Duration(milliseconds: 20), () => _withPhoto));
      final notifier = _notifier(service: service);

      final first = notifier.choose(PhotoSource.gallery);
      await Future<void>.delayed(Duration.zero);
      final second = await notifier.choose(PhotoSource.gallery);
      await first;

      expect(second.messageKey, isNull);
      expect(service.uploads, 1);
    });
  });
}
