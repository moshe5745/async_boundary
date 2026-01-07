import 'package:async_boundary/async_boundary.dart';
import 'package:flutter/material.dart';

class JsonParser extends StatefulWidget {
  const JsonParser({super.key});

  @override
  State<JsonParser> createState() => _JsonParserState();
}

class _JsonParserState extends State<JsonParser> {
  String? _parsed;

  @override
  void initState() {
    super.initState();
    _parse();
  }

  void _parse() {
    (() {  // Callback for parse (include by default)
      // Mock parse
      if (mounted) setState(() => _parsed = 'JSON Parsed!');
    }).asyncBoundary(context, tracked: true);  // Explicit include
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Text(_parsed ?? 'Parsing JSON...'),
      ),
    );
  }
}