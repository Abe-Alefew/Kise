enum GoalStatusFilter {
  all,
  active,
  completed,
  canceled,
}

extension GoalStatusFilterX on GoalStatusFilter {
  String get apiValue {
    switch (this) {
      case GoalStatusFilter.all:
        return 'all';
      case GoalStatusFilter.active:
        return 'active';
      case GoalStatusFilter.completed:
        return 'completed';
      case GoalStatusFilter.canceled:
        return 'canceled';
    }
  }

  String get uiLabel {
    switch (this) {
      case GoalStatusFilter.all:
        return 'All';
      case GoalStatusFilter.active:
        return 'Active';
      case GoalStatusFilter.completed:
        return 'Completed';
      case GoalStatusFilter.canceled:
        return 'Canceled';
    }
  }

  Map<String, String> toQueryParameters() {
    if (this == GoalStatusFilter.all) {
      return const {};
    }
    return {'status': apiValue};
  }

  static GoalStatusFilter fromApiValue(String value) {
    switch (value.toLowerCase()) {
      case 'active':
        return GoalStatusFilter.active;
      case 'completed':
        return GoalStatusFilter.completed;
      case 'canceled':
        return GoalStatusFilter.canceled;
      case 'all':
      default:
        return GoalStatusFilter.all;
    }
  }

  static GoalStatusFilter fromUiLabel(String label) {
    switch (label.trim()) {
      case 'Active':
        return GoalStatusFilter.active;
      case 'Completed':
        return GoalStatusFilter.completed;
      case 'Canceled':
        return GoalStatusFilter.canceled;
      case 'All':
      default:
        return GoalStatusFilter.all;
    }
  }
}