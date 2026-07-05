import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:roofgrid_uk/app/organisation/company_permissions.dart';
import 'package:roofgrid_uk/app/organisation/models/company_role.dart';
import 'package:roofgrid_uk/app/organisation/providers/company_permissions_provider.dart';
import 'package:roofgrid_uk/app/organisation/providers/organisation_provider.dart';
import 'package:roofgrid_uk/models/user_model.dart';
import 'package:roofgrid_uk/widgets/section_header.dart';
import 'package:roofgrid_uk/widgets/results/results_section_header.dart';

class CompanyHubWidget extends ConsumerStatefulWidget {
  final UserModel user;

  const CompanyHubWidget({super.key, required this.user});

  @override
  ConsumerState<CompanyHubWidget> createState() => _CompanyHubWidgetState();
}

class _CompanyHubWidgetState extends ConsumerState<CompanyHubWidget> {
  final _companyNameController = TextEditingController();
  final _inviteEmailController = TextEditingController();
  CompanyRole _inviteRole = CompanyRole.estimator;
  bool _isBusy = false;

  @override
  void dispose() {
    _companyNameController.dispose();
    _inviteEmailController.dispose();
    super.dispose();
  }

  Future<void> _createCompany() async {
    final name = _companyNameController.text.trim();
    if (name.isEmpty) return;
    setState(() => _isBusy = true);
    try {
      await ref.read(organisationServiceProvider).createOrganisation(
            name: name,
            owner: widget.user,
          );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Company created')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }

  Future<void> _inviteMember() async {
    final org = ref.read(currentOrganisationProvider).value;
    if (org == null) return;

    final members = ref.read(orgMembersProvider).value ?? const [];
    final invites = ref.read(orgPendingInvitesProvider).value ?? const [];

    setState(() => _isBusy = true);
    try {
      await ref.read(organisationServiceProvider).inviteMember(
            org: org,
            inviter: widget.user,
            email: _inviteEmailController.text,
            role: _inviteRole,
            currentMemberCount: members.length,
            pendingInviteCount: invites.length,
          );
      _inviteEmailController.clear();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Invite sent')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final orgAsync = ref.watch(currentOrganisationProvider);
    final membership = ref.watch(currentOrgMembershipProvider).value;
    final canManage = ref.watch(canManageCompanyTeamProvider);

    return orgAsync.when(
      data: (org) {
        if (org == null) {
          return _buildCreateCompanyCard();
        }
        return _buildCompanyDashboard(
          orgName: org.name,
          seatLimit: org.seatLimit,
          membership: membership,
          canManage: canManage,
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(child: Text('Error loading company: $error')),
    );
  }

  Widget _buildCreateCompanyCard() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SectionHeader(
                title: 'Company account',
                subtitle:
                    'Create a shared workspace for estimators and installers',
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _companyNameController,
                decoration: const InputDecoration(
                  labelText: 'Company name',
                  hintText: 'e.g. HW Roofing Ltd',
                ),
                textInputAction: TextInputAction.done,
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: _isBusy ? null : _createCompany,
                icon: _isBusy
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.business_outlined),
                label: const Text('Create company'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCompanyDashboard({
    required String orgName,
    required int seatLimit,
    required membership,
    required bool canManage,
  }) {
    final membersAsync = ref.watch(orgMembersProvider);
    final invitesAsync = ref.watch(orgPendingInvitesProvider);
    final roleLabel = membership?.role.label ?? 'Member';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    orgName,
                    style: GoogleFonts.poppins(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Your role: $roleLabel',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  if (membership?.role == CompanyRole.installer) ...[
                    const SizedBox(height: 8),
                    Text(
                      'Installers run set-out from assigned jobs — pricing is hidden.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          const ResultsSectionHeader(title: 'Team'),
          const SizedBox(height: 8),
          membersAsync.when(
            data: (members) => Card(
              child: Column(
                children: members
                    .map(
                      (member) => ListTile(
                        title: Text(
                          member.displayName?.trim().isNotEmpty == true
                              ? member.displayName!
                              : member.email ?? member.userId,
                        ),
                        subtitle: Text(member.role.label),
                        trailing: member.userId == widget.user.id
                            ? const Chip(label: Text('You'))
                            : null,
                      ),
                    )
                    .toList(),
              ),
            ),
            loading: () => const LinearProgressIndicator(),
            error: (error, _) => Text('Could not load team: $error'),
          ),
          if (canManage) ...[
            const SizedBox(height: 16),
            const ResultsSectionHeader(title: 'Invite teammate'),
            const SizedBox(height: 8),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    TextField(
                      controller: _inviteEmailController,
                      decoration: const InputDecoration(
                        labelText: 'Email address',
                      ),
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<CompanyRole>(
                      value: _inviteRole,
                      decoration: const InputDecoration(labelText: 'Role'),
                      items: const [
                        DropdownMenuItem(
                          value: CompanyRole.estimator,
                          child: Text('Estimator — survey & quote'),
                        ),
                        DropdownMenuItem(
                          value: CompanyRole.installer,
                          child: Text('Installer — set-out only'),
                        ),
                      ],
                      onChanged: _isBusy
                          ? null
                          : (value) {
                              if (value != null) {
                                setState(() => _inviteRole = value);
                              }
                            },
                    ),
                    const SizedBox(height: 12),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Seats: ${(membersAsync.value?.length ?? 0) + (invitesAsync.value?.length ?? 0)} / $seatLimit',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                    const SizedBox(height: 12),
                    FilledButton.icon(
                      onPressed: _isBusy ? null : _inviteMember,
                      icon: const Icon(Icons.person_add_outlined),
                      label: const Text('Send invite'),
                    ),
                  ],
                ),
              ),
            ),
            invitesAsync.when(
              data: (invites) {
                if (invites.isEmpty) return const SizedBox.shrink();
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 16),
                    const ResultsSectionHeader(title: 'Pending invites'),
                    const SizedBox(height: 8),
                    Card(
                      child: Column(
                        children: invites
                            .map(
                              (invite) => ListTile(
                                title: Text(invite.email),
                                subtitle: Text(invite.role.label),
                              ),
                            )
                            .toList(),
                      ),
                    ),
                  ],
                );
              },
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
            ),
          ] else ...[
            const SizedBox(height: 12),
            Text(
              CompanyPermissions.canManageTeam(membership?.role)
                  ? ''
                  : 'Team management is available to company owners.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ],
        ],
      ),
    );
  }
}