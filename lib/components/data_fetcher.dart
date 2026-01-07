import 'dart:math';

import 'package:flutter/material.dart';

class DataFetcher extends StatefulWidget {
  const DataFetcher({super.key});

  @override
  State<DataFetcher> createState() => _DataFetcherState();
}

class _DataFetcherState extends State<DataFetcher> {
  String? _data;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    try {
      await Future.delayed(Duration(seconds: Random().nextInt(3) + 1));  // Ignored delay
      if (Random().nextBool()) throw Exception('Random fetch error');
      if (mounted) setState(() => _data = 'Data Fetched!');
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Text(_error ?? _data ?? 'Fetching data...'),
      ),
    );
  }
}