import 'dart:io';
import 'package:animate_do/animate_do.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:brand_dashboard/features/settings/presentation/providers/profile_provider.dart';

/// Splash screen shown when the app first launches.
/// Displays brand logo and name with animations.
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    // Navigate to main app after 2.5 seconds
    Future.delayed(const Duration(milliseconds: 2500), () {
      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/home');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(brandProfileProvider);
    final profile = profileAsync.value;
    final accentColor = profile?.accentColor ?? const Color(0xFFB8860B);

    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // ── Logo ──
            FadeInDown(
              duration: const Duration(milliseconds: 800),
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: accentColor,
                    width: 2,
                  ),
                  color: const Color(0xFF1E1E1E),
                ),
                child: profile?.logoPath != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(60),
                        child: Image.file(
                          File(profile!.logoPath!),
                          fit: BoxFit.cover,
                        ),
                      )
                    : Icon(
                        Icons.store,
                        color: accentColor,
                        size: 50,
                      ),
              ),
            ),
            const SizedBox(height: 24),

            // ── Brand Name ──
            FadeInUp(
              delay: const Duration(milliseconds: 400),
              duration: const Duration(milliseconds: 800),
              child: Text(
                profile?.brandName ?? 'Brand Dashboard',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: accentColor,
                  letterSpacing: 4,
                ),
              ),
            ),
            const SizedBox(height: 8),

            // ── Tagline ──
            FadeIn(
              delay: const Duration(milliseconds: 800),
              duration: const Duration(milliseconds: 800),
              child: const Text(
                'Dashboard de Costos',
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 14,
                  letterSpacing: 2,
                ),
              ),
            ),
            const SizedBox(height: 48),

            // ── Loading indicator ──
            FadeIn(
              delay: const Duration(milliseconds: 1200),
              child: SizedBox(
                width: 40,
                child: LinearProgressIndicator(
                  backgroundColor: Colors.grey.withValues(alpha: 0.2),
                  color: accentColor,
                  minHeight: 2,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}