import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;
import '../models/song.dart';

class ApiService {
  static const String _clientId = '1e9d72bc';

  static const String _baseUrl = 'https://api.jamendo.com/v3.0/tracks';

  Future<List<Song>> fetchSongs({String? search}) async {
    final randomOffset = Random().nextInt(200);

    final queryParams = <String, String>{
      'client_id': _clientId,
      'format': 'json',
      'limit': '50',
      'offset': randomOffset.toString(),
      'audioformat': 'mp32',
      'include': 'musicinfo+stats',
      'cache_buster': DateTime.now()
          .millisecondsSinceEpoch
          .toString(), // ✅ PREVENT CACHING
    };

    // ✅ SEARCH SUPPORT
    if (search != null && search.trim().isNotEmpty) {
      queryParams['search'] = search.trim();
    }

    final uri = Uri.parse(_baseUrl).replace(queryParameters: queryParams);

    final response = await http.get(uri);

    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body) as Map<String, dynamic>;
      final List<dynamic> results = decoded['results'] as List<dynamic>;

      return results
          .map((json) =>
          Song.fromJamendoJson(json as Map<String, dynamic>))
          .toList();
    } else {
      throw Exception(
        'Failed to load songs from Jamendo: ${response.statusCode}',
      );
    }
  }
}
