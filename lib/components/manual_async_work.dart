import 'package:async_boundary/async_boundary.dart';
import 'package:flutter/material.dart';

class ManualAsyncWork extends StatefulWidget {
  const ManualAsyncWork({super.key});

  @override
  State<ManualAsyncWork> createState() => _ManualAsyncWorkState();
}

class _ManualAsyncWorkState extends State<ManualAsyncWork> {
  String? _result;

  @override
  void initState() {
    super.initState();
    _doWork();
  }

  Future<void> _doWork() async {
    // Manually include ignored async (triggers spinner)
    await Future.delayed(const Duration(seconds: 3)).asyncBoundary(context, tracked: true);
    if (mounted) setState(() => _result = 'Manual Work Done!');
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Text(_result ?? 'Doing manual async work...'),
      ),
    );
  }
}
