import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_core_platform_interface/test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roofgrid_uk/providers/auth_provider.dart';
import 'package:roofgrid_uk/widgets/user_theme_sync_listener.dart';

class _TestAuthNotifier extends AuthNotifier {
  @override
  AuthState build() => const AuthState();
}

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    setupFirebaseCoreMocks();
    await Firebase.initializeApp();
  });

  testWidgets('UserThemeSyncListener mounts without throwing', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authProvider.overrideWith(_TestAuthNotifier.new),
        ],
        child: const UserThemeSyncListener(
          child: MaterialApp(home: Text('ok')),
        ),
      ),
    );

    await tester.pump();
    await tester.pump();

    expect(find.text('ok'), findsOneWidget);
  });
}