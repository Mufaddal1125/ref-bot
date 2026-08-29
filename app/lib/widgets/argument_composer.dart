import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/debate_provider.dart';

class ArgumentComposer extends StatefulWidget {
  const ArgumentComposer({super.key});

  @override
  State<ArgumentComposer> createState() => _ArgumentComposerState();
}

class _ArgumentComposerState extends State<ArgumentComposer> {
  final _body = TextEditingController();

  @override
  void dispose() {
    _body.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final body = _body.text.trim();
    if (body.isEmpty) {
      return;
    }
    await context.read<DebateProvider>().submitArgument(body);
    if (mounted && context.read<DebateProvider>().error == null) {
      _body.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = context.select((DebateProvider p) => p.isLoading);

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          TextField(
            controller: _body,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'Your argument',
              alignLabelWithHint: true,
            ),
          ),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: isLoading ? null : _send,
            child: const Text('Submit argument'),
          ),
        ],
      ),
    );
  }
}
