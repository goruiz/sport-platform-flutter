import 'dart:typed_data';

/// De dónde sale la foto.
enum PhotoSource { camera, gallery }

/// Una foto elegida: sus bytes y el nombre del archivo (de ahí se saca su tipo).
class PickedPhoto {
  final Uint8List bytes;
  final String fileName;

  const PickedPhoto({required this.bytes, required this.fileName});
}

/// Quien deja elegir una foto (la cámara o la galería). Es una interfaz para poder probar el flujo sin el selector real.
abstract interface class ProfilePhotoPicker {
  /// La foto que eligió la persona, ya reducida; null si cerró el selector sin elegir.
  Future<PickedPhoto?> pick(PhotoSource source);
}
