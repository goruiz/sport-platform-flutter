import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

/// Abre algo fuera de la app (un enlace, el calendario, el mapa) o lo comparte. Nunca lanza: devuelve si se pudo, para
/// que la pantalla avise al usuario en vez de romperse en un dispositivo sin esa aplicación.
class ExternalLauncher {
  ExternalLauncher._();

  static Future<bool> open(Uri uri) async {
    try {
      return await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      return false;
    }
  }

  static Future<bool> shareText(String text) async {
    try {
      await SharePlus.instance.share(ShareParams(text: text));
      return true;
    } catch (_) {
      return false;
    }
  }
}
