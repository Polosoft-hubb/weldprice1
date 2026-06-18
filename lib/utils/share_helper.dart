import 'share_helper_stub.dart'
    if (dart.library.html) 'share_helper_web.dart';

void shareEstimateWeb(String text, String subject) {
  nativeWebShare(text, subject);
}
