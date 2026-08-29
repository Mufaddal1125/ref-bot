import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/api_client.dart';
import 'core/router.dart';
import 'core/theme.dart';
import 'providers/debate_provider.dart';
import 'providers/session_provider.dart';

void main() {
  runApp(const RefBotApp());
}

class RefBotApp extends StatefulWidget {
  const RefBotApp({super.key});

  @override
  State<RefBotApp> createState() => _RefBotAppState();
}

class _RefBotAppState extends State<RefBotApp> {
  final _api = ApiClient();
  late final _session = SessionProvider(_api)..restore();
  late final _router = createRouter(_session);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: _session),
        ChangeNotifierProvider(create: (_) => DebateProvider(_api)),
      ],
      child: MaterialApp.router(
        title: 'RefBot',
        theme: refbotTheme,
        routerConfig: _router,
      ),
    );
  }
}
