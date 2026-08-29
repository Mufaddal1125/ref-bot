import 'package:go_router/go_router.dart';

import '../providers/session_provider.dart';
import '../screens/create_screen.dart';
import '../screens/debate_screen.dart';
import '../screens/home_screen.dart';
import '../screens/join_screen.dart';

const _entryRoutes = {'/', '/create', '/join'};

GoRouter createRouter(SessionProvider session) => GoRouter(
  refreshListenable: session,
  routes: [
    GoRoute(path: '/', builder: (_, _) => const HomeScreen()),
    GoRoute(path: '/create', builder: (_, _) => const CreateScreen()),
    GoRoute(path: '/join', builder: (_, _) => const JoinScreen()),
    GoRoute(
      path: '/debate/:id',
      builder: (_, state) =>
          DebateScreen(debateId: state.pathParameters['id']!),
    ),
  ],
  redirect: (context, state) {
    if (!session.restored) {
      return null;
    }
    final atEntry = _entryRoutes.contains(state.matchedLocation);

    if (session.hasSession && atEntry) {
      return '/debate/${session.debateId}';
    }
    if (!session.hasSession && !atEntry) {
      return '/';
    }
    return null;
  },
);
