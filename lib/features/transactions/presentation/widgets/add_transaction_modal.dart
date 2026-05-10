import 'package:flutter/material.dart';
import 'package:kise/core/theme/text_theme.dart';

import '../../../../core/widgets/kise_action_button.dart';

class AddTransactionModal extends StatefulWidget {
  const AddTransactionModal({super.key});

  @override
  State<AddTransactionModal> createState() => _AddTransactionModalState();
}

class _AddTransactionModalState extends State<AddTransactionModal> {
  String selectedType = "Expense";
  String? selectedCategory;
  String? selectedAccount;

  final amountController = TextEditingController();
  final noteController = TextEditingController();

  final List<String> expenseCategories = [
    "Food",
    "Transport",
    "Education",
    "Shopping",
  ];
  final List<String> incomeSources = ["Salary", "Freelance", "Investment"];
  final List<String> accounts = ["CBE", "Telebirr", "Cash"];

  List<String> get currentCategories =>
      selectedType == "Income" ? incomeSources : expenseCategories;

  @override
  void dispose() {
    amountController.dispose();
    noteController.dispose();
    super.dispose();
  }

  Widget _fieldShadow({required Widget child}) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );
  }

  InputDecoration _inputDec(
    BuildContext context, {
    String? hint,
    Widget? suffix,
  }) {
    final cs = Theme.of(context).colorScheme;
    return InputDecoration(
      isDense: true,
      filled: false,
      hintText: hint,
      suffixIcon: suffix,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(
          color: cs.outline.withValues(alpha: 0.25),
          width: 0.8,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(
          color: cs.primary.withValues(alpha: 0.5),
          width: 0.8,
        ),
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(
          color: cs.outline.withValues(alpha: 0.25),
          width: 0.8,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final screen = MediaQuery.of(context).size.height;
    final kb = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: kb),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: screen * 0.60),
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
                /// HEADER
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("New Transaction", style: tt.titleMedium),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: Icon(Icons.close, size: 20, color: cs.primary),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                /// TYPE TOGGLE
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
                          onTap: () => setState(() {
                            selectedType = type;
                            selectedCategory = null;
                          }),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            height: 34,
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? (type == "Income"
                                        ? cs.tertiary
                                        : cs.primary)
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Center(
                              child: Text(
                                type,
                                style: tt.labelMedium?.copyWith(
                                  color: isSelected ? cs.onPrimary : cs.outline,
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

                const SizedBox(height: 12),

                /// AMOUNT
                Text("Amount (ETB)", style: tt.labelMedium),
                const SizedBox(height: 5),
                _fieldShadow(
                  child: TextField(
                    controller: amountController,
                    keyboardType: TextInputType.number,
                    decoration: _inputDec(context, hint: "0.00"),
                  ),
                ),

                const SizedBox(height: 12),

                /// CATEGORY + ACCOUNT
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
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
                              initialValue: selectedCategory,
                              isDense: true,
                              decoration: _inputDec(context),
                              items: currentCategories
                                  .map(
                                    (e) => DropdownMenuItem(
                                      value: e,
                                      child: Text(e, style: tt.bodySmall),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (v) =>
                                  setState(() => selectedCategory = v),
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
                            selectedType == "Income"
                                ? "Deposit To"
                                : "Paid From",
                            style: tt.labelMedium,
                          ),
                          const SizedBox(height: 5),
                          _fieldShadow(
                            child: DropdownButtonFormField<String>(
                              initialValue: selectedAccount,
                              isDense: true,
                              decoration: _inputDec(context),
                              items: accounts
                                  .map(
                                    (e) => DropdownMenuItem(
                                      value: e,
                                      child: Text(e, style: tt.bodySmall),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (v) =>
                                  setState(() => selectedAccount = v),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                /// DATE
                Text("Date", style: tt.labelMedium),
                const SizedBox(height: 5),
                _fieldShadow(
                  child: TextField(
                    readOnly: true,
                    decoration: _inputDec(
                      context,
                      hint: "16/04/2026",
                      suffix: Icon(
                        Icons.calendar_today,
                        size: 16,
                        color: cs.outline,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                /// NOTE
                Text("Note (optional)", style: tt.labelMedium),
                const SizedBox(height: 5),
                _fieldShadow(
                  child: TextField(
                    controller: noteController,
                    maxLines: 2,
                    decoration: _inputDec(context, hint: "Add a note..."),
                  ),
                ),

                const SizedBox(height: 16),

                /// BUTTONS
                Row(
                  children: [
                    Expanded(
                      child: KiseActionButton(
                        label: "Cancel",
                        variant: KiseButtonVariant.outline,
                        height: 38,
                        borderRadius: 10,
                        textStyle: AppTextStyles.bodySm.copyWith(
                          color: Colors.black,
                        ),
                        outlineBorderSide: BorderSide(
                          color: cs.outline.withValues(alpha: 0.25),
                          width: 0.8,
                        ),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: KiseActionButton(
                        label: "Add Transaction",
                        height: 38,
                        borderRadius: 10,
                        textStyle: AppTextStyles.bodySm,
                        onPressed: () {},
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
