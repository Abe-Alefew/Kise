import 'package:flutter/material.dart';
import 'package:kise/core/widgets/widgets.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:kise/core/theme/colors.dart';
import 'package:kise/core/theme/text_theme.dart';
import 'package:kise/core/theme/app_dimensions.dart';
import 'package:kise/core/widgets/kise_pill_filter.dart';
import 'package:kise/features/goals/presentation/widgets/goal_card.dart';

class GoalsScreen extends StatefulWidget {
  const GoalsScreen({super.key});

  @override
  State<GoalsScreen> createState() => _GoalsScreenState();
}

class _GoalsScreenState extends State<GoalsScreen> {
  String _selectedFilter = 'All';

  final List<Goal> _goals = [
    Goal(id: '1', title: 'Vacation', period: 'Monthly', dueDate: 'Due Mon Feb 25 2026', currentAmount: 1000, targetAmount: 1000, isCompleted: true),
    Goal(id: '2', title: 'Buy Sneakers', period: 'Monthly', dueDate: 'Due Mon Feb 25 2026', currentAmount: 1200, targetAmount: 3800, isCompleted: false),
    Goal(id: '3', title: 'Buy Food', period: 'Weekly', dueDate: 'Due Mon Feb 25 2026', currentAmount: 413, targetAmount: 800, isCompleted: false),
    Goal(id: '4', title: 'New Laptop', period: 'Monthly', dueDate: 'Due Wed Jun 10 2026', currentAmount: 50000, targetAmount: 120000, isCompleted: false),
    Goal(id: '5', title: 'Emergency Fund', period: 'Monthly', dueDate: 'Due Fri Jan 1 2027', currentAmount: 10000, targetAmount: 50000, isCompleted: false),
    Goal(id: '6', title: 'Car Paint Job', period: 'One-time', dueDate: 'Due Tue Oct 12 2026', currentAmount: 0, targetAmount: 15000, isCompleted: false),
  ];

  List<Goal> get _filteredGoals {
    if (_selectedFilter == 'All') return _goals;
    if (_selectedFilter == 'Active') return _goals.where((g) => !g.isCompleted && g.currentAmount > 0).toList();
    if (_selectedFilter == 'Completed') return _goals.where((g) => g.isCompleted).toList();
    // For demonstration, Canceled is empty
    if (_selectedFilter == 'Canceled') return []; 
    return _goals;
  }

  void _handleDelete(String id) {
    setState(() {
      _goals.removeWhere((g) => g.id == id);
    });
  }

  void _handleDeposit(Goal goal, double amount, String source) {
    setState(() {
      final newAmount = goal.currentAmount + amount;
      final index = _goals.indexWhere((g) => g.id == goal.id);
      if (index != -1) {
        _goals[index] = Goal(
          id: goal.id,
          title: goal.title,
          period: goal.period,
          dueDate: goal.dueDate,
          currentAmount: newAmount,
          targetAmount: goal.targetAmount,
          isCompleted: newAmount >= goal.targetAmount,
          isLocked: goal.isLocked,
        );
      }
    });
  }

  void _handleEdit(Goal goal, String newTitle, double newTarget, String newDeadline, String newPeriod) {
    setState(() {
      final index = _goals.indexWhere((g) => g.id == goal.id);
      if (index != -1) {
        _goals[index] = Goal(
          id: goal.id,
          title: newTitle,
          period: newPeriod,
          dueDate: newDeadline,
          currentAmount: goal.currentAmount,
          targetAmount: newTarget,
          isCompleted: goal.currentAmount >= newTarget,
          isLocked: goal.isLocked,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColorsDark.scaffold : AppColorsLight.scaffold,
      body: SafeArea(
        child: Padding(
          padding: AppDimensions.pagePadding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: AppDimensions.lg),
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Goals',
                        style: isDark ? AppTextStylesDark.h1 : AppTextStyles.h1,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Track your savings targets',
                        style: AppTextStyles.bodySm.copyWith(color: isDark ? AppColorsDark.textHint : AppColorsLight.textHint),
                      ),
                    ],
                  ),
                  KiseActionButton(leadingIcon: LucideIcons.plus, label: 'New', onPressed: () {}, expanded: false, width: 110.0,),
                ],
              ),
              const SizedBox(height: AppDimensions.xl),
              // Pill Filters
              KisePillFilter(
                options: const ['All', 'Active', 'Completed', 'Canceled'],
                selected: _selectedFilter,
                onSelected: (val) {
                  setState(() {
                    _selectedFilter = val;
                  });
                },
              ),
              const SizedBox(height: AppDimensions.lg),
              // Goal Cards List
              Expanded(
                child: ListView.builder(
                  itemCount: _filteredGoals.length,
                  // padding: const EdgeInsets.only(bottom: AppDimensions.lg),
                  itemBuilder: (context, index) {
                    final Goal goal = _filteredGoals[index];
                    return GoalCard(
                      key: ValueKey(goal.id),
                      goal: goal,
                      onDelete: () => _handleDelete(goal.id),
                      onDeposit: (amount, source) => _handleDeposit(goal, amount, source),
                      onEdit: (title, target, deadline, period) => _handleEdit(goal, title, target, deadline, period),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
