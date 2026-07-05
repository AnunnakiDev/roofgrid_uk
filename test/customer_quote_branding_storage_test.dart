import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:roofgrid_uk/app/labour_pricing/models/customer_quote_branding.dart';
import 'package:roofgrid_uk/app/labour_pricing/services/customer_quote_branding_storage.dart';

void main() {
  group('CustomerQuoteBrandingStorage', () {
    late Box<Map> box;

    setUp(() async {
      Hive.init('customer_quote_branding_storage_test');
      box = await Hive.openBox<Map>('branding_test_box');
    });

    tearDown(() async {
      await box.clear();
      await box.close();
    });

    test('returns empty branding when box is empty', () {
      final branding = CustomerQuoteBrandingStorage.loadFromBox(box);
      expect(branding, CustomerQuoteBranding.empty);
    });

    test('round-trips branding through box', () async {
      const original = CustomerQuoteBranding(
        companyName: 'Acme Roofing Ltd',
        address: '1 High Street\nLeeds',
        phone: '0113 000 0000',
        email: 'quotes@acme.test',
        vatNumber: 'GB123456789',
        quoteFooterNotes: 'Valid for 30 days.',
      );

      await CustomerQuoteBrandingStorage.saveToBox(box, original);
      final restored = CustomerQuoteBrandingStorage.loadFromBox(box);

      expect(restored.companyName, original.companyName);
      expect(restored.address, original.address);
      expect(restored.phone, original.phone);
      expect(restored.email, original.email);
      expect(restored.vatNumber, original.vatNumber);
      expect(restored.quoteFooterNotes, original.quoteFooterNotes);
    });
  });
}