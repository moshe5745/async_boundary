import 'dart:async';
import 'dart:math';  // For random delays/errors

import 'package:flutter/material.dart';

import 'async_boundary.dart';
import 'components/data_fetcher.dart';
import 'components/excluded_fetcher.dart';
import 'components/json_parser.dart';
import 'components/manual_async_work.dart';
import 'components/periodic_updater.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Async Boundary Demo',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const DemoPage(),
    );
  }
}

// Page with multiple components (outer boundary for main spinner coordination)
class DemoPage extends StatelessWidget {
  const DemoPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Async Boundary Multi-Component Demo')),
      body: AsyncBoundary(  // Outer: Main spinner for initial loads
        loadingWidget: const Center(child: Text('Loading page components...')),
        errorHandler: (context, error, stack) => Center(child: Text('Page error: $error')),
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: const [
            DataFetcher(),  // 1: Simple fetch with delay (auto-tracked if microtask, ignored delay)
            PeriodicUpdater(),  // 2: Initial fetch (spinner), periodic updates without spinner
            ManualAsyncWork(),  // 3: Ignored async, but manually included to trigger spinner
            JsonParser(),  // Extra: Auto-tracked json parse (microtask)
            ExcludedFetcher(),  // Extra: Fully excluded async (no spinner)
          ],
        ),
      ),
    );
  }
}
