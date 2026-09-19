import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/sound_categories.dart';
import '../../data/models/sound_profile.dart';
import '../../providers/settings_providers.dart';
import '../shared/sound_icon.dart';

class ProfileEditorScreen extends ConsumerStatefulWidget {
  const ProfileEditorScreen({super.key});

  @override
  ConsumerState<ProfileEditorScreen> createState() => _ProfileEditorScreenState();
}

class _ProfileEditorScreenState extends ConsumerState<ProfileEditorScreen> {
  String _expandedProfileId = 'home';

  @override
  Widget build(BuildContext context) {
    final profiles = ref.watch(soundProfilesProvider);
    final settings = ref.watch(userSettingsProvider);
    final theme = Theme.of(context);

    // Fallback if profiles list is empty
    final displayProfiles = profiles.isNotEmpty
        ? profiles
        : [SoundProfile.home(), SoundProfile.sleep(), SoundProfile.outdoor()];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sound Profiles'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          Text(
            'Customize which sounds AlertSense listens for in each environment profile.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 16),
          ...displayProfiles.map((profile) {
            final isExpanded = _expandedProfileId == profile.id;
            final isActive = settings.activeProfileId == profile.id;

            return Card(
              margin: const EdgeInsets.only(bottom: 16.0),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(
                  color: isActive
                      ? theme.colorScheme.primary
                      : theme.colorScheme.outlineVariant.withValues(alpha: 0.6),
                  width: isActive ? 2 : 1,
                ),
              ),
              child: Column(
                children: [
                  ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    leading: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primaryContainer.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(profile.emoji, style: const TextStyle(fontSize: 24)),
                    ),
                    title: Row(
                      children: [
                        Text(
                          profile.name,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (isActive) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primary,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Text(
                              'ACTIVE',
                              style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ],
                    ),
                    subtitle: Text('${profile.enabledCategories.length} sound(s) monitored'),
                    trailing: IconButton(
                      icon: Icon(isExpanded ? Icons.expand_less : Icons.expand_more),
                      onPressed: () {
                        setState(() {
                          _expandedProfileId = isExpanded ? '' : profile.id;
                        });
                      },
                    ),
                    onTap: () {
                      ref.read(userSettingsProvider.notifier).setActiveProfileId(profile.id);
                    },
                  ),
                  if (isExpanded) ...[
                    const Divider(height: 1),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Monitored Sounds', style: theme.textTheme.labelMedium),
                          TextButton(
                            onPressed: () {
                              final all = SoundCategory.values.map((c) => c.name).toList();
                              final updated = profile.copyWith(enabledCategories: all);
                              ref.read(soundProfilesProvider.notifier).saveProfile(updated);
                            },
                            child: const Text('Enable All'),
                          ),
                        ],
                      ),
                    ),
                    ...SoundCategory.values.map((category) {
                      final isEnabled = profile.enabledCategories.contains(category.name);
                      return SwitchListTile(
                        dense: true,
                        secondary: SoundIcon(
                          emoji: category.emoji,
                          color: category.color.withValues(alpha: 0.15),
                        ),
                        title: Text(category.label),
                        subtitle: Text(
                          category.description,
                          style: const TextStyle(fontSize: 11),
                        ),
                        value: isEnabled,
                        onChanged: (val) {
                          final updatedList = List<String>.from(profile.enabledCategories);
                          if (val) {
                            updatedList.add(category.name);
                          } else {
                            updatedList.remove(category.name);
                          }
                          final updated = profile.copyWith(enabledCategories: updatedList);
                          ref.read(soundProfilesProvider.notifier).saveProfile(updated);
                        },
                      );
                    }),
                    const SizedBox(height: 8),
                  ],
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}
