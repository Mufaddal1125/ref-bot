import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/debate.dart';
import '../models/enums.dart';
import '../providers/debate_provider.dart';
import '../providers/session_provider.dart';
import '../widgets/argument_composer.dart';
import '../widgets/argument_tile.dart';
import '../widgets/chat_panel.dart';
import '../widgets/participant_grid.dart';
import '../widgets/turn_banner.dart';
import '../widgets/vote_panel.dart';

/// A projector is wide; a phone is not. One breakpoint, one layout each — and
/// which side of it we are on decides where the chat lives.
const _wide = 900.0;

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
    final role = session.role ?? Role.audience;
    final isWide = MediaQuery.sizeOf(context).width >= _wide;

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
          // On a wide screen the chat is already on screen, in its own column.
          if (debate != null && !isWide)
            IconButton(
              onPressed: () => _openChatSheet(context, role),
              icon: Badge.count(
                count: debates.unreadChat,
                isLabelVisible: debates.unreadChat > 0,
                child: const Icon(Icons.chat_bubble_outline),
              ),
              tooltip: 'Live chat',
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
        final d => _DebateBody(debate: d, role: role),
      },
    );
  }

  /// On a phone the chat is a sheet, not a column: there is only one column.
  Future<void> _openChatSheet(BuildContext context, Role role) async {
    final debates = context.read<DebateProvider>();

    debates.setChatOpen(true);
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      useSafeArea: true,
      builder: (sheet) {
        final height = MediaQuery.sizeOf(sheet).height;
        // The keyboard has to come out of the sheet's height, not sit over the
        // box somebody is typing into.
        final keyboard = MediaQuery.viewInsetsOf(sheet).bottom;

        return Padding(
          padding: EdgeInsets.only(bottom: keyboard),
          child: SizedBox(
            height: (height * 0.85 - keyboard).clamp(200.0, height),
            child: ChatPanel(role: role),
          ),
        );
      },
    );
    debates.setChatOpen(false);
  }
}

class _DebateBody extends StatelessWidget {
  const _DebateBody({required this.debate, required this.role});

  final Debate debate;
  final Role role;

  @override
  Widget build(BuildContext context) {
    final debates = context.watch<DebateProvider>();
    final isWide = MediaQuery.sizeOf(context).width >= _wide;

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
        Expanded(
          child: isWide
              ? Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 3, child: _History(debate: debate)),
                    const VerticalDivider(width: 1),
                    Expanded(child: _RoomPanel(debate: debate, role: role)),
                  ],
                )
              : _History(debate: debate),
        ),
        if (debate.isTurnOf(role)) const ArgumentComposer(),
        if (debate.status == DebateStatus.voting ||
            debate.status == DebateStatus.closed)
          VotePanel(debate: debate, role: role),
        if (role == Role.moderator) _ModeratorControls(debate: debate),
      ],
    );
  }
}

/// The right-hand column on a wide screen: the chat, with the room behind it.
///
/// Chat leads, because it is the half that changes second by second. The tab
/// also tells the provider when the chat is being looked at, so the unread
/// count means "missed" rather than "arrived".
class _RoomPanel extends StatefulWidget {
  const _RoomPanel({required this.debate, required this.role});

  final Debate debate;
  final Role role;

  @override
  State<_RoomPanel> createState() => _RoomPanelState();
}

class _RoomPanelState extends State<_RoomPanel>
    with SingleTickerProviderStateMixin {
  static const _chatTab = 0;

  late final TabController _tabs = TabController(length: 2, vsync: this)
    ..addListener(_reportChatVisible);

  DebateProvider? _debates;

  @override
  void initState() {
    super.initState();
    // Chat is the tab this opens on, so nothing is unread to begin with.
    WidgetsBinding.instance.addPostFrameCallback((_) => _reportChatVisible());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _debates = context.read<DebateProvider>();
  }

  @override
  void dispose() {
    _tabs.dispose();
    // The window shrank past the breakpoint and the chat went with it. Deferred,
    // because notifying listeners while this subtree unmounts is not safe.
    final debates = _debates;
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => debates?.setChatOpen(false),
    );
    super.dispose();
  }

  void _reportChatVisible() {
    if (mounted) {
      _debates?.setChatOpen(_tabs.index == _chatTab);
    }
  }

  @override
  Widget build(BuildContext context) {
    final unread = context.watch<DebateProvider>().unreadChat;

    return Column(
      children: [
        TabBar(
          controller: _tabs,
          tabs: [
            Tab(
              child: Badge.count(
                count: unread,
                isLabelVisible: unread > 0,
                offset: const Offset(12, -6),
                child: const Text('Chat'),
              ),
            ),
            Tab(text: 'People (${widget.debate.participants.length})'),
          ],
        ),
        Expanded(
          child: TabBarView(
            controller: _tabs,
            children: [
              ChatPanel(role: widget.role),
              SingleChildScrollView(
                child: ParticipantGrid(
                  participants: widget.debate.participants,
                ),
              ),
            ],
          ),
        ),
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
