import 'package:http/http.dart' as http;

/// The shields.io URL of a badge showing [version].
///
/// shields.io splits the path at single dashes and underscores, so a
/// pre-release like `3.0.0-dev.1` has them doubled to stay part of the message.
/// Undoubled, it gets a "404: badge not found" image back.
String versionBadgeUrl(String version) {
  final message = Uri.encodeComponent(version.replaceAll('-', '--').replaceAll('_', '__'));
  return 'https://img.shields.io/badge/version-$message-blue';
}

Future<String> generateVersionBadge(String version) async {
  final response = await http.get(Uri.parse(versionBadgeUrl(version)));

  return response.body;
}
