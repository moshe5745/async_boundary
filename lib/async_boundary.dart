import 'dart:async';

import 'package:flutter/material.dart';

/// Tracker for async tasks
class AsyncTaskTracker {
  final Set<Future<dynamic>> _manualTasks = <Future<dynamic>>{};
  int _autoTasks = 0;  // For zone-tracked microtasks
  final StreamController<int> _controller = StreamController<int>.broadcast();

  /// Stream of current active task count (0 = idle)
  Stream<int> get taskCountStream => _controller.stream;

  /// Current count (read-only)
  int get taskCount => _manualTasks.length + _autoTasks;

  /// Manual register (for Future.asyncBoundary)
  void registerManual(Future<dynamic> future) {
    if (_manualTasks.contains(future)) return;

    _manualTasks.add(future);
    _updateCount();

    future.whenComplete(() {
      _manualTasks.remove(future);
      _updateCount();
    });
  }

  /// Auto increment/decrement (for zone microtasks)
  void _incrementAuto() {
    _autoTasks++;
    _updateCount();
  }

  void _decrementAuto() {
    _autoTasks = _autoTasks > 0 ? _autoTasks - 1 : 0;
    _updateCount();
  }

  void _updateCount() => _controller.add(taskCount);

  void dispose() => _controller.close();
}

/// Async boundary widget
class AsyncBoundary extends StatefulWidget {
  const AsyncBoundary({
    super.key,
    required this.child,
    this.loadingWidget = const Center(child: CircularProgressIndicator()),
    this.errorHandler,
  });

  final Widget child;
  final Widget loadingWidget;
  final Widget? Function(BuildContext context, Object error, StackTrace stackTrace)? errorHandler;

  /// Find the nearest boundary state (for asyncBoundary methods)
  static AsyncBoundaryState? maybeOf(BuildContext context) {
    return context.findAncestorStateOfType<AsyncBoundaryState>();
  }

  @override
  State<AsyncBoundary> createState() => AsyncBoundaryState();
}

class AsyncBoundaryState extends State<AsyncBoundary> {
  final AsyncTaskTracker _tracker = AsyncTaskTracker();
  Object? _error;
  StackTrace? _stackTrace;

  @override
  void dispose() {
    _tracker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Generic wrapper for void callbacks
    void Function() wrapAction(void Function() action) {
      return () {
        try {
          action();
        } finally {
          _tracker._decrementAuto();
        }
      };
    }

    Widget? zonedChild = runZonedGuarded<Widget?>(
          () => widget.child,
          (error, stack) {
        setState(() {
          _error = error;
          _stackTrace = stack;
        });
        print("Uncaught error in async boundary: $error\n$stack");
      },
      zoneSpecification: ZoneSpecification(
        // Auto-track microtasks (async/await, Future.then) — ignores timers/delays by default
        scheduleMicrotask: (Zone self, ZoneDelegate parent, Zone zone, void Function() f) {
          _tracker._incrementAuto();
          parent.scheduleMicrotask(zone, wrapAction(f));
        },
        // No overrides for createTimer/createPeriodicTimer — ignored unless manually tracked
      ),
    );

    return StreamBuilder<int>(
      stream: _tracker.taskCountStream,
      initialData: 0,
      builder: (context, snapshot) {
        if (_error != null) {
          final errorUI = widget.errorHandler?.call(context, _error!, _stackTrace!);
          return errorUI ?? Center(child: Text('Error: $_error'));  // Fallback if null
        }
        final bool isLoading = (snapshot.data ?? 0) > 0;
        return isLoading ? widget.loadingWidget : (zonedChild ?? const SizedBox.shrink());
      },
    );
  }
}

/// Extension for manual include/exclude on Future (tracked: true to include/manual track, false no-op)
extension AsyncBoundaryFutureExtension<T> on Future<T> {
  /// Include/exclude this future in the nearest AsyncBoundary (tracked: true to manually track, false no-op)
  Future<T> asyncBoundary(BuildContext context, {bool tracked = true}) {
    if (tracked) {
      final state = AsyncBoundary.maybeOf(context);
      if (state == null) return this;  // No-op if no boundary
      state._tracker.registerManual(this as Future<dynamic>);
    }
    return this;
  }
}

/// Extension for include/exclude on callbacks (tracked: true to include/run normal, false to exclude/run untracked)
extension AsyncBoundaryFunctionExtension<T> on T Function() {
  /// Include/exclude this callback in the nearest AsyncBoundary (tracked: true to run tracked, false untracked)
  T asyncBoundary(BuildContext context, {bool tracked = true}) {
    if (tracked) {
      // Run in default zone (auto-tracked for microtasks)
      return this();
    } else {
      // Run in excluded sub-zone (no auto-tracking)
      return runZoned<T>(
        this,
        zoneSpecification: const ZoneSpecification(),  // Empty spec — no tracking overrides
      );
    }
  }
}