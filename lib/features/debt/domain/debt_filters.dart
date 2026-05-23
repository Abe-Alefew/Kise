enum DebtListFilter {
  all,
  active,
  lent,
  borrowed,
  settled,
}

extension DebtListFilterX on DebtListFilter {
  String get apiValue {
    switch (this) {
      case DebtListFilter.all:
        return 'all';
      case DebtListFilter.active:
        return 'active';
      case DebtListFilter.lent:
        return 'lent';
      case DebtListFilter.borrowed:
        return 'borrowed';
      case DebtListFilter.settled:
        return 'settled';
    }
  }

  String get uiLabel {
    switch (this) {
      case DebtListFilter.all:
        return 'All';
      case DebtListFilter.active:
        return 'Active';
      case DebtListFilter.lent:
        return 'Lent';
      case DebtListFilter.borrowed:
        return 'Borrowed';
      case DebtListFilter.settled:
        return 'Settled';
    }
  }

  Map<String, String> toQueryParameters() {
    if (this == DebtListFilter.all) {
      return const {};
    }
    return {'filter': apiValue};
  }

  static DebtListFilter fromApiValue(String value) {
    switch (value.toLowerCase()) {
      case 'active':
        return DebtListFilter.active;
      case 'lent':
        return DebtListFilter.lent;
      case 'borrowed':
        return DebtListFilter.borrowed;
      case 'settled':
        return DebtListFilter.settled;
      case 'all':
      default:
        return DebtListFilter.all;
    }
  }

  static DebtListFilter fromUiLabel(String label) {
    switch (label.trim()) {
      case 'Active':
        return DebtListFilter.active;
      case 'Lent':
        return DebtListFilter.lent;
      case 'Borrowed':
        return DebtListFilter.borrowed;
      case 'Settled':
        return DebtListFilter.settled;
      case 'All':
      default:
        return DebtListFilter.all;
    }
  }
}