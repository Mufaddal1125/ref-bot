import 'package:go_router/go_router.dart';

import '../providers/session_provider.dart';
import '../screens/create_screen.dart';
import '../screens/debate_screen.dart';
import '../screens/home_screen.dart';
import '../screens/join_screen.dart';

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
    // TODO(step 6): the entry routes are '/', '/create' and '/join'.
    // While restoring, stay put. With a session, an entry route goes to the
    // debate; without one, anything else goes home.
    return null;
  },
);
