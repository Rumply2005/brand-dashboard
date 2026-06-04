import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:brand_dashboard/features/settings/data/repositories/profile_repository.dart';

/// Provides the ProfileRepository instance.
final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  return ProfileRepository();
});

/// State class that holds all brand profile data.
class BrandProfile {
  final String brandName;
  final Color accentColor;
  final String? logoPath;

  const BrandProfile({
    required this.brandName,
    required this.accentColor,
    this.logoPath,
  });

  BrandProfile copyWith({
    String? brandName,
    Color? accentColor,
    String? logoPath,
  }) {
    return BrandProfile(
      brandName: brandName ?? this.brandName,
      accentColor: accentColor ?? this.accentColor,
      logoPath: logoPath ?? this.logoPath,
    );
  }
}

/// Notifier that manages brand profile state.
class BrandProfileNotifier extends AsyncNotifier<BrandProfile> {
  @override
  Future<BrandProfile> build() async {
    final repo = ref.read(profileRepositoryProvider);
    final name = await repo.getBrandName();
    final colorValue = await repo.getAccentColor();
    final logoPath = await repo.getLogoPath();

    return BrandProfile(
      brandName: name,
      accentColor: Color(colorValue),
      logoPath: logoPath,
    );
  }

  Future<void> updateBrandName(String name) async {
    final repo = ref.read(profileRepositoryProvider);
    await repo.saveBrandName(name);
    final current = state.value!;
    state = AsyncData(current.copyWith(brandName: name));
  }

  Future<void> updateAccentColor(Color color) async {
    final repo = ref.read(profileRepositoryProvider);
    await repo.saveAccentColor(color.toARGB32());
    final current = state.value!;
    state = AsyncData(current.copyWith(accentColor: color));
  }

  Future<void> updateLogoPath(String path) async {
    final repo = ref.read(profileRepositoryProvider);
    await repo.saveLogoPath(path);
    final current = state.value!;
    state = AsyncData(current.copyWith(logoPath: path));
  }
}

/// Global provider for brand profile.
final brandProfileProvider =
    AsyncNotifierProvider<BrandProfileNotifier, BrandProfile>(
  BrandProfileNotifier.new,
);