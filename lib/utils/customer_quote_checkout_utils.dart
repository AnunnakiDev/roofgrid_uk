import 'package:roofgrid_uk/utils/roofgrid_api_client.dart';

/// Starts Stripe Checkout for the customer quote add-on.
Future<String> createCustomerQuoteCheckoutSessionUrl() async {
  final response = await postAuthenticatedApi(
    '/createCheckoutSession',
    data: {'plan': 'customerQuote'},
  );
  final data = decodeApiJson(response);
  final sessionUrl = data['sessionUrl'] as String?;
  if (sessionUrl == null || sessionUrl.isEmpty) {
    throw Exception('No checkout URL returned from payment service');
  }
  return sessionUrl;
}