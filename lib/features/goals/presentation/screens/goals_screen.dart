import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kise/core/network/dio_client.dart';
import 'package:kise/core/theme/app_dimensions.dart';
import 'package:kise/core/theme/colors.dart';
import 'package:kise/core/theme/text_theme.dart';
import 'package:kise/core/widgets/widgets.dart';
import 'package:kise/features/goals/domain/goal_entity.dart';
import 'package:kise/features/goals/domain/goal_filters.dart';
import 'package:kise/features/goals/domain/goal_inputs.dart';
import 'package:kise/features/goals/presentation/providers/goals_notifier.dart';
import 'package:kise/features/goals/presentation/widgets/goal_card.dart';
import 'package:kise/features/goals/presentation/widgets/new_goal_bottom_sheet.dart';
import 'package:lucide_icons/lucide_icons.dart';

class GoalsScreen extends ConsumerStatefulWidget {
  const GoalsScreen({super.key});

  @override
  ConsumerState<GoalsScreen> createState() => _GoalsScreenState();
}

class _GoalsScreenState extends ConsumerState<GoalsScreen> {
  String _selectedFilter = 'All';
  List<GoalEntity> _lastStableGoals = const [];

  List<GoalEntity> _resolveGoals(AsyncValue<List<GoalEntity>> goalsAsync) {
    if (goalsAsync.hasValue && goalsAsync.value != null) {
      _lastStableGoals = goalsAsync.value!;
      return goalsAsync.value!;
    }
    return _lastStableGoals;
  }

  List<GoalEntity> _filteredDisplay(
    List<GoalEntity> items,
    GoalStatusFilter filter,
  ) {
    if (filter == GoalStatusFilter.all) {
      return items;
    }
    return items.where((goal) => goal.status == filter.apiValue).toList();
  }

  void _showError(Object error) {
    if (!mounted) {
      return;
    }
    final message = error is ApiException ? error.message : error.toString();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _onFilterSelected(String val) async {
    setState(() => _selectedFilter = val);
    try {
      await ref.read(goalsNotifierProvider.notifier).applyUiFilter(val);
    } catch (error) {
      _showError(error);
    }
  }

  Future<void> _handleDelete(String id) async {
    try {
      await ref.read(goalsNotifierProvider.notifier).deleteGoal(id);
    } catch (error) {
      _showError(error);
    }
  }

  Future<void> _handleDeposit(GoalEntity goal, double amount, String source,) async {
    try {
      await ref.read(goalsNotifierProvider.notifier).logDeposit(
            goal: goal,
            amount: amount,
            source: source,
          );
    } catch (error) {
      _showError(error);
    }
  }

  Future<void> _handleEdit(
    GoalEntity goal,
    String newTitle,
    double newTarget,
    String newDeadline,
    String newPeriod,
  ) async {
    final parsedDue =
        GoalDateParser.parseDueDate(newDeadline) ?? DateTime.now();
    try {
      await ref.read(goalsNotifierProvider.notifier).updateGoal(
            goal.id,
            UpdateGoalInput(
              title: newTitle.trim(),
              targetAmount: newTarget,
              dueDate: GoalDateParser.toIsoDate(parsedDue),
              period: GoalDateParser.normalizePeriod(newPeriod),
            ),
          );
    } catch (error) {
      _showError(error);
    }
  }

  Future<void> _handleLock(GoalEntity goal) async {
    try {
      await ref.read(goalsNotifierProvider.notifier).toggleLock(goal);
    } catch (error) {
      _showError(error);
    }
  }

  void _handleAddGoal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext sheetContext) {
        return NewGoalBottomSheet(
          onSave: (title, targetAmount, currentAmount, deadline, period, note) async {
            try {
              await ref.read(goalsNotifierProvider.notifier).addGoal(
                    title: title,
                    period: period,
                    targetAmount: targetAmount,
                    currentAmount: currentAmount,
                    dueDateDisplay: deadline,
                    note: note,
                  );
              if (sheetContext.mounted) {
                Navigator.of(sheetContext).pop();
              }
            } catch (error) {
              _showError(error);
            }
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final goalsAsync = ref.watch(goalsNotifierProvider);
    final notifier = ref.read(goalsNotifierProvider.notifier);
    final allGoals = _resolveGoals(goalsAsync);
    final displayGoals = _filteredDisplay(allGoals, notifier.filter);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColorsDark.scaffold : AppColorsLight.scaffold,
      body: SafeArea(
        child: Padding(
          padding: AppDimensions.pagePadding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: AppDimensions.lg),
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
                        style: AppTextStyles.bodySm.copyWith(
                          color: isDark ? AppColorsDark.textHint : AppColorsLight.textHint,
                        ),
                      ),
                    ],
                  ),
                  KiseActionButton(
                    leadingIcon: LucideIcons.plus,
                    label: 'New',
                    onPressed: _handleAddGoal,
                    expanded: false,
                    width: 110.0,
                  ),
                ],
              ),
              const SizedBox(height: AppDimensions.xl),
              KisePillFilter(
                options: const ['All', 'Active', 'Completed', 'Canceled'],
                selected: _selectedFilter,
                onSelected: _onFilterSelected,
              ),
              const SizedBox(height: AppDimensions.lg),
              displayGoals.isEmpty
                  ? const Expanded(
                      child: KiseEmptyIndicator(
                        title: 'No goals found',
                        subtitle:
                            'Try adjusting your filters or add a new goal.',
                        icon: LucideIcons.target,
                      ),
                    )
                  : Expanded(
                      child: ListView.builder(
                        itemCount: displayGoals.length,
                        itemBuilder: (context, index) {
                          final goal = displayGoals[index];
                          return GoalCard(
                            key: ValueKey(goal.id),
                            goal: goal,
                            onDelete: () => _handleDelete(goal.id),
                            onLock: () => _handleLock(goal),
                            onDeposit: (amount, source) =>
                                _handleDeposit(goal, amount, source),
                            onEdit: (title, target, deadline, period) =>
                                _handleEdit(
                              goal,
                              title,
                              target,
                              deadline,
                              period,
                            ),
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
