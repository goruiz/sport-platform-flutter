import 'package:sport_platform/core/constants/app_constants.dart';
import 'package:sport_platform/core/network/api_error_codes.dart';

/// Por qué una foto de perfil no sirve. El backend rechaza lo mismo con un código (`PlayerPhotoError`); la app lo
/// revisa antes de enviarla para no subir un archivo que se va a rechazar.
enum ProfilePhotoProblem {
  empty('EMPTY_FILE', 'mobile.profile.photo.error_empty'),
  unsupportedType('UNSUPPORTED_TYPE', 'mobile.profile.photo.error_type'),
  tooLarge('FILE_TOO_LARGE', 'mobile.profile.photo.error_too_large');

  const ProfilePhotoProblem(this.backendCode, this.translationKey);

  /// El código con que el backend explica el rechazo.
  final String backendCode;

  /// La frase que se le muestra a la persona.
  final String translationKey;

  /// El problema que dijo el backend, o null si el rechazo fue por otra cosa.
  static ProfilePhotoProblem? fromBackend(ApiErrorCodes codes) =>
      codes.firstOf(values, (problem) => problem.backendCode);
}

/// Los tipos de imagen que acepta el backend (`app.photos.allowed-content-types`), por extensión del archivo.
const Map<String, String> _mimeTypeByExtension = {
  'jpg': 'image/jpeg',
  'jpeg': 'image/jpeg',
  'png': 'image/png',
  'webp': 'image/webp',
};

/// El tipo de imagen de [fileName] según su extensión; null si no es uno de los que acepta el backend.
String? imageMimeTypeOf(String fileName) {
  final dot = fileName.lastIndexOf('.');
  if (dot < 0 || dot == fileName.length - 1) return null;
  return _mimeTypeByExtension[fileName.substring(dot + 1).toLowerCase()];
}

/// El problema de una foto de [fileName] que pesa [sizeBytes]; null si sirve para subirla.
ProfilePhotoProblem? checkProfilePhoto({required String fileName, required int sizeBytes}) {
  if (sizeBytes <= 0) return ProfilePhotoProblem.empty;
  if (imageMimeTypeOf(fileName) == null) return ProfilePhotoProblem.unsupportedType;
  if (sizeBytes > AppConstants.profilePhotoMaxBytes) return ProfilePhotoProblem.tooLarge;
  return null;
}
