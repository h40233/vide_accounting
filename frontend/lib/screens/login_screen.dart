import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../providers/auth_provider.dart';

class LoginScreen extends ConsumerWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);

    return Scaffold(
      body: Stack(
        children: [
          // 背景裝飾大圓 (Gradients)
          Positioned(
            top: -100,
            right: -100,
            child: Container(
              width: 400,
              height: 400,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.tealAccent.withOpacity(0.05),
              ),
            ),
          ),
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(FontAwesomeIcons.vault, size: 80, color: Colors.tealAccent),
                const SizedBox(height: 30),
                Text(
                  'Accounting Premium',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Your financial life, simplified.',
                  style: TextStyle(color: Colors.white.withOpacity(0.5)),
                ),
                const SizedBox(height: 60),
                
                // Google Login Button
                if (authState.isLoading)
                  const CircularProgressIndicator(color: Colors.tealAccent)
                else
                  ElevatedButton.icon(
                    onPressed: () => ref.read(authProvider.notifier).login(),
                    icon: const Icon(FontAwesomeIcons.google, size: 18),
                    label: const Text('Continue with Google'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.black,
                      minimumSize: const Size(280, 56),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 0,
                    ),
                  ),
                
                if (authState.hasError)
                  Padding(
                    padding: const EdgeInsets.only(top: 20),
                    child: Text(
                      'Login failed. Please try again.',
                      style: TextStyle(color: Colors.redAccent.withOpacity(0.8)),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
