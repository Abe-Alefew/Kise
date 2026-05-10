import 'package:flutter/material.dart';

import '../../../../core/widgets/kise_action_button.dart';
import '../../../../core/widgets/kise_form_system/form_validation.dart';
import '../../../../core/widgets/kise_form_system/kise_text_field.dart';
import '../../../../core/widgets/kise_form_system/kise_form_system.dart';

import '../../data/transaction_form_data.dart';

class AddTransactionScreen extends StatefulWidget {

  const AddTransactionScreen({
    super.key,
  });

  @override
  State<AddTransactionScreen> createState() =>
      _AddTransactionScreenState();
}

class _AddTransactionScreenState
    extends State<AddTransactionScreen> {

  final formKey =
      GlobalKey<FormState>();

  final amountController =
      TextEditingController();

  final titleController =
      TextEditingController();

  final notesController =
      TextEditingController();

  String selectedType = "Expense";

  String? selectedCategory;

  List<String> get currentDropdownItems {

    if (selectedType == "Income") {

      return TransactionFormData
          .incomeSources;
    }

    return TransactionFormData
        .expenseCategories;
  }

  @override
  void dispose() {

    amountController.dispose();
    titleController.dispose();
    notesController.dispose();

    super.dispose();
  }

  void submitForm() {

    if (formKey.currentState!.validate()) {

      ScaffoldMessenger.of(context)
          .showSnackBar(

        const SnackBar(
          content:
              Text("Transaction Added"),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(

      appBar: AppBar(
        title:
            const Text("Add Transaction"),
      ),

      body: SingleChildScrollView(

        padding:
            const EdgeInsets.all(16),

        child: KiseFormSystem(

          formKey: formKey,

          children: [

            /// TITLE
            KiseTextField(

              label: "Title",

              controller:
                  titleController,

              validator:
                  Validators.requiredField,

              hint:
                  "Enter transaction title",

              icon: Icons.title,
            ),

            /// AMOUNT
            KiseTextField(

              label: "Amount",

              controller:
                  amountController,

              validator:
                  Validators.requiredField,

              keyboardType:
                  TextInputType.number,

              hint:
                  "Enter amount",

              icon:
                  Icons.attach_money,
            ),

            const SizedBox(height: 20),

            /// TYPE SELECTOR
            const Text(

              "Transaction Type",

              style: TextStyle(
                fontWeight:
                    FontWeight.bold,
                fontSize: 16,
              ),
            ),

            const SizedBox(height: 12),

            Row(

              children: [

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

                      padding:
                          const EdgeInsets.symmetric(
                        vertical: 14,
                      ),

                      decoration: BoxDecoration(

                        color:
                            selectedType
                                    == "Income"
                                ? Colors.green
                                : Colors.white,

                        borderRadius:
                            BorderRadius.circular(
                                14),

                        border: Border.all(
                          color: Colors.green,
                        ),
                      ),

                      child: Center(

                        child: Text(

                          "Income",

                          style: TextStyle(

                            color:
                                selectedType
                                        == "Income"
                                    ? Colors.white
                                    : Colors.green,

                            fontWeight:
                                FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(width: 14),

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

                      padding:
                          const EdgeInsets.symmetric(
                        vertical: 14,
                      ),

                      decoration: BoxDecoration(

                        color:
                            selectedType
                                    == "Expense"
                                ? Colors.red
                                : Colors.white,

                        borderRadius:
                            BorderRadius.circular(
                                14),

                        border: Border.all(
                          color: Colors.red,
                        ),
                      ),

                      child: Center(

                        child: Text(

                          "Expense",

                          style: TextStyle(

                            color:
                                selectedType
                                        == "Expense"
                                    ? Colors.white
                                    : Colors.red,

                            fontWeight:
                                FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            /// CATEGORY DROPDOWN
            DropdownButtonFormField<String>(

              value: selectedCategory,

              decoration: InputDecoration(

                labelText:
                    selectedType == "Income"
                    ? "Income Source"
                    : "Expense Category",

                border:
                    OutlineInputBorder(

                  borderRadius:
                      BorderRadius.circular(
                          14),
                ),
              ),

              items:
                  currentDropdownItems.map((item) {

                return DropdownMenuItem(

                  value: item,

                  child: Text(item),
                );

              }).toList(),

              onChanged: (value) {

                setState(() {
                  selectedCategory = value;
                });
              },

              validator: (value) {

                if (value == null) {
                  return "Please select a category";
                }

                return null;
              },
            ),

            const SizedBox(height: 20),

            /// NOTES
            TextFormField(

              controller:
                  notesController,

              maxLines: 4,

              decoration: InputDecoration(

                labelText: "Notes",

                hintText:
                    "Additional details",

                border:
                    OutlineInputBorder(

                  borderRadius:
                      BorderRadius.circular(
                          14),
                ),
              ),
            ),

            const SizedBox(height: 30),

            /// SAVE BUTTON
            KiseActionButton(

              label: "Save Transaction",

              onPressed: submitForm,

              leadingIcon:
                  Icons.check,
            ),
          ],
        ),
      ),
    );
  }
}