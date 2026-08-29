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
      context.read<DebateProvider>().connect(widget.debateId);
    });
  }

  @override
  void dispose() {
    context.read<DebateProvider>().disconnect();
    super.dispose();
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
          IconButton(
            onPressed: () async {
              await debates.disconnect();
              if (context.mounted) {
                await session.leave();
              }
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
        null => Center(child: Text(debates.error ?? 'Connecting…')),
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
    final debates = context.watch<DebateProvider>();

    return Column(
      children: [
        if (!debates.isConnected) const _ReconnectingBanner(),
        TurnBanner(debate: debate, role: role),
        if (debates.error != null)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            color: Theme.of(context).colorScheme.errorContainer,
            child: Text(debates.error!, textAlign: TextAlign.center),
          ),
        Expanded(child: _History(debate: debate)),
        if (debate.isTurnOf(role)) const ArgumentComposer(),
        if (role == Role.moderator) _ModeratorControls(debate: debate),
      ],
    );
  }
}

/// The debate history. Stateful now, because once arguments arrive on their
/// own the list has to move on its own too.
class _History extends StatefulWidget {
  const _History({required this.debate});

  final Debate debate;

  @override
  State<_History> createState() => _HistoryState();
}

class _HistoryState extends State<_History> {
  final _scroll = ScrollController();

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(_History oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Only when the history actually grew. Following every rebuild would drag
    // the list back down while somebody is reading through it.
    if (widget.debate.arguments.length > oldWidget.debate.arguments.length) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _followNewest());
    }
  }

  /// The new row does not exist until the frame after the rebuild, so this
  /// runs from a post-frame callback and asks whether there is a list at all.
  void _followNewest() {
    if (!_scroll.hasClients) {
      return;
    }
    _scroll.animateTo(
      _scroll.position.maxScrollExtent,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final arguments = widget.debate.arguments;

    if (arguments.isEmpty) {
      return const Center(child: Text('No arguments yet.'));
    }
    return ListView.builder(
      controller: _scroll,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: arguments.length,
      itemBuilder: (_, i) => ArgumentTile(argument: arguments[i]),
    );
  }
}

class _ReconnectingBanner extends StatelessWidget {
  const _ReconnectingBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      color: Theme.of(context).colorScheme.errorContainer,
      child: const Text('Reconnecting…', textAlign: TextAlign.center),
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
