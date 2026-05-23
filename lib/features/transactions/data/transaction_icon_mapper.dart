import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

abstract final class TransactionIconMapper {
  static const _monthLabels = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];

  static IconData resolve(
    String iconKey, {
    String? category,
    String? type,
  }) {
    switch (iconKey) {
      case 'briefcase':
        return LucideIcons.briefcase;
      case 'laptop':
        return LucideIcons.laptop;
      case 'trendingUp':
        return LucideIcons.trendingUp;
      case 'gift':
        return LucideIcons.gift;
      case 'home':
        return LucideIcons.home;
      case 'shoppingCart':
        return LucideIcons.shoppingCart;
      case 'car':
        return LucideIcons.car;
      case 'tv':
        return LucideIcons.tv;
      case 'graduationCap':
        return LucideIcons.graduationCap;
      case 'shoppingBag':
        return LucideIcons.shoppingBag;
      case 'heart':
        return LucideIcons.heart;
      case 'plane':
        return LucideIcons.plane;
      case 'partyPopper':
        return LucideIcons.partyPopper;
      default:
        return defaultIconForCategory(category ?? '', type: type);
    }
  }

  static IconData defaultIconForCategory(String category, {String? type}) {
    return resolve(defaultIconKeyForCategory(category), category: category, type: type);
  }

  static String defaultIconKeyForCategory(String category) {
    switch (category) {
      case 'Salary':
      case 'Business':
        return 'briefcase';
      case 'Freelance':
        return 'laptop';
      case 'Investment':
        return 'trendingUp';
      case 'Allowance':
      case 'Bonus':
        return 'gift';
      case 'Housing':
      case 'Bills':
        return 'home';
      case 'Food':
        return 'shoppingCart';
      case 'Transport':
        return 'car';
      case 'Education':
        return 'graduationCap';
      case 'Entertainment':
        return 'tv';
      case 'Shopping':
        return 'shoppingBag';
      case 'Health':
        return 'heart';
      case 'Travel':
        return 'plane';
      default:
        return 'circle';
    }
  }

  static String formatDisplayDate(DateTime date) {
    return '${_monthLabels[date.month - 1]} ${date.day}';
  }

  static String formatMonthLabel(DateTime date) {
    return _monthLabels[date.month - 1];
  }
}