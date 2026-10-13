import 'dart:async';

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_text.dart';

/// Short messages at the top of the screen, like "Expense saved" with
/// "Undo". They slide in under the status bar, go away after a few
/// seconds, and can be swiped up. Only one shows at a time.
///
/// Get it with [TopToast.of] before leaving a page, then call [show]:
///
/// ```dart
/// final toast = TopToast.of(context);
/// context.pop();
/// toast.show('Expense saved', actionLabel: 'Undo', onAction: undo);
/// ```
class TopToast {
  TopToast._(this._overlay);

  /// Uses the app's top overlay, so the message stays when a page closes.
  factory TopToast.of(BuildContext context) =>
      TopToast._(Overlay.of(context, rootOverlay: true));

  final OverlayState _overlay;

  /// The message on screen now, if any.
  static OverlayEntry? _current;

  /// How long a message stays.
  static const duration = Duration(seconds: 4);

  void show(String message, {String? actionLabel, VoidCallback? onAction}) {
    hideCurrent();
    late final OverlayEntry entry;
    entry = OverlayEntry(
      builder: (_) => _Toast(
        message: message,
        actionLabel: actionLabel,
        onAction: onAction,
        onDone: () {
          if (_current == entry) hideCurrent();
        },
      ),
    );
    _current = entry;
    _overlay.insert(entry);
  }

  /// Removes the message on screen now.
  static void hideCurrent() {
    final entry = _current;
    _current = null;
    // Not mounted when the app was closed (or a test ended).
    if (entry != null && entry.mounted) entry.remove();
  }
}

/// Shortcut for a message without an action.
void showToast(BuildContext context, String message) =>
    TopToast.of(context).show(message);

class _Toast extends StatefulWidget {
  const _Toast({
    required this.message,
    required this.actionLabel,
    required this.onAction,
    required this.onDone,
  });

  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;
  final VoidCallback onDone;

  @override
  State<_Toast> createState() => _ToastState();
}

class _ToastState extends State<_Toast> with SingleTickerProviderStateMixin {
  late final _motion = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 220),
  );
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _motion.forward();
    _timer = Timer(TopToast.duration, _close);
  }

  Future<void> _close() async {
    _timer?.cancel();
    if (!mounted) return;
    await _motion.reverse();
    if (mounted) widget.onDone();
  }

  @override
  void dispose() {
    // The timer must not outlive the message.
    _timer?.cancel();
    _motion.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final curve = CurvedAnimation(parent: _motion, curve: Curves.easeOutCubic);
    final action = widget.actionLabel;

    return Positioned(
      top: MediaQuery.paddingOf(context).top + 8,
      left: 16,
      right: 16,
      child: SlideTransition(
        position: Tween(
          begin: const Offset(0, -0.6),
          end: Offset.zero,
        ).animate(curve),
        child: FadeTransition(
          opacity: curve,
          child: Dismissible(
            key: const ValueKey('toast'),
            direction: DismissDirection.up,
            onDismissed: (_) => widget.onDone(),
            child: Semantics(
              container: true,
              liveRegion: true,
              child: Material(
                // Dark on light (and light on dark), so it stands apart
                // from the page.
                color: c.textPrimary,
                elevation: 6,
                shadowColor: const Color(0x40000000),
                borderRadius: BorderRadius.circular(14),
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    16,
                    6,
                    action == null ? 16 : 6,
                    6,
                  ),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(minHeight: 40),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            widget.message,
                            style: AppText.label14.copyWith(
                              color: c.background,
                            ),
                          ),
                        ),
                        if (action != null)
                          TextButton(
                            onPressed: () {
                              widget.onAction?.call();
                              _close();
                            },
                            style: TextButton.styleFrom(
                              foregroundColor: c.background,
                              textStyle: AppText.label14Strong,
                            ),
                            child: Text(action),
                          ),
                      ],
                    ),
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
