import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'core/app_theme.dart';
import 'viewmodels/settings_viewmodel.dart';
import 'viewmodels/home_viewmodel.dart';
import 'views/scan_page.dart';
import 'views/home_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final settings = SettingsViewModel();
  await settings.load(); // đọc SharedPreferences trước khi render

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: settings),
        ChangeNotifierProvider(
          create: (_) => HomeViewModel(settings: settings)..init(),
        ),
      ],
      child: const VoiceUidApp(),
    ),
  );
}

class VoiceUidApp extends StatelessWidget {
  const VoiceUidApp({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsViewModel>();
    return MaterialApp(
      title:                    'Voice UID',
      debugShowCheckedModeBanner: false,
      themeMode:                settings.themeMode,
      theme:                    AppTheme.light(),
      darkTheme:                AppTheme.dark(),
      home:                     const _AppShell(),
    );
  }
}

/// Shell bao ngoài: xử lý nút back (exit dialog) + navigation
class _AppShell extends StatelessWidget {
  const _AppShell();

  Future<bool> _onWillPop(BuildContext context) async {
    final vm = context.read<HomeViewModel>();
    // Nếu đang connected, back → disconnect (không hỏi thoát)
    if (vm.isConnected) {
      await vm.disconnect();
      return false;
    }

    // Hỏi thoát app
    final exit = await showDialog<bool>(
      context: context,
      builder: (_) => _ExitDialog(),
    );
    return exit ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final shouldExit = await _onWillPop(context);
        if (shouldExit && context.mounted) {
          SystemNavigator.pop();
        }
      },
      child: const _RootNavigator(),
    );
  }
}

class _RootNavigator extends StatelessWidget {
  const _RootNavigator();

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<HomeViewModel>();

    if (!vm.ready) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: context.cAccent),
              const SizedBox(height: 16),
              Text('Đang khởi động...', style: TextStyle(color: context.cTextDim)),
            ],
          ),
        ),
      );
    }

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 350),
      child: vm.isConnected
          ? const HomePage(key: ValueKey('home'))
          : const ScanPage(key: ValueKey('scan')),
    );
  }
}

class _ExitDialog extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;
    return AlertDialog(
      backgroundColor: context.cCard,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(
        'Thoát ứng dụng?',
        style: TextStyle(color: context.cText, fontWeight: FontWeight.w700),
      ),
      content: Text(
        'Bạn có chắc muốn thoát Voice UID không?',
        style: TextStyle(color: context.cTextDim),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text('Ở lại', style: TextStyle(color: context.cAccent)),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.no,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          onPressed: () => Navigator.pop(context, true),
          child: const Text('Thoát'),
        ),
      ],
    );
  }
}