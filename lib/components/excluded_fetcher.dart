import 'package:async_boundary/async_boundary.dart';
import 'package:flutter/material.dart';

class ExcludedFetcher extends StatefulWidget {
  const ExcludedFetcher({super.key});

  @override
  State<ExcludedFetcher> createState() => _ExcludedFetcherState();
}

class _ExcludedFetcherState extends State<ExcludedFetcher> {
  String? _data;

  @override
  void initState() {
    super.initState();
    _fetchExcluded();
  }

  void _fetchExcluded() {
    (() async {  // Callback for fetch (exclude)
      await Future.delayed(const Duration(seconds: 2));
      if (mounted) setState(() => _data = 'Excluded Fetch Done');
    }).asyncBoundary(context, tracked: false);
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Text(_data ?? 'Fetching excluded...'),
      ),
    );
  }
}