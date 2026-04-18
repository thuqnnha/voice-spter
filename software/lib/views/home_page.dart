import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/app_theme.dart';
import '../viewmodels/home_viewmodel.dart';
import '../viewmodels/settings_viewmodel.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            _Header(),
            Expanded(
              child: Consumer<HomeViewModel>(
                builder: (context, vm, _) => SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                  child: Column(
                    children: [
                      _PredictionCard(vm: vm),
                      const SizedBox(height: 12),
                      _ConfidenceSection(vm: vm),
                      const SizedBox(height: 12),
                      _CollapsibleSection(
                        title: 'RAW FEATURES',
                        visible: vm.showFeatures,
                        onToggle: vm.toggleFeatures,
                        child: _FeaturesGrid(vm: vm),
                      ),
                      const SizedBox(height: 12),
                      _CollapsibleSection(
                        title: 'LỊCH SỬ',
                        visible: vm.showHistory,
                        onToggle: vm.toggleHistory,
                        child: _HistoryList(vm: vm),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// HEADER
// ─────────────────────────────────────────────────────────────
class _Header extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final vm       = context.watch<HomeViewModel>();
    final settings = context.watch<SettingsViewModel>();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: context.cSurface,
        border: Border(
          bottom: BorderSide(color: context.cBorder, width: 1),
        ),
      ),
      child: Row(
        children: [
          // BLE blink dot
          _BlinkDot(color: context.cAccent),
          const SizedBox(width: 10),

          // Title + status
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'VOICE UID',
                  style: TextStyle(
                    color: context.cAccent,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 3,
                  ),
                ),
                Text(
                  vm.statusMsg,
                  style: TextStyle(color: context.cTextDim, fontSize: 10),
                ),
              ],
            ),
          ),

          // Pred count chip
          _MiniChip(label: 'PRED', value: '${vm.predCount}', context: context),
          const SizedBox(width: 6),

          // Mute toggle
          _IconBtn(
            icon: settings.isMuted ? Icons.volume_off : Icons.volume_up,
            color: settings.isMuted ? AppColors.no : context.cAccent,
            tooltip: settings.isMuted ? 'Bật tiếng' : 'Tắt tiếng',
            onTap: settings.toggleMute,
          ),

          // Dark/light mode toggle
          _IconBtn(
            icon: settings.isDark ? Icons.light_mode : Icons.dark_mode,
            color: context.cTextDim,
            tooltip: settings.isDark ? 'Chế độ sáng' : 'Chế độ tối',
            onTap: settings.toggleTheme,
          ),

          // Disconnect
          _IconBtn(
            icon: Icons.bluetooth_disabled,
            color: AppColors.no.withOpacity(0.8),
            tooltip: 'Ngắt kết nối',
            onTap: () => context.read<HomeViewModel>().disconnect(),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// PREDICTION CARD
// ─────────────────────────────────────────────────────────────
class _PredictionCard extends StatelessWidget {
  final HomeViewModel vm;
  const _PredictionCard({required this.vm});

  Color _color(VoiceLabel l, BuildContext ctx) => switch (l) {
    VoiceLabel.yes    => AppColors.yes,
    VoiceLabel.no     => AppColors.no,
    VoiceLabel.silent => AppColors.silent,
  };

  String _emoji(VoiceLabel l) => switch (l) {
    VoiceLabel.yes    => '✅',
    VoiceLabel.no     => '❌',
    VoiceLabel.silent => '🔇',
  };

  @override
  Widget build(BuildContext context) {
    final result = vm.lastResult;
    final label  = result?.label ?? VoiceLabel.silent;
    final color  = _color(label, context);
    final conf   = result?.confidence ?? 0.0;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
      decoration: BoxDecoration(
        color: context.cCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: color.withOpacity(conf > 0.7 ? 0.5 : 0.2),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(conf > 0.7 ? 0.12 : 0.03),
            blurRadius: 24,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            'NHẬN DẠNG GIỌNG NÓI',
            style: TextStyle(
              color: context.cTextDim, fontSize: 9, letterSpacing: 2.5,
            ),
          ),
          const SizedBox(height: 18),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 220),
            child: Column(
              key: ValueKey(label),
              children: [
                Text(_emoji(label), style: const TextStyle(fontSize: 52)),
                const SizedBox(height: 6),
                Text(
                  (result?.labelText ?? '—').toUpperCase(),
                  style: TextStyle(
                    color: color,
                    fontSize: 38,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 4,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Mute indicator
              if (context.watch<SettingsViewModel>().isMuted)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Row(
                    children: [
                      Icon(Icons.volume_off, size: 12, color: AppColors.no),
                      const SizedBox(width: 4),
                      Text('TẮT TIẾNG', style: TextStyle(
                        color: AppColors.no, fontSize: 9, letterSpacing: 1.5,
                      )),
                    ],
                  ),
                ),
              Text(
                result == null ? '—' : '${(conf * 100).toStringAsFixed(1)}%',
                style: TextStyle(color: context.cTextDim, fontSize: 13),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// CONFIDENCE BARS
// ─────────────────────────────────────────────────────────────
class _ConfidenceSection extends StatelessWidget {
  final HomeViewModel vm;
  const _ConfidenceSection({required this.vm});

  @override
  Widget build(BuildContext context) {
    final probs  = vm.lastResult?.probs ?? [0.333, 0.333, 0.334];
    final labels = ['Silent', 'Có', 'Không'];
    final colors = [AppColors.silent, AppColors.yes, AppColors.no];

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.cCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: context.cBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('PHÂN PHỐI XÁC SUẤT', style: TextStyle(
            color: context.cTextDim, fontSize: 9, letterSpacing: 2,
          )),
          const SizedBox(height: 12),
          ...List.generate(3, (i) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                SizedBox(
                  width: 50,
                  child: Text(labels[i], style: TextStyle(
                    color: colors[i], fontSize: 11, fontWeight: FontWeight.w600,
                  )),
                ),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: Stack(
                      children: [
                        Container(height: 7, color: context.cSurface),
                        AnimatedFractionallySizedBox(
                          duration: const Duration(milliseconds: 350),
                          widthFactor: probs[i].clamp(0.0, 1.0),
                          child: Container(
                            height: 7,
                            decoration: BoxDecoration(
                              color: colors[i],
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: 36,
                  child: Text(
                    '${(probs[i] * 100).toStringAsFixed(0)}%',
                    textAlign: TextAlign.right,
                    style: TextStyle(color: context.cTextDim, fontSize: 10),
                  ),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// COLLAPSIBLE SECTION WRAPPER
// ─────────────────────────────────────────────────────────────
class _CollapsibleSection extends StatelessWidget {
  final String title;
  final bool visible;
  final VoidCallback onToggle;
  final Widget child;

  const _CollapsibleSection({
    required this.title,
    required this.visible,
    required this.onToggle,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.cCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: context.cBorder),
      ),
      child: Column(
        children: [
          // Section header với toggle button
          InkWell(
            onTap: onToggle,
            borderRadius: visible
                ? const BorderRadius.vertical(top: Radius.circular(14))
                : BorderRadius.circular(14),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: context.cTextDim,
                      fontSize: 9,
                      letterSpacing: 2,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  AnimatedRotation(
                    duration: const Duration(milliseconds: 200),
                    turns: visible ? 0 : 0.5,
                    child: Icon(
                      Icons.keyboard_arrow_up,
                      size: 18,
                      color: context.cTextDim,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Collapsible content
          AnimatedCrossFade(
            duration: const Duration(milliseconds: 250),
            firstCurve: Curves.easeOut,
            secondCurve: Curves.easeIn,
            crossFadeState: visible
                ? CrossFadeState.showFirst
                : CrossFadeState.showSecond,
            firstChild: Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
              child: child,
            ),
            secondChild: const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// FEATURES GRID
// ─────────────────────────────────────────────────────────────
class _FeaturesGrid extends StatelessWidget {
  final HomeViewModel vm;
  const _FeaturesGrid({required this.vm});

  @override
  Widget build(BuildContext context) {
    final f = vm.rawFeatures;
    if (f.length < 6) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Text(
          'Chưa có dữ liệu',
          style: TextStyle(color: context.cTextDim, fontSize: 12),
        ),
      );
    }

    final items = [
      ('PIEZO RMS',  f[0], 'ADC'),
      ('PIEZO PEAK', f[1], 'ADC'),
      ('MIC RMS',    f[2], 'ADC'),
      ('MIC ZCR',    f[3], ''),
      ('MIC ENERGY', f[4], 'dB'),
      ('RATIO',      f[5], ''),
    ];

    return GridView.count(
      crossAxisCount: 3,
      crossAxisSpacing: 8,
      mainAxisSpacing: 8,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 1.4,
      children: items.map((it) => _FeatureTile(
        label: it.$1, value: it.$2, unit: it.$3,
      )).toList(),
    );
  }
}

class _FeatureTile extends StatelessWidget {
  final String label, unit;
  final double value;
  const _FeatureTile({required this.label, required this.value, required this.unit});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(8),
    decoration: BoxDecoration(
      color: context.cSurface,
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: context.cBorder),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(color: context.cTextDim, fontSize: 7, letterSpacing: 0.5)),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Flexible(
              child: Text(
                value.toStringAsFixed(2),
                style: TextStyle(
                  color: context.cText, fontSize: 13, fontWeight: FontWeight.w700,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (unit.isNotEmpty) ...[
              const SizedBox(width: 2),
              Text(unit, style: TextStyle(color: context.cTextDim, fontSize: 7)),
            ],
          ],
        ),
      ],
    ),
  );
}

// ─────────────────────────────────────────────────────────────
// HISTORY LIST
// ─────────────────────────────────────────────────────────────
class _HistoryList extends StatelessWidget {
  final HomeViewModel vm;
  const _HistoryList({required this.vm});

  @override
  Widget build(BuildContext context) {
    if (vm.history.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Text(
          'Chưa có lịch sử',
          style: TextStyle(color: context.cTextDim, fontSize: 12),
        ),
      );
    }
    return Column(
      children: vm.history.map((r) => _HistoryTile(result: r)).toList(),
    );
  }
}

class _HistoryTile extends StatelessWidget {
  final PredictionResult result;
  const _HistoryTile({required this.result});

  Color _color() => switch (result.label) {
    VoiceLabel.yes    => AppColors.yes,
    VoiceLabel.no     => AppColors.no,
    VoiceLabel.silent => AppColors.silent,
  };

  String _emoji() => switch (result.label) {
    VoiceLabel.yes    => '✅',
    VoiceLabel.no     => '❌',
    VoiceLabel.silent => '🔇',
  };

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 6),
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    decoration: BoxDecoration(
      color: context.cSurface,
      borderRadius: BorderRadius.circular(8),
      border: Border(left: BorderSide(color: _color(), width: 3)),
    ),
    child: Row(
      children: [
        Text(_emoji(), style: const TextStyle(fontSize: 14)),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            result.labelText,
            style: TextStyle(
              color: _color(), fontWeight: FontWeight.w600, fontSize: 13,
            ),
          ),
        ),
        Text(
          '${(result.confidence * 100).toStringAsFixed(1)}%',
          style: TextStyle(color: context.cTextDim, fontSize: 11),
        ),
      ],
    ),
  );
}

// ─────────────────────────────────────────────────────────────
// SHARED SMALL WIDGETS
// ─────────────────────────────────────────────────────────────
class _BlinkDot extends StatefulWidget {
  final Color color;
  const _BlinkDot({required this.color});
  @override
  State<_BlinkDot> createState() => _BlinkDotState();
}

class _BlinkDotState extends State<_BlinkDot> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 1100),
    )..repeat(reverse: true);
  }
  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) => FadeTransition(
    opacity: _ctrl,
    child: Container(
      width: 8, height: 8,
      decoration: BoxDecoration(color: widget.color, shape: BoxShape.circle),
    ),
  );
}

class _MiniChip extends StatelessWidget {
  final String label, value;
  final BuildContext context;
  const _MiniChip({required this.label, required this.value, required this.context});

  @override
  Widget build(_) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(
      color: context.cSurface,
      borderRadius: BorderRadius.circular(6),
      border: Border.all(color: context.cAccent.withOpacity(0.25)),
    ),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label, style: TextStyle(color: context.cTextDim, fontSize: 7, letterSpacing: 1)),
        Text(value,  style: TextStyle(color: context.cAccent,   fontSize: 13, fontWeight: FontWeight.bold)),
      ],
    ),
  );
}

class _IconBtn extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String tooltip;
  final VoidCallback onTap;

  const _IconBtn({
    required this.icon,
    required this.color,
    required this.tooltip,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => Tooltip(
    message: tooltip,
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.all(6),
        child: Icon(icon, size: 20, color: color),
      ),
    ),
  );
}