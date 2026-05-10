import 'package:flutter/material.dart';
import 'package:kise/features/goals/presentation/widgets/build_top_section.dart';
import 'package:kise/features/goals/presentation/widgets/goal_action_buttons.dart';
import 'package:kise/features/goals/presentation/widgets/goal_deposit_form.dart';
import 'package:kise/features/goals/presentation/widgets/goal_edit_form.dart';
import 'package:kise/core/theme/app_dimensions.dart';
import 'package:kise/core/widgets/kise_card_holder.dart';

enum GoalCardState { collapsed, expandedActions, expandedDeposit, expandedEdit }

class Goal {
  final String id;
  final String title;
  final String period;
  final String dueDate;
  final double currentAmount;
  final double targetAmount;
  final bool isCompleted;
  bool isLocked;

  Goal({
    required this.id,
    required this.title,
    required this.period,
    required this.dueDate,
    required this.currentAmount,
    required this.targetAmount,
    required this.isCompleted,
    this.isLocked = false,
  });

  double get progressPercentage => (currentAmount / targetAmount).clamp(0.0, 1.0);
}

class GoalCard extends StatefulWidget {
  final Goal goal;
  final VoidCallback onDelete;
  final void Function(double amount, String source) onDeposit;
  final void Function(String title, double targetAmount, String deadline, String period) onEdit;
  
  const GoalCard({
    super.key, 
    required this.goal,
    required this.onDelete,
    required this.onDeposit,
    required this.onEdit,
  });

  @override
  State<GoalCard> createState() => _GoalCardState();
}

class _GoalCardState extends State<GoalCard> {
  GoalCardState _state = GoalCardState.collapsed;

  void _handleCardTap() {
    setState(() {
      if (_state == GoalCardState.collapsed) {
        _state = GoalCardState.expandedActions;
      } else {
        _state = GoalCardState.collapsed;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppDimensions.md),
      child: KiseCardHolder(
        padding: EdgeInsets.zero,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(16.0),
            onTap: _handleCardTap,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  buildTopSection(context, widget),
                  if (_state != GoalCardState.collapsed) ...[
                    const Divider(height: 32, thickness: 1,),
                  ],
                  if (_state == GoalCardState.expandedActions) 
                    GoalActionButtons(
                      onDepositTap: () => setState(() => _state = GoalCardState.expandedDeposit),
                      onEditTap: () => setState(() => _state = GoalCardState.expandedEdit),
                      onLockTap: () {
                        setState(() {
                          widget.goal.isLocked = !widget.goal.isLocked;
                        });
                      },
                      onDeleteTap: widget.onDelete,
                      isLocked: widget.goal.isLocked,
                    ),
                  if (_state == GoalCardState.expandedDeposit) 
                    GoalDepositForm(
                      onSave: (amount, source) {
                        widget.onDeposit(amount, source);
                        setState(() => _state = GoalCardState.collapsed);
                      },
                      onCancel: () => setState(() => _state = GoalCardState.expandedActions),
                    ),
                  if (_state == GoalCardState.expandedEdit) 
                    GoalEditForm(
                      initialTitle: widget.goal.title,
                      initialTarget: widget.goal.targetAmount,
                      initialDeadline: widget.goal.dueDate,
                      initialPeriod: widget.goal.period,
                      onSave: (title, target, deadline, period) {
                        widget.onEdit(title, target, deadline, period);
                        setState(() => _state = GoalCardState.collapsed);
                      },
                      onCancel: () => setState(() => _state = GoalCardState.expandedActions),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
