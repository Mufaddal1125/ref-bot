import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../providers/session_provider.dart';

class CreateScreen extends StatefulWidget {
  const CreateScreen({super.key});

  @override
  State<CreateScreen> createState() => _CreateScreenState();
}

class _CreateScreenState extends State<CreateScreen> {
  final _topic = TextEditingController();
  final _name = TextEditingController();

  @override
  void dispose() {
    _topic.dispose();
    _name.dispose();
    super.dispose();
  }

  void _submit() {
    if (_topic.text.trim().isEmpty || _name.text.trim().isEmpty) {
      return;
    }
    context.read<SessionProvider>().create(
      topic: _topic.text.trim(),
      displayName: _name.text.trim(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final session = context.watch<SessionProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Start a debate'),
        leading: BackButton(onPressed: () => context.go('/')),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: ListView(
            shrinkWrap: true,
            padding: const EdgeInsets.all(24),
            children: [
              TextField(
                controller: _topic,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Topic',
                  hintText: 'Social media does more harm than good',
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _name,
                decoration: const InputDecoration(labelText: 'Your name'),
                onSubmitted: (_) => _submit(),
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: session.isBusy ? null : _submit,
                child: session.isBusy
                    ? const CircularProgressIndicator()
                    : const Text('Create as moderator'),
              ),
              if (session.error != null) ...[
                const SizedBox(height: 16),
                Text(
                  session.error!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
