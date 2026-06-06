import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kise/core/network/dio_client.dart';
import 'package:kise/core/routing/app_router.dart';
import 'package:kise/core/widgets/kise_action_button.dart';
import 'package:kise/features/settings/domain/settings_models.dart';
import 'package:kise/features/settings/presentation/state/settings_notifier.dart';
import 'package:kise/features/transactions/domain/transaction_entity.dart';
import 'package:kise/features/transactions/domain/transaction_inputs.dart';
import 'package:kise/features/transactions/presentation/state/transactions_notifier.dart';

class AddTransactionModal extends ConsumerStatefulWidget {
  final TransactionEntity? transactionToEdit;

  const AddTransactionModal({super.key, this.transactionToEdit});

  bool get isEditMode => transactionToEdit != null;

  @override
  ConsumerState<AddTransactionModal> createState() => _AddTransactionModalState();
}

class _AddTransactionModalState extends ConsumerState<AddTransactionModal> {
  late String selectedType;
  String? selectedCategory;
  String? selectedAccountId;
  late DateTime selectedDate;

  final amountController = TextEditingController();
  final noteController = TextEditingController();

  bool _isSubmitting = false;

  final List<String> expenseCategories = ["Food", "Transport", "Education", "Shopping"];
  final List<String> incomeSources = ["Salary", "Freelance", "Investment"];

  List<String> get currentCategories =>
      selectedType == "Income" ? incomeSources : expenseCategories;

  @override
  void initState() {
    super.initState();
    final existing = widget.transactionToEdit;
    if (existing != null) {
      selectedType = existing.type;
      selectedCategory = currentCategories.contains(existing.category)
          ? existing.category
          : null;
      selectedDate = DateTime.tryParse('${existing.transactionDate}T00:00:00') ??
          DateTime.now();
      amountController.text = _formatAmount(existing.amount);
      noteController.text = existing.note ?? '';
      selectedAccountId = existing.accountId;
    } else {
      selectedType = "Expense";
      selectedDate = DateTime.now();
    }
  }

  static String _formatAmount(double value) {
    if (value == value.roundToDouble()) {
      return value.toInt().toString();
    }
    return value.toString();
  }

  @override
  void dispose() {
    amountController.dispose();
    noteController.dispose();
    super.dispose();
  }

  Widget _fieldShadow({required Widget child}) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).shadowColor.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );
  }

  InputDecoration _inputDec(BuildContext context, {String? hint, Widget? suffix}) {
    final cs = Theme.of(context).colorScheme;
    return InputDecoration(
      isDense: true,
      filled: true,
      fillColor: cs.surface,
      hintText: hint,
      suffixIcon: suffix,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: cs.outline.withValues(alpha: 0.25), width: 0.8),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: cs.primary.withValues(alpha: 0.5), width: 0.8),
      ),
    );
  }

  Future<void> _submit() async {
    if (_isSubmitting) return;

    final paymentAccounts = ref.read(paymentAccountsProvider);
    final accountId = _resolvedAccountId(paymentAccounts);

    if (selectedCategory == null || accountId == null || amountController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            accountId == null
                ? 'Add a payment account in Settings first'
                : 'Please fill all required fields',
          ),
        ),
      );
      return;
    }

    final amount = double.tryParse(amountController.text.trim());
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid amount')),
      );
      return;
    }

    final transactionDate =
        '${selectedDate.year.toString().padLeft(4, '0')}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.day.toString().padLeft(2, '0')}';

    setState(() => _isSubmitting = true);

    try {
      final notifier = ref.read(transactionsNotifierProvider.notifier);

      if (widget.isEditMode) {
        await notifier.updateTransaction(
          widget.transactionToEdit!.id,
          UpdateTransactionInput(
            type: selectedType,
            title: selectedCategory ?? selectedType,
            category: selectedCategory!,
            amount: amount,
            transactionDate: transactionDate,
            accountId: accountId,
            note: noteController.text.trim().isEmpty
                ? null
                : noteController.text.trim(),
            iconKey: widget.transactionToEdit!.iconKey,
          ),
        );

        if (!context.mounted) return;
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Transaction updated successfully')),
        );
      } else {
        await notifier.addTransaction(
          CreateTransactionInput(
            type: selectedType,
            title: selectedCategory ?? selectedType,
            category: selectedCategory!,
            amount: amount,
            transactionDate: transactionDate,
            accountId: accountId,
            note: noteController.text.trim().isEmpty
                ? null
                : noteController.text.trim(),
          ),
        );

        if (!context.mounted) return;
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Transaction added successfully')),
        );
      }
    } catch (e) {
      if (!context.mounted) return;
      final message = e is ApiException
          ? e.message
          : 'Could not save transaction. '
              'Make sure the backend is running at http://127.0.0.1:3000.';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  String? _resolvedAccountId(List<PaymentAccountSettings> paymentAccounts) {
    if (paymentAccounts.isEmpty) {
      return null;
    }

    if (selectedAccountId != null &&
        paymentAccounts.any((account) => account.id == selectedAccountId)) {
      return selectedAccountId;
    }

    return paymentAccounts.first.id;
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final kb = MediaQuery.of(context).viewInsets.bottom;
    final isEdit = widget.isEditMode;
    final paymentAccounts = ref.watch(paymentAccountsProvider);
    final resolvedAccountId = _resolvedAccountId(paymentAccounts);

    return Padding(
      padding: EdgeInsets.only(bottom: kb),
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    isEdit ? "Edit Transaction" : "New Transaction",
                    style: tt.titleMedium,
                  ),
                  IconButton(
                    onPressed: _isSubmitting ? null : () => Navigator.pop(context),
                    icon: Icon(Icons.close, size: 20, color: cs.primary),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              Container(
                decoration: BoxDecoration(
                  color: cs.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: const EdgeInsets.all(3),
                child: Row(
                  children: ["Expense", "Income"].map((type) {
                    final isSelected = selectedType == type;
                    return Expanded(
                      child: GestureDetector(
                        onTap: _isSubmitting
                            ? null
                            : () => setState(() {
                                  selectedType = type;
                                  if (selectedCategory != null &&
                                      !currentCategories.contains(selectedCategory)) {
                                    selectedCategory = null;
                                  }
                                }),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          height: 34,
                          decoration: BoxDecoration(
                            color: isSelected
                                ? (type == "Income" ? cs.tertiary : cs.error)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Center(
                            child: Text(
                              type,
                              style: tt.labelMedium?.copyWith(
                                color: isSelected
                                    ? (type == "Income" ? cs.onTertiary : cs.onError)
                                    : cs.onSurfaceVariant,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 16),

              Text("Amount (ETB)", style: tt.labelMedium),
              const SizedBox(height: 5),
              _fieldShadow(
                child: TextField(
                  controller: amountController,
                  enabled: !_isSubmitting,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: _inputDec(context, hint: "0.00"),
                ),
              ),
              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          selectedType == "Income" ? "Source" : "Category",
                          style: tt.labelMedium,
                        ),
                        const SizedBox(height: 5),
                        _fieldShadow(
                          child: DropdownButtonFormField<String>(
                            value: selectedCategory,
                            isExpanded: true,
                            isDense: true,
                            dropdownColor: cs.surface,
                            borderRadius: BorderRadius.circular(12),
                            elevation: 4,
                            icon: Icon(Icons.keyboard_arrow_down,
                                color: cs.outline, size: 20),
                            decoration: _inputDec(context),
                            items: currentCategories
                                .map(
                                  (e) => DropdownMenuItem(
                                    value: e,
                                    child: Text(e, style: tt.bodyMedium),
                                  ),
                                )
                                .toList(),
                            onChanged: _isSubmitting
                                ? null
                                : (v) => setState(() => selectedCategory = v),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          selectedType == "Income" ? "Deposit To" : "Paid From",
                          style: tt.labelMedium,
                        ),
                        const SizedBox(height: 5),
                        paymentAccounts.isEmpty
                            ? _fieldShadow(
                                child: ListTile(
                                  dense: true,
                                  title: Text(
                                    'No accounts yet',
                                    style: tt.bodyMedium,
                                  ),
                                  subtitle: Text(
                                    'Add one in Settings',
                                    style: tt.bodySmall,
                                  ),
                                  trailing: TextButton(
                                    onPressed: _isSubmitting
                                        ? null
                                        : () {
                                            Navigator.pop(context);
                                            context.go(AppRoutes.settings);
                                          },
                                    child: const Text('Settings'),
                                  ),
                                ),
                              )
                            : _fieldShadow(
                                child: DropdownButtonFormField<String>(
                                  value: resolvedAccountId,
                                  isExpanded: true,
                                  isDense: true,
                                  dropdownColor: cs.surface,
                                  borderRadius: BorderRadius.circular(12),
                                  elevation: 4,
                                  icon: Icon(Icons.keyboard_arrow_down,
                                      color: cs.outline, size: 20),
                                  decoration: _inputDec(context),
                                  items: paymentAccounts
                                      .map(
                                        (account) => DropdownMenuItem(
                                          value: account.id,
                                          child: Text(
                                            account.name,
                                            style: tt.bodyMedium,
                                          ),
                                        ),
                                      )
                                      .toList(),
                                  onChanged: _isSubmitting
                                      ? null
                                      : (v) =>
                                          setState(() => selectedAccountId = v),
                                ),
                              ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              Text("Date", style: tt.labelMedium),
              const SizedBox(height: 5),
              _fieldShadow(
                child: TextField(
                  readOnly: true,
                  onTap: _isSubmitting
                      ? null
                      : () async {
                          final date = await showDatePicker(
                            context: context,
                            initialDate: selectedDate,
                            firstDate: DateTime(2000),
                            lastDate: DateTime(2100),
                          );
                          if (date != null) setState(() => selectedDate = date);
                        },
                  decoration: _inputDec(
                    context,
                    hint:
                        "${selectedDate.day}/${selectedDate.month}/${selectedDate.year}",
                    suffix: Icon(Icons.calendar_today, size: 16, color: cs.outline),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              Text("Note (optional)", style: tt.labelMedium),
              const SizedBox(height: 5),
              _fieldShadow(
                child: TextField(
                  controller: noteController,
                  enabled: !_isSubmitting,
                  maxLines: 2,
                  decoration: _inputDec(context, hint: "Add a note..."),
                ),
              ),
              const SizedBox(height: 20),

              Row(
                children: [
                  Expanded(
                    child: KiseActionButton(
                      label: "Cancel",
                      variant: KiseButtonVariant.outline,
                      height: 42,
                      borderRadius: 10,
                      textColor: cs.onSurface,
                      outlineBorderSide: BorderSide(
                        color: cs.outline.withValues(alpha: 0.25),
                        width: 0.8,
                      ),
                      onPressed:
                          _isSubmitting ? null : () => Navigator.pop(context),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: KiseActionButton(
                      label: isEdit ? "Save Update" : "Add Transaction",
                      borderRadius: 10,
                      height: 42,
                      onPressed: _isSubmitting ? null : _submit,
                    ),
                  ),
                ],
              ),
              if (_isSubmitting) ...[
                const SizedBox(height: 12),
                const Center(
                  child: SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
