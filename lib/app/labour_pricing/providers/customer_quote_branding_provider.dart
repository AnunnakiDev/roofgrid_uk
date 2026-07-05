import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:roofgrid_uk/app/labour_pricing/models/customer_quote_branding.dart';
import 'package:roofgrid_uk/app/labour_pricing/services/customer_quote_branding_storage.dart';
import 'package:roofgrid_uk/services/hive_service.dart';

class CustomerQuoteBrandingState {
  final CustomerQuoteBranding branding;
  final bool isHydrated;

  const CustomerQuoteBrandingState({
    required this.branding,
    this.isHydrated = false,
  });

  factory CustomerQuoteBrandingState.initial() {
    return const CustomerQuoteBrandingState(
      branding: CustomerQuoteBranding.empty,
    );
  }

  CustomerQuoteBrandingState copyWith({
    CustomerQuoteBranding? branding,
    bool? isHydrated,
  }) {
    return CustomerQuoteBrandingState(
      branding: branding ?? this.branding,
      isHydrated: isHydrated ?? this.isHydrated,
    );
  }
}

class CustomerQuoteBrandingNotifier extends Notifier<CustomerQuoteBrandingState> {
  Timer? _persistDebounce;

  @override
  CustomerQuoteBrandingState build() {
    ref.onDispose(() => _persistDebounce?.cancel());
    _hydrateFromHive();
    return CustomerQuoteBrandingState.initial();
  }

  Future<void> _hydrateFromHive() async {
    final box = await HiveService.ensureLabourConfigBox();
    final branding = CustomerQuoteBrandingStorage.loadFromBox(box);
    state = state.copyWith(branding: branding, isHydrated: true);
  }

  void updateBranding(CustomerQuoteBranding branding) {
    state = state.copyWith(branding: branding);
    _schedulePersist();
  }

  void _schedulePersist() {
    _persistDebounce?.cancel();
    _persistDebounce = Timer(const Duration(milliseconds: 400), () async {
      final box = await HiveService.ensureLabourConfigBox();
      await CustomerQuoteBrandingStorage.saveToBox(box, state.branding);
    });
  }
}

final customerQuoteBrandingProvider =
    NotifierProvider<CustomerQuoteBrandingNotifier, CustomerQuoteBrandingState>(
  CustomerQuoteBrandingNotifier.new,
);