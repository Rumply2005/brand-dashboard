import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:brand_dashboard/features/settings/presentation/providers/profile_provider.dart';

/// Screen where the user customizes their brand profile.
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(brandProfileProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Perfil de Marca'),
      ),
      body: profileAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('Error: $error')),
        data: (profile) => ListView(
          padding: const EdgeInsets.all(24),
          children: [
            // ── Logo Section ──
            _LogoSection(profile: profile),
            const SizedBox(height: 32),

            // ── Brand Name ──
            _BrandNameSection(profile: profile),
            const SizedBox(height: 32),

            // ── Color Picker ──
            _ColorSection(profile: profile),
            const SizedBox(height: 32),

            // ── Preview ──
            _PreviewSection(profile: profile),
          ],
        ),
      ),
    );
  }
}

// ── LOGO SECTION ──────────────────────────────────────────
class _LogoSection extends ConsumerWidget {
  final BrandProfile profile;
  const _LogoSection({required this.profile});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Logo de Marca',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Center(
          child: GestureDetector(
            onTap: () => _pickImage(ref),
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: const Color(0xFF1E1E1E),
                borderRadius: BorderRadius.circular(60),
                border: Border.all(
                  color: profile.accentColor,
                  width: 2,
                ),
              ),
              child: profile.logoPath != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(60),
                      child: Image.file(
                        File(profile.logoPath!),
                        fit: BoxFit.cover,
                      ),
                    )
                  : Icon(
                      Icons.add_a_photo_outlined,
                      color: profile.accentColor,
                      size: 40,
                    ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        const Center(
          child: Text(
            'Toca para cambiar el logo',
            style: TextStyle(color: Colors.grey, fontSize: 12),
          ),
        ),
      ],
    );
  }

  Future<void> _pickImage(WidgetRef ref) async {
    final picker = ImagePicker();
    final image = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 512,
      maxHeight: 512,
    );
    if (image != null) {
      ref.read(brandProfileProvider.notifier).updateLogoPath(image.path);
    }
  }
}

// ── BRAND NAME SECTION ────────────────────────────────────
class _BrandNameSection extends ConsumerStatefulWidget {
  final BrandProfile profile;
  const _BrandNameSection({required this.profile});

  @override
  ConsumerState<_BrandNameSection> createState() =>
      _BrandNameSectionState();
}

class _BrandNameSectionState extends ConsumerState<_BrandNameSection> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.profile.brandName);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Nombre de la Marca',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _controller,
          decoration: const InputDecoration(
            labelText: 'Nombre *',
            hintText: 'ej. JUST PURE',
            border: OutlineInputBorder(),
          ),
          onSubmitted: (value) {
            if (value.isNotEmpty) {
              ref
                  .read(brandProfileProvider.notifier)
                  .updateBrandName(value.trim());
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Nombre guardado ✅')),
              );
            }
          },
        ),
        const SizedBox(height: 8),
        const Text(
          'Presiona Enter para guardar',
          style: TextStyle(color: Colors.grey, fontSize: 12),
        ),
      ],
    );
  }
}

// ── COLOR SECTION ─────────────────────────────────────────
class _ColorSection extends ConsumerWidget {
  final BrandProfile profile;
  const _ColorSection({required this.profile});

  // Predefined brand-friendly colors
  static const List<Color> _colors = [
    Color(0xFFB8860B), // Gold — default
    Color(0xFFE8E0D0), // Warm white
    Color(0xFF2C2C2C), // Charcoal
    Color(0xFF8B4513), // Saddle brown
    Color(0xFF4A90D9), // Sky blue
    Color(0xFF7B68EE), // Medium slate
    Color(0xFF2ECC71), // Emerald
    Color(0xFFE74C3C), // Red
    Color(0xFFFF6B35), // Orange
    Color(0xFFE91E63), // Pink
    Color(0xFF00BCD4), // Cyan
    Color(0xFF9C27B0), // Purple
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Color de Acento',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: _colors.map((color) {
            final isSelected = profile.accentColor.value == color.value;
            return GestureDetector(
              onTap: () => ref
                  .read(brandProfileProvider.notifier)
                  .updateAccentColor(color),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                  border: isSelected
                      ? Border.all(color: Colors.white, width: 3)
                      : null,
                  boxShadow: isSelected
                      ? [BoxShadow(
                          color: color.withOpacity(0.5),
                          blurRadius: 8,
                          spreadRadius: 2,
                        )]
                      : null,
                ),
                child: isSelected
                    ? const Icon(Icons.check, color: Colors.white, size: 20)
                    : null,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

// ── PREVIEW SECTION ───────────────────────────────────────
class _PreviewSection extends StatelessWidget {
  final BrandProfile profile;
  const _PreviewSection({required this.profile});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Vista Previa',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                // Logo preview
                if (profile.logoPath != null)
                  CircleAvatar(
                    radius: 30,
                    backgroundImage: FileImage(File(profile.logoPath!)),
                  )
                else
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: profile.accentColor.withOpacity(0.2),
                    child: Icon(
                      Icons.store,
                      color: profile.accentColor,
                      size: 30,
                    ),
                  ),
                const SizedBox(height: 12),
                Text(
                  profile.brandName,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: profile.accentColor,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 16),
                // Sample button with brand color
                FilledButton(
                  onPressed: null,
                  style: FilledButton.styleFrom(
                    backgroundColor: profile.accentColor,
                  ),
                  child: const Text('Ejemplo de botón'),
                ),
                const SizedBox(height: 8),
                // Sample card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: profile.accentColor.withOpacity(0.3),
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Ejemplo de elemento con tu color',
                    style: TextStyle(
                      color: profile.accentColor,
                      fontSize: 12,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}