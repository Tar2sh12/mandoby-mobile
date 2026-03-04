import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'api/api_service.dart';
import 'providers/auth_provider.dart';
import 'router.dart';
import 'theme.dart';

void main()  {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: AppColors.bgCard,
    ),
  );
   ApiService().init();
  runApp(const MandobyApp());
}

class MandobyApp extends StatelessWidget {
  const MandobyApp({super.key});

  @override
  Widget build(BuildContext context)  {
    return ChangeNotifierProvider(
      create: (_)  =>  AuthProvider()..init(),
      child: const _AppContent(),
    );
  }
}

class _AppContent extends StatefulWidget {
  const _AppContent();

  @override
  State<_AppContent> createState() => _AppContentState();
}

class _AppContentState extends State<_AppContent> {
  late final _router = createRouter(context);

  @override
  Widget build(BuildContext context) {
    context.watch<AuthProvider>(); // trigger router refresh on auth change
    return MaterialApp.router(
      title: 'Mandoby',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      routerConfig: _router,
    );
  }
}
