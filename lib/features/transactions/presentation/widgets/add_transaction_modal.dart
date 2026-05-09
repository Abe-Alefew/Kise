import 'package:flutter/material.dart';

import '../../../../core/widgets/kise_action_button.dart';

class AddTransactionModal extends StatefulWidget {

  const AddTransactionModal({
    super.key,
  });

  @override
  State<AddTransactionModal> createState() =>
      _AddTransactionModalState();
}

class _AddTransactionModalState
    extends State<AddTransactionModal> {

  String selectedType = "Expense";

  String? selectedCategory;

  String? selectedAccount;

  final amountController =
      TextEditingController();

  final noteController =
      TextEditingController();

  final List<String> expenseCategories = [
    "Food",
    "Transport",
    "Education",
    "Shopping",
  ];

  final List<String> incomeSources = [
    "Salary",
    "Freelance",
    "Investment",
  ];

  final List<String> accounts = [
    "CBE",
    "Telebirr",
    "Cash",
  ];

  List<String> get currentCategories {

    if (selectedType == "Income") {
      return incomeSources;
    }

    return expenseCategories;
  }

  @override
  Widget build(BuildContext context) {

    return Container(

      padding: const EdgeInsets.all(20),

      decoration: const BoxDecoration(

        color: Colors.white,

        borderRadius: BorderRadius.vertical(
          top: Radius.circular(28),
        ),
      ),

      child: SingleChildScrollView(

        child: Column(

          mainAxisSize: MainAxisSize.min,

          crossAxisAlignment:
              CrossAxisAlignment.start,

          children: [

            /// HEADER
            Row(

              mainAxisAlignment:
                  MainAxisAlignment.spaceBetween,

              children: [

                const Text(

                  "New Transaction",

                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                IconButton(

                  onPressed: () {
                    Navigator.pop(context);
                  },

                  icon: const Icon(
                    Icons.close,
                    color: Color(0xFFD4AF37),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            /// TOGGLE
            Row(

              children: [

                Expanded(

                  child: GestureDetector(

                    onTap: () {

                      setState(() {

                        selectedType =
                            "Expense";

                        selectedCategory =
                            null;
                      });
                    },

                    child: Container(

                      height: 44,

                      decoration: BoxDecoration(

                        color:
                            selectedType
                                    == "Expense"
                                ? const Color(0xFFD4AF37)
                                : const Color(0xFFF2F2F2),

                        borderRadius:
                            BorderRadius.circular(
                                10),
                      ),

                      child: Center(

                        child: Text(

                          "Expense",

                          style: TextStyle(

                            color:
                                selectedType
                                        == "Expense"
                                    ? Colors.white
                                    : Colors.grey,

                            fontWeight:
                                FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(width: 12),

                Expanded(

                  child: GestureDetector(

                    onTap: () {

                      setState(() {

                        selectedType =
                            "Income";

                        selectedCategory =
                            null;
                      });
                    },

                    child: Container(

                      height: 44,

                      decoration: BoxDecoration(

                        color:
                            selectedType
                                    == "Income"
                                ? Colors.green
                                : const Color(0xFFF2F2F2),

                        borderRadius:
                            BorderRadius.circular(
                                10),
                      ),

                      child: Center(

                        child: Text(

                          "Income",

                          style: TextStyle(

                            color:
                                selectedType
                                        == "Income"
                                    ? Colors.white
                                    : Colors.grey,

                            fontWeight:
                                FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            /// AMOUNT
            const Text(
              "Amount (ETB)",
            ),

            const SizedBox(height: 8),

            TextField(

              controller:
                  amountController,

              decoration: InputDecoration(

                hintText: "0.00",

                filled: true,
                fillColor:
                    const Color(0xFFF8F8F8),

                border:
                    OutlineInputBorder(

                  borderRadius:
                      BorderRadius.circular(
                          12),

                  borderSide:
                      BorderSide.none,
                ),
              ),
            ),

            const SizedBox(height: 18),

            /// CATEGORY + ACCOUNT
            Row(

              children: [

                Expanded(

                  child:
                      DropdownButtonFormField<String>(

                    value: selectedCategory,

                    decoration: InputDecoration(

                      labelText:
                          "Category",

                      filled: true,

                      fillColor:
                          const Color(
                              0xFFF8F8F8),

                      border:
                          OutlineInputBorder(

                        borderRadius:
                            BorderRadius.circular(
                                12),

                        borderSide:
                            BorderSide.none,
                      ),
                    ),

                    items:
                        currentCategories.map((item) {

                      return DropdownMenuItem(
                        value: item,
                        child: Text(item),
                      );

                    }).toList(),

                    onChanged: (value) {

                      setState(() {
                        selectedCategory =
                            value;
                      });
                    },
                  ),
                ),

                const SizedBox(width: 12),

                Expanded(

                  child:
                      DropdownButtonFormField<String>(

                    value: selectedAccount,

                    decoration: InputDecoration(

                      labelText:
                          selectedType == "Income"
                          ? "Deposit To"
                          : "Paid From",

                      filled: true,

                      fillColor:
                          const Color(
                              0xFFF8F8F8),

                      border:
                          OutlineInputBorder(

                        borderRadius:
                            BorderRadius.circular(
                                12),

                        borderSide:
                            BorderSide.none,
                      ),
                    ),

                    items:
                        accounts.map((account) {

                      return DropdownMenuItem(
                        value: account,
                        child: Text(account),
                      );

                    }).toList(),

                    onChanged: (value) {

                      setState(() {
                        selectedAccount =
                            value;
                      });
                    },
                  ),
                ),
              ],
            ),

            const SizedBox(height: 18),

            /// DATE
            const Text("Date"),

            const SizedBox(height: 8),

            TextField(

              readOnly: true,

              decoration: InputDecoration(

                hintText: "16/04/2026",

                suffixIcon:
                    const Icon(Icons.calendar_today),

                filled: true,

                fillColor:
                    const Color(0xFFF8F8F8),

                border:
                    OutlineInputBorder(

                  borderRadius:
                      BorderRadius.circular(
                          12),

                  borderSide:
                      BorderSide.none,
                ),
              ),
            ),

            const SizedBox(height: 18),

            /// NOTE
            const Text(
              "Note (optional)",
            ),

            const SizedBox(height: 8),

            TextField(

              controller:
                  noteController,

              maxLines: 3,

              decoration: InputDecoration(

                hintText: "Add a note...",

                filled: true,

                fillColor:
                    const Color(0xFFF8F8F8),

                border:
                    OutlineInputBorder(

                  borderRadius:
                      BorderRadius.circular(
                          12),

                  borderSide:
                      BorderSide.none,
                ),
              ),
            ),

            const SizedBox(height: 24),

            /// BUTTONS
            Row(

              children: [

                Expanded(

                  child: KiseActionButton(

                    label: "Cancel",

                    variant:
                        KiseButtonVariant.outline,

                    expanded: false,

                    onPressed: () {

                      Navigator.pop(context);
                    },
                  ),
                ),

                const SizedBox(width: 12),

                Expanded(

                  child: KiseActionButton(

                    label: "Add Transaction",

                    expanded: false,

                    onPressed: () {},
                  ),
                ),
              ],
            ),

            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }
}