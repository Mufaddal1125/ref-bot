import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/debate.dart';
import '../models/enums.dart';
import '../providers/debate_provider.dart';
import '../providers/session_provider.dart';
import '../widgets/argument_composer.dart';
import '../widgets/argument_tile.dart';
import '../widgets/turn_banner.dart';

class DebateScreen extends StatefulWidget {
  const DebateScreen({required this.debateId, super.key});

  final String debateId;

  @override
  State<DebateScreen> createState() => _DebateScreenState();
}

class _DebateScreenState extends State<DebateScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DebateProvider>().refresh(widget.debateId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final debates = context.watch<DebateProvider>();
    final session = context.watch<SessionProvider>();
    final debate = debates.debate;

    return Scaffold(
      appBar: AppBar(
        title: Text(debate?.topic ?? 'Debate'),
        actions: [
          if (debate != null)
            Center(
              child: Padding(
                padding: const EdgeInsets.only(right: 12),
                child: Text(debate.joinCode),
              ),
            ),
          // TODO(phase 2): WebSockets remove the need for this.
          IconButton(
            onPressed: () => debates.refresh(widget.debateId),
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
          ),
          IconButton(
            onPressed: () {
              debates.clear();
              session.leave();
            },
            icon: const Icon(Icons.logout),
            tooltip: 'Leave',
          ),
        ],
      ),
      body: switch (debate) {
        null when debates.isLoading => const Center(
          child: CircularProgressIndicator(),
        ),
        null => Center(child: Text(debates.error ?? 'No debate loaded.')),
        final d => _DebateBody(debate: d, role: session.role ?? Role.audience),
      },
    );
  }
}

class _DebateBody extends StatelessWidget {
  const _DebateBody({required this.debate, required this.role});

  final Debate debate;
  final Role role;

  @override
  Widget build(BuildContext context) {
    final error = context.select((DebateProvider p) => p.error);

    return Column(
      children: [
        TurnBanner(debate: debate, role: role),
        if (error != null)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            color: Theme.of(context).colorScheme.errorContainer,
            child: Text(error, textAlign: TextAlign.center),
          ),
        Expanded(
          child: debate.arguments.isEmpty
              ? const Center(child: Text('No arguments yet.'))
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  itemCount: debate.arguments.length,
                  itemBuilder: (_, i) =>
                      ArgumentTile(argument: debate.arguments[i]),
                ),
        ),
        if (debate.isTurnOf(role)) const ArgumentComposer(),
        if (role == Role.moderator) _ModeratorControls(debate: debate),
      ],
    );
  }
}

class _ModeratorControls extends StatelessWidget {
  const _ModeratorControls({required this.debate});

  final Debate debate;

  @override
  Widget build(BuildContext context) {
    final debates = context.read<DebateProvider>();

    return Padding(
      padding: const EdgeInsets.all(16),
      child: switch (debate.status) {
        DebateStatus.lobby => FilledButton(
          onPressed: debates.start,
          child: const Text('Start the debate'),
        ),
        DebateStatus.active => FilledButton(
          onPressed: debates.end,
          child: const Text('End the debate'),
        ),
        _ => const SizedBox.shrink(),
      },
    );
  }
}
