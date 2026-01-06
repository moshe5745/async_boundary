import 'dart:async';
import 'dart:convert';  // For jsonDecode simulation
import 'dart:math';  // For random errors

import 'package:async_tracker/async_boundary.dart';
import 'package:flutter/material.dart';

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

// Page with couple of widgets (Profile and News) for coordination
class DemoPage extends StatelessWidget {
  const DemoPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Async Boundary Multi-Widget Demo')),
      body: ListView(
        children: [
          // Outer boundary for page-level coordination (waits for both widgets)
          AsyncBoundary(
            loadingWidget: const Center(child: Text('Loading entire page...')),
            child: Column(
              children: [
                // Inner boundary for ProfileWidget
                AsyncBoundary(
                  loadingWidget: const Card(child: Center(child: CircularProgressIndicator())),
                  errorHandler: (context, error, stack) => Card(
                    color: Colors.red[100],
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text('Profile error: $error'),
                    ),
                  ),
                  child: const ProfileWidget(),
                ),
                // Inner boundary for NewsWidget
                AsyncBoundary(
                  loadingWidget: const Card(child: Center(child: CircularProgressIndicator())),
                  errorHandler: (context, error, stack) => Card(
                    color: Colors.red[100],
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text('News error: $error'),
                    ),
                  ),
                  child: const NewsWidget(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Widget 1: ProfileWidget with auto-tracked async, excluded future, and timers
class ProfileWidget extends StatefulWidget {
  const ProfileWidget({super.key});

  @override
  State<ProfileWidget> createState() => _ProfileWidgetState();
}

class _ProfileWidgetState extends State<ProfileWidget> {
  String? _profileData;
  String? _parsedJson;
  String? _localError;

  @override
  void initState() {
    super.initState();
    _fetchProfile();
    _parseJson();  // Auto-tracked (microtask)
    _ignoredTimer();  // Automatically ignored timer
    _trackedTimer();  // Manually tracked timer
    _periodicIgnored();  // Automatically ignored periodic
  }

  Future<void> _fetchProfile() async {
    try {
      await Future.delayed(const Duration(seconds: 2));  // Ignored delay (no track)
      if (Random().nextBool()) {
        throw Exception('Profile fetch error');
      }
      if (mounted) {
        setState(() => _profileData = 'Profile Loaded!');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _localError = e.toString());
      }
    }
  }

  void _parseJson() {
    // Simulate json parse as auto-tracked Future (microtask)
    Future.microtask(() async {
      await Future.delayed(const Duration(milliseconds: 500));  // Short delay
      jsonDecode('{"key": "value"}');  // Auto-tracked
      if (mounted) {
        setState(() => _parsedJson = 'JSON Parsed!');
      }
    });
  }

  void _ignoredTimer() {
    // Automatically ignored one-shot timer (no loading trigger)
    Timer(const Duration(seconds: 3), () {
      print('Ignored timer completed - no loading shown');
    });
  }

  void _trackedTimer() {
    // Manually tracked timer (will trigger loading)
    Future.delayed(const Duration(seconds: 4)).trackBoundary(context).then((_) {
      print('Tracked timer completed - loading shown during delay');
    });
  }

  void _periodicIgnored() {
    // Automatically ignored periodic (no loading per tick)
    Timer.periodic(const Duration(seconds: 5), (timer) {
      print('Ignored periodic tick');
      if (timer.tick > 3) timer.cancel();  // Stop after a few
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_localError != null) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text('Local error: $_localError'),
        ),
      );
    }
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text(_profileData ?? 'Waiting for profile...'),
            Text(_parsedJson ?? 'Waiting for JSON...'),
          ],
        ),
      ),
    );
  }
}

// Widget 2: NewsWidget with excluded future demo
class NewsWidget extends StatefulWidget {
  const NewsWidget({super.key});

  @override
  State<NewsWidget> createState() => _NewsWidgetState();
}

class _NewsWidgetState extends State<NewsWidget> {
  String? _newsData;

  @override
  void initState() {
    super.initState();
    _fetchNews();
  }

  Future<void> _fetchNews() async {
    // Exclude this entire async block from auto-tracking
    excludeBoundary(context, () async {
      try {
        await Future.delayed(const Duration(seconds: 3));  // Excluded - no loading
        if (Random().nextBool()) {
          throw Exception('News fetch error');
        }
        if (mounted) {
          setState(() => _newsData = 'News Loaded (excluded from tracking)!');
        }
      } catch (e) {
        if (mounted) {
          setState(() => _newsData = 'Error: $e (handled locally, excluded)');
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Text(_newsData ?? 'Waiting for news (excluded)...'),
      ),
    );
  }
}