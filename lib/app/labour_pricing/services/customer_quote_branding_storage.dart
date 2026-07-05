import 'package:hive/hive.dart';
import 'package:roofgrid_uk/app/labour_pricing/models/customer_quote_branding.dart';

const customerQuoteBrandingStorageKey = 'customerQuoteBranding';

class CustomerQuoteBrandingStorage {
  CustomerQuoteBrandingStorage._();

  static CustomerQuoteBranding loadFromBox(Box<Map> box) {
    final raw = box.get(customerQuoteBrandingStorageKey);
    if (raw == null) return CustomerQuoteBranding.empty;

    try {
      return CustomerQuoteBranding.fromJson(
        Map<String, dynamic>.from(raw),
      );
    } catch (_) {
      return CustomerQuoteBranding.empty;
    }
  }

  static Future<void> saveToBox(
    Box<Map> box,
    CustomerQuoteBranding branding,
  ) async {
    await box.put(customerQuoteBrandingStorageKey, branding.toJson());
  }
}