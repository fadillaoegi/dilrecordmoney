import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/constants/app_constants.dart';

/// Sumber data lokal untuk status onboarding (SharedPreferences).
abstract interface class OnboardingLocalDataSource {
  bool getOnboardingSeen();
  Future<void> setOnboardingSeen(bool value);
}

class OnboardingLocalDataSourceImpl implements OnboardingLocalDataSource {
  const OnboardingLocalDataSourceImpl(this._prefs);

  final SharedPreferences _prefs;

  @override
  bool getOnboardingSeen() {
    return _prefs.getBool(AppConstants.kOnboardingSeen) ?? false;
  }

  @override
  Future<void> setOnboardingSeen(bool value) {
    return _prefs.setBool(AppConstants.kOnboardingSeen, value);
  }
}
