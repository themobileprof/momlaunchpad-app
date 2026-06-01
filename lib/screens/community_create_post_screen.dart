import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/community.dart';
import '../providers/community_provider.dart';
import '../providers/service_providers.dart';
import '../theme/colors.dart';
import '../theme/spacing.dart';
import '../theme/typography.dart';
import '../widgets/online_image_url_list_editor.dart';
import '../widgets/widgets.dart';

class CommunityCreatePostScreen extends ConsumerStatefulWidget {
  final CommunityComposeMode mode;

  const CommunityCreatePostScreen({
    super.key,
    this.mode = CommunityComposeMode.post,
  });

  @override
  ConsumerState<CommunityCreatePostScreen> createState() =>
      _CommunityCreatePostScreenState();
}

class _CommunityCreatePostScreenState
    extends ConsumerState<CommunityCreatePostScreen> {
  final _bodyController = TextEditingController();
  final _eventTitleController = TextEditingController();
  final _eventVenueController = TextEditingController();
  bool _isAnonymous = false;
  String? _eventType;
  List<CommunityCatalogItem> _eventTypes = [];
  DateTime? _eventStartsAt;
  bool _submitting = false;
  List<String> _imageUrls = [];

  bool get _isEventMode => widget.mode == CommunityComposeMode.event;

  @override
  void initState() {
    super.initState();
    if (_isEventMode) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _loadEventTypes());
    }
  }

  Future<void> _loadEventTypes() async {
    try {
      final types = await ref.read(apiServiceProvider).getCommunityEventTypes();
      if (!mounted) return;
      setState(() {
        _eventTypes = types;
        _eventType = types.isNotEmpty ? types.first.key : null;
      });
    } catch (_) {}
  }

  @override
  void dispose() {
    _bodyController.dispose();
    _eventTitleController.dispose();
    _eventVenueController.dispose();
    super.dispose();
  }

  Future<void> _pickEventDate() async {
    final date = await showDatePicker(
      context: context,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      initialDate: _eventStartsAt ?? DateTime.now(),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_eventStartsAt ?? DateTime.now()),
    );
    if (time == null || !mounted) return;
    setState(() {
      _eventStartsAt = DateTime(date.year, date.month, date.day, time.hour, time.minute);
    });
  }

  Future<void> _submit() async {
    final body = _bodyController.text.trim();
    if (body.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _isEventMode
                ? 'Describe your event so others know what to expect'
                : 'Write something to share',
          ),
        ),
      );
      return;
    }

    CreateEventPayload? event;
    if (_isEventMode) {
      final title = _eventTitleController.text.trim();
      if (title.isEmpty || _eventStartsAt == null || _eventType == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Add event type, title, and start time')),
        );
        return;
      }
      event = CreateEventPayload(
        eventType: _eventType!,
        title: title,
        venue: _eventVenueController.text.trim().isEmpty
            ? null
            : _eventVenueController.text.trim(),
        startsAt: _eventStartsAt!,
      );
    }

    setState(() => _submitting = true);
    final post = await ref.read(communityProvider.notifier).createPost(
          CreatePostPayload(
            body: body,
            isAnonymous: _isAnonymous,
            event: event,
            imageUrls: _imageUrls,
          ),
        );
    if (!mounted) return;
    setState(() => _submitting = false);
    if (post != null) {
      Navigator.pop(context, post);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.appCanvas,
      appBar: MomAppBar(pageTitle: _isEventMode ? 'New event' : 'New post'),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.spaceMD,
          AppSpacing.spaceSM,
          AppSpacing.spaceMD,
          120,
        ),
        children: [
          Text(
            _isEventMode
                ? 'Events appear in the Events tab with date, venue, and RSVP. '
                    'Use the description for details moms should know before joining.'
                : 'Use **bold**, *italic*, - bullets, and [links](https://example.com). '
                    'AI will categorize your post automatically.',
            style: AppTypography.caption.copyWith(color: AppColors.textLight),
          ),
          const SizedBox(height: AppSpacing.spaceMD),
          if (_isEventMode) ...[
            DropdownButtonFormField<String>(
              value: _eventType,
              decoration: const InputDecoration(labelText: 'Event type'),
              items: _eventTypes
                  .map((t) => DropdownMenuItem(value: t.key, child: Text(t.label)))
                  .toList(),
              onChanged: (v) => setState(() => _eventType = v),
            ),
            const SizedBox(height: AppSpacing.spaceSM),
            TextField(
              controller: _eventTitleController,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(labelText: 'Event title'),
            ),
            const SizedBox(height: AppSpacing.spaceSM),
            TextField(
              controller: _eventVenueController,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(labelText: 'Venue (optional)'),
            ),
            const SizedBox(height: AppSpacing.spaceSM),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(
                _eventStartsAt == null
                    ? 'Pick start date & time'
                    : _eventStartsAt!.toLocal().toString(),
              ),
              trailing: const Icon(Icons.calendar_today_outlined),
              onTap: _pickEventDate,
            ),
            const SizedBox(height: AppSpacing.spaceMD),
            Text(
              'Description',
              style: AppTypography.bodyTextMedium.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: AppSpacing.spaceXS),
          ],
          TextField(
            controller: _bodyController,
            minLines: 5,
            maxLines: 12,
            decoration: InputDecoration(
              hintText: _isEventMode
                  ? 'What happens at this event? Who is it for?'
                  : 'Share with the community…',
              filled: true,
              fillColor: context.appSurface,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
            ),
          ),
          if (!_isEventMode) ...[
            const SizedBox(height: AppSpacing.spaceMD),
            OnlineImageUrlListEditor(
              onChanged: (urls) => _imageUrls = urls,
            ),
          ],
          const SizedBox(height: AppSpacing.spaceMD),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Post as Anonymous Mom'),
            subtitle: const Text('Moderators can still see your account'),
            value: _isAnonymous,
            onChanged: (v) => setState(() => _isAnonymous = v),
          ),
          const SizedBox(height: AppSpacing.spaceXL),
          GradientButton(
            onPressed: _submitting ? null : _submit,
            isLoading: _submitting,
            label: _isEventMode ? 'Publish event' : 'Post',
          ),
        ],
      ),
    );
  }
}
