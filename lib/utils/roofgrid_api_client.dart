import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'package:roofgrid_uk/utils/roofgrid_api_config.dart';

/// POST to the RoofGrid Cloud Functions Express API with a verified Bearer token.
Future<http.Response> postAuthenticatedApi(
  String path, {
  required Map<String, dynamic> data,
}) async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) {
    throw Exception('User not authenticated');
  }

  final idToken = await user.getIdToken();
  return http.post(
    roofgridApiUri(path),
    headers: {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $idToken',
    },
    body: jsonEncode({'data': data}),
  );
}

Map<String, dynamic> decodeApiJson(http.Response response) {
  if (response.statusCode != 200) {
    throw Exception('API error (${response.statusCode}): ${response.body}');
  }
  return jsonDecode(response.body) as Map<String, dynamic>;
}