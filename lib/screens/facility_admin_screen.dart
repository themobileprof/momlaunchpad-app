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

/// Health-center admin: claim, roster, broadcasts, and 1:1 inbox messages.
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
  bool _loading = true;
  bool _busy = false;
  String? _error;
  String? _message;

  final _roleController = TextEditingController();
  final _proofNoteController = TextEditingController();
  final _proofUrlController = TextEditingController();
  final _announceTitleController = TextEditingController();
  final _announceBodyController = TextEditingController();

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
        if (_selectedFacilityId.isEmpty && me.approved.isNotEmpty) {
          _selectedFacilityId = me.approved.first.healthcareFacilityId;
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
    try {
      final api = ref.read(apiServiceProvider);
      final members = await api.listFacilityMembers(facilityId);
      final anns = await api.listFacilityAnnouncements(facilityId);
      if (!mounted) return;
      setState(() {
        _members = members.members;
        _memberTotal = members.total;
        _announcements = anns;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _error = e.message);
    } catch (_) {
      if (!mounted) return;
      setState(() => _error = 'Could not load center data');
    }
  }

  Future<void> _submitClaim() async {
    final profile = ref.read(profileProvider).profile;
    final facilityId = profile?.healthcareFacilityId;
    if (facilityId == null || facilityId.isEmpty) {
      setState(() =>
          _error = 'Complete community setup and select your health center first.');
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
      setState(() => _message = 'Claim submitted for review.');
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
      setState(() =>
          _message = 'Announcement sent to ${ann.recipientCount} member(s).');
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
          padding: EdgeInsets.only(
            bottom: MediaQuery.viewInsetsOf(ctx).bottom,
          ),
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
                    'Goes to their MomLaunchpad inbox. Limit 30 direct messages per day for this center.',
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
                    label: 'Send',
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
      setState(() => _message = 'Message sent to member inbox.');
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
    await SharePlus.instance.share(
      ShareParams(text: 'https://wa.me/$digits'),
    );
  }

  String _journeyLabel(String? stage) {
    if (stage == null || stage.isEmpty) return '';
    return JourneyStage.fromApi(stage)?.label ?? stage;
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(profileProvider).profile;
    final selected = _approved
        .where((c) => c.healthcareFacilityId == _selectedFacilityId)
        .firstOrNull;
    final facilityId = profile?.healthcareFacilityId;
    final hasPending = facilityId != null &&
        _claims.any(
          (c) =>
              c.healthcareFacilityId == facilityId && c.status == 'pending',
        );
    final alreadyApproved = facilityId != null &&
        _approved.any((c) => c.healthcareFacilityId == facilityId);

    return Scaffold(
      appBar: const MomAppBar(pageTitle: 'Health center admin'),
      body: _loading
          ? const LoadingState(message: 'Loading…')
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
                  Text(
                    'Claim your health center, see who registered it, send center-wide announcements, or message one member at a time.',
                    style: AppTypography.bodyText.copyWith(
                      color: context.appInkSubtle,
                    ),
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: AppSpacing.spaceMD),
                    _banner(_error!, isError: true),
                  ],
                  if (_message != null) ...[
                    const SizedBox(height: AppSpacing.spaceMD),
                    _banner(_message!, isError: false),
                  ],
                  const SizedBox(height: AppSpacing.spaceLG),
                  Text('Claim your center', style: AppTypography.caption),
                  const SizedBox(height: AppSpacing.spaceSM),
                  AppCard(
                    padding: const EdgeInsets.all(AppSpacing.spaceMD),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (profile?.healthcareFacilityName != null) ...[
                          Text.rich(
                            TextSpan(
                              style: AppTypography.bodyText,
                              children: [
                                const TextSpan(text: 'Your community center: '),
                                TextSpan(
                                  text: profile!.healthcareFacilityName!,
                                  style: AppTypography.bodyTextMedium,
                                ),
                                if (profile.city != null &&
                                    profile.city!.isNotEmpty)
                                  TextSpan(text: ' · ${profile.city}'),
                              ],
                            ),
                          ),
                        ] else ...[
                          Text(
                            'Set your health center in community location before claiming admin access.',
                            style: AppTypography.bodyText,
                          ),
                          const SizedBox(height: AppSpacing.spaceSM),
                          OutlinedButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      const CommunityOnboardingScreen(),
                                ),
                              );
                            },
                            child: const Text('Community location'),
                          ),
                        ],
                        const SizedBox(height: AppSpacing.spaceMD),
                        if (alreadyApproved)
                          Text(
                            'You are an approved admin for this center.',
                            style: AppTypography.caption.copyWith(
                              color: context.appInkSubtle,
                            ),
                          )
                        else if (hasPending)
                          Text(
                            'Your claim is pending MomLaunchpad review.',
                            style: AppTypography.caption.copyWith(
                              color: context.appInkSubtle,
                            ),
                          )
                        else if (facilityId != null && facilityId.isNotEmpty) ...[
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
                            label: _busy
                                ? 'Submitting…'
                                : 'Request health center admin',
                            isLoading: _busy,
                            onPressed: _busy ? null : _submitClaim,
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (_claims.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.spaceLG),
                    Text('Your claims', style: AppTypography.caption),
                    const SizedBox(height: AppSpacing.spaceSM),
                    AppCard(
                      padding: const EdgeInsets.all(AppSpacing.spaceMD),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: _claims
                            .map(
                              (c) => Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: Text.rich(
                                  TextSpan(
                                    style: AppTypography.bodyText,
                                    children: [
                                      TextSpan(
                                        text: c.facilityName ?? 'Health center',
                                        style: AppTypography.bodyTextMedium,
                                      ),
                                      TextSpan(text: ' — ${c.statusLabel}'),
                                      if (c.adminNote != null &&
                                          c.adminNote!.isNotEmpty)
                                        TextSpan(
                                          text: ' · ${c.adminNote}',
                                          style: AppTypography.caption.copyWith(
                                            color: context.appInkSubtle,
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                            )
                            .toList(),
                      ),
                    ),
                  ],
                  if (_approved.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.spaceLG),
                    Text('Your centers', style: AppTypography.caption),
                    const SizedBox(height: AppSpacing.spaceSM),
                    AppCard(
                      padding: const EdgeInsets.all(AppSpacing.spaceMD),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (_approved.length > 1) ...[
                            DropdownButtonFormField<String>(
                              initialValue: _selectedFacilityId.isEmpty
                                  ? null
                                  : _selectedFacilityId,
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
                                setState(() => _selectedFacilityId = value);
                                await _loadFacilityData(value);
                              },
                              decoration: const InputDecoration(
                                labelText: 'Center',
                                border: OutlineInputBorder(),
                              ),
                            ),
                            const SizedBox(height: AppSpacing.spaceMD),
                          ],
                          if (selected != null)
                            Text(
                              [
                                selected.facilityName ?? 'Health center',
                                if (selected.facilityCity != null &&
                                    selected.facilityCity!.isNotEmpty)
                                  selected.facilityCity!,
                                '$_memberTotal member${_memberTotal == 1 ? '' : 's'} on MomLaunchpad',
                              ].join(' · '),
                              style: AppTypography.bodyTextMedium,
                            ),
                          const SizedBox(height: AppSpacing.spaceLG),
                          Text(
                            'Broadcast to all',
                            style: AppTypography.headingSmall,
                          ),
                          const SizedBox(height: AppSpacing.spaceMD),
                          AppTextField(
                            controller: _announceTitleController,
                            label: 'Announcement title',
                            hint: 'e.g. Antenatal class this Thursday',
                            maxLength: 200,
                          ),
                          const SizedBox(height: AppSpacing.spaceMD),
                          AppTextField(
                            controller: _announceBodyController,
                            label: 'Message',
                            hint:
                                'Keep it short — members see this in their inbox.',
                            maxLines: 4,
                            maxLength: 2000,
                          ),
                          const SizedBox(height: AppSpacing.spaceSM),
                          Text(
                            'Limit: 3 announcements per center per week. Only members who opted in receive broadcasts.',
                            style: AppTypography.caption.copyWith(
                              color: context.appInkSubtle,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.spaceMD),
                          GradientButton(
                            label: _busy
                                ? 'Sending…'
                                : 'Send in-app announcement',
                            isLoading: _busy,
                            onPressed: _busy ? null : _sendAnnouncement,
                          ),
                        ],
                      ),
                    ),
                    if (_announcements.isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.spaceLG),
                      Text(
                        'Recent announcements',
                        style: AppTypography.caption,
                      ),
                      const SizedBox(height: AppSpacing.spaceSM),
                      AppCard(
                        padding: const EdgeInsets.all(AppSpacing.spaceMD),
                        child: Column(
                          children: [
                            for (var i = 0; i < _announcements.length; i++) ...[
                              if (i > 0) const Divider(height: 24),
                              _announcementTile(_announcements[i]),
                            ],
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: AppSpacing.spaceLG),
                    Text(
                      'Members ($_memberTotal)',
                      style: AppTypography.caption,
                    ),
                    const SizedBox(height: AppSpacing.spaceSM),
                    AppCard(
                      padding: const EdgeInsets.all(AppSpacing.spaceMD),
                      child: _members.isEmpty
                          ? Text(
                              'No one has registered this center yet. Ask patients to pick it during community setup.',
                              style: AppTypography.bodyText.copyWith(
                                color: context.appInkSubtle,
                              ),
                            )
                          : Column(
                              children: [
                                for (var i = 0; i < _members.length; i++) ...[
                                  if (i > 0) const Divider(height: 24),
                                  _memberTile(_members[i]),
                                ],
                              ],
                            ),
                    ),
                  ],
                ],
              ),
            ),
    );
  }

  Widget _banner(String text, {required bool isError}) {
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.spaceMD),
      child: Text(
        text,
        style: AppTypography.bodyText.copyWith(
          color: isError
              ? Theme.of(context).colorScheme.error
              : context.appPrimary,
        ),
      ),
    );
  }

  Widget _announcementTile(FacilityAnnouncement a) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(a.title, style: AppTypography.bodyTextMedium),
          const SizedBox(height: 4),
          Text(
            '${DateFormat.yMMMd().add_jm().format(a.createdAt.toLocal())} · ${a.recipientCount} recipient${a.recipientCount == 1 ? '' : 's'}',
            style: AppTypography.caption.copyWith(color: context.appInkSubtle),
          ),
          const SizedBox(height: 6),
          Text(a.body, style: AppTypography.bodyText),
        ],
      ),
    );
  }

  Widget _memberTile(FacilityMember m) {
    final journey = _journeyLabel(m.journeyStage);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text.rich(
          TextSpan(
            style: AppTypography.bodyText,
            children: [
              TextSpan(
                text: m.displayName,
                style: AppTypography.bodyTextMedium,
              ),
              if (m.city != null && m.city!.isNotEmpty)
                TextSpan(
                  text: ' · ${m.city}',
                  style: TextStyle(color: context.appInkSubtle),
                ),
              if (journey.isNotEmpty)
                TextSpan(
                  text: ' · $journey',
                  style: TextStyle(color: context.appInkSubtle),
                ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        if (m.phoneNumber != null && m.phoneNumber!.isNotEmpty)
          TextButton.icon(
            onPressed: () => _shareWhatsApp(m.phoneNumber!),
            icon: const Icon(Icons.chat_outlined, size: 18),
            label: Text('WhatsApp ${m.phoneNumber}'),
            style: TextButton.styleFrom(
              padding: EdgeInsets.zero,
              alignment: Alignment.centerLeft,
            ),
          )
        else
          Text(
            'No phone on file',
            style: AppTypography.caption.copyWith(color: context.appInkSubtle),
          ),
        if (!m.facilityAnnouncementsOptIn)
          Text(
            'Opted out of announcements',
            style: AppTypography.caption.copyWith(color: context.appInkSubtle),
          ),
        const SizedBox(height: AppSpacing.spaceSM),
        OutlinedButton(
          onPressed: _busy ? null : () => _messageMember(m),
          child: const Text('Message in app'),
        ),
      ],
    );
  }
}
