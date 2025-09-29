import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart';

// Core Services
import 'core/services/storage_service.dart';
import 'core/services/api_service.dart';
import 'core/services/notification_service.dart';

// Providers
import 'providers/auth_provider.dart';
import 'providers/theme_provider.dart';
import 'providers/home_provider.dart';
import 'providers/events_provider.dart';
import 'providers/news_provider.dart';
import 'providers/profile_provider.dart';
import 'providers/rewards_provider.dart';

// Screens
import 'screens/auth/login_screen.dart';
import 'screens/auth/register_screen.dart';
import 'screens/auth/selfie_capture_screen.dart';
import 'screens/auth/voice_recording_screen.dart';
import 'screens/home/home_screen.dart';
import 'screens/events/events_list_screen.dart';
import 'screens/events/create_event_screen.dart';
import 'screens/events/event_detail_screen.dart';
import 'screens/news/news_detail_screen.dart';
import 'screens/news/news_list_screen.dart' as news_list;
import 'screens/news/manage_news_screen.dart' as manage_news;
import 'screens/news/create_news_screen.dart';
import 'screens/profile/profile_screen.dart';
import 'screens/lucky_draw/lucky_draw_screen.dart';
import 'screens/lucky_draw/my_rewards_screen.dart';
import 'screens/events/manage_events_screen.dart';

// Constants
import 'core/constants/colors.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize core services
  await _initializeServices();
  
  runApp(const MyApp());
}

Future<void> _initializeServices() async {
  try {
    // Initialize storage service
    await StorageService.init();
    
    // Initialize API service
    await ApiService.init();
    
    // Initialize notification service
    await NotificationService.initialize();
    
  } catch (e) {
    debugPrint('Error initializing services: $e');
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => HomeProvider()),
        ChangeNotifierProvider(create: (_) => EventsProvider()),
        ChangeNotifierProvider(create: (_) => NewsProvider()),
        ChangeNotifierProvider(create: (_) => ProfileProvider()),
        ChangeNotifierProvider(create: (_) => RewardsProvider()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return MaterialApp(
            title: 'Events & Rewards',
            debugShowCheckedModeBanner: false,
            themeMode: themeProvider.themeMode,
            theme: _lightTheme,
            darkTheme: _darkTheme,
            home: const AppInitializer(),
            routes: {
              '/home': (context) => const HomeScreen(),
              '/login': (context) => const LoginScreen(),
              '/register': (context) => const RegisterScreen(),
              '/selfie-capture': (context) => const SelfieCaptureScreen(),
              '/voice-recording': (context) => const VoiceRecordingScreen(),
              '/events': (context) => const EventsListScreen(),
              '/profile': (context) => const ProfileScreen(),
              '/lucky-draw': (context) => const LuckyDrawScreen(),
              '/my-rewards': (context) => const MyRewardsScreen(),
              '/create-event': (context) => const CreateEventScreen(),
              '/manage-events': (context) => const ManageEventsScreen(),
              '/news': (context) => const news_list.NewsListScreen(),
              '/my-news': (context) => const manage_news.ManageNewsScreen(),
              '/create-news': (context) => const CreateNewsScreen(),
              '/edit-news': (context) => const CreateNewsScreen(), 
            },
            onGenerateRoute: (settings) {
              switch (settings.name) {
                case '/event-detail':
                  final eventId = settings.arguments as String;
                  return MaterialPageRoute(
                    builder: (context) => EventDetailScreen(eventId: eventId),
                  );
                case '/news-detail':
                  final newsId = settings.arguments as String;
                  return MaterialPageRoute(
                    builder: (context) => NewsDetailScreen(newsId: newsId),
                  );
                default:
                  return null;
              }
            },
          );
        },
      ),
    );
  }

  ThemeData get _lightTheme => ThemeData(
    brightness: Brightness.light,
    primarySwatch: Colors.blue,
    primaryColor: AppColors.primaryColor,
    scaffoldBackgroundColor: AppColors.backgroundColor,
    cardColor: AppColors.cardColor,
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.primaryColor,
      foregroundColor: Colors.white,
      elevation: 0,
      systemOverlayStyle: SystemUiOverlayStyle.light,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primaryColor,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    ),
  );

  ThemeData get _darkTheme => ThemeData(
    brightness: Brightness.dark,
    primarySwatch: Colors.blue,
    primaryColor: AppColors.primaryColor,
    scaffoldBackgroundColor: AppColors.darkBackgroundColor,
    cardColor: AppColors.darkCardColor,
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.darkCardColor,
      foregroundColor: AppColors.darkTextPrimaryColor,
      elevation: 0,
      systemOverlayStyle: SystemUiOverlayStyle.light,
    ),
  );
}

class AppInitializer extends StatefulWidget {
  const AppInitializer({super.key});

  @override
  State<AppInitializer> createState() => _AppInitializerState();
}

class _AppInitializerState extends State<AppInitializer> {
  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    
    // Initialize theme
    await themeProvider.initialize();
    
    // Initialize auth provider (this will check authentication status internally)
    await authProvider.initialize();
    
    // Navigate to appropriate screen
    if (mounted) {
      if (authProvider.isLoggedIn) {
        Navigator.of(context).pushReplacementNamed('/home');
      } else {
        Navigator.of(context).pushReplacementNamed('/login');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.primaryColor,
              // ignore: deprecated_member_use
              AppColors.primaryColor.withOpacity(0.8),
            ],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.event_available,
                size: 80,
                color: Colors.white,
              ),
              const SizedBox(height: 24),
              const Text(
                'Events & Rewards',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Discover, Participate, Win!',
                style: TextStyle(
                  fontSize: 16,
                  // ignore: deprecated_member_use
                  color: Colors.white.withOpacity(0.8),
                ),
              ),
              const SizedBox(height: 48),
              const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation(Colors.white),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
