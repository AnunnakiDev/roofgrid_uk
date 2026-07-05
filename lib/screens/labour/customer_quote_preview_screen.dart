import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:roofgrid_uk/app/auth/providers/permissions_provider.dart';
import 'package:roofgrid_uk/app/labour_pricing/models/labour_roof_type.dart';
import 'package:roofgrid_uk/app/labour_pricing/providers/customer_quote_branding_provider.dart';
import 'package:roofgrid_uk/app/labour_pricing/providers/labour_pricing_provider.dart';
import 'package:roofgrid_uk/app/labour_pricing/services/labour_quote_pdf_exporter.dart';
import 'package:roofgrid_uk/navigation/home_back_button.dart';
import 'package:roofgrid_uk/widgets/main_drawer.dart';
import 'package:roofgrid_uk/widgets/section_header.dart';
import 'package:share_plus/share_plus.dart';

class CustomerQuotePreviewScreen extends ConsumerStatefulWidget {
  const CustomerQuotePreviewScreen({super.key});

  @override
  ConsumerState<CustomerQuotePreviewScreen> createState() =>
      _CustomerQuotePreviewScreenState();
}

class _CustomerQuotePreviewScreenState
    extends ConsumerState<CustomerQuotePreviewScreen> {
  bool _isExporting = false;

  Future<void> _exportPdf() async {
    final pricingState = ref.read(labourPricingProvider);
    final brandingState = ref.read(customerQuoteBrandingProvider);
    final projectResult = pricingState.projectResult;
    if (projectResult == null) return;

    setState(() => _isExporting = true);
    try {
      final logoPath = brandingState.branding.logoAssetPath;
      Uint8List? logoBytes;
      if (logoPath.isNotEmpty && File(logoPath).existsSync()) {
        logoBytes = await File(logoPath).readAsBytes();
      }

      final bytes = await LabourQuotePdfExporter.generateBrandedBytes(
        project: pricingState.project,
        config: pricingState.quoteConfig,
        projectResult: projectResult,
        branding: brandingState.branding,
        logoBytes: logoBytes,
      );
      final directory = await getTemporaryDirectory();
      final path =
          '${directory.path}/roofgrid_customer_quote_${DateTime.now().millisecondsSinceEpoch}.pdf';
      await File(path).writeAsBytes(bytes, flush: true);
      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(path, mimeType: 'application/pdf')],
          text: 'Roofing quotation',
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error exporting quote: $e')),
      );
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final canAccess = ref.watch(canAccessCustomerQuoteProvider);
    final pricingState = ref.watch(labourPricingProvider);
    final brandingState = ref.watch(customerQuoteBrandingProvider);
    final project = pricingState.project;
    final projectResult = pricingState.projectResult;
    final branding = brandingState.branding;
    final colorScheme = Theme.of(context).colorScheme;
    final gbp = NumberFormat.currency(locale: 'en_GB', symbol: '£');
    final quoteDate = project.quoteDate ?? DateTime.now();

    if (!canAccess) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (projectResult == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Customer Quote'),
          actions: const [HomeBackButton()],
        ),
        drawer: const MainDrawer(),
        body: const Center(
          child: Text('Calculate a quote on the labour calculator first.'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Customer Quote'),
        actions: [
          IconButton(
            icon: _isExporting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.share_outlined),
            tooltip: 'Share PDF',
            onPressed: _isExporting ? null : _exportPdf,
          ),
          const HomeBackButton(),
        ],
      ),
      drawer: const MainDrawer(),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 32),
        children: [
          Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SectionHeader(
              title: 'Preview',
              subtitle: 'Client-facing layout before you share the PDF',
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (branding.hasLogo &&
                            File(branding.logoAssetPath).existsSync())
                          Padding(
                            padding: const EdgeInsets.only(right: 12),
                            child: Image.file(
                              File(branding.logoAssetPath),
                              width: 72,
                              height: 48,
                              fit: BoxFit.contain,
                            ),
                          ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                branding.companyName.trim().isNotEmpty
                                    ? branding.companyName.trim()
                                    : 'Your company name',
                                style: GoogleFonts.poppins(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              if (branding.address.trim().isNotEmpty)
                                Text(
                                  branding.address.trim(),
                                  style: GoogleFonts.poppins(fontSize: 12),
                                ),
                              if (branding.phone.trim().isNotEmpty)
                                Text(
                                  branding.phone.trim(),
                                  style: GoogleFonts.poppins(fontSize: 12),
                                ),
                              if (branding.email.trim().isNotEmpty)
                                Text(
                                  branding.email.trim(),
                                  style: GoogleFonts.poppins(fontSize: 12),
                                ),
                              if (branding.vatNumber.trim().isNotEmpty)
                                Text(
                                  'VAT: ${branding.vatNumber.trim()}',
                                  style: GoogleFonts.poppins(fontSize: 12),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'QUOTATION',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: colorScheme.secondary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      DateFormat('d MMMM yyyy').format(quoteDate),
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    if (project.quoteRef.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        'Reference: ${project.quoteRef}',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                    const SizedBox(height: 16),
                    _PreviewBlock(
                      title: 'Customer & site',
                      lines: [
                        if (project.customerName.isNotEmpty)
                          project.customerName,
                        if (project.siteAddress.isNotEmpty) project.siteAddress,
                        if (project.accessNotes.isNotEmpty)
                          'Access: ${project.accessNotes}',
                        if (project.scaffoldNotes.isNotEmpty)
                          'Scaffold: ${project.scaffoldNotes}',
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Quoted works',
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...projectResult.sectionResults.map((sectionResult) {
                      final section = sectionResult.section;
                      final area = section.input.roofAreaSqm > 0
                          ? '${section.input.roofAreaSqm.toStringAsFixed(1)} m²'
                          : '—';
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                '${section.label} (${section.input.roofType.label}, $area)',
                                style: GoogleFonts.poppins(fontSize: 13),
                              ),
                            ),
                            Text(
                              gbp.format(sectionResult.activeLabourCostGbp),
                              style: GoogleFonts.poppins(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                    const Divider(),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Total quotation',
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        Text(
                          gbp.format(projectResult.rollup.quoteTotalGbp),
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w700,
                            color: colorScheme.secondary,
                          ),
                        ),
                      ],
                    ),
                    if (branding.quoteFooterNotes.trim().isNotEmpty) ...[
                      const SizedBox(height: 16),
                      _PreviewBlock(
                        title: 'Terms & notes',
                        lines: [branding.quoteFooterNotes.trim()],
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _isExporting ? null : _exportPdf,
                icon: _isExporting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.picture_as_pdf_outlined),
                label: Text(_isExporting ? 'Preparing PDF…' : 'Share PDF'),
              ),
            ),
            if (!branding.hasCompanyDetails) ...[
              const SizedBox(height: 12),
              Text(
                'Tip: add your company details in Profile → Labour Rates → '
                'Customer Quote.',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ],
        ),
        ],
      ),
    );
  }
}

class _PreviewBlock extends StatelessWidget {
  final String title;
  final List<String> lines;

  const _PreviewBlock({
    required this.title,
    required this.lines,
  });

  @override
  Widget build(BuildContext context) {
    if (lines.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 6),
        ...lines.map(
          (line) => Text(
            line,
            style: GoogleFonts.poppins(fontSize: 13),
          ),
        ),
      ],
    );
  }
}