import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:roofgrid_uk/app/auth/providers/permissions_provider.dart';
import 'package:roofgrid_uk/app/labour_pricing/models/labour_quote_method.dart';
import 'package:roofgrid_uk/app/labour_pricing/providers/labour_pricing_provider.dart';
import 'package:roofgrid_uk/screens/labour/widgets/labour_result_cards.dart';
import 'package:roofgrid_uk/utils/layout_utils.dart';
import 'package:roofgrid_uk/widgets/section_header.dart';

class LabourResultsStep extends ConsumerWidget {
  final VoidCallback onOpenCustomerQuote;
  final bool embedded;

  const LabourResultsStep({
    super.key,
    required this.onOpenCustomerQuote,
    this.embedded = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(labourPricingProvider);
    final projectResult = state.projectResult;
    final gbp = NumberFormat.currency(locale: 'en_GB', symbol: '£');
    final horizontalPadding = screenHorizontalPadding(context);
    final canAccessCustomerQuote = ref.watch(canAccessCustomerQuoteProvider);

    if (projectResult == null) {
      final empty = Text(
        'Calculate your quote on the Quote step to see results here.',
        style: GoogleFonts.poppins(fontSize: 14),
      );
      if (embedded) return empty;
      return SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          horizontalPadding,
          16,
          horizontalPadding,
          24,
        ),
        child: empty,
      );
    }

    final content = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SectionHeader(
            title: 'Quote results',
            subtitle: 'Method comparison and project totals',
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: LabourMethodTotalCard(
                  title: 'Method A',
                  subtitle: 'All sections rate-based',
                  totalGbp: projectResult.methodATotalGbp,
                  isSelected: false,
                  gbp: gbp,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: LabourMethodTotalCard(
                  title: 'Method B',
                  subtitle: 'All sections timing-based',
                  totalGbp: projectResult.methodBTotalGbp,
                  isSelected: false,
                  gbp: gbp,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          LabourResultHighlight(
            label: 'Quote total',
            value: gbp.format(projectResult.activeQuoteTotalGbp),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: onOpenCustomerQuote,
              icon: const Icon(Icons.description_outlined),
              label: Text(
                canAccessCustomerQuote
                    ? 'Open customer quote preview'
                    : 'Unlock customer quote PDF',
              ),
            ),
          ),
          const SizedBox(height: 10),
          LabourResultRow(
            label: 'Profitable day rate / man',
            value: gbp.format(projectResult.rollup.profitableDayRatePerManGbp),
          ),
          LabourResultRow(
            label: 'Profitable day rate / gang',
            value: gbp.format(projectResult.rollup.profitableDayRatePerGangGbp),
          ),
          LabourResultRow(
            label: 'Man-days (gang)',
            value: projectResult.rollup.manDays.toStringAsFixed(2),
          ),
          LabourResultRow(
            label: 'Total hours',
            value: projectResult.rollup.upliftedHours.toStringAsFixed(1),
          ),
          LabourResultRow(
            label: 'Labour cost',
            value: gbp.format(projectResult.rollup.baseLabourCostGbp),
          ),
          if (projectResult.rollup.travelCostGbp > 0)
            LabourResultRow(
              label: 'Travel',
              value: gbp.format(projectResult.rollup.travelCostGbp),
            ),
          if (projectResult.rollup.overnightCostGbp > 0)
            LabourResultRow(
              label: 'Overnight',
              value: gbp.format(projectResult.rollup.overnightCostGbp),
            ),
          if (state.project.contingencyPercent > 0)
            LabourResultRow(
              label: 'Contingency',
              value: gbp.format(projectResult.contingencyCostGbp),
            ),
          const SizedBox(height: 16),
          const SectionHeader(title: 'Section totals'),
          const SizedBox(height: 8),
          ...projectResult.sectionResults.map(
            (sectionResult) => Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      sectionResult.section.label,
                      style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      sectionResult.section.selectedMethod.shortLabel,
                      style: GoogleFonts.poppins(fontSize: 12),
                    ),
                    const SizedBox(height: 6),
                    LabourResultRow(
                      label: 'Section labour',
                      value: gbp.format(sectionResult.activeLabourCostGbp),
                    ),
                  ],
                ),
              ),
            ),
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