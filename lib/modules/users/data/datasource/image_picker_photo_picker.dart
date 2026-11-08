import 'package:image_picker/image_picker.dart';
import 'package:sport_platform/core/constants/app_constants.dart';
import 'package:sport_platform/modules/users/domain/profile_photo_picker.dart';

/// El selector real de fotos del dispositivo (`image_picker`). Reduce la imagen al elegirla: una foto de cámara
/// pesa varios MB y el backend solo guarda las que caben en `AppConstants.profilePhotoMaxMegabytes`.
class ImagePickerPhotoPicker implements ProfilePhotoPicker {
  final ImagePicker _picker;

  ImagePickerPhotoPicker({ImagePicker? picker}) : _picker = picker ?? ImagePicker();

  @override
  Future<PickedPhoto?> pick(PhotoSource source) async {
    final file = await _picker.pickImage(
      source: switch (source) {
        PhotoSource.camera => ImageSource.camera,
        PhotoSource.gallery => ImageSource.gallery,
      },
      maxWidth: AppConstants.profilePhotoMaxSide.value,
      maxHeight: AppConstants.profilePhotoMaxSide.value,
      imageQuality: AppConstants.profilePhotoQuality.value,
    );
    if (file == null) return null;
    return PickedPhoto(bytes: await file.readAsBytes(), fileName: file.name);
  }
}
