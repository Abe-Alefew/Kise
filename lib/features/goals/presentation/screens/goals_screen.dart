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

  Future<void> _handleDeposit(
    GoalEntity goal,
    double amount,
    String source,
  ) async {
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
    ref.listen<AsyncValue<List<GoalEntity>>>(goalsNotifierProvider, (prev, next) {
      if (next.hasError && next.error != prev?.error) {
        _showError(next.error!);
      }
    });

    final goalsAsync = ref.watch(goalsNotifierProvider);
    final filter = ref.read(goalsNotifierProvider.notifier).filter;
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
                          color: isDark
                              ? AppColorsDark.textHint
                              : AppColorsLight.textHint,
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
              Expanded(
                child: goalsAsync.when(
                  loading: () => const Center(
                    child: CircularProgressIndicator(),
                  ),
                  error: (error, _) => KiseEmptyIndicator(
                    title: 'Could not load goals',
                    subtitle: error is ApiException
                        ? error.message
                        : error.toString(),
                    icon: LucideIcons.target,
                  ),
                  data: (goals) {
                    final displayGoals =
                        goals.where(filter.matches).toList();

                    if (displayGoals.isEmpty) {
                      return const KiseEmptyIndicator(
                        title: 'No goals found',
                        subtitle:
                            'Try adjusting your filters or add a new goal.',
                        icon: LucideIcons.target,
                      );
                    }

                    return ListView.builder(
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
