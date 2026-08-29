import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../models/enums.dart';
import '../providers/session_provider.dart';

const _joinableRoles = [Role.teamA, Role.teamB, Role.audience];

class JoinScreen extends StatefulWidget {
  const JoinScreen({super.key});

  @override
  State<JoinScreen> createState() => _JoinScreenState();
}

class _JoinScreenState extends State<JoinScreen> {
  final _code = TextEditingController();
  final _name = TextEditingController();
  Role _role = Role.teamA;

  @override
  void dispose() {
    _code.dispose();
    _name.dispose();
    super.dispose();
  }

  void _submit() {
    if (_code.text.trim().isEmpty || _name.text.trim().isEmpty) {
      return;
    }
    context.read<SessionProvider>().join(
      joinCode: _code.text.trim(),
      displayName: _name.text.trim(),
      role: _role,
    );
  }

  @override
  Widget build(BuildContext context) {
    final session = context.watch<SessionProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Join a debate'),
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
                controller: _code,
                textCapitalization: TextCapitalization.characters,
                decoration: const InputDecoration(
                  labelText: 'Join code',
                  hintText: 'ABC123',
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _name,
                decoration: const InputDecoration(labelText: 'Your name'),
              ),
              const SizedBox(height: 16),
              SegmentedButton<Role>(
                segments: [
                  for (final role in _joinableRoles)
                    ButtonSegment(value: role, label: Text(role.label)),
                ],
                selected: {_role},
                onSelectionChanged: (selection) =>
                    setState(() => _role = selection.first),
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: session.isBusy ? null : _submit,
                child: session.isBusy
                    ? const CircularProgressIndicator()
                    : const Text('Join'),
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
