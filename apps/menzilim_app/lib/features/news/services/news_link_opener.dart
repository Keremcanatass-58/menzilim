import 'package:url_launcher/url_launcher.dart';

/// Haber kaynağını açan fonksiyon. Testlerde sahtesi verilebilir.
typedef NewsLinkOpener = Future<bool> Function(Uri uri);

/// Varsayılan: içerik detayındaki gibi harici tarayıcıda/uygulamada açar.
Future<bool> openNewsLinkExternally(Uri uri) {
  return launchUrl(
    uri,
    mode: LaunchMode.externalApplication,
  );
}
