import 'package:flutter/gestures.dart' show PointerDeviceKind;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../content/loader.dart';
import '../engine/game_controller.dart';
import '../theme/app_theme.dart';

/// The whole joke catalog on a brass drum. Spin it to browse; tap a line to
/// preview it; hit Tell it to deliver whatever is on the centre line.
///
/// Order is stable (grouped by the stretch a joke belongs to, then by title) so
/// players learn where things live. On entry the drum rolls to the middle of the
/// jokes that suit the current stretch. It never shows a score: the title and the
/// plain facts (flavour, beats, risky, told count) are all the hint there is.
class JokeDrum extends StatefulWidget {
  const JokeDrum({super.key, required this.controller});

  final GameController controller;

  @override
  State<JokeDrum> createState() => _JokeDrumState();
}

class _JokeDrumState extends State<JokeDrum> {
  /// Where the drum was last left, so the next stretch rolls from there.
  static int? _lastIndex;

  static const double _rowExtent = 36;

  late final List<String> _ids;
  late final FixedExtentScrollController _wheel;
  int _selected = 0;
  String? _previewId;

  @override
  void initState() {
    super.initState();
    final g = widget.controller.g;
    final ids = List<String>.of(g.run!.hand);
    String groupOf(String id) {
      final j = g.jokes[id]!;
      return j.at.isEmpty ? '' : j.at.first;
    }

    ids.sort((a, b) {
      final c = groupOf(a).compareTo(groupOf(b));
      return c != 0 ? c : g.jokes[a]!.title.compareTo(g.jokes[b]!.title);
    });
    _ids = ids;

    // Target: the middle of the jokes that suit this stretch (not the best one,
    // so choosing is still the player's job). Nothing on topic: stay put.
    final onTopic = <int>[
      for (var i = 0; i < ids.length; i++)
        if (g.jokeOnTopic(g.jokes[ids[i]]!)) i,
    ];
    final target = onTopic.isNotEmpty
        ? onTopic[onTopic.length ~/ 2]
        : (_lastIndex ?? 0).clamp(0, ids.length - 1);
    final from = (_lastIndex ?? target).clamp(0, ids.length - 1);
    _selected = from;
    _wheel = FixedExtentScrollController(initialItem: from);
    if (from != target) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _wheel.hasClients) {
          _wheel.animateToItem(
            target,
            duration: const Duration(milliseconds: 700),
            curve: Curves.easeInOutCubic,
          );
        }
      });
    }
  }

  @override
  void dispose() {
    _wheel.dispose();
    super.dispose();
  }

  void _tapRow(int i) {
    HapticFeedback.selectionClick();
    final id = _ids[i];
    setState(() => _previewId = _previewId == id && i == _selected ? null : id);
    if (i != _selected) {
      _wheel.animateToItem(
        i,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    }
  }

  void _tell() {
    HapticFeedback.mediumImpact();
    final id = _ids[_selected];
    setState(() => _previewId = null);
    widget.controller.tellJoke(id);
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.controller;
    final g = c.g;
    final r = g.run!;
    final S = c.strings;
    final nodeS = Map<String, dynamic>.from(S['node'] as Map);
    final metaS = Map<String, dynamic>.from(S['jokeMeta'] as Map);
    final tellLabel = (nodeS['tellIt'] as String?) ?? 'Tell it';

    final id = _ids[_selected];
    final j = g.jokes[id]!;
    final canTell = !r.awaitingContinue && r.beat >= j.attentionCost;

    final bits = <String>[
      j.flavors.join(' / '),
      j.attentionCost == 1
          ? fill(metaS['beats'] as String, {'n': j.attentionCost})
          : fill(metaS['beatsPlural'] as String, {'n': j.attentionCost}),
      if ((r.used[id] ?? 0) > 0) fill(metaS['told'] as String, {'n': r.used[id]}),
      if (j.risk != null) metaS['risky'] as String,
      if (j.deadpan) metaS['deadpan'] as String,
    ].where((b) => b.isNotEmpty).toList();

    final scroll = ScrollConfiguration.of(context).copyWith(
      dragDevices: {
        PointerDeviceKind.touch,
        PointerDeviceKind.mouse,
        PointerDeviceKind.trackpad,
        PointerDeviceKind.stylus,
      },
    );

    return Container(
      decoration: BoxDecoration(
        color: AppColors.chart.withValues(alpha: 0.93),
        border: Border.all(color: AppColors.water, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: Stack(
                    children: [
                      ScrollConfiguration(
                        behavior: scroll,
                        child: ListWheelScrollView.useDelegate(
                          controller: _wheel,
                          itemExtent: _rowExtent,
                          diameterRatio: 2.6,
                          perspective: 0.003,
                          overAndUnderCenterOpacity: 0.55,
                          physics: const FixedExtentScrollPhysics(),
                          onSelectedItemChanged: (i) {
                            _lastIndex = i;
                            HapticFeedback.selectionClick();
                            setState(() => _selected = i);
                          },
                          childDelegate: ListWheelChildBuilderDelegate(
                            childCount: _ids.length,
                            builder: (context, i) => _Line(
                              title: g.jokes[_ids[i]]!.title,
                              times: r.used[_ids[i]] ?? 0,
                              onTap: () => _tapRow(i),
                            ),
                          ),
                        ),
                      ),
                      // Brass bars around the centre line.
                      Positioned.fill(
                        child: IgnorePointer(
                          child: Center(
                            child: Container(
                              height: _rowExtent,
                              decoration: const BoxDecoration(
                                border: Border.symmetric(
                                  horizontal: BorderSide(color: AppColors.brass, width: 2),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: SizedBox(
                    width: 84,
                    child: _TellButton(label: tellLabel, onTap: canTell ? _tell : null),
                  ),
                ),
                const SizedBox(width: 6),
              ],
            ),
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 150),
            alignment: Alignment.topCenter,
            child: _previewId == id
                ? Container(
                    padding: const EdgeInsets.fromLTRB(10, 6, 6, 6),
                    decoration: const BoxDecoration(
                      border: Border(top: BorderSide(color: AppColors.water, width: 1)),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            '${j.title}\n${bits.join(' · ').toUpperCase()}',
                            style: AppTheme.mono.copyWith(fontSize: 12, letterSpacing: 1),
                          ),
                        ),
                        const SizedBox(width: 8),
                        SizedBox(
                          width: 84,
                          child: _TellButton(label: tellLabel, onTap: canTell ? _tell : null),
                        ),
                      ],
                    ),
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}

class _Line extends StatelessWidget {
  const _Line({required this.title, required this.times, required this.onTap});

  final String title;
  final int times;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Opacity(
        // Jokes already told fade, so you can see what has worn out.
        opacity: times > 0 ? 0.4 : 1,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTheme.display.copyWith(fontSize: 15, fontWeight: FontWeight.w500),
                ),
              ),
              if (times > 0)
                Text('×$times', style: AppTheme.mono.copyWith(fontSize: 12)),
            ],
          ),
        ),
      ),
    );
  }
}

class _TellButton extends StatelessWidget {
  const _TellButton({required this.label, required this.onTap});

  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return Semantics(
      button: true,
      enabled: enabled,
      label: label,
      child: Opacity(
        opacity: enabled ? 1 : 0.4,
        child: Material(
          color: AppColors.brass,
          child: InkWell(
            onTap: onTap,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 44),
              child: Center(
                child: Text(
                  label.toUpperCase(),
                  style: AppTheme.display.copyWith(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.2,
                    color: AppColors.chart,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
