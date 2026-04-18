import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/app_theme.dart';
import '../viewmodels/home_viewmodel.dart';
import '../viewmodels/settings_viewmodel.dart';

class ScanPage extends StatelessWidget {
  const ScanPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Consumer<HomeViewModel>(
        builder: (context, vm, _) {
          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Top bar: theme toggle ──
                  Align(
                    alignment: Alignment.centerRight,
                    child: Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: _ThemeToggle(),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // ── Title ──
                  Text('VOICE', style: TextStyle(
                    color: context.cAccent,
                    fontSize: 44,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 6,
                    height: 1,
                  )),
                  Text('UID', style: TextStyle(
                    color: context.cText,
                    fontSize: 44,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 6,
                    height: 1,
                  )),
                  const SizedBox(height: 6),
                  Text('ESP32 · BLE · TFLite · TTS', style: TextStyle(
                    color: context.cTextDim, fontSize: 10, letterSpacing: 2,
                  )),

                  const Spacer(),

                  // ── Radar ──
                  Center(
                    child: _BleRadar(scanning: vm.appState == AppState.scanning),
                  ),

                  const Spacer(),

                  // ── Status ──
                  Center(
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 200),
                      child: Text(
                        key: ValueKey(vm.statusMsg),
                        vm.statusMsg,
                        style: TextStyle(color: context.cTextDim, fontSize: 12, letterSpacing: 1),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // ── Scan button ──
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: _ScanButton(state: vm.appState, onTap: vm.startScan),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _ThemeToggle extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsViewModel>();
    return GestureDetector(
      onTap: settings.toggleTheme,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: context.cCard,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: context.cBorder),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              settings.isDark ? Icons.light_mode : Icons.dark_mode,
              size: 14,
              color: context.cTextDim,
            ),
            const SizedBox(width: 6),
            Text(
              settings.isDark ? 'Sáng' : 'Tối',
              style: TextStyle(color: context.cTextDim, fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }
}

class _ScanButton extends StatelessWidget {
  final AppState state;
  final VoidCallback onTap;
  const _ScanButton({required this.state, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final loading = state == AppState.scanning || state == AppState.connecting;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        color: loading ? context.cCard : context.cAccent,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: loading ? context.cAccent.withOpacity(0.4) : context.cAccent,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: loading ? null : onTap,
          borderRadius: BorderRadius.circular(12),
          child: Center(
            child: loading
                ? Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: 14, height: 14,
                  child: CircularProgressIndicator(
                    strokeWidth: 2, color: context.cAccent,
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  state == AppState.connecting ? 'ĐANG KẾT NỐI...' : 'ĐANG QUÉT...',
                  style: TextStyle(
                    color: context.cAccent, fontSize: 11, letterSpacing: 2,
                  ),
                ),
              ],
            )
                : Text(
              'QUÉT THIẾT BỊ',
              style: TextStyle(
                color: context.isDark ? AppColors.darkBg : Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w800,
                letterSpacing: 3,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _BleRadar extends StatefulWidget {
  final bool scanning;
  const _BleRadar({required this.scanning});
  @override
  State<_BleRadar> createState() => _BleRadarState();
}

class _BleRadarState extends State<_BleRadar> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 1600),
    )..repeat();
  }
  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 140, height: 140,
    child: widget.scanning
        ? AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) => CustomPaint(
        painter: _RadarPainter(_ctrl.value, context.cAccent),
      ),
    )
        : Center(
      child: Icon(
        Icons.bluetooth,
        color: context.cAccent.withOpacity(0.5),
        size: 52,
      ),
    ),
  );
}

class _RadarPainter extends CustomPainter {
  final double t;
  final Color color;
  _RadarPainter(this.t, this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final maxR   = size.width / 2;
    for (int i = 0; i < 3; i++) {
      final phase  = (t + i / 3) % 1.0;
      final radius = phase * maxR;
      final opacity= (1 - phase) * 0.55;
      canvas.drawCircle(
        center, radius,
        Paint()
          ..color = color.withOpacity(opacity)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.8,
      );
    }
    canvas.drawCircle(center, 7, Paint()..color = color);
  }

  @override
  bool shouldRepaint(_RadarPainter old) => old.t != t;
}