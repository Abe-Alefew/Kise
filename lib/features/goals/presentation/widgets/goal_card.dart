import 'package:flutter/material.dart';
import 'package:kise/core/theme/app_dimensions.dart';
import 'package:kise/core/widgets/kise_card_holder.dart';
import 'package:kise/features/goals/domain/goal_entity.dart';
import 'package:kise/features/goals/presentation/widgets/build_top_section.dart';
import 'package:kise/features/goals/presentation/widgets/goal_action_buttons.dart';
import 'package:kise/features/goals/presentation/widgets/goal_deposit_form.dart';
import 'package:kise/features/goals/presentation/widgets/goal_edit_form.dart';

enum GoalCardState { collapsed, expandedActions, expandedDeposit, expandedEdit }

class GoalCard extends StatefulWidget {
  final GoalEntity goal;
  final VoidCallback onDelete;
  final VoidCallback onLock;
  final void Function(double amount, String source) onDeposit;
  final void Function(String title, double targetAmount, String deadline, String period) onEdit;

  const GoalCard({
    super.key,
    required this.goal,
    required this.onDelete,
    required this.onLock,
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
                    const Divider(height: 32, thickness: 1),
                  ],
                  if (_state == GoalCardState.expandedActions)
                    GoalActionButtons(
                      onDepositTap: () {
                        if (widget.goal.isLocked) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'This goal is locked. Unlock it before adding a deposit.',
                              ),
                            ),
                          );
                          return;
                        }
                        setState(() => _state = GoalCardState.expandedDeposit);
                      },
                      onEditTap: () {
                        if (widget.goal.isLocked) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'This goal is locked and cannot be edited.',
                              ),
                            ),
                          );
                          return;
                        }
                        setState(() => _state = GoalCardState.expandedEdit);
                      },
                      onLockTap: widget.onLock,
                      onDeleteTap: widget.onDelete,
                      isLocked: widget.goal.isLocked,
                    ),
                  if (_state == GoalCardState.expandedDeposit)
                    GoalDepositForm(
                      isLocked: widget.goal.isLocked,
                      onSave: (amount, source) {
                        widget.onDeposit(amount, source);
                        setState(() => _state = GoalCardState.collapsed);
                      },
                      onCancel: () =>
                          setState(() => _state = GoalCardState.expandedActions),
                    ),
                  if (_state == GoalCardState.expandedEdit)
                    GoalEditForm(
                      initialTitle: widget.goal.title,
                      initialTarget: widget.goal.targetAmount,
                      initialDeadline: widget.goal.dueDateLabel,
                      initialPeriod: widget.goal.periodLabel,
                      isLocked: widget.goal.isLocked,
                      onSave: (title, target, deadline, period) {
                        widget.onEdit(title, target, deadline, period);
                        setState(() => _state = GoalCardState.collapsed);
                      },
                      onCancel: () =>
                          setState(() => _state = GoalCardState.expandedActions),
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
