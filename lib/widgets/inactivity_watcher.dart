import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../router.dart';
import '../state/auth_notifier.dart';

class InactivityWatcher extends StatefulWidget {
  final Widget child;
  final Duration timeout;
  final Duration warningBefore;

  const InactivityWatcher({
    super.key,
    required this.child,
    this.timeout = const Duration(minutes: 3),
    this.warningBefore = const Duration(seconds: 30),
  });

  @override
  State<InactivityWatcher> createState() => _InactivityWatcherState();
}

class _InactivityWatcherState extends State<InactivityWatcher> {
  Timer? _warningTimer;
  Timer? _logoutTimer;
  bool _dialogOpen = false;

  @override
  void initState() {
    super.initState();
    HardwareKeyboard.instance.addHandler(_onKey);
    _resetTimers();
  }

  @override
  void didUpdateWidget(InactivityWatcher oldWidget) {
    super.didUpdateWidget(oldWidget);
    _resetTimers();
  }

  bool _onKey(KeyEvent event) {
    _onUserActivity();
    return false;
  }

  void _onUserActivity() {
    final auth = context.read<AuthNotifier>();
    if (!auth.isAuthenticated) return;
    if (_dialogOpen) return;
    _resetTimers();
  }

  void _resetTimers() {
    _warningTimer?.cancel();
    _logoutTimer?.cancel();

    final diff = widget.timeout - widget.warningBefore;
    final warningDelay = diff.isNegative ? Duration.zero : diff;

    _warningTimer = Timer(warningDelay, _showWarningDialog);
    _logoutTimer = Timer(widget.timeout, _performLogout);
  }

  void _showWarningDialog() {
    final auth = context.read<AuthNotifier>();
    if (!auth.isAuthenticated || !mounted || _dialogOpen) return;

    final navContext = rootNavigatorKey.currentContext;
    if (navContext == null) return;

    setState(() => _dialogOpen = true);

    showDialog(
      context: navContext,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.timer_outlined, color: Colors.orange),
            SizedBox(width: 8),
            Text('Таймаут сессии'),
          ],
        ),
        content: const Text(
          'Вы не проявляли активности. Сессия будет завершена через 30 секунд в целях безопасности.',
        ),
        actions: [
          FilledButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              setState(() => _dialogOpen = false);
              _resetTimers();
            },
            child: const Text('Остаться в системе'),
          ),
        ],
      ),
    );
  }

  Future<void> _performLogout() async {
    if (!mounted) return;
    if (_dialogOpen) {
      final navContext = rootNavigatorKey.currentContext;
      if (navContext != null) {
        Navigator.of(navContext, rootNavigator: true).pop();
      }
      setState(() => _dialogOpen = false);
    }
    await context.read<AuthNotifier>().logout();
  }

  @override
  void dispose() {
    HardwareKeyboard.instance.removeHandler(_onKey);
    _warningTimer?.cancel();
    _logoutTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: (_) => _onUserActivity(),
      child: widget.child,
    );
  }
}
