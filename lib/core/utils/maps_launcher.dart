import 'package:url_launcher/url_launcher.dart';

Future<bool> launchGoogleMapsSearch(String address) async {
  final normalizedAddress = address.trim();
  if (normalizedAddress.isEmpty || normalizedAddress == '-') {
    return false;
  }

  final uri = Uri.https('www.google.com', '/maps/search/', {
    'api': '1',
    'query': normalizedAddress,
  });

  try {
    if (await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      return true;
    }
  } catch (_) {
    // Fall through to the platform default launcher.
  }

  try {
    return await launchUrl(uri, mode: LaunchMode.platformDefault);
  } catch (_) {
    return false;
  }
}
