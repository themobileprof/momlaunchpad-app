import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import '../models/facility_admin.dart';
import '../models/journey_stage.dart';
import '../providers/profile_provider.dart';
import '../providers/service_providers.dart';
import '../services/api_service.dart';
import '../theme/colors.dart';
import '../theme/spacing.dart';
import '../theme/typography.dart';
import '../widgets/widgets.dart';
import 'community_onboarding_screen.dart';

enum _DashTab { overview, members, broadcast, team }

/// Health-center admin: verification request → multi-admin dashboard.
class FacilityAdminScreen extends ConsumerStatefulWidget {
  const FacilityAdminScreen({super.key});

  @override
  ConsumerState<FacilityAdminScreen> createState() =>
      _FacilityAdminScreenState();
}

class _FacilityAdminScreenState extends ConsumerState<FacilityAdminScreen> {
  List<FacilityAdminClaim> _claims = [];
  List<FacilityAdminClaim> _approved = [];
  String _selectedFacilityId = '';
  List<FacilityMember> _members = [];
  int _memberTotal = 0;
  List<FacilityAnnouncement> _announcements = [];
  List<FacilityAdminPeer> _admins = [];
  _DashTab _tab = _DashTab.overview;
  String _memberQuery = '';

  bool _loading = true;
  bool _dashLoading = false;
  bool _busy = false;
  String? _error;
  String? _message;

  final _roleController = TextEditingController();
  final _proofNoteController = TextEditingController();
  final _proofUrlController = TextEditingController();
  final _announceTitleController = TextEditingController();
  final _announceBodyController = TextEditingController();
  final _memberSearchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    Future.microtask(_loadClaims);
  }

  @override
  void dispose() {
    _roleController.dispose();
    _proofNoteController.dispose();
    _proofUrlController.dispose();
    _announceTitleController.dispose();
    _announceBodyController.dispose();
    _memberSearchController.dispose();
    super.dispose();
  }

  Future<void> _loadClaims() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final me = await ref.read(apiServiceProvider).getMyFacilityAdmin();
      if (!mounted) return;
      setState(() {
        _claims = me.claims;
        _approved = me.approved;
        if (_selectedFacilityId.isEmpty ||
            !me.approved.any((c) => c.healthcareFacilityId == _selectedFacilityId)) {
          _selectedFacilityId =
              me.approved.isNotEmpty ? me.approved.first.healthcareFacilityId : '';
        }
      });
      if (_selectedFacilityId.isNotEmpty) {
        await _loadFacilityData(_selectedFacilityId);
      }
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _error = e.message);
    } catch (_) {
      if (!mounted) return;
      setState(() => _error = 'Could not load facility admin status');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _loadFacilityData(String facilityId) async {
    setState(() => _dashLoading = true);
    try {
      final api = ref.read(apiServiceProvider);
      final members = await api.listFacilityMembers(facilityId);
      final anns = await api.listFacilityAnnouncements(facilityId);
      final admins = await api.listFacilityAdmins(facilityId);
      if (!mounted) return;
      setState(() {
        _members = members.members;
        _memberTotal = members.total;
        _announcements = anns;
        _admins = admins;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _error = e.message);
    } catch (_) {
      if (!mounted) return;
      setState(() => _error = 'Could not load center data');
    } finally {
      if (mounted) setState(() => _dashLoading = false);
    }
  }

  Future<void> _submitClaim() async {
    final profile = ref.read(profileProvider).profile;
    final facilityId = profile?.healthcareFacilityId;
    if (facilityId == null || facilityId.isEmpty) {
      setState(() => _error = 'Choose your health center in community location first.');
      return;
    }
    if (_roleController.text.trim().isEmpty ||
        _proofNoteController.text.trim().isEmpty) {
      setState(() => _error = 'Add your role and how we can verify you.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
      _message = null;
    });
    try {
      await ref.read(apiServiceProvider).createFacilityAdminClaim(
            healthcareFacilityId: facilityId,
            roleTitle: _roleController.text.trim(),
            proofNote: _proofNoteController.text.trim(),
            proofUrl: _proofUrlController.text.trim(),
          );
      _roleController.clear();
      _proofNoteController.clear();
      _proofUrlController.clear();
      if (!mounted) return;
      setState(() => _message = 'Request sent — MomLaunchpad will review shortly.');
      await _loadClaims();
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _error = e.message);
    } catch (_) {
      if (!mounted) return;
      setState(() => _error = 'Could not submit claim');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _sendAnnouncement() async {
    if (_selectedFacilityId.isEmpty) return;
    final title = _announceTitleController.text.trim();
    final body = _announceBodyController.text.trim();
    if (title.isEmpty || body.isEmpty) return;
    setState(() {
      _busy = true;
      _error = null;
      _message = null;
    });
    try {
      final ann = await ref.read(apiServiceProvider).createFacilityAnnouncement(
            facilityId: _selectedFacilityId,
            title: title,
            body: body,
          );
      _announceTitleController.clear();
      _announceBodyController.clear();
      if (!mounted) return;
      setState(() {
        _message =
            'Announcement delivered to ${ann.recipientCount} member(s).';
        _tab = _DashTab.broadcast;
      });
      final anns = await ref
          .read(apiServiceProvider)
          .listFacilityAnnouncements(_selectedFacilityId);
      if (!mounted) return;
      setState(() => _announcements = anns);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _error = e.message);
    } catch (_) {
      if (!mounted) return;
      setState(() => _error = 'Could not send announcement');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _messageMember(FacilityMember member) async {
    final titleController = TextEditingController();
    final bodyController = TextEditingController();
    final sent = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(ctx).bottom),
          child: GlassContainer(
            opacity: 0.98,
            padding: const EdgeInsets.all(AppSpacing.spaceMD),
            child: SafeArea(
              top: false,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Message ${member.displayName}',
                    style: AppTypography.headingSmall,
                  ),
                  const SizedBox(height: AppSpacing.spaceSM),
                  Text(
                    'Delivered to their MomLaunchpad inbox · up to 30 direct messages per day for this center',
                    style: AppTypography.caption.copyWith(
                      color: context.appInkSubtle,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.spaceMD),
                  AppTextField(
                    controller: titleController,
                    label: 'Subject',
                    maxLength: 200,
                  ),
                  const SizedBox(height: AppSpacing.spaceMD),
                  AppTextField(
                    controller: bodyController,
                    label: 'Message',
                    maxLines: 4,
                    maxLength: 2000,
                  ),
                  const SizedBox(height: AppSpacing.spaceMD),
                  GradientButton(
                    label: 'Send message',
                    onPressed: () {
                      if (titleController.text.trim().isEmpty ||
                          bodyController.text.trim().isEmpty) {
                        return;
                      }
                      Navigator.pop(ctx, true);
                    },
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(ctx, false),
                    child: const Text('Cancel'),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );

    final title = titleController.text.trim();
    final body = bodyController.text.trim();
    titleController.dispose();
    bodyController.dispose();
    if (sent != true || title.isEmpty || body.isEmpty) return;

    setState(() {
      _busy = true;
      _error = null;
      _message = null;
    });
    try {
      await ref.read(apiServiceProvider).sendFacilityDirectMessage(
            facilityId: _selectedFacilityId,
            memberUserId: member.userId,
            title: title,
            body: body,
          );
      if (!mounted) return;
      setState(() => _message = 'Message sent to their MomLaunchpad inbox.');
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _error = e.message);
    } catch (_) {
      if (!mounted) return;
      setState(() => _error = 'Could not send message');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _shareWhatsApp(String phone) async {
    final digits = phone.replaceAll(RegExp(r'\D'), '');
    if (digits.isEmpty) return;
    await SharePlus.instance.share(ShareParams(text: 'https://wa.me/$digits'));
  }

  String _journeyLabel(String? stage) {
    if (stage == null || stage.isEmpty) return '';
    return JourneyStage.fromApi(stage)?.label ?? stage;
  }

  String _formatWhen(DateTime dt) =>
      DateFormat.yMMMd().add_jm().format(dt.toLocal());

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return '?';
    if (parts.length == 1) {
      return parts.first.substring(0, parts.first.length.clamp(0, 2)).toUpperCase();
    }
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(profileProvider).profile;
    final selected = _approved
        .cast<FacilityAdminClaim?>()
        .firstWhere(
          (c) => c?.healthcareFacilityId == _selectedFacilityId,
          orElse: () => null,
        );
    final facilityId = profile?.healthcareFacilityId;
    final claimForProfile = _claims
        .cast<FacilityAdminClaim?>()
        .firstWhere(
          (c) => c?.healthcareFacilityId == facilityId,
          orElse: () => null,
        );
    final hasPending = claimForProfile?.status == 'pending';
    final alreadyApproved =
        _approved.any((c) => c.healthcareFacilityId == facilityId);
    final isDashboard = _approved.isNotEmpty && selected != null;
    final optedIn =
        _members.where((m) => m.facilityAnnouncementsOptIn).length;
    final q = _memberQuery.trim().toLowerCase();
    final filteredMembers = q.isEmpty
        ? _members
        : _members.where((m) {
            final hay = [
              m.displayName,
              m.city,
              m.phoneNumber,
              _journeyLabel(m.journeyStage),
            ].whereType<String>().join(' ').toLowerCase();
            return hay.contains(q);
          }).toList();

    return Scaffold(
      appBar: MomAppBar(
        pageTitle: isDashboard
            ? (selected.facilityName ?? 'Center dashboard')
            : 'Health center admin',
      ),
      body: _loading
          ? const LoadingState(message: 'Loading your admin access…')
          : RefreshIndicator(
              onRefresh: _loadClaims,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.spaceMD,
                  AppSpacing.spaceMD,
                  AppSpacing.spaceMD,
                  120,
                ),
                children: [
                  if (_error != null) _banner(_error!, isError: true),
                  if (_message != null) _banner(_message!, isError: false),
                  if (isDashboard)
                    ..._buildDashboard(
                      selected: selected,
                      optedIn: optedIn,
                      filteredMembers: filteredMembers,
                    )
                  else
                    ..._buildAccessFlow(
                      profileFacilityName: profile?.healthcareFacilityName,
                      profileCity: profile?.city,
                      hasFacility: facilityId != null && facilityId.isNotEmpty,
                      claim: claimForProfile,
                      hasPending: hasPending,
                      canRequest: facilityId != null &&
                          facilityId.isNotEmpty &&
                          !alreadyApproved &&
                          !hasPending,
                    ),
                  if (isDashboard &&
                      facilityId != null &&
                      facilityId.isNotEmpty &&
                      !alreadyApproved &&
                      !hasPending) ...[
                    const SizedBox(height: AppSpacing.spaceLG),
                    Text('Also manage your community center?',
                        style: AppTypography.caption),
                    const SizedBox(height: AppSpacing.spaceSM),
                    _claimCard(
                      title: 'Request admin for ${profile?.healthcareFacilityName}',
                      subtitle:
                          'Multiple staff can be approved for the same center.',
                    ),
                  ],
                ],
              ),
            ),
    );
  }

  List<Widget> _buildAccessFlow({
    required String? profileFacilityName,
    required String? profileCity,
    required bool hasFacility,
    required FacilityAdminClaim? claim,
    required bool hasPending,
    required bool canRequest,
  }) {
    return [
      Text(
        'FOR HEALTH CENTER STAFF',
        style: AppTypography.caption.copyWith(
          color: context.appPrimary,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.8,
        ),
      ),
      const SizedBox(height: AppSpacing.spaceSM),
      Text(
        'Reach the moms who chose your center',
        style: AppTypography.headingMedium,
      ),
      const SizedBox(height: AppSpacing.spaceSM),
      Text(
        'Request verification once. After approval, you and your colleagues get a shared dashboard for roster, broadcasts, and one-to-one check-ins — without seeing clinical records.',
        style: AppTypography.bodyText.copyWith(color: context.appInkSubtle),
      ),
      const SizedBox(height: AppSpacing.spaceLG),
      _step(1, 'Select your health center in community location',
          done: hasFacility, current: !hasFacility),
      _step(2, 'Request admin with your role and proof',
          done: hasPending || claim?.status == 'approved',
          current: hasFacility && !hasPending && claim?.status != 'approved'),
      _step(3, 'MomLaunchpad reviews — then your dashboard unlocks',
          done: claim?.status == 'approved', current: hasPending),
      const SizedBox(height: AppSpacing.spaceLG),
      if (!hasFacility)
        AppCard(
          padding: const EdgeInsets.all(AppSpacing.spaceMD),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Choose your center first', style: AppTypography.headingSmall),
              const SizedBox(height: AppSpacing.spaceSM),
              Text(
                'Admins are tied to a real facility. Multiple staff can request the same center.',
                style: AppTypography.bodyText,
              ),
              const SizedBox(height: AppSpacing.spaceMD),
              GradientButton(
                label: 'Open community location',
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const CommunityOnboardingScreen(),
                    ),
                  );
                },
              ),
            ],
          ),
        )
      else if (hasPending)
        AppCard(
          padding: const EdgeInsets.all(AppSpacing.spaceMD),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _statusChip('Pending review', Colors.orange.shade800,
                  Colors.orange.shade50),
              const SizedBox(height: AppSpacing.spaceSM),
              Text(profileFacilityName ?? 'Health center',
                  style: AppTypography.headingSmall),
              const SizedBox(height: AppSpacing.spaceSM),
              Text(
                '${profileCity != null && profileCity.isNotEmpty ? '$profileCity · ' : ''}We are verifying your request. This usually takes 1–2 business days.',
                style: AppTypography.bodyText
                    .copyWith(color: context.appInkSubtle),
              ),
            ],
          ),
        )
      else if (canRequest)
        _claimCard(
          title: 'Request access',
          subtitle:
              '$profileFacilityName${profileCity != null && profileCity.isNotEmpty ? ' · $profileCity' : ''}\n\nTell us who you are at this center. Colleagues can request separately.',
        ),
      if (_claims.isNotEmpty) ...[
        const SizedBox(height: AppSpacing.spaceLG),
        Text('Your requests', style: AppTypography.caption),
        const SizedBox(height: AppSpacing.spaceSM),
        ..._claims.map(
          (c) => Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.spaceSM),
            child: AppCard(
              padding: const EdgeInsets.all(AppSpacing.spaceMD),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(c.facilityName ?? 'Health center',
                            style: AppTypography.bodyTextMedium),
                        if (c.roleTitle != null)
                          Text(c.roleTitle!,
                              style: AppTypography.caption.copyWith(
                                color: context.appInkSubtle,
                              )),
                        if (c.adminNote != null && c.adminNote!.isNotEmpty)
                          Text(c.adminNote!,
                              style: AppTypography.caption.copyWith(
                                color: context.appInkSubtle,
                              )),
                      ],
                    ),
                  ),
                  _statusChip(c.statusLabel, _statusColor(c.status),
                      _statusBg(c.status)),
                ],
              ),
            ),
          ),
        ),
      ],
    ];
  }

  List<Widget> _buildDashboard({
    required FacilityAdminClaim selected,
    required int optedIn,
    required List<FacilityMember> filteredMembers,
  }) {
    return [
      if (_approved.length > 1) ...[
        Text('Your centers', style: AppTypography.caption),
        const SizedBox(height: AppSpacing.spaceSM),
        DropdownButtonFormField<String>(
          initialValue: _selectedFacilityId.isEmpty ? null : _selectedFacilityId,
          items: _approved
              .map(
                (c) => DropdownMenuItem(
                  value: c.healthcareFacilityId,
                  child: Text(
                    c.facilityName ?? 'Center',
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              )
              .toList(),
          onChanged: (value) async {
            if (value == null) return;
            setState(() {
              _selectedFacilityId = value;
              _tab = _DashTab.overview;
              _memberQuery = '';
              _memberSearchController.clear();
            });
            await _loadFacilityData(value);
          },
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: AppSpacing.spaceMD),
      ] else ...[
        Text('APPROVED ADMIN',
            style: AppTypography.caption.copyWith(
              color: context.appPrimary,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
            )),
        const SizedBox(height: AppSpacing.spaceXS),
        Text(selected.facilityName ?? 'Health center',
            style: AppTypography.headingMedium),
        const SizedBox(height: AppSpacing.spaceXS),
      ],
      Text(
        [
          selected.facilityCity,
          selected.facilityStateProvince,
          selected.roleTitle,
        ].whereType<String>().where((s) => s.isNotEmpty).join(' · '),
        style: AppTypography.caption.copyWith(color: context.appInkSubtle),
      ),
      const SizedBox(height: AppSpacing.spaceMD),
      Row(
        children: [
          _statTile('$_memberTotal', 'Members'),
          _statTile('$optedIn', 'Opted-in'),
          _statTile('${_admins.length}', 'Admins'),
          _statTile('${_announcements.length}', 'Broadcasts'),
        ],
      ),
      const SizedBox(height: AppSpacing.spaceMD),
      SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: _DashTab.values.map((t) {
            final label = switch (t) {
              _DashTab.overview => 'Overview',
              _DashTab.members => 'Members',
              _DashTab.broadcast => 'Broadcast',
              _DashTab.team => 'Team',
            };
            final selectedTab = _tab == t;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                label: Text(label),
                selected: selectedTab,
                onSelected: (_) => setState(() => _tab = t),
              ),
            );
          }).toList(),
        ),
      ),
      const SizedBox(height: AppSpacing.spaceMD),
      if (_dashLoading)
        const Padding(
          padding: EdgeInsets.all(24),
          child: Center(child: CircularProgressIndicator()),
        )
      else
        ...switch (_tab) {
          _DashTab.overview => [
              _quickTile(
                'View roster',
                '$_memberTotal moms linked this center',
                () => setState(() => _tab = _DashTab.members),
              ),
              _quickTile(
                'Send broadcast',
                '3 per week · opted-in only',
                () => setState(() => _tab = _DashTab.broadcast),
              ),
              _quickTile(
                'Admin team',
                '${_admins.length} approved admin${_admins.length == 1 ? '' : 's'}',
                () => setState(() => _tab = _DashTab.team),
              ),
              const SizedBox(height: AppSpacing.spaceMD),
              Text('Recent broadcasts', style: AppTypography.headingSmall),
              const SizedBox(height: AppSpacing.spaceSM),
              if (_announcements.isEmpty)
                Text(
                  'No announcements yet. Start with a short ANC reminder.',
                  style: AppTypography.bodyText
                      .copyWith(color: context.appInkSubtle),
                )
              else
                ..._announcements.take(3).map(_announcementTile),
              const SizedBox(height: AppSpacing.spaceMD),
              Text(
                'Privacy: you see who chose this center and contact details they shared — not chat content or clinical notes.',
                style: AppTypography.caption
                    .copyWith(color: context.appInkSubtle),
              ),
            ],
          _DashTab.members => [
              AppTextField(
                controller: _memberSearchController,
                label: 'Search members',
                hint: 'Name, city, or journey…',
                onChanged: (v) => setState(() => _memberQuery = v),
              ),
              const SizedBox(height: AppSpacing.spaceMD),
              if (filteredMembers.isEmpty)
                Text(
                  _memberQuery.isEmpty
                      ? 'No one has registered this center yet. Ask patients to pick it during community setup.'
                      : 'No members match that search.',
                  style: AppTypography.bodyText
                      .copyWith(color: context.appInkSubtle),
                )
              else
                ...filteredMembers.map(_memberTile),
            ],
          _DashTab.broadcast => [
              AppCard(
                padding: const EdgeInsets.all(AppSpacing.spaceMD),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text('Broadcast to opted-in members',
                        style: AppTypography.headingSmall),
                    const SizedBox(height: AppSpacing.spaceMD),
                    AppTextField(
                      controller: _announceTitleController,
                      label: 'Title',
                      maxLength: 200,
                    ),
                    const SizedBox(height: AppSpacing.spaceMD),
                    AppTextField(
                      controller: _announceBodyController,
                      label: 'Message',
                      maxLines: 4,
                      maxLength: 2000,
                    ),
                    Text(
                      'Limit 3 per center per week · $optedIn currently opted in',
                      style: AppTypography.caption
                          .copyWith(color: context.appInkSubtle),
                    ),
                    const SizedBox(height: AppSpacing.spaceMD),
                    GradientButton(
                      label: _busy ? 'Sending…' : 'Send in-app announcement',
                      isLoading: _busy,
                      onPressed: _busy ? null : _sendAnnouncement,
                    ),
                  ],
                ),
              ),
              if (_announcements.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.spaceLG),
                Text('History', style: AppTypography.caption),
                const SizedBox(height: AppSpacing.spaceSM),
                ..._announcements.map(_announcementTile),
              ],
            ],
          _DashTab.team => [
              AppCard(
                padding: const EdgeInsets.all(AppSpacing.spaceMD),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Multiple admins welcome',
                        style: AppTypography.headingSmall),
                    const SizedBox(height: AppSpacing.spaceSM),
                    Text(
                      'Any verified staff member can request access for this center. Everyone approved shares the same roster and broadcast tools.',
                      style: AppTypography.bodyText
                          .copyWith(color: context.appInkSubtle),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.spaceMD),
              ..._admins.map(
                (a) => Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.spaceSM),
                  child: AppCard(
                    padding: const EdgeInsets.all(AppSpacing.spaceMD),
                    child: Row(
                      children: [
                        CircleAvatar(
                          backgroundColor:
                              context.appPrimary.withValues(alpha: 0.12),
                          foregroundColor: context.appPrimary,
                          child: Text(_initials(a.displayName),
                              style: const TextStyle(fontWeight: FontWeight.w700)),
                        ),
                        const SizedBox(width: AppSpacing.spaceMD),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(a.displayName,
                                  style: AppTypography.bodyTextMedium),
                              Text(
                                [
                                  a.roleTitle ?? 'Admin',
                                  'since ${_formatWhen(a.approvedAt)}',
                                ].join(' · '),
                                style: AppTypography.caption.copyWith(
                                  color: context.appInkSubtle,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
        },
    ];
  }

  Widget _claimCard({required String title, required String subtitle}) {
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.spaceMD),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(title, style: AppTypography.headingSmall),
          const SizedBox(height: AppSpacing.spaceSM),
          Text(subtitle,
              style:
                  AppTypography.bodyText.copyWith(color: context.appInkSubtle)),
          const SizedBox(height: AppSpacing.spaceMD),
          AppTextField(
            controller: _roleController,
            label: 'Your role at the center',
            hint: 'e.g. Matron, Community midwife, Admin',
          ),
          const SizedBox(height: AppSpacing.spaceMD),
          AppTextField(
            controller: _proofNoteController,
            label: 'How we can verify you',
            hint: 'Work email, staff ID, or how patients know you',
            maxLines: 3,
          ),
          const SizedBox(height: AppSpacing.spaceMD),
          AppTextField(
            controller: _proofUrlController,
            label: 'Optional verification link',
            hint: 'https://',
          ),
          const SizedBox(height: AppSpacing.spaceMD),
          GradientButton(
            label: _busy ? 'Submitting…' : 'Submit for verification',
            isLoading: _busy,
            onPressed: _busy ? null : _submitClaim,
          ),
        ],
      ),
    );
  }

  Widget _step(int n, String label,
      {required bool done, required bool current}) {
    final color = done
        ? Colors.green.shade700
        : current
            ? context.appPrimary
            : context.appInkSubtle;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.spaceSM),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 26,
            height: 26,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: current
                  ? context.appPrimary
                  : done
                      ? Colors.green.shade50
                      : context.appPrimary.withValues(alpha: 0.08),
            ),
            child: Text(
              '$n',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: current ? Colors.white : color,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: AppTypography.bodyText.copyWith(
                color: color,
                fontWeight: current ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _statTile(String value, String label) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.only(right: 6),
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
        decoration: BoxDecoration(
          color: context.appSurface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: context.appPrimary.withValues(alpha: 0.12),
          ),
        ),
        child: Column(
          children: [
            Text(value,
                style: AppTypography.bodyTextMedium
                    .copyWith(color: context.appPrimary)),
            Text(label,
                style: AppTypography.caption.copyWith(
                  fontSize: 10,
                  color: context.appInkSubtle,
                )),
          ],
        ),
      ),
    );
  }

  Widget _quickTile(String title, String subtitle, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.spaceSM),
      child: Material(
        color: context.appSurface,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: onTap,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSpacing.spaceMD),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: context.appPrimary.withValues(alpha: 0.14),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTypography.bodyTextMedium),
                const SizedBox(height: 4),
                Text(subtitle,
                    style: AppTypography.caption
                        .copyWith(color: context.appInkSubtle)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _memberTile(FacilityMember m) {
    final journey = _journeyLabel(m.journeyStage);
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.spaceSM),
      child: AppCard(
        padding: const EdgeInsets.all(AppSpacing.spaceMD),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              backgroundColor: context.appPrimary.withValues(alpha: 0.12),
              foregroundColor: context.appPrimary,
              child: Text(_initials(m.displayName),
                  style: const TextStyle(fontWeight: FontWeight.w700)),
            ),
            const SizedBox(width: AppSpacing.spaceMD),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(m.displayName, style: AppTypography.bodyTextMedium),
                  Text(
                    [m.city, journey].whereType<String>().where((s) => s.isNotEmpty).join(' · '),
                    style: AppTypography.caption
                        .copyWith(color: context.appInkSubtle),
                  ),
                  if (m.phoneNumber != null && m.phoneNumber!.isNotEmpty)
                    TextButton(
                      onPressed: () => _shareWhatsApp(m.phoneNumber!),
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: Text('WhatsApp ${m.phoneNumber}'),
                    )
                  else
                    Text('No phone on file',
                        style: AppTypography.caption
                            .copyWith(color: context.appInkSubtle)),
                  if (!m.facilityAnnouncementsOptIn)
                    Text('Opted out of broadcasts',
                        style: AppTypography.caption
                            .copyWith(color: context.appInkSubtle)),
                  const SizedBox(height: AppSpacing.spaceSM),
                  OutlinedButton(
                    onPressed: _busy ? null : () => _messageMember(m),
                    child: const Text('Message'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _announcementTile(FacilityAnnouncement a) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.spaceSM),
      child: AppCard(
        padding: const EdgeInsets.all(AppSpacing.spaceMD),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(a.title, style: AppTypography.bodyTextMedium),
            const SizedBox(height: 4),
            Text(
              '${_formatWhen(a.createdAt)} · ${a.recipientCount} recipient${a.recipientCount == 1 ? '' : 's'}',
              style:
                  AppTypography.caption.copyWith(color: context.appInkSubtle),
            ),
            const SizedBox(height: 6),
            Text(a.body, style: AppTypography.bodyText),
          ],
        ),
      ),
    );
  }

  Widget _statusChip(String label, Color fg, Color bg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: fg,
          letterSpacing: 0.3,
        ),
      ),
    );
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'approved':
        return Colors.green.shade800;
      case 'pending':
        return Colors.orange.shade800;
      case 'rejected':
        return Colors.red.shade800;
      default:
        return context.appInkSubtle;
    }
  }

  Color _statusBg(String status) {
    switch (status) {
      case 'approved':
        return Colors.green.shade50;
      case 'pending':
        return Colors.orange.shade50;
      case 'rejected':
        return Colors.red.shade50;
      default:
        return context.appPrimary.withValues(alpha: 0.08);
    }
  }

  Widget _banner(String text, {required bool isError}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.spaceMD),
      child: AppCard(
        padding: const EdgeInsets.all(AppSpacing.spaceMD),
        child: Text(
          text,
          style: AppTypography.bodyText.copyWith(
            color: isError
                ? Theme.of(context).colorScheme.error
                : context.appPrimary,
          ),
        ),
      ),
    );
  }
}
