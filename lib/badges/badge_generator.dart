import 'package:http/http.dart' as http;

Future<String> generateVersionBadge(String version) async {
  final shieldUrl = 'https://img.shields.io/badge/version-$version-blue';

  final response = await http.get(Uri.parse(shieldUrl));

  return response.body;
}
