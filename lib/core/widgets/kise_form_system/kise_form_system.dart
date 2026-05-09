import 'package:flutter/material.dart';

class KiseFormSystem extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final List<Widget> children;
  const KiseFormSystem({
    super.key,
    required this.formKey,
    required this.children,
  });

  void validateAndSubmit() {
    if (formKey.currentState!.validate()) {
      formKey.currentState!.save();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: children,
      ),
    );
  }
}
