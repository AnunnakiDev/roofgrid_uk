import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:roofgrid_uk/app/labour_pricing/providers/labour_quotes_provider.dart';
import 'package:roofgrid_uk/utils/connectivity_utils.dart';

class LabourQuotesSyncChip extends ConsumerStatefulWidget {
  const LabourQuotesSyncChip({super.key});

  @override
  ConsumerState<LabourQuotesSyncChip> createState() =>
      _LabourQuotesSyncChipState();
}

class _LabourQuotesSyncChipState extends ConsumerState<LabourQuotesSyncChip> {
  bool _isOnline = true;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;

  @override
  void initState() {
    super.initState();
    unawaited(_checkConnectivity());
    _connectivitySubscription =
        Connectivity().onConnectivityChanged.listen((results) {
      if (!mounted) return;
      setState(() => _isOnline = isOnlineFromResults(results));
    });
  }

  Future<void> _checkConnectivity() async {
    final online = await isDeviceOnline();
    if (!mounted) return;
    setState(() => _isOnline = online);
  }

  @override
  void dispose() {
    _connectivitySubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final syncUi = ref.watch(labourQuotesSyncUiProvider);
    final scheme = Theme.of(context).colorScheme;

    final LabourQuotesSyncStatus status;
    if (!_isOnline) {
      status = LabourQuotesSyncStatus.offline;
    } else if (syncUi.pendingCount > 0 || syncUi.isFlushing) {
      status = LabourQuotesSyncStatus.pending;
    } else {
      status = LabourQuotesSyncStatus.synced;
    }

    final (label, icon, background, foreground) = switch (status) {
      LabourQuotesSyncStatus.offline => (
          syncUi.pendingCount > 0
              ? 'Offline · ${syncUi.pendingCount} pending'
              : 'Offline',
          Icons.cloud_off_outlined,
          scheme.surfaceContainerHighest,
          scheme.onSurfaceVariant,
        ),
      LabourQuotesSyncStatus.pending => (
          syncUi.isFlushing
              ? 'Syncing…'
              : 'Pending sync (${syncUi.pendingCount})',
          Icons.cloud_upload_outlined,
          scheme.tertiaryContainer,
          scheme.onTertiaryContainer,
        ),
      LabourQuotesSyncStatus.synced => (
          'Synced',
          Icons.cloud_done_outlined,
          scheme.primaryContainer.withValues(alpha: 0.55),
          scheme.onPrimaryContainer,
        ),
    };

    return ActionChip(
      avatar: syncUi.isFlushing
          ? SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: foreground,
              ),
            )
          : Icon(icon, size: 18, color: foreground),
      label: Text(
        label,
        style: GoogleFonts.poppins(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: foreground,
        ),
      ),
      backgroundColor: background,
      side: BorderSide.none,
      onPressed: status == LabourQuotesSyncStatus.pending && !syncUi.isFlushing
          ? () => ref.read(labourQuotesProvider.notifier).flushPendingSync()
          : null,
    );
  }
}