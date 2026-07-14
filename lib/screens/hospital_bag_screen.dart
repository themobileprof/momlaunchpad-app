import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import '../models/hospital_bag_item.dart';
import '../providers/hospital_bag_provider.dart';
import '../services/api_service.dart';
import '../theme/colors.dart';
import '../theme/spacing.dart';
import '../theme/typography.dart';
import '../utils/hospital_bag_share.dart';
import '../widgets/widgets.dart';

/// Hospital / delivery bag checklist with prices, packed state, and sharing.
class HospitalBagScreen extends ConsumerStatefulWidget {
  const HospitalBagScreen({super.key});

  @override
  ConsumerState<HospitalBagScreen> createState() => _HospitalBagScreenState();
}

class _HospitalBagScreenState extends ConsumerState<HospitalBagScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(hospitalBagProvider.notifier).fetchItems());
  }

  Future<void> _shareList() async {
    final state = ref.read(hospitalBagProvider);
    if (state.items.isEmpty) return;
    await SharePlus.instance.share(
      ShareParams(
        text: formatHospitalBagShareText(state.toList()),
        subject: 'Hospital bag checklist',
      ),
    );
  }

  Future<void> _showAddSheet() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _ItemEditorSheet(
        currency: ref.read(hospitalBagProvider).currency,
        onSave: (label, category, price) async {
          try {
            await ref.read(hospitalBagProvider.notifier).addItem(
                  label: label,
                  category: category,
                  price: price,
                );
            if (context.mounted) Navigator.pop(context);
          } on ApiException catch (e) {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(e.message)),
              );
            }
          }
        },
      ),
    );
  }

  Future<void> _showEditSheet(HospitalBagItem item) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _ItemEditorSheet(
        item: item,
        currency: ref.read(hospitalBagProvider).currency,
        onSave: (label, category, price) async {
          try {
            await ref.read(hospitalBagProvider.notifier).updateItem(
                  id: item.id,
                  label: label,
                  category: category,
                  price: price,
                  clearPrice: price == null,
                );
            if (context.mounted) Navigator.pop(context);
          } on ApiException catch (e) {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(e.message)),
              );
            }
          }
        },
        onDelete: () => _confirmDelete(item),
      ),
    );
  }

  Future<void> _confirmDelete(HospitalBagItem item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove item?'),
        content: Text('Remove "${item.label}" from your checklist?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          AppButton(
            label: 'Remove',
            variant: AppButtonVariant.danger,
            isFullWidth: false,
            size: AppButtonSize.small,
            onPressed: () => Navigator.pop(context, true),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    try {
      await ref.read(hospitalBagProvider.notifier).deleteItem(item.id);
      if (mounted) Navigator.pop(context);
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message)),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(hospitalBagProvider);

    return Scaffold(
      backgroundColor: context.appCanvas,
      appBar: MomAppBar(
        pageTitle: 'Hospital bag',
        actions: [
          IconButton(
            tooltip: 'Share checklist',
            onPressed: state.items.isEmpty ? null : _shareList,
            icon: const Icon(Icons.ios_share_rounded),
          ),
        ],
      ),
      body: _buildBody(state),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 80),
        child: NeumorphicButton(
          filled: true,
          borderRadius: 30,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          onPressed: _showAddSheet,
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.add_rounded),
              SizedBox(width: 8),
              Text('Add item'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBody(HospitalBagState state) {
    if (state.isLoading && state.items.isEmpty) {
      return const LoadingState(message: 'Loading your checklist...');
    }

    if (state.error != null && state.items.isEmpty) {
      return ErrorState(
        description: state.error!,
        onRetry: () => ref.read(hospitalBagProvider.notifier).fetchItems(),
      );
    }

    if (state.items.isEmpty) {
      return EmptyState(
        icon: Icons.luggage_outlined,
        title: 'Your bag checklist',
        description:
            'Pack with confidence — track what you need, add prices, and share with your support person.',
        actionLabel: 'Add item',
        onAction: _showAddSheet,
      );
    }

    final grouped = _groupByCategory(state.items);
    final priceFormatter = NumberFormat.currency(
      symbol: _currencySymbol(state.currency),
      decimalDigits: 2,
    );

    return RefreshIndicator(
      onRefresh: () => ref.read(hospitalBagProvider.notifier).fetchItems(),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.spaceMD,
          AppSpacing.spaceSM,
          AppSpacing.spaceMD,
          120,
        ),
        children: [
          _ProgressCard(
            packedCount: state.packedCount,
            totalCount: state.totalCount,
            progress: state.progress,
            totalPrice: state.totalPrice,
            priceLabel: state.totalPrice > 0
                ? priceFormatter.format(state.totalPrice)
                : null,
          ),
          const SizedBox(height: AppSpacing.spaceMD),
          for (final category in HospitalBagCategory.order) ...[
            if ((grouped[category] ?? []).isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.only(
                  left: AppSpacing.spaceXS,
                  bottom: AppSpacing.spaceXS,
                  top: AppSpacing.spaceSM,
                ),
                child: Text(
                  HospitalBagCategory.label(category),
                  style: AppTypography.bodyTextMedium,
                ),
              ),
              ...grouped[category]!.map(
                (item) => _ChecklistTile(
                  item: item,
                  currency: state.currency,
                  onToggle: () => _togglePacked(item),
                  onTap: () => _showEditSheet(item),
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }

  Map<String, List<HospitalBagItem>> _groupByCategory(
    List<HospitalBagItem> items,
  ) {
    final grouped = <String, List<HospitalBagItem>>{};
    for (final item in items) {
      grouped.putIfAbsent(item.category, () => []).add(item);
    }
    return grouped;
  }

  Future<void> _togglePacked(HospitalBagItem item) async {
    try {
      await ref.read(hospitalBagProvider.notifier).togglePacked(item);
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
      );
    }
  }
}

class _ProgressCard extends StatelessWidget {
  final int packedCount;
  final int totalCount;
  final double progress;
  final double totalPrice;
  final String? priceLabel;

  const _ProgressCard({
    required this.packedCount,
    required this.totalCount,
    required this.progress,
    required this.totalPrice,
    this.priceLabel,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.luggage_rounded, color: context.appPrimary),
              const SizedBox(width: AppSpacing.spaceSM),
              Expanded(
                child: Text(
                  '$packedCount of $totalCount packed',
                  style: AppTypography.bodyTextMedium,
                ),
              ),
              if (priceLabel != null)
                Text(
                  priceLabel!,
                  style: AppTypography.caption.copyWith(
                    color: context.appInkSubtle,
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.spaceSM),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: context.appPrimary.withValues(alpha: 0.12),
              color: context.appPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

class _ChecklistTile extends StatelessWidget {
  final HospitalBagItem item;
  final String currency;
  final VoidCallback onToggle;
  final VoidCallback onTap;

  const _ChecklistTile({
    required this.item,
    required this.currency,
    required this.onToggle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final priceLabel = item.price != null
        ? NumberFormat.currency(
            symbol: _currencySymbol(currency),
            decimalDigits: 2,
          ).format(item.price)
        : null;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.spaceXS),
      child: AppCard(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.spaceSM,
          vertical: AppSpacing.spaceXS,
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Row(
            children: [
              Checkbox(
                value: item.isPacked,
                onChanged: (_) => onToggle(),
                activeColor: context.appPrimary,
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.label,
                      style: AppTypography.bodyText.copyWith(
                        decoration: item.isPacked
                            ? TextDecoration.lineThrough
                            : null,
                        color: item.isPacked
                            ? context.appInkSubtle
                            : context.appInk,
                      ),
                    ),
                    if (priceLabel != null)
                      Text(
                        priceLabel,
                        style: AppTypography.caption.copyWith(
                          color: context.appInkSubtle,
                        ),
                      ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: context.appInkSubtle,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ItemEditorSheet extends StatefulWidget {
  final HospitalBagItem? item;
  final String currency;
  final Future<void> Function(String label, String category, double? price)
      onSave;
  final VoidCallback? onDelete;

  const _ItemEditorSheet({
    this.item,
    required this.currency,
    required this.onSave,
    this.onDelete,
  });

  @override
  State<_ItemEditorSheet> createState() => _ItemEditorSheetState();
}

class _ItemEditorSheetState extends State<_ItemEditorSheet> {
  late final TextEditingController _labelController;
  late final TextEditingController _priceController;
  late String _category;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _labelController = TextEditingController(text: widget.item?.label ?? '');
    _priceController = TextEditingController(
      text: widget.item?.price?.toString() ?? '',
    );
    _category = widget.item?.category ?? 'other';
  }

  @override
  void dispose() {
    _labelController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final label = _labelController.text.trim();
    if (label.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter an item name')),
      );
      return;
    }

    final priceText = _priceController.text.trim();
    double? price;
    if (priceText.isNotEmpty) {
      price = double.tryParse(priceText.replaceAll(',', ''));
      if (price == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Enter a valid price')),
        );
        return;
      }
    }

    setState(() => _saving = true);
    try {
      await widget.onSave(label, _category, price);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    final isEditing = widget.item != null;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: GlassContainer(
        opacity: 0.98,
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.spaceMD,
          AppSpacing.spaceMD,
          AppSpacing.spaceMD,
          AppSpacing.spaceLG,
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                isEditing ? 'Edit item' : 'Add item',
                style: AppTypography.headingMedium,
              ),
              const SizedBox(height: AppSpacing.spaceMD),
              TextField(
                controller: _labelController,
                decoration: const InputDecoration(
                  labelText: 'Item name',
                  hintText: 'e.g. Nursing pillow',
                ),
                textCapitalization: TextCapitalization.sentences,
              ),
              const SizedBox(height: AppSpacing.spaceMD),
              DropdownButtonFormField<String>(
                initialValue: _category,
                decoration: const InputDecoration(labelText: 'Category'),
                items: HospitalBagCategory.order
                    .map(
                      (category) => DropdownMenuItem(
                        value: category,
                        child: Text(HospitalBagCategory.label(category)),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value != null) setState(() => _category = value);
                },
              ),
              const SizedBox(height: AppSpacing.spaceMD),
              TextField(
                controller: _priceController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: InputDecoration(
                  labelText: 'Price (optional)',
                  prefixText: _currencySymbol(widget.currency),
                ),
              ),
              const SizedBox(height: AppSpacing.spaceLG),
              AppButton(
                label: isEditing ? 'Save changes' : 'Add to checklist',
                isLoading: _saving,
                onPressed: _saving ? null : _save,
              ),
              if (widget.onDelete != null) ...[
                const SizedBox(height: AppSpacing.spaceSM),
                AppButton(
                  label: 'Remove item',
                  variant: AppButtonVariant.ghost,
                  onPressed: widget.onDelete,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

String _currencySymbol(String currencyCode) {
  switch (currencyCode) {
    case 'NGN':
      return '₦';
    case 'USD':
      return '\$';
    default:
      return currencyCode;
  }
}
