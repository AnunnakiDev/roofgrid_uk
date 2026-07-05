import 'package:roofgrid_uk/utils/roofgrid_api_client.dart';

/// Starts Stripe Checkout for the labour pricing add-on.
Future<String> createLabourCheckoutSessionUrl() async {
  final response = await postAuthenticatedApi(
    '/createCheckoutSession',
    data: {'plan': 'labour'},
  );
  final data = decodeApiJson(response);
  final sessionUrl = data['sessionUrl'] as String?;
  if (sessionUrl == null || sessionUrl.isEmpty) {
    throw Exception('No checkout URL returned from payment service');
  }
  return sessionUrl;
}