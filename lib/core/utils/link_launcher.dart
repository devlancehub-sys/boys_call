import 'package:url_launcher/url_launcher.dart';

import '../constants/app_urls.dart';
import '../messaging/app_messenger.dart';

abstract final class LinkLauncher {
  static Future<void> openTermsAndConditions() => open(AppUrls.termsAndConditions);

  static Future<void> open(String url) async {
    final uri = Uri.parse(url);
    final launched = await launchUrl(
      uri,
      mode: LaunchMode.inAppBrowserView,
    );
    if (!launched) {
      AppMessenger.show('Error', 'Could not open link');
    }
  }
}
