import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui' show lerpDouble;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/theme/app_text_styles.dart';
import '../../cubits/profile/profile_cubit.dart';
import '../../cubits/profile/profile_state.dart';
import '../../cubits/theme/theme_cubit.dart';
import '../../cubits/theme/theme_state.dart';
import '../../cubits/auth/auth_cubit.dart';
import '../../core/utils/xp_utils.dart';
import '../../widgets/climb_ui.dart';
import '../../widgets/dot_climb.dart';
import '../../widgets/xp_bar.dart';
import '../achievements/achievements_screen.dart';
import '../../core/network/api_constants.dart';
import '../../data/repositories/api_repository.dart';
import '../../cubits/onboarding/onboarding_cubit.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/user_model.dart';

const double _headerMaxExtent = 228.0;
const double _headerMinExtent = 72.0;

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late final ScrollController _scrollController;
  bool _isSnapping = false;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return BlocBuilder<ProfileCubit, ProfileState>(
      builder: (context, state) {
        final user = state.user;
        final progress = XPUtils.levelProgress(user.totalXP);

        return SafeArea(
          bottom: false,
          child: NotificationListener<ScrollNotification>(
            onNotification: (notification) {
              if (notification is ScrollStartNotification) {
                _isSnapping = false;
              }
              if (_isSnapping) return false;
              if (notification is ScrollEndNotification) {
                final double offset = _scrollController.offset;
                const double maxScroll = _headerMaxExtent - _headerMinExtent;
                if (offset > 0.5 && offset < maxScroll - 0.5) {
                  final double target = offset < maxScroll / 2 ? 0.0 : maxScroll;
                  _isSnapping = true;
                  Future.microtask(() {
                    if (_scrollController.hasClients) {
                      _scrollController.animateTo(
                        target,
                        duration: const Duration(milliseconds: 375),
                        curve: Curves.fastOutSlowIn,
                      ).then((_) {
                        _isSnapping = false;
                      });
                    } else {
                      _isSnapping = false;
                    }
                  });
                }
              }
              return false;
            },
            child: CustomScrollView(
              controller: _scrollController,
              slivers: [
                SliverPersistentHeader(
                  pinned: true,
                  delegate: _ProfileHeaderDelegate(
                    user: user,
                    progress: progress,
                    context: context,
                    cs: cs,
                    tt: tt,
                    themeCubit: context.read<ThemeCubit>(),
                    authCubit: context.read<AuthCubit>(),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 120),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Stats
                        AppCard(
                          child: Column(
                            children: [
                              StatRow(
                                stats: [
                                  StatBlock(
                                    value: formatNumber(user.totalXP),
                                    label: 'Total XP',
                                  ),
                                  StatBlock(
                                    value: formatNumber(user.tasksCompleted),
                                    label: 'Tasks done',
                                  ),
                                ],
                              ),
                              const SizedBox(height: 18),
                              StatRow(
                                stats: [
                                  StatBlock(
                                    value: '${user.currentStreak}d',
                                    label: 'Streak',
                                  ),
                                  StatBlock(
                                    value: '${state.unlockedAchievements.length}',
                                    label: 'Achievements',
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 10),

                        // XP History Chart
                        AppCard(
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text('XP this week', style: tt.titleMedium),
                                  ),
                                  MutedLabel(
                                    '${formatNumber(user.weeklyXP.fold<int>(0, (a, b) => a + b))} XP',
                                  ),
                                ],
                              ),
                              const SizedBox(height: 18),
                              DotWeekChart(weeklyXP: user.weeklyXP),
                            ],
                          ),
                        ),
                        const SizedBox(height: 10),

                        // Achievements section
                        AppCard(
                          padding: EdgeInsets.zero,
                          child: _MenuTile(
                            label: 'Achievements',
                            detail:
                                '${state.unlockedAchievements.length} of ${state.achievements.length}',
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => BlocProvider.value(
                                    value: context.read<ProfileCubit>(),
                                    child: const AchievementsScreen(),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 10),

                        // Settings & Legal Section
                        AppCard(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Column(
                            children: [
                              _MenuTile(
                                label: 'Notification time',
                                onTap: () => _showNotificationTimePicker(context),
                              ),
                              _MenuTile(
                                label: 'Privacy policy',
                                onTap: () => _launchURL(ApiConstants.privacyPolicy),
                              ),
                              _MenuTile(
                                label: 'Terms of service',
                                onTap: () => _launchURL(ApiConstants.termsOfService),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 10),
                        AppCard(
                          padding: EdgeInsets.zero,
                          child: _MenuTile(
                            label: 'Delete account',
                            color: cs.error,
                            onTap: () => _showDeleteConfirmation(context),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _ProfileHeaderDelegate extends SliverPersistentHeaderDelegate {
  final UserModel user;
  final double progress;
  final BuildContext context;
  final ColorScheme cs;
  final TextTheme tt;
  final ThemeCubit themeCubit;
  final AuthCubit authCubit;

  _ProfileHeaderDelegate({
    required this.user,
    required this.progress,
    required this.context,
    required this.cs,
    required this.tt,
    required this.themeCubit,
    required this.authCubit,
  });

  @override
  double get maxExtent => _headerMaxExtent;

  @override
  double get minExtent => _headerMinExtent;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    final double t = (shrinkOffset / (maxExtent - minExtent)).clamp(0.0, 1.0);
    final double detailsOpacity = (1.0 - t * 2.5).clamp(0.0, 1.0);

    // The avatar stays on the left and shrinks into the collapsed top bar.
    const double expandedRingSize = 84.0;
    const double collapsedRingSize = 42.0;
    final double ringSize = lerpDouble(expandedRingSize, collapsedRingSize, t)!;
    final double avatarSize = ringSize - lerpDouble(14.0, 6.0, t)!;
    final double avatarY = lerpDouble(68.0, 15.0, t)!;

    // "Profile" slides right to sit beside the small avatar.
    final double textX = lerpDouble(20.0, 20.0 + collapsedRingSize + 12.0, t)!;
    final double textY = lerpDouble(16.0, 20.0, t)!;
    final double fontSize = lerpDouble(32.0, 22.0, t)!;

    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: Stack(
        children: [
          // Name, handle and level (fade out as we scroll)
          if (detailsOpacity > 0.0) ...[
            Positioned(
              left: 20 + expandedRingSize + 16,
              right: 20,
              top: 70,
              child: Opacity(
                opacity: detailsOpacity,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.name,
                      style: tt.headlineSmall,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '@${user.username}',
                      style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => _showEditProfileSheet(context, user),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Text(
                          'Edit profile',
                          style: tt.labelLarge?.copyWith(color: cs.onSurface, decoration: TextDecoration.underline, decorationColor: cs.onSurfaceVariant),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              left: 20,
              right: 20,
              top: 170,
              child: Opacity(
                opacity: detailsOpacity,
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Level ${user.level}  ·  ${user.title}',
                            style: tt.titleSmall,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(
                          XPUtils.xpToNextLevel(user.totalXP) > 0
                              ? '${formatNumber(XPUtils.xpToNextLevel(user.totalXP))} XP to next'
                              : 'Summit reached',
                          style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    XPBar(progress: progress),
                  ],
                ),
              ),
            ),
          ],

          // Avatar + level ring (moves and scales)
          Positioned(
            left: 20,
            top: avatarY,
            child: SizedBox(
              width: ringSize,
              height: ringSize,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox.expand(
                    child: CircularProgressIndicator(
                      value: progress,
                      strokeWidth: lerpDouble(2.5, 2.0, t)!,
                      backgroundColor: cs.surfaceContainerHighest,
                      valueColor: AlwaysStoppedAnimation(cs.secondary),
                    ),
                  ),
                  UserAvatar(
                    name: user.name,
                    url: user.avatarUrl,
                    size: avatarSize,
                  ),
                ],
              ),
            ),
          ),

          // "Profile" title (moves and shrinks)
          Positioned(
            left: textX,
            top: textY,
            child: Text(
              'Profile',
              style: AppTextStyles.display(fontSize, color: cs.onSurface),
            ),
          ),

          // Action buttons (top right)
          Positioned(
            right: 8,
            top: 12,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Theme toggle
                IconButton(
                  tooltip: 'Change theme',
                  onPressed: () => themeCubit.toggleTheme(),
                  icon: BlocBuilder<ThemeCubit, ThemeState>(
                    bloc: themeCubit,
                    builder: (context, themeState) {
                      final isDark = Theme.of(context).brightness == Brightness.dark;
                      return AnimatedSwitcher(
                        duration: const Duration(milliseconds: 300),
                        child: Icon(
                          isDark
                              ? Icons.light_mode_outlined
                              : Icons.dark_mode_outlined,
                          key: ValueKey(isDark),
                          color: cs.onSurfaceVariant,
                        ),
                      );
                    },
                  ),
                ),
                // Logout button
                IconButton(
                  tooltip: 'Log out',
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Log out?'),
                        content: const Text('Are you sure you want to log out?'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Cancel'),
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.pop(context);
                              authCubit.logout();
                            },
                            child: Text(
                              'Log out',
                              style: TextStyle(color: cs.error),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                  icon: Icon(Icons.logout_rounded, color: cs.onSurfaceVariant),
                ),
              ],
            ),
          ),

        ],
      ),
    );
  }

  @override
  bool shouldRebuild(covariant _ProfileHeaderDelegate oldDelegate) {
    return oldDelegate.user != user ||
        oldDelegate.progress != progress ||
        oldDelegate.cs != cs ||
        oldDelegate.tt != tt;
  }
}

class _MenuTile extends StatelessWidget {
  final String label;
  final String? detail;
  final VoidCallback onTap;
  final Color? color;

  const _MenuTile({
    required this.label,
    required this.onTap,
    this.detail,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: tt.titleSmall?.copyWith(fontSize: 15, color: color),
              ),
            ),
            if (detail != null) ...[
              MutedLabel(detail!),
              const SizedBox(width: 6),
            ],
            Icon(
              Icons.chevron_right_rounded,
              size: 20,
              color: color ?? cs.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }
}

Future<void> _launchURL(String url) async {
  final uri = Uri.parse(url);
  if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
    throw Exception('Could not launch $url');
  }
}

void _showNotificationTimePicker(BuildContext context) async {
  final profileCubit = context.read<ProfileCubit>();
  final user = profileCubit.state.user;

  final parts = user.notificationTime.split(':');
  final utcHour = int.tryParse(parts[0]) ?? 8;
  final utcMinute = parts.length > 1 ? (int.tryParse(parts[1]) ?? 0) : 0;

  final now = DateTime.now();
  final utcDateTime = DateTime.utc(
    now.year,
    now.month,
    now.day,
    utcHour,
    utcMinute,
  );
  final localDateTime = utcDateTime.toLocal();

  final initialTime = TimeOfDay(
    hour: localDateTime.hour,
    minute: localDateTime.minute,
  );

  final TimeOfDay? picked = await showTimePicker(
    context: context,
    initialTime: initialTime,
  );

  if (picked != null) {
    final pickedDateTime = DateTime(
      now.year,
      now.month,
      now.day,
      picked.hour,
      picked.minute,
    );
    final utcDateTime = pickedDateTime.toUtc();
    final timeStr =
        '${utcDateTime.hour.toString().padLeft(2, '0')}:${utcDateTime.minute.toString().padLeft(2, '0')}';

    final updatedUser = user.copyWith(notificationTime: timeStr);
    final success = await profileCubit.updateUser(updatedUser);

    if (success && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Notification time updated to ${picked.format(context)}',
          ),
        ),
      );
    }
  }
}

void _showDeleteConfirmation(BuildContext context) {
  final cs = Theme.of(context).colorScheme;

  showDialog(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('Delete account?'),
      content: const Text(
        'Are you absolutely sure? This will permanently delete your account, '
        'all your XP, levels, and task history. This action cannot be undone.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () async {
            Navigator.pop(dialogContext);
            // Show loading
            if (!context.mounted) return;

            showDialog(
              context: context,
              barrierDismissible: false,
              builder: (ctx) =>
                  const Center(child: CircularProgressIndicator()),
            );

            final success = await ApiRepository().deleteAccount();

            if (!context.mounted) return;
            Navigator.pop(context); // hide loading

            if (success) {
              context.read<OnboardingCubit>().resetOnboarding();
              context.read<AuthCubit>().logout();
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Failed to delete account. Please try again.'),
                ),
              );
            }
          },
          style: TextButton.styleFrom(foregroundColor: cs.error),
          child: const Text('Delete permanently'),
        ),
      ],
    ),
  );
}

void _showEditProfileSheet(BuildContext context, UserModel user) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (_) => BlocProvider.value(
      value: context.read<ProfileCubit>(),
      child: _EditProfileSheet(user: user),
    ),
  );
}

class _EditProfileSheet extends StatefulWidget {
  final UserModel user;

  const _EditProfileSheet({required this.user});

  @override
  State<_EditProfileSheet> createState() => _EditProfileSheetState();
}

class _EditProfileSheetState extends State<_EditProfileSheet> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _usernameController;
  File? _pickedImage;
  String? _avatarBase64;
  bool _isLoading = false;

  // Username Availability State
  bool? _isUsernameAvailable = true;
  bool _isCheckingUsername = false;
  Timer? _usernameDebounce;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.user.name);
    _usernameController = TextEditingController(text: widget.user.username);
  }

  @override
  void dispose() {
    _usernameDebounce?.cancel();
    _nameController.dispose();
    _usernameController.dispose();
    super.dispose();
  }

  void _onUsernameChanged(String value) {
    if (_usernameDebounce?.isActive ?? false) _usernameDebounce!.cancel();

    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      setState(() {
        _isUsernameAvailable = null;
        _isCheckingUsername = false;
      });
      return;
    }

    if (trimmed.toLowerCase() == widget.user.username.toLowerCase()) {
      setState(() {
        _isUsernameAvailable = true;
        _isCheckingUsername = false;
      });
      return;
    }

    if (trimmed.length < 3) {
      setState(() {
        _isUsernameAvailable = null;
        _isCheckingUsername = false;
      });
      return;
    }

    setState(() {
      _isCheckingUsername = true;
      _isUsernameAvailable = null;
    });

    _usernameDebounce = Timer(const Duration(milliseconds: 500), () async {
      final available = await ApiRepository().isUsernameAvailable(
        trimmed,
        excludeUserId: widget.user.id,
      );
      if (mounted) {
        setState(() {
          _isUsernameAvailable = available;
          _isCheckingUsername = false;
        });
      }
    });
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: source,
        imageQuality: 70,
        maxWidth: 500,
      );
      if (pickedFile != null) {
        final file = File(pickedFile.path);
        final bytes = await file.readAsBytes();
        setState(() {
          _pickedImage = file;
          _avatarBase64 = base64Encode(bytes);
        });
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
    }
  }

  void _showImagePickerOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: const Text('Take a photo'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Choose from gallery'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    final updatedUser = widget.user.copyWith(
      name: _nameController.text.trim(),
      username: _usernameController.text.trim(),
    );

    final success = await context.read<ProfileCubit>().updateUser(
      updatedUser,
      avatarBase64: _avatarBase64,
    );

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
      if (success) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to update profile. Please try again.'),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Edit profile', style: tt.headlineMedium),
              const SizedBox(height: 20),
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: _showImagePickerOptions,
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 36,
                      backgroundColor: cs.surfaceContainerHighest,
                      backgroundImage: _pickedImage != null
                          ? FileImage(_pickedImage!)
                          : (widget.user.avatarUrl.isNotEmpty
                                ? NetworkImage(widget.user.avatarUrl)
                                      as ImageProvider
                                : null),
                      child:
                          _pickedImage == null && widget.user.avatarUrl.isEmpty
                          ? Text(
                              widget.user.name.isNotEmpty
                                  ? widget.user.name[0].toUpperCase()
                                  : 'U',
                              style: AppTextStyles.display(28, color: cs.onSurface),
                            )
                          : null,
                    ),
                    const SizedBox(width: 16),
                    Text(
                      'Change photo',
                      style: tt.labelLarge?.copyWith(color: cs.onSurface),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 22),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Name'),
                validator: (val) => val == null || val.trim().isEmpty
                    ? 'Name cannot be empty'
                    : null,
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _usernameController,
                onChanged: _onUsernameChanged,
                decoration: InputDecoration(
                  labelText: 'Username',
                  prefixText: '@',
                  suffixIcon: _isCheckingUsername
                      ? const Padding(
                          padding: EdgeInsets.all(14.0),
                          child: SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        )
                      : (_isUsernameAvailable != null
                            ? Icon(
                                _isUsernameAvailable!
                                    ? Icons.check_rounded
                                    : Icons.close_rounded,
                                color: _isUsernameAvailable!
                                    ? cs.primary
                                    : cs.error,
                              )
                            : null),
                  helperText:
                      _isUsernameAvailable == true &&
                          _usernameController.text.trim().toLowerCase() !=
                              widget.user.username.toLowerCase()
                      ? 'Username is available'
                      : null,
                  helperStyle: tt.bodySmall?.copyWith(color: cs.primary),
                  errorText: _isUsernameAvailable == false
                      ? 'Username is already taken'
                      : null,
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Username cannot be empty';
                  }
                  if (val.trim().length < 3) {
                    return 'Username must be at least 3 characters';
                  }
                  if (_isUsernameAvailable == false) {
                    return 'Username is already taken';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 22),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed:
                      _isLoading ||
                          _isCheckingUsername ||
                          _isUsernameAvailable != true
                      ? null
                      : _save,
                  child: _isLoading
                      ? SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: cs.onSurfaceVariant,
                          ),
                        )
                      : const Text('Save changes'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
