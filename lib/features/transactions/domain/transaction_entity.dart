import 'package:flutter/material.dart';

class TransactionEntity {

  final String title;
  final String category;
  final double amount;
  final String type;
  final String date;
  final IconData icon;
  final String month;

  const TransactionEntity({
    required this.title,
    required this.category,
    required this.amount,
    required this.type,
    required this.date,
    required this.icon,
    required this.month,
  });
}