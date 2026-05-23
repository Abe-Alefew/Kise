import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kise/features/home/data/home_dashboard_repository.dart';
import 'package:kise/features/home/domain/home_dashboard_models.dart';

class HomeDashboardNotifier extends AsyncNotifier<HomeDashboardBundle> {
  static const String defaultRange = '6m';

  @override
  Future<HomeDashboardBundle> build() {
    return _load();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(_load);
  }

  Future<HomeDashboardBundle> _load() {
    return ref.read(homeDashboardRepositoryProvider).fetchHome(
          range: defaultRange,
        );
  }
}

final homeDashboardProvider =
    AsyncNotifierProvider<HomeDashboardNotifier, HomeDashboardBundle>(
  HomeDashboardNotifier.new,
);
