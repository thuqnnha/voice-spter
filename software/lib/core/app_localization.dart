import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../viewmodels/settings_viewmodel.dart';
import 'app_strings.dart';

extension LocalizationExt on BuildContext {
  AppStrings get txt {
    final settings = read<SettingsViewModel>();
    return AppStrings(settings.language);
  }
}