import 'package:flutter_test/flutter_test.dart';
import 'package:roofgrid_uk/models/user_model.dart';
import 'package:roofgrid_uk/navigation/nav_items.dart';
import 'package:roofgrid_uk/navigation/nav_utils.dart';

void main() {
  group('shellTabIndexFromLocation', () {
    test('maps home', () {
      expect(shellTabIndexFromLocation('/home'), 0);
    });

    test('maps calculator and nested routes to tab 1', () {
      expect(shellTabIndexFromLocation('/calculator'), 1);
      expect(shellTabIndexFromLocation('/calculator/tile-select'), 1);
    });

    test('maps results to tab 2', () {
      expect(shellTabIndexFromLocation('/results'), 2);
    });

    test('maps tiles to tab 3', () {
      expect(shellTabIndexFromLocation('/tiles'), 3);
    });
  });

  group('isProGatedShellPath', () {
    test('identifies pro-gated paths', () {
      expect(isProGatedShellPath('/results'), isTrue);
      expect(isProGatedShellPath('/tiles'), isTrue);
      expect(isProGatedShellPath('/home'), isFalse);
      expect(isProGatedShellPath('/calculator'), isFalse);
    });
  });

  group('resolveAppRedirect', () {
    final proUser = UserModel(
      id: 'u1',
      email: 'pro@example.com',
      role: UserRole.pro,
      createdAt: DateTime(2026, 1, 1),
    );

    test('splash sends authenticated users home', () {
      expect(
        resolveAppRedirect(
          location: '/splash',
          isAuthenticated: true,
          effectiveIsPro: true,
        ),
        '/home',
      );
    });

    test('splash sends guests to login', () {
      expect(
        resolveAppRedirect(
          location: '/splash',
          isAuthenticated: false,
          effectiveIsPro: false,
        ),
        '/auth/login',
      );
    });

    test('free users are redirected from results and tiles', () {
      expect(
        resolveAppRedirect(
          location: '/results',
          isAuthenticated: true,
          effectiveIsPro: false,
          currentUser: proUser,
        ),
        '/subscription',
      );
      expect(
        resolveAppRedirect(
          location: '/tiles',
          isAuthenticated: true,
          effectiveIsPro: false,
          currentUser: proUser,
        ),
        '/subscription',
      );
    });

    test('pro users can access results and tiles', () {
      expect(
        resolveAppRedirect(
          location: '/results',
          isAuthenticated: true,
          effectiveIsPro: true,
          currentUser: proUser,
        ),
        isNull,
      );
    });

    test('non-admin users cannot access admin routes', () {
      expect(
        resolveAppRedirect(
          location: '/admin/dashboard',
          isAuthenticated: true,
          effectiveIsPro: true,
          currentUser: proUser,
        ),
        '/home',
      );
    });

    test('users without labour add-on are redirected to upsell', () {
      expect(
        resolveAppRedirect(
          location: labourCalculatorPath,
          isAuthenticated: true,
          effectiveIsPro: true,
          currentUser: proUser,
          canAccessLabourCalculator: false,
        ),
        labourCalculatorUpsellPath,
      );
    });

    test('users with labour add-on can open calculator', () {
      final labourUser = proUser.copyWith(labourCalculatorActive: true);
      expect(
        resolveAppRedirect(
          location: labourCalculatorPath,
          isAuthenticated: true,
          effectiveIsPro: true,
          currentUser: labourUser,
          canAccessLabourCalculator: true,
        ),
        isNull,
      );
    });

    test('entitled users skip upsell screen', () {
      expect(
        resolveAppRedirect(
          location: labourCalculatorUpsellPath,
          isAuthenticated: true,
          effectiveIsPro: false,
          currentUser: proUser.copyWith(labourCalculatorActive: true),
          canAccessLabourCalculator: true,
        ),
        labourCalculatorPath,
      );
    });

    test('customer quote preview redirects to upsell without add-on', () {
      expect(
        resolveAppRedirect(
          location: customerQuotePreviewPath,
          isAuthenticated: true,
          effectiveIsPro: true,
          currentUser: proUser.copyWith(labourCalculatorActive: true),
          canAccessLabourCalculator: true,
          canAccessCustomerQuote: false,
        ),
        customerQuoteUpsellPath,
      );
    });

    test('customer quote preview allowed when entitled', () {
      expect(
        resolveAppRedirect(
          location: customerQuotePreviewPath,
          isAuthenticated: true,
          effectiveIsPro: true,
          currentUser: proUser.copyWith(
            labourCalculatorActive: true,
            customerQuoteActive: true,
          ),
          canAccessLabourCalculator: true,
          canAccessCustomerQuote: true,
        ),
        isNull,
      );
    });
  });

  group('resolveProfileTabIndex', () {
    test('maps labour-rates deep link to tab 3', () {
      expect(resolveProfileTabIndex('labour-rates'), 3);
      expect(resolveProfileTabIndex('2'), 2);
      expect(resolveProfileTabIndex(null), 0);
    });
  });

  group('mainShellNavItems', () {
    test('has four tabs in canonical order', () {
      expect(mainShellNavItems.length, 4);
      expect(mainShellNavItems[0].label, 'Home');
      expect(mainShellNavItems[1].label, 'Calculator');
      expect(mainShellNavItems[2].label, 'My Jobs');
      expect(mainShellNavItems[3].label, 'Tiles');
    });
  });
}