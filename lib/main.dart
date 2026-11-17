import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme/app_theme.dart';
import 'screens/landing_page_screen.dart';
import 'screens/home_screen.dart';
import 'services/api_service.dart';
import 'state/wedding_registry_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await ApiService.instance.init();
  runApp(
    const ProviderScope(
      child: PlotTheirFutureApp(),
    ),
  );
}

class PlotTheirFutureApp extends StatelessWidget {
  const PlotTheirFutureApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Plot Their Future • Wedding Gift Registry',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.festiveLightTheme,
      initialRoute: '/',
      onGenerateRoute: (settings) {
        final rawName = settings.name ?? '';
        final uri = Uri.tryParse(rawName);

        if (uri != null) {
          // Handle /w/:slug or scheme links
          String? slug;
          if (uri.pathSegments.isNotEmpty && uri.pathSegments.first == 'w' && uri.pathSegments.length > 1) {
            slug = uri.pathSegments[1];
          } else if (uri.host == 'w' && uri.pathSegments.isNotEmpty) {
            slug = uri.pathSegments.first;
          }

          if (slug != null && slug.isNotEmpty) {
            final wedding = WeddingRegistryRepository.findBySlugOrUrl(slug);
            if (wedding != null) {
              return MaterialPageRoute(
                builder: (_) => HomeScreen(customWedding: wedding),
                settings: settings,
              );
            }
          }
        }

        return MaterialPageRoute(
          builder: (_) => const LandingPageScreen(),
          settings: settings,
        );
      },
    );
  }
}
