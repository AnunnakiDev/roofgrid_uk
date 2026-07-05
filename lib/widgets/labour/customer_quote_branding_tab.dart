import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:path_provider/path_provider.dart';
import 'package:roofgrid_uk/app/auth/providers/permissions_provider.dart';
import 'package:roofgrid_uk/app/labour_pricing/models/customer_quote_branding.dart';
import 'package:roofgrid_uk/app/labour_pricing/providers/customer_quote_branding_provider.dart';
import 'package:roofgrid_uk/navigation/nav_utils.dart';

class CustomerQuoteBrandingTab extends ConsumerStatefulWidget {
  const CustomerQuoteBrandingTab({super.key});

  @override
  ConsumerState<CustomerQuoteBrandingTab> createState() =>
      _CustomerQuoteBrandingTabState();
}

class _CustomerQuoteBrandingTabState
    extends ConsumerState<CustomerQuoteBrandingTab> {
  late TextEditingController _companyNameController;
  late TextEditingController _addressController;
  late TextEditingController _phoneController;
  late TextEditingController _emailController;
  late TextEditingController _vatController;
  late TextEditingController _footerController;
  String _logoPath = '';

  @override
  void initState() {
    super.initState();
    _companyNameController = TextEditingController();
    _addressController = TextEditingController();
    _phoneController = TextEditingController();
    _emailController = TextEditingController();
    _vatController = TextEditingController();
    _footerController = TextEditingController();
  }

  @override
  void dispose() {
    _companyNameController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _vatController.dispose();
    _footerController.dispose();
    super.dispose();
  }

  void _syncControllers(CustomerQuoteBranding branding) {
    if (_companyNameController.text != branding.companyName) {
      _companyNameController.text = branding.companyName;
    }
    if (_addressController.text != branding.address) {
      _addressController.text = branding.address;
    }
    if (_phoneController.text != branding.phone) {
      _phoneController.text = branding.phone;
    }
    if (_emailController.text != branding.email) {
      _emailController.text = branding.email;
    }
    if (_vatController.text != branding.vatNumber) {
      _vatController.text = branding.vatNumber;
    }
    if (_footerController.text != branding.quoteFooterNotes) {
      _footerController.text = branding.quoteFooterNotes;
    }
    if (_logoPath != branding.logoAssetPath) {
      _logoPath = branding.logoAssetPath;
    }
  }

  void _persistFromControllers() {
    final branding = CustomerQuoteBranding(
      companyName: _companyNameController.text.trim(),
      address: _addressController.text.trim(),
      phone: _phoneController.text.trim(),
      email: _emailController.text.trim(),
      vatNumber: _vatController.text.trim(),
      quoteFooterNotes: _footerController.text.trim(),
      logoAssetPath: _logoPath,
    );
    ref.read(customerQuoteBrandingProvider.notifier).updateBranding(branding);
  }

  Future<void> _pickLogo() async {
    final result = await FilePicker.pickFiles(type: FileType.image);
    if (result == null || result.files.single.path == null) return;

    final source = File(result.files.single.path!);
    final directory = await getApplicationDocumentsDirectory();
    final logosDir = Directory('${directory.path}/customer_quote_logos');
    if (!await logosDir.exists()) {
      await logosDir.create(recursive: true);
    }
    final fileName =
        'logo_${DateTime.now().millisecondsSinceEpoch}${source.path.contains('.') ? source.path.substring(source.path.lastIndexOf('.')) : '.png'}';
    final destPath = '${logosDir.path}/$fileName';
    await source.copy(destPath);

    setState(() => _logoPath = destPath);
    _persistFromControllers();
  }

  void _removeLogo() {
    setState(() => _logoPath = '');
    _persistFromControllers();
  }

  @override
  Widget build(BuildContext context) {
    final canAccess = ref.watch(canAccessCustomerQuoteProvider);
    final brandingState = ref.watch(customerQuoteBrandingProvider);
    final colorScheme = Theme.of(context).colorScheme;

    if (!canAccess) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Customer Quote branding',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Subscribe to the Customer Quote add-on to save your company '
              'logo and details for branded PDF exports.',
              style: GoogleFonts.poppins(
                fontSize: 13,
                color: colorScheme.onSurfaceVariant,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: () => context.go(customerQuoteUpsellPath),
              icon: const Icon(Icons.workspace_premium_outlined),
              label: const Text('View Customer Quote plans'),
            ),
          ],
        ),
      );
    }

    if (!brandingState.isHydrated) {
      return const Center(child: CircularProgressIndicator());
    }

    _syncControllers(brandingState.branding);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Company branding',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Saved on this device. Used for customer-facing quote PDFs.',
            style: GoogleFonts.poppins(
              fontSize: 13,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 16),
          Center(
            child: Stack(
              children: [
                Container(
                  width: 120,
                  height: 80,
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: colorScheme.outline.withValues(alpha: 0.4),
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  alignment: Alignment.center,
                  child: _logoPath.isNotEmpty && File(_logoPath).existsSync()
                      ? Image.file(File(_logoPath), fit: BoxFit.contain)
                      : Icon(
                          Icons.image_outlined,
                          color: colorScheme.onSurfaceVariant,
                        ),
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: IconButton.filledTonal(
                    onPressed: _pickLogo,
                    icon: const Icon(Icons.upload_file, size: 18),
                    tooltip: 'Upload logo',
                  ),
                ),
              ],
            ),
          ),
          if (_logoPath.isNotEmpty) ...[
            const SizedBox(height: 8),
            Center(
              child: TextButton(
                onPressed: _removeLogo,
                child: const Text('Remove logo'),
              ),
            ),
          ],
          const SizedBox(height: 16),
          TextField(
            controller: _companyNameController,
            decoration: const InputDecoration(
              labelText: 'Company name',
              border: OutlineInputBorder(),
            ),
            onChanged: (_) => _persistFromControllers(),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _addressController,
            decoration: const InputDecoration(
              labelText: 'Address',
              border: OutlineInputBorder(),
            ),
            maxLines: 3,
            onChanged: (_) => _persistFromControllers(),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _phoneController,
            decoration: const InputDecoration(
              labelText: 'Phone',
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.phone,
            onChanged: (_) => _persistFromControllers(),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _emailController,
            decoration: const InputDecoration(
              labelText: 'Email',
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.emailAddress,
            onChanged: (_) => _persistFromControllers(),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _vatController,
            decoration: const InputDecoration(
              labelText: 'VAT number',
              border: OutlineInputBorder(),
            ),
            onChanged: (_) => _persistFromControllers(),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _footerController,
            decoration: const InputDecoration(
              labelText: 'Quote footer notes',
              helperText: 'Payment terms, validity, or standard disclaimers',
              border: OutlineInputBorder(),
            ),
            maxLines: 4,
            onChanged: (_) => _persistFromControllers(),
          ),
        ],
      ),
    );
  }
}