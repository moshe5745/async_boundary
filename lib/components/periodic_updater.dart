import 'dart:async';

import 'package:async_boundary/async_boundary.dart';
import 'package:flutter/material.dart';

class PeriodicUpdater extends StatefulWidget {
  const PeriodicUpdater({super.key});

  @override
  State<PeriodicUpdater> createState() => _PeriodicUpdaterState();
}

class _PeriodicUpdaterState extends State<PeriodicUpdater> {
  String? _data = 'Initial...';
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _fetchInitial();  // Initial fetch (tracked, shows spinner)
    _timer = Timer.periodic(const Duration(seconds: 5), (_) => _updatePeriodic());
  }

  Future<void> _fetchInitial() async {
    (() async {  // Callback for initial (include)
      await Future.delayed(const Duration(seconds: 2));  // Simulate initial load
      if (mounted) setState(() => _data = 'Initial Data Loaded');
    }).asyncBoundary(context, tracked: true);
  }

  void _updatePeriodic() {
    (() async {  // Callback for update (exclude)
      await Future.delayed(const Duration(seconds: 1));  // Background update
      if (mounted) setState(() => _data = 'Updated at ${DateTime.now().second}');
    }).asyncBoundary(context, tracked: false);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Text(_data ?? 'Periodic updater...'),
      ),
    );
  }
}