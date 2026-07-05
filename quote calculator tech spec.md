HW ROOFING LABOUR-ONLY
QUOTE TOOL v8
Flutter Module Technical Specification
For Integration into Existing Installation Calculator
Version 1.0 — 04 July 2026
Fully Detailed Build Prompt for Implementation
TABLE OF CONTENTS
1. Project Overview & Goals
2. Architecture & Integration Requirements
3. Core Domain Model
4. Complete User Workflow
5. Key Screens & UI Flows
6. Calculation Engine (Rate-Based + Timing-Based)
7. Material Price List & CSV Import Specification
8. Admin / Base Rates Management Module
9. Paid Customer Quote Module
10. Future Live Supplier Pricing Layer
11. Technical Stack, State Management & Best Practices
12. Testing & Quality Requirements
1. PROJECT OVERVIEW & GOALS
This specification defines a Flutter module for a professional labour-only UK roofing quoting application. The
module will be integrated into an existing installation calculator application.
Core Objectives
• Provide accurate labour pricing and man-day timing estimates for traditional and modern UK roofing
techniques.
• Support multiple independent Roof Sections within a single quote (pitched, flat, lead work, etc.).
• Enable detailed complexity capture via dynamic expandable cards with measurements.
• Offer two parallel calculation methods (Rate-Based and Timing-Based) with clear comparison.
• Include optional structured materials pricing with auto-generated Bill of Quantities (BoQ).
• Provide a clean Admin experience for managing all base rates and the personal Material Price List.
• Include a paid Customer Quote module for professional branded PDF output.
• Design for future additive live supplier pricing integration (paid).
• Maintain excellent offline capability with optional online enhancements.
Key Constraints
• Must integrate cleanly into an existing Flutter installation calculator.
• Core labour functionality must work fully offline.
• Material Price List is personal to each user (local persistence + CSV import/export).
• Customer Quote features and future live pricing are paid add-ons (gated by feature flag).
• All rates and timings must be fully editable by the end user via Admin.
2. ARCHITECTURE & INTEGRATION REQUIREMENTS
The module should be designed as a self-contained Flutter feature/package that can be integrated into the
existing app via navigation, dependency injection, or modular routing.
Recommended Structure
• Use clean architecture (domain / data / presentation layers).
• State management: Riverpod (recommended) or Bloc/Cubit.
• Persistence: Hive or Isar for complex objects + shared_preferences for simple settings.
• CSV handling: Use the `csv` package + `file_picker` for import.
• PDF generation (for Customer Quote): Use `pdf` package (or `printing` + `pdf`).
• Feature flag for paid module: Simple boolean in local storage (can be upgraded later to license key system).
Integration Points with Existing Calculator
• Expose a clear entry point (e.g. `RoofingQuoteModule` or route).
• Allow passing initial job/customer data from the host app.
• Provide callbacks or streams for when a quote is saved/finalised so the host app can react.
• Share theming where possible with the existing app.
3. CORE DOMAIN MODEL (Recommended)
The following data models are recommended. Adapt as needed for your existing app's architecture.
Key Entities
Quote / Project: Top-level object containing customer details, list of RoofSections, project-level
adjustments, and metadata.
RoofSection: One independent area (e.g. Main Roof, Extension Flat Roof). Contains covering type, area,
pitch, complexity features, linear items, ancillaries, materials, and calculated results.
ComplexityFeature: A selected feature (Dormer, Chimney, etc.) with quantity and list of measurements per
instance.
Measurement: Per-face or per-instance data (width, height, pitch, upstand height, etc.).
MaterialLine: A material item in a section (linked to MaterialPriceList entry or custom). Includes quantity
(suggested + user override).
RateSet: All pricing and timing data for one roof type (strip/install rates, linear rates, ancillary rates, hours).
MaterialPriceEntry: Entry in the user's personal price list (with coverage data for auto BoQ).
Note: Store RateSets and the Material Price List in a central repository (e.g. Riverpod provider or repository layer) so
changes in Admin immediately affect open quotes.
4. COMPLETE USER WORKFLOW
1. Start New Quote → Enter customer details once at project level.
2. Add one or more Roof Sections.
3. For each section: Configure covering type, area, pitch, and Complexity Features (dynamic expandable
cards with measurements).
4. Project Material Specification: Select main materials from the structured price list. System auto-suggests
quantities.
5. Per-section Materials: Use project defaults or override. Review/adjust suggested BoQ quantities. Add
extra materials.
6. Review live calculations (Rate-Based including materials + Timing-Based) per section and project totals.
7. Apply project-level adjustments (miles, overnight, contingencies).
8. View internal breakdown or generate paid Customer Quote (with logo + company details if unlocked).
9. Save quote, load previous quotes, or export data.
5. KEY SCREENS & UI FLOWS (Recommended)
Project Dashboard: List of sections, quick totals, Add Section button, Project Materials button.
Section Editor: All fields for one section + expandable Complexity cards + Materials panel.
Complexity Feature Cards: Dynamic cards that appear based on selections in Category 3. Support
multiple faces/measurements.
Materials Panel: Project defaults + per-section override mode + ability to add extra lines. Shows suggested
vs actual quantities.
Calculations View: Side-by-side Rate-Based vs Timing-Based results with breakdown.
Admin / Settings: Tabbed interface for Rates, Timing, Day Rates, Material Price List (with CSV
import/export), Reset to Defaults.
Customer Quote Preview (Paid): Professional preview + PDF export with logo and company branding.
6. CALCULATION ENGINE
Two parallel methods must always be calculated and displayed. Materials only affect the Rate-Based method.
Rate-Based Method (includes Materials)
For each section:
Base Labour = (Strip m² × rate) + (Install m² × rate × slateMultiplier)
+ Σ (Linear qty × rate)
+ Σ (Ancillary qty × rate)
+ Σ (Material qty × unitPrice)
Apply section uplifts → Section Direct/Sub Total
Timing-Based Method (Labour Hours Only)
Total Man-Hours = (stripQty × hoursStrip) + (installQty × hoursInstall)
+ Σ (linearQty × hoursPerLM) + Σ (ancillaryQty × hoursPerUnit)
+ extra hours derived from complexity feature measurements
totalDays = ceil(TotalManHours / (8 × gangSize))
Timing Cost = totalDays × dayRatePerMan × gangSize
Important: The system must clearly display both results and allow the user to select which one to use for the final
quote total.
7. MATERIAL PRICE LIST & CSV IMPORT SPECIFICATION
CSV Import Requirements (Mandatory)
The Admin must provide a clear Import from CSV button for the Material Price List.
CSV Format Specification:
Column Required Description / Example
Category Yes TilesSlates, Underlay, LeadFlashings, Ventilation, FlatRoof, Solar,
Structural, Other
Description Yes Full product name/description
Unit Yes m2, lm, each, roll, piece, kg, etc.
CoveragePerUnit Yes Numeric value used for auto BoQ (e.g. 10 for tiles per m2, 3 for
ridge lm per piece)
WastePercent No (default
7.5)
Default waste allowance %
UnitPrice Yes Numeric price per unit
Notes No Supplier, code, colour, etc.
The import must validate required columns, handle duplicates gracefully (update or skip), and show a clear
summary of imported/updated/skipped rows.
8. ADMIN / BASE RATES MANAGEMENT MODULE
A dedicated, well-organised Admin area is critical. Use tabs or a clean sidebar navigation.
• Pricing Rates — Editable tables for Strip and Install rates per roof type (Direct & Sub).
• Linear Items — All groups with rates (including permanent Lead Work and Flat Roof items).
• Ancillaries — All items with rates.
• Timing (Man-Hours) — Hours per m², per lm, per unit + extra complexity hours.
• Day Rates & Config — Full/Half day rates, working hours, miles, overnight, default uplifts.
• Material Price List — Full management + CSV Import / Export buttons + search.
• Reset to Defaults — One-click restore of researched 2026 default values (with confirmation).
All changes in Admin should immediately reflect in any open quotes (reactive updates).

9. PAID CUSTOMER QUOTE MODULE

9.1 Purpose
The Customer Quote add-on provides a professional, customer-facing quotation separate from the internal labour breakdown PDF. It is gated independently from the labour calculator but requires labour access first.

9.2 Entitlement & Gating
• `labourCalculatorActive` — unlocks the labour pricing module (or admin role).
• `customerQuoteActive` — unlocks branded preview and PDF export (requires labour access).
• Flags are stored on the Firestore `users/{uid}` document and mirrored in `UserModel`.
• Pre-launch testing: admins can toggle both flags in User Management without Stripe.
• At launch: Stripe Checkout plan `customerQuote` sets `customerQuoteActive` via webhook.

9.3 Routes (go_router)
• `/labour-calculator` — main quote editor (upsell redirect if not entitled).
• `/labour-calculator/upsell` — labour add-on purchase screen.
• `/customer-quote` — redirects to preview (parent route has no builder).
• `/customer-quote/preview` — branded quote preview and PDF export.
• `/customer-quote/upsell` — customer quote add-on purchase screen.

9.4 Branding Storage
• `CustomerQuoteBranding` model: company name, address, phone, email, VAT number, footer notes, optional logo bytes.
• Persisted per user in Hive via `CustomerQuoteBrandingStorage`.
• Edited in Profile → Labour Rates → Customer Quote branding tab.

9.5 Branded PDF Output
• `LabourQuotePdfExporter.generateBrandedBytes()` produces an A4 customer PDF.
• Includes: company header (logo optional), quotation date/ref, customer & site, quoted works per section with totals, materials specification BoQ table (description, qty, unit, unit price, line total), terms/notes footer.
• Material costs are noted as included in the quoted labour total where applicable.
• Internal PDF (`generateBytes()`) retains full Method A/B breakdown for office use.

9.6 Checkout Integration
• `createCustomerQuoteCheckoutSessionUrl()` → POST `/createCheckoutSession` with `plan: "customerQuote"`.
• Server requires Bearer ID token and active labour add-on (or admin).
• Returns 503 until `STRIPE_CUSTOMER_QUOTE_PRICE_ID` is configured in production.

9.7 Host Handoff
• `LabourCalculatorRouteArgs` passed via GoRouter `extra` supports:
  - `initialProject` / `initialQuoteConfig` from saved set-out jobs
  - `importJobId` for traceability
  - `onQuoteSaved` callback when a quote is persisted

10. FUTURE LIVE SUPPLIER PRICING LAYER

10.1 Design Intent
The current Material Price List is personal, offline-first, and CSV-driven. A future paid layer would overlay live supplier pricing without replacing local persistence.

10.2 Recommended Architecture (not yet implemented)
• Supplier adapter interface: `fetchPrices(categories, region)` returning normalised `MaterialPriceEntry` rows.
• Merge strategy: local entries win on conflict unless user opts into live override per line.
• Cache TTL in Hive (e.g. 24 h) with stale indicator in the Materials panel.
• Entitlement flag: `liveSupplierPricingActive` (parallel to labour/customer quote flags).
• Rate-limit and offline fallback: always fall back to cached/local price list.

10.3 Integration Points
• `BoqSuggestionService` — swap or augment unit prices from live feed after quantity suggestion.
• Admin Materials tab — “Refresh from supplier” action with diff summary (updated / unchanged / failed).
• Customer Quote PDF — optional “Prices valid as of {date}” footer when live data used.

11. TECHNICAL STACK, STATE MANAGEMENT & BEST PRACTICES

11.1 Stack (as implemented in RoofGrid UK)
• Flutter (mobile, web, desktop)
• Riverpod for state (`labourPricingProvider`, `labourMaterialsProvider`, `labourQuotesProvider`, `customerQuoteBrandingProvider`)
• go_router for navigation and entitlement redirects (`resolveAppRedirect`)
• Hive for offline persistence (rates, materials, saved quotes, branding)
• `pdf` package for PDF export
• `csv` + `file_picker` for material CSV import
• Firebase Auth + Firestore for user entitlements
• Cloud Functions (Express on Gen 2) for Stripe checkout and webhooks

11.2 Module Layout
```
lib/app/labour_pricing/
  models/          — domain types (project, section, materials, branding)
  providers/       — Riverpod notifiers
  services/        — engine, storage, PDF, BoQ, validation, defaults
lib/screens/labour/ — calculator, preview, upsell screens + widgets
lib/widgets/labour/ — shared UI (materials tab, branding tab)
lib/utils/         — checkout helpers, API client, decimal input utils
```

11.3 API Client
• `roofgridApiConfig.dart` — production base URL with `--dart-define=ROOFGRID_API_BASE` override for emulator.
• `roofgridApiClient.dart` — authenticated HTTP POST with Firebase ID token Bearer header.
• Emulator (Android): `http://10.0.2.2:5002/roofgriduk-f2f56/us-central1/api`

11.4 Security
• Checkout endpoints verify Bearer token server-side (`verifyAuthFromRequest`); never trust `uid` in request body.
• Firestore rules block self-updates to privileged fields (`role`, add-on flags, subscription fields) unless admin or allowed Pro trial upgrade.
• Stripe webhook uses `express.raw()` and `STRIPE_WEBHOOK_SECRET` env var.
• Secrets live in `functions/.env` locally only; production via Cloud Run env (set at launch).

11.5 UX Conventions
• Decimal fields use `LabourDecimalTextField` / `LabourIntTextField` to avoid `1.0` overwrite on rebuild.
• Section reorder via drag handles; complexity UI is dynamic per roof type.
• Permissions checked via `permissionsProvider` — labour and customer quote are independent of set-out Pro.

12. TESTING & QUALITY REQUIREMENTS

12.1 Test Gate
Run before any deploy:
```
flutter test
flutter build web --release
```

12.2 Test Coverage Areas (implemented)
| Area | Test files |
|------|------------|
| Pricing engine (dual method, materials in Method A) | `labour_pricing_engine_test`, `labour_dual_method_test`, `labour_materials_engine_test` |
| Complexity & linear catalogs | `labour_complexity_catalog_test`, `labour_linear_catalog_test`, `labour_complexity_integration_test` |
| Multi-section projects | `labour_multi_section_test`, `labour_section_reorder_test`, `labour_section_method_test` |
| Materials & BoQ | `labour_materials_storage_test`, `material_csv_service_test`, `boq_suggestion_service_test` |
| Offline persistence | `labour_config_storage_test`, `labour_quotes_storage_test`, `labour_offline_readiness_test` |
| Permissions & routing | `labour_permissions_test`, `app_bottom_nav_test`, `customer_quote_permissions_test` |
| Customer quote UI/PDF | `customer_quote_preview_screen_test`, `customer_quote_pdf_exporter_test`, `customer_quote_branding_storage_test` |
| Set-out handoff | `saved_result_labour_adapter_test` |
| Decimal inputs | `decimal_input_utils_test` |
| Admin | `admin_utils_test`, `admin_analytics_utils_test` |
| Labour quote cloud sync | `labour_quotes_sync_test`, `labour_quotes_sync_queue_test`, `labour_quotes_firestore_service_test`, `labour_quotes_analytics_test`, `npm run test:firestore-rules` |
| Org job ↔ quote linking | `labour_quote_job_link_test`, `org_job_test` |

12.3 Manual Smoke Checklist (pre-launch)
1. Admin toggles labour + customer quote on test user.
2. Create multi-section quote with complexity and materials CSV import.
3. Verify Method A vs B totals update live.
4. Export internal PDF and branded customer PDF (with BoQ if materials present).
5. Save quote, reload, confirm Hive persistence offline.
6. Import from saved set-out result into labour calculator.
7. Confirm upsell screens appear for unentitled users.

12.5 Cloud sync architecture (labour quotes)

**Path:** `users/{uid}/labour_quotes/{quoteId}`

**Local-first:** Hive (`labourQuotesBox`) is the UI source of truth. Firestore is backup and multi-device restore.

**Merge policy (on login / refresh):**
1. Key quotes by `id`
2. Newest `savedAt` wins per id; equal timestamps prefer remote
3. After merge, upload local-only or newer-local quotes

**Offline queue (Phase 2):** Failed save/delete ops are stored in Hive under `pendingSync` as `LabourQuoteSyncEntry` (`save` | `delete`). `flushPendingSync()` runs on reconnect, login refresh, and app resume.

**Entitlement:** Firestore rules require `labourCalculatorActive == true` on the owner’s user doc (admin bypass). Verified by `npm run test:firestore-rules`.

**Job linking:** Saving a quote with `sourceJobId` sets `linkedQuoteId` on the saved result and org job (best-effort). Deleting a quote clears stale links.

**Analytics events:**
- `sync_labour_quote` — `{ operation, quote_id }`
- `sync_labour_quote_failed` — `{ operation, quote_id, reason? }`

12.4 Launch Checklist (deferred)
1. Rotate Stripe secret key.
2. Create Stripe products/prices for labour and customer quote add-ons.
3. Set Cloud Run env vars (`STRIPE_*`, `STRIPE_WEBHOOK_SECRET`).
4. `firebase deploy --only "functions,firestore:rules"`
5. Configure Stripe webhook → `/stripeWebhook`.
6. End-to-end test checkout in Stripe test mode.
