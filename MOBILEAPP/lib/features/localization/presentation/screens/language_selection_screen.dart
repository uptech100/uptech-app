import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobileapp/core/l10n/app_localizations.dart';
import '../../../../main.dart';
import '../../../auth/presentation/screens/login_screen.dart';

class LanguageSelectionScreen extends ConsumerWidget {
  const LanguageSelectionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Note: AppLocalizations might be null if not loaded yet, add a safe fallback if needed, but it should be loaded.
    final l10n = AppLocalizations.of(context);
    final title = l10n?.appTitle ?? 'Company All Task Management';
    
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Select Language / भाषा चुनें / भाषा निवडा',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 40),
            _buildLanguageButton(context, ref, 'English', const Locale('en')),
            const SizedBox(height: 16),
            _buildLanguageButton(context, ref, 'हिंदी', const Locale('hi')),
            const SizedBox(height: 16),
            _buildLanguageButton(context, ref, 'मराठी', const Locale('mr')),
          ],
        ),
      ),
    );
  }

  Widget _buildLanguageButton(BuildContext context, WidgetRef ref, String language, Locale locale) {
    return SizedBox(
      width: 200,
      height: 50,
      child: ElevatedButton(
        onPressed: () {
          ref.read(localeProvider.notifier).state = locale;
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => const LoginScreen()),
          );
        },
        child: Text(language, style: const TextStyle(fontSize: 18)),
      ),
    );
  }
}
