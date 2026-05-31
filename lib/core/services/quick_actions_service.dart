import 'package:flutter/foundation.dart';
import 'package:quick_actions/quick_actions.dart';

/// Bridges native launcher long-press shortcuts (Android App Shortcuts /
/// iOS Home Screen Quick Actions) to in-app handlers.
///
/// Lifecycle:
///   1. [bootstrap] is called once at app start (before `runApp`).
///      Registers shortcut items with the OS and subscribes to taps.
///   2. The page that knows how to react (currently `MainPage`) calls
///      [registerHandler] after its first frame.
///   3. If a shortcut tap arrived before a handler was registered
///      (cold start case — the user launched the app via the shortcut),
///      it is queued and flushed as soon as a handler appears.
class QuickActionsService {
  QuickActionsService._();
  static final QuickActionsService instance = QuickActionsService._();

  /// Shortcut identifier for the "Catat dengan AI" action.
  static const String shortcutQuickAi = 'action_quick_ai';

  final QuickActions _quickActions = const QuickActions();

  void Function(String type)? _handler;
  String? _pendingType;
  bool _initialized = false;

  Future<void> bootstrap() async {
    if (_initialized) return;
    _initialized = true;

    _quickActions.initialize(_dispatch);

    try {
      await _quickActions.setShortcutItems(const <ShortcutItem>[
        ShortcutItem(
          type: shortcutQuickAi,
          localizedTitle: 'Catat dengan AI',
          localizedSubtitle: 'Suara atau teks',
          icon: 'ic_shortcut_ai',
        ),
      ]);
    } catch (e) {
      // Surface during dev; never crash the app over a shortcut config.
      debugPrint('QuickActionsService: setShortcutItems failed: $e');
    }
  }

  void registerHandler(void Function(String type) handler) {
    _handler = handler;
    final queued = _pendingType;
    if (queued != null) {
      _pendingType = null;
      handler(queued);
    }
  }

  void clearHandler() {
    _handler = null;
  }

  void _dispatch(String type) {
    final h = _handler;
    if (h != null) {
      h(type);
    } else {
      _pendingType = type;
    }
  }
}
