import 'package:flutter/foundation.dart';
import 'package:sport_platform/core/network/api_error_codes.dart';
import 'package:sport_platform/modules/events/event_types/leagues/data/models/player_model.dart';
import 'package:sport_platform/modules/users/data/datasource/player_photo_service.dart';
import 'package:sport_platform/modules/users/domain/profile_photo_picker.dart';
import 'package:sport_platform/modules/users/domain/profile_photo_rules.dart';

/// Cómo terminó cambiar o quitar la foto.
class ProfilePhotoOutcome {
  /// El jugador con su foto nueva; null si no se cambió nada.
  final PlayerModel? player;

  /// La frase que se le muestra a la persona; null si cerró el selector sin elegir (no hay nada que decir).
  final String? messageKey;

  /// Si [messageKey] cuenta un éxito o un problema.
  final bool isSuccess;

  const ProfilePhotoOutcome({this.player, this.messageKey, this.isSuccess = false});

  const ProfilePhotoOutcome.cancelled() : this();
}

/// Cambiar y quitar la foto de perfil: elegirla, revisarla antes de subirla, subirla y explicar cómo terminó.
class ProfilePhotoNotifier extends ChangeNotifier {
  static const _updatedKey = 'mobile.profile.photo.updated';
  static const _removedKey = 'mobile.profile.photo.removed';
  static const _saveErrorKey = 'mobile.profile.photo.error_save';
  static const _removeErrorKey = 'mobile.profile.photo.error_remove';
  static const _noPlayerKey = 'mobile.profile.photo.error_no_player';

  final PlayerPhotoService _service;
  final ProfilePhotoPicker _picker;

  ProfilePhotoNotifier({
    required PlayerPhotoService service,
    required ProfilePhotoPicker picker,
  }) : _service = service,
       _picker = picker;

  bool _isWorking = false;
  bool _isDisposed = false;

  /// Hay una foto subiéndose o quitándose: la pantalla no debe ofrecer otro cambio todavía.
  bool get isWorking => _isWorking;

  /// Deja elegir una foto de [source], la revisa y la sube.
  Future<ProfilePhotoOutcome> choose(PhotoSource source) async {
    if (_isWorking) return const ProfilePhotoOutcome.cancelled();
    final PickedPhoto? photo;
    try {
      photo = await _picker.pick(source);
    } catch (_) {
      // El selector falla, por ejemplo, si la persona negó el permiso de la cámara o de la galería.
      return const ProfilePhotoOutcome(messageKey: _saveErrorKey);
    }
    if (photo == null) return const ProfilePhotoOutcome.cancelled();

    final picked = photo;
    final problem = checkProfilePhoto(fileName: picked.fileName, sizeBytes: picked.bytes.length);
    if (problem != null) return ProfilePhotoOutcome(messageKey: problem.translationKey);

    return _run(
      () => _service.upload(bytes: picked.bytes, fileName: picked.fileName),
      successKey: _updatedKey,
      failureKey: _saveErrorKey,
    );
  }

  Future<ProfilePhotoOutcome> remove() {
    if (_isWorking) return Future.value(const ProfilePhotoOutcome.cancelled());
    return _run(_service.remove, successKey: _removedKey, failureKey: _removeErrorKey);
  }

  Future<ProfilePhotoOutcome> _run(
    Future<PlayerModel> Function() action, {
    required String successKey,
    required String failureKey,
  }) async {
    _isWorking = true;
    _notify();
    try {
      final player = await action();
      return ProfilePhotoOutcome(player: player, messageKey: successKey, isSuccess: true);
    } catch (error) {
      return ProfilePhotoOutcome(messageKey: _failureKeyFor(error, failureKey));
    } finally {
      _isWorking = false;
      _notify();
    }
  }

  /// Lo que dijo el backend si fue un rechazo que se puede explicar; si no, la frase general.
  String _failureKeyFor(Object error, String fallbackKey) {
    final codes = ApiErrorCodes.of(error);
    final problem = ProfilePhotoProblem.fromBackend(codes);
    if (problem != null) return problem.translationKey;
    if (codes.statusCode == 404) return _noPlayerKey;
    return fallbackKey;
  }

  /// Una operación que termina después de cerrar la pantalla no debe avisar a nadie.
  void _notify() {
    if (!_isDisposed) notifyListeners();
  }

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }
}
