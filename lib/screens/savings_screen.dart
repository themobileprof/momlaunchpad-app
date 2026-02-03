import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../theme/colors.dart';
import '../theme/spacing.dart';
import '../theme/typography.dart';
import '../models/savings_summary.dart';
import '../models/savings_entry.dart';
import '../providers/savings_provider.dart';
import '../widgets/premium_upsell_dialog.dart';
import '../widgets/widgets.dart';

/// Savings screen with EDD, goal tracking, and entries
class SavingsScreen extends ConsumerStatefulWidget {
  const SavingsScreen({super.key});

  @override
  ConsumerState<SavingsScreen> createState() => _SavingsScreenState();
}

class _SavingsScreenState extends ConsumerState<SavingsScreen> {
  @override
  void initState() {
    super.initState();
    // Fetch savings data on load
    Future.microtask(() => ref.read(savingsProvider.notifier).fetchSavingsData());
  }

  @override
  Widget build(BuildContext context) {
    final savingsState = ref.watch(savingsProvider);
    final summary = savingsState.summary;

    return Scaffold(
      appBar: AppBar(
        title: Text('Savings', style: AppTypography.headingMedium),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => _showSettingsDialog(context),
          ),
        ],
      ),
      body: savingsState.isLoading
          ? const Center(child: CircularProgressIndicator())
          : savingsState.error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.error_outline,
                        size: 64,
                        color: AppColors.error,
                      ),
                      const SizedBox(height: AppSpacing.spaceMD),
                      Text(
                        'Failed to load savings',
                        style: AppTypography.bodyText.copyWith(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: AppSpacing.spaceSM),
                      Text(
                        savingsState.error!,
                        style: AppTypography.caption.copyWith(
                          color: AppColors.textLight,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: AppSpacing.spaceLG),
                      if (savingsState.error!.contains('premium subscription'))
                        ElevatedButton.icon(
                          onPressed: () {
                             showDialog(
                              context: context,
                              builder: (context) => const PremiumUpsellDialog(featureName: 'Savings Tracker'),
                            );
                          },
                          icon: const Icon(Icons.star),
                          label: const Text('Upgrade'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primaryPurple,
                            foregroundColor: Colors.white,
                          ),
                        )
                      else
                        ElevatedButton.icon(
                          onPressed: () => ref.read(savingsProvider.notifier).fetchSavingsData(),
                          icon: const Icon(Icons.refresh),
                          label: const Text('Retry'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primaryPink,
                            foregroundColor: Colors.white,
                          ),
                        ),
                    ],
                  ),
                )
              : summary == null
                  ? const Center(child: Text('No savings data available'))
                  : RefreshIndicator(
                      onRefresh: () => ref.read(savingsProvider.notifier).fetchSavingsData(),
                      child: ListView(
                        padding: const EdgeInsets.only(
                          top: AppSpacing.spaceMD,
                          left: AppSpacing.spaceMD,
                          right: AppSpacing.spaceMD,
                          bottom: 120, // Space for floating navbar
                        ),
                        children: [
                          // Summary card
                          _buildSummaryCard(summary),
                          const SizedBox(height: AppSpacing.spaceLG),
                          
                          // Entries section
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Recent Entries', style: AppTypography.headingMedium),
                              TextButton.icon(
                                onPressed: () => _showAddEntryDialog(context),
                                icon: const Icon(Icons.add),
                                label: const Text('Add'),
                                style: TextButton.styleFrom(
                                  foregroundColor: AppColors.primaryPink,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.spaceMD),
                          
                          if (savingsState.entries.isEmpty)
                            Center(
                              child: Padding(
                                padding: const EdgeInsets.all(AppSpacing.spaceXL),
                                child: Text(
                                  'No entries yet',
                                  style: AppTypography.caption,
                                ),
                              ),
                            )
                          else
                            ...savingsState.entries.map((entry) => _buildEntryCard(entry, summary.currency)),
                        ],
                      ),
                    ),
      floatingActionButton: summary != null
          ? Padding(
              padding: const EdgeInsets.only(bottom: 80.0), // Raise above updated nav
              child: NeumorphicButton(
                onPressed: () => _showAddEntryDialog(context),
                height: 56,
                width: 56,
                borderRadius: 28,
                color: AppColors.primaryPink,
                padding: EdgeInsets.zero,
                child: const Icon(Icons.add_rounded, color: Colors.white),
              ),
            )
          : null,
    );
  }

  Widget _buildSummaryCard(SavingsSummary summary) {
    final currencySymbol = _getCurrencySymbol(summary.currency);
    final formatter = NumberFormat.currency(symbol: currencySymbol, decimalDigits: 2);
    
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.spaceLG),
        child: Column(
          children: [
            // Progress circle
            Center(
              child: SizedBox(
                width: 150,
                height: 150,
                child: Stack(
                  children: [
                    CircularProgressIndicator(
                      value: summary.progressPercentage / 100,
                      strokeWidth: 12,
                      backgroundColor: AppColors.textLight.withOpacity(0.2),
                      valueColor: const AlwaysStoppedAnimation<Color>(AppColors.success),
                    ),
                    Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            '${summary.progressPercentage.toStringAsFixed(1)}%',
                            style: AppTypography.headingLarge.copyWith(
                              color: AppColors.primaryPurple,
                            ),
                          ),
                          Text(
                            'saved',
                            style: AppTypography.caption,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.spaceLG),
            
            // Stats
            _buildStatRow('Total Saved', formatter.format(summary.totalSaved)),
            const SizedBox(height: AppSpacing.spaceMD),
            _buildStatRow('Goal', formatter.format(summary.savingsGoal)),
            const SizedBox(height: AppSpacing.spaceMD),
            if (summary.expectedDeliveryDate != null) ...[
              _buildStatRow(
                'Days Until Delivery',
                '${summary.daysUntilDelivery} days',
              ),
              const SizedBox(height: AppSpacing.spaceSM),
              Text(
                'EDD: ${DateFormat('MMM dd, yyyy').format(summary.expectedDeliveryDate!)}',
                style: AppTypography.caption.copyWith(
                  color: AppColors.textLight,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: AppTypography.bodyText),
        Text(
          value,
          style: AppTypography.bodyText.copyWith(
            fontWeight: FontWeight.w600,
            color: AppColors.primaryPurple,
          ),
        ),
      ],
    );
  }

  Widget _buildEntryCard(SavingsEntry entry, String currency) {
    final currencySymbol = _getCurrencySymbol(currency);
    final formatter = NumberFormat.currency(symbol: currencySymbol, decimalDigits: 2);
    
    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.spaceMD),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.spaceMD),
        child: Row(
          children: [
            Container(
              width: 4,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.success,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: AppSpacing.spaceMD),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    entry.description,
                    style: AppTypography.bodyText.copyWith(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: AppSpacing.spaceXS),
                  Text(
                    DateFormat('MMM dd, yyyy').format(entry.entryDate),
                    style: AppTypography.caption,
                  ),
                ],
              ),
            ),
            Text(
              formatter.format(entry.amount),
              style: AppTypography.bodyText.copyWith(
                fontWeight: FontWeight.w600,
                color: AppColors.success,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddEntryDialog(BuildContext context) {
    final amountController = TextEditingController();
    final descriptionController = TextEditingController();
    
    // Get current currency
    final currency = ref.read(savingsProvider).summary?.currency ?? 'NGN';
    final currencySymbol = _getCurrencySymbol(currency);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Savings Entry'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: amountController,
              decoration: InputDecoration(
                labelText: 'Amount',
                prefixText: currencySymbol,
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
            ),
            const SizedBox(height: AppSpacing.spaceMD),
            TextField(
              controller: descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final amount = double.tryParse(amountController.text);
              if (amount != null && descriptionController.text.isNotEmpty) {
                try {
                  await ref.read(savingsProvider.notifier).addEntry(
                        amount: amount,
                        description: descriptionController.text,
                      );
                  if (context.mounted) Navigator.pop(context);
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Failed to add entry: $e')),
                    );
                  }
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryPink,
              foregroundColor: Colors.white,
            ),
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _showSettingsDialog(BuildContext context) {
    final goalController = TextEditingController();
    DateTime? selectedDate;
    String? selectedCurrency;
    
    // Get current values
    final summary = ref.read(savingsProvider).summary;
    if (summary != null) {
      goalController.text = summary.savingsGoal.toString();
      selectedDate = summary.expectedDeliveryDate;
      selectedCurrency = summary.currency;
    }
    
    // Helper for currency options
    final currencies = {
      'NGN': 'Nigerian Naira (₦)',
      'USD': 'US Dollar (\$)',
      'EUR': 'Euro (€)',
      'GBP': 'British Pound (£)',
    };
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Settings'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: goalController,
                  decoration: InputDecoration(
                    labelText: 'Savings Goal',
                    prefixText: _getCurrencySymbol(selectedCurrency ?? 'NGN'),
                  ),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                ),
                const SizedBox(height: AppSpacing.spaceMD),
                
                DropdownButtonFormField<String>(
                  value: selectedCurrency,
                  decoration: const InputDecoration(labelText: 'Currency'),
                  items: currencies.entries.map((e) {
                    return DropdownMenuItem(value: e.key, child: Text(e.value));
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) setState(() => selectedCurrency = value);
                  },
                ),
                const SizedBox(height: AppSpacing.spaceMD),

                ElevatedButton.icon(
                  onPressed: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: selectedDate ?? DateTime.now(),
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (date != null) {
                      setState(() => selectedDate = date);
                    }
                  },
                  icon: const Icon(Icons.calendar_today),
                  label: Text(selectedDate != null 
                    ? 'EDD: ${DateFormat('MMM dd, yyyy').format(selectedDate!)}'
                    : 'Set Expected Delivery Date'
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                try {
                  final goal = double.tryParse(goalController.text);
                  
                  // Update all changed fields
                  if (goal != null && goal != summary?.savingsGoal) {
                    await ref.read(savingsProvider.notifier).updateGoal(goal);
                  }
                  if (selectedDate != summary?.expectedDeliveryDate) {
                    await ref.read(savingsProvider.notifier).updateEDD(selectedDate);
                  }
                  if (selectedCurrency != null && selectedCurrency != summary?.currency) {
                    await ref.read(savingsProvider.notifier).updateCurrency(selectedCurrency!);
                  }
                  
                  if (context.mounted) Navigator.pop(context);
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Failed to update: $e')),
                    );
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryPink,
                foregroundColor: Colors.white,
              ),
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  String _getCurrencySymbol(String currencyCode) {
    switch (currencyCode) {
      case 'NGN': return '₦';
      case 'USD': return '\$';
      case 'EUR': return '€';
      case 'GBP': return '£';
      default: return currencyCode;
    }
  }
}
