import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/theme_service.dart';
import '../services/update_service.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final themeSvc = context.watch<ThemeService>();
    final updateSvc = context.watch<UpdateService>();
    final cs = Theme.of(context).colorScheme;

    final presets = [
      {'name': 'ESIEE Blue', 'color': const Color(0xFF2F2A86)},
      {'name': 'Purple Rain', 'color': Colors.deepPurple},
      {'name': 'Ocean Breeze', 'color': Colors.teal},
      {'name': 'Cherry', 'color': Colors.pink},
      {'name': 'Forest', 'color': Colors.green},
      {'name': 'Sunset', 'color': Colors.orange},
    ];

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Paramètres',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w900,
                  color: cs.onSurface,
                  letterSpacing: -1,
                ),
              ),
              const SizedBox(height: 32),

              // ── Theme Section ──
              _SectionTitle(title: 'Apparence'),
              const SizedBox(height: 16),
              _SettingsCard(
                child: Column(
                  children: [
                    ListTile(
                      leading: Icon(
                        themeSvc.themeMode == ThemeMode.dark
                            ? Icons.dark_mode_rounded
                            : Icons.light_mode_rounded,
                        color: cs.primary,
                      ),
                      title: const Text('Mode Sombre',
                          style: TextStyle(fontWeight: FontWeight.w700)),
                      trailing: Switch(
                        value: themeSvc.themeMode == ThemeMode.dark,
                        onChanged: (val) {
                          themeSvc.setThemeMode(val ? ThemeMode.dark : ThemeMode.light);
                        },
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // ── Theme Builder ──
              _SectionTitle(title: 'Personnalisation'),
              const SizedBox(height: 16),
              _SettingsCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
                      child: Text(
                        'Couleur d\'accentuation',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.fromLTRB(16, 0, 16, 16),
                      child: Text(
                        'Choisissez une couleur pour générer une palette.',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ),
                    SizedBox(
                      height: 100,
                      child: ListView.separated(
                        clipBehavior: Clip.hardEdge, // Back to standard clipping
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        itemCount: presets.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 12),
                        itemBuilder: (context, i) {
                          final p = presets[i];
                          final color = p['color'] as Color;
                          final isSelected = themeSvc.seedColor == color;

                          return GestureDetector(
                            onTap: () => themeSvc.setSeedColor(color),
                            child: Column(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8), // Padding inside the gesture area for the glow
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 300),
                                    width: 48,
                                    height: 48,
                                    decoration: BoxDecoration(
                                      color: color,
                                      shape: BoxShape.circle,
                                      border: isSelected
                                          ? Border.all(color: cs.onSurface, width: 3)
                                          : null,
                                      boxShadow: isSelected
                                          ? [
                                              BoxShadow(
                                                  color: color.withValues(alpha: 0.4),
                                                  blurRadius: 10,
                                                  spreadRadius: 2)
                                            ]
                                          : null,
                                    ),
                                    child: isSelected
                                        ? Icon(Icons.check,
                                            color: color.computeLuminance() > 0.5
                                                ? Colors.black
                                                : Colors.white)
                                        : null,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  p['name'] as String,
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: isSelected ? FontWeight.w900 : FontWeight.w600,
                                    color: isSelected ? cs.primary : cs.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Divider(height: 1),
                    const Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Text(
                        'Aperçu de la palette',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      child: Row(
                        children: [
                          _PalettePreview(
                            label: 'Primaire',
                            bg: themeSvc.themeMode == ThemeMode.dark ? cs.onPrimary : cs.primary,
                            fg: themeSvc.themeMode == ThemeMode.dark ? cs.primary : cs.onPrimary,
                          ),
                          const SizedBox(width: 8),
                          _PalettePreview(
                            label: 'Secondaire',
                            bg: themeSvc.themeMode == ThemeMode.dark ? cs.onSecondary : cs.secondary,
                            fg: themeSvc.themeMode == ThemeMode.dark ? cs.secondary : cs.onSecondary,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // ── Update Section ──
              _SectionTitle(title: 'Application'),
              const SizedBox(height: 16),
              _SettingsCard(
                child: Column(
                  children: [
                    ListTile(
                      leading: Icon(Icons.info_outline_rounded, color: cs.primary),
                      title: const Text('Version', style: TextStyle(fontWeight: FontWeight.w700)),
                      subtitle: Text(updateSvc.currentVersion),
                      trailing: updateSvc.isChecking
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : IconButton(
                              icon: const Icon(Icons.refresh_rounded),
                              onPressed: () async {
                                final hasUpdate = await updateSvc.checkForUpdate();
                                if (!context.mounted) return;
                                if (hasUpdate) {
                                  _showUpdateDialog(context, updateSvc);
                                } else if (updateSvc.error != null) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text(updateSvc.error!)),
                                  );
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('L\'application est à jour.')),
                                  );
                                }
                              },
                            ),
                    ),
                    if (updateSvc.isDownloading)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Téléchargement de la mise à jour...',
                                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                            const SizedBox(height: 8),
                            LinearProgressIndicator(
                              value: updateSvc.downloadProgress / 100,
                              backgroundColor: cs.surfaceContainerHighest,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showUpdateDialog(BuildContext context, UpdateService updateSvc) {
    final release = updateSvc.latestRelease!;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Nouvelle version disponible : ${release.tagName}'),
        content: SingleChildScrollView(
          child: Text(release.body.isEmpty ? 'Aucune note de version.' : release.body),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Plus tard'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              updateSvc.downloadAndInstall();
            },
            child: const Text('Mettre à jour'),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title.toUpperCase(),
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w800,
        color: Theme.of(context).colorScheme.onSurfaceVariant,
        letterSpacing: 1,
      ),
    );
  }
}

class _SettingsCard extends StatelessWidget {
  final Widget child;
  const _SettingsCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(24),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: child,
      ),
    );
  }
}

class _PalettePreview extends StatelessWidget {
  final String label;
  final Color bg;
  final Color fg;

  const _PalettePreview({
    required this.label,
    required this.bg,
    required this.fg,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Text(
              label,
              style: TextStyle(
                color: fg,
                fontSize: 11,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 4),
            Icon(Icons.color_lens_outlined, color: fg, size: 16),
          ],
        ),
      ),
    );
  }
}
