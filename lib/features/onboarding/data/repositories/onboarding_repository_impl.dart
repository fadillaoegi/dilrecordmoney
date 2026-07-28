import '../../domain/repositories/onboarding_repository.dart';
import '../datasources/onboarding_local_datasource.dart';

/// Implementasi [OnboardingRepository] yang men-delegasikan ke sumber data lokal.
class OnboardingRepositoryImpl implements OnboardingRepository {
  const OnboardingRepositoryImpl(this._local);

  final OnboardingLocalDataSource _local;

  @override
  bool isOnboardingSeen() => _local.getOnboardingSeen();

  @override
  Future<void> markOnboardingSeen() => _local.setOnboardingSeen(true);
}
