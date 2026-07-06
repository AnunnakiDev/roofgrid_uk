import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:roofgrid_uk/app/labour_pricing/models/labour_flow_step.dart';
import 'package:roofgrid_uk/app/labour_pricing/providers/labour_flow_provider.dart';
import 'package:roofgrid_uk/app/labour_pricing/providers/labour_pricing_provider.dart';
import 'package:roofgrid_uk/providers/auth_provider.dart';
import 'package:roofgrid_uk/screens/labour/widgets/labour_decimal_text_field.dart';
import 'package:roofgrid_uk/screens/labour/widgets/labour_int_text_field.dart';
import 'package:roofgrid_uk/screens/labour/widgets/labour_quotes_sync_chip.dart';
import 'package:roofgrid_uk/screens/labour/widgets/labour_saved_quotes_sheet.dart';
import 'package:roofgrid_uk/utils/layout_utils.dart';
import 'package:roofgrid_uk/widgets/section_header.dart';

class LabourQuoteStep extends ConsumerWidget {
  final Future<void> Function() onSaveQuote;
  final bool embedded;

  const LabourQuoteStep({
    super.key,
    required this.onSaveQuote,
    this.embedded = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(labourPricingProvider);
    final notifier = ref.read(labourPricingProvider.notifier);
    final userId = ref.watch(currentUserProvider).value?.id;
    final horizontalPadding = screenHorizontalPadding(context);
    final useTwoColumn = !isNarrowLayout(context);

    final gangSizeField = LabourIntTextField(
      label: 'Gang size',
      value: state.quoteConfig.gangSize,
      onChanged: (value) => notifier.updateQuoteConfig(
        state.quoteConfig.copyWith(gangSize: value),
      ),
    );
    final travelField = LabourDecimalTextField(
      label: 'Travel miles (one way)',
      value: state.quoteConfig.travelMiles,
      onChanged: (value) => notifier.updateQuoteConfig(
        state.quoteConfig.copyWith(travelMiles: value),
      ),
    );
    final difficultyField = LabourDecimalTextField(
      label: 'Difficulty uplift (%)',
      value: state.quoteConfig.difficultyUpliftPercent,
      onChanged: (value) => notifier.updateQuoteConfig(
        state.quoteConfig.copyWith(difficultyUpliftPercent: value),
      ),
    );
    final overnightField = LabourIntTextField(
      label: 'Overnight nights',
      value: state.quoteConfig.overnightNights,
      onChanged: (value) => notifier.updateQuoteConfig(
        state.quoteConfig.copyWith(overnightNights: value),
      ),
    );

    final content = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SectionHeader(
            title: 'Gang & uplifts',
            subtitle: 'Pricing assumptions before you calculate',
          ),
          const SizedBox(height: 16),
          if (useTwoColumn) ...[
            Row(
              children: [
                Expanded(child: gangSizeField),
                const SizedBox(width: 12),
                Expanded(child: travelField),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: difficultyField),
                const SizedBox(width: 12),
                Expanded(child: overnightField),
              ],
            ),
          ] else ...[
            gangSizeField,
            const SizedBox(height: 12),
            travelField,
            const SizedBox(height: 12),
            difficultyField,
            const SizedBox(height: 12),
            overnightField,
          ],
          const SizedBox(height: 12),
          LabourDecimalTextField(
            label: 'Target margin (%)',
            value: state.quoteConfig.targetMarginPercent,
            onChanged: (value) => notifier.updateQuoteConfig(
              state.quoteConfig.copyWith(targetMarginPercent: value),
            ),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () => context.go('/profile?tab=labour-rates'),
            icon: const Icon(Icons.tune_rounded),
            label: const Text('Edit rates in Profile'),
          ),
          const SizedBox(height: 20),
          if (userId != null && userId.isNotEmpty) ...[
            const Align(
              alignment: Alignment.centerLeft,
              child: LabourQuotesSyncChip(),
            ),
            const SizedBox(height: 12),
          ],
          OutlinedButton.icon(
            onPressed: onSaveQuote,
            icon: const Icon(Icons.save_outlined),
            label: const Text('Save current quote'),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () => showLabourSavedQuotesSheet(context),
            icon: const Icon(Icons.folder_open_outlined),
            label: const Text('Saved quotes'),
          ),
        ],
      );

    if (embedded) return content;

    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
        horizontalPadding,
        16,
        horizontalPadding,
        24,
      ),
      child: content,
    );
  }
}

Future<void> calculateLabourQuote(
  BuildContext context,
  WidgetRef ref,
) async {
  final message = ref.read(labourPricingProvider.notifier).recalculate();
  if (!context.mounted) return;
  if (message != null) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
    return;
  }
  ref.read(labourFlowProvider.notifier).goTo(LabourFlowStep.results);
}