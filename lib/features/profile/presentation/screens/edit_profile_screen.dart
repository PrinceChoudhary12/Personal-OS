// lib/features/profile/presentation/screens/edit_profile_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../domain/models/user_profile.dart';
import '../providers/profile_providers.dart';

class EditProfileScreen extends ConsumerWidget {
  const EditProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(userProfileProvider);
    final controllerState = ref.watch(profileControllerProvider);

    // Listen to profile controller state changes
    ref.listen<AsyncValue<void>>(profileControllerProvider, (previous, next) {
      next.when(
        data: (_) {
          if (previous is AsyncLoading) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Profile updated successfully! 🎉'),
                backgroundColor: AppColors.success,
                behavior: SnackBarBehavior.floating,
              ),
            );
            context.pop(); // Navigate back to the Profile screen
          }
        },
        error: (err, _) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to update profile: $err'),
              backgroundColor: AppColors.error,
              behavior: SnackBarBehavior.floating,
            ),
          );
        },
        loading: () {},
      );
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profile'),
        centerTitle: true,
      ),
      body: profileAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(
            color: AppColors.primary,
          ),
        ),
        error: (error, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Text(
              'Error loading profile: $error',
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.error),
            ),
          ),
        ),
        data: (profile) {
          if (profile == null) {
            return const Center(child: Text('No profile data found.'));
          }

          return Stack(
            children: [
              Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 600),
                    child: _EditProfileForm(
                      profile: profile,
                      isLoading: controllerState.isLoading,
                    ),
                  ),
                ),
              ),
              if (controllerState.isLoading)
                Container(
                  color: Colors.black.withValues(alpha: 0.3),
                  child: const Center(
                    child: CircularProgressIndicator(
                      color: AppColors.primary,
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _EditProfileForm extends ConsumerStatefulWidget {
  final UserProfile profile;
  final bool isLoading;

  const _EditProfileForm({
    required this.profile,
    required this.isLoading,
  });

  @override
  ConsumerState<_EditProfileForm> createState() => _EditProfileFormState();
}

class _EditProfileFormState extends ConsumerState<_EditProfileForm> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _displayNameCtrl;
  late final TextEditingController _photoUrlCtrl;
  late final TextEditingController _bioCtrl;
  late final TextEditingController _careerGoalCtrl;
  late final TextEditingController _skillsCtrl;

  late final TextEditingController _universityCtrl;
  late final TextEditingController _courseCtrl;
  late final TextEditingController _dailyGoalHoursCtrl;
  late final TextEditingController _weeklyGoalHoursCtrl;
  late int _selectedSemester;
  late String _selectedStudyTime;

  final List<String> _studyTimeOptions = ['Morning', 'Afternoon', 'Evening', 'Night'];

  @override
  void initState() {
    super.initState();
    _displayNameCtrl = TextEditingController(text: widget.profile.displayName);
    _photoUrlCtrl = TextEditingController(text: widget.profile.photoUrl);
    _bioCtrl = TextEditingController(text: widget.profile.bio);
    _careerGoalCtrl = TextEditingController(text: widget.profile.careerGoal);
    _skillsCtrl = TextEditingController(text: widget.profile.skills.join(', '));

    _universityCtrl = TextEditingController(text: widget.profile.university);
    _courseCtrl = TextEditingController(text: widget.profile.course);
    _dailyGoalHoursCtrl =
        TextEditingController(text: widget.profile.dailyGoalHours.toString());
    _weeklyGoalHoursCtrl =
        TextEditingController(text: widget.profile.weeklyGoalHours.toString());
    _selectedSemester = widget.profile.semester > 0 ? widget.profile.semester : 1;

    final origTime = widget.profile.preferredStudyTime;
    _selectedStudyTime =
        _studyTimeOptions.contains(origTime) ? origTime : 'Morning';
  }

  @override
  void dispose() {
    _displayNameCtrl.dispose();
    _photoUrlCtrl.dispose();
    _bioCtrl.dispose();
    _careerGoalCtrl.dispose();
    _skillsCtrl.dispose();
    _universityCtrl.dispose();
    _courseCtrl.dispose();
    _dailyGoalHoursCtrl.dispose();
    _weeklyGoalHoursCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    // Parse skills from comma-separated string
    final List<String> parsedSkills = _skillsCtrl.text
        .split(',')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();

    final updated = widget.profile.copyWith(
      displayName: _displayNameCtrl.text.trim(),
      photoUrl: _photoUrlCtrl.text.trim(),
      bio: _bioCtrl.text.trim(),
      careerGoal: _careerGoalCtrl.text.trim(),
      skills: parsedSkills,
      university: _universityCtrl.text.trim(),
      course: _courseCtrl.text.trim(),
      semester: _selectedSemester,
      dailyGoalHours: double.tryParse(_dailyGoalHoursCtrl.text.trim()) ?? 0.0,
      weeklyGoalHours: double.tryParse(_weeklyGoalHoursCtrl.text.trim()) ?? 0.0,
      preferredStudyTime: _selectedStudyTime,
      updatedAt: DateTime.now(),
    );

    ref.read(profileControllerProvider.notifier).updateProfile(updated);
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Section: General Info
          _buildSectionHeader('General Details'),
          const SizedBox(height: 12),

          TextFormField(
            controller: _displayNameCtrl,
            enabled: !widget.isLoading,
            decoration: const InputDecoration(
              labelText: 'Display Name *',
              prefixIcon: Icon(Icons.person_outline),
              border: OutlineInputBorder(),
            ),
            validator: (v) {
              if (v == null || v.trim().isEmpty) {
                return 'Please enter your display name';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),

          TextFormField(
            controller: _photoUrlCtrl,
            enabled: !widget.isLoading,
            decoration: const InputDecoration(
              labelText: 'Profile Picture URL',
              prefixIcon: Icon(Icons.image_outlined),
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),

          TextFormField(
            controller: _bioCtrl,
            enabled: !widget.isLoading,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'Biography',
              prefixIcon: Icon(Icons.description_outlined),
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),

          TextFormField(
            controller: _careerGoalCtrl,
            enabled: !widget.isLoading,
            decoration: const InputDecoration(
              labelText: 'Career Goal',
              prefixIcon: Icon(Icons.flag_outlined),
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),

          TextFormField(
            controller: _skillsCtrl,
            enabled: !widget.isLoading,
            decoration: const InputDecoration(
              labelText: 'Skills (comma-separated)',
              helperText: 'e.g. Flutter, Firebase, Python, Coding',
              prefixIcon: Icon(Icons.psychology_outlined),
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 24),

          // Section: Academic Profile
          _buildSectionHeader('Academic Profile'),
          const SizedBox(height: 12),

          TextFormField(
            controller: _universityCtrl,
            enabled: !widget.isLoading,
            decoration: const InputDecoration(
              labelText: 'University',
              prefixIcon: Icon(Icons.account_balance_outlined),
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),

          TextFormField(
            controller: _courseCtrl,
            enabled: !widget.isLoading,
            decoration: const InputDecoration(
              labelText: 'Course / Major',
              prefixIcon: Icon(Icons.book_outlined),
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),

          DropdownButtonFormField<int>(
            initialValue: _selectedSemester,
            decoration: const InputDecoration(
              labelText: 'Semester',
              prefixIcon: Icon(Icons.calendar_month_outlined),
              border: OutlineInputBorder(),
            ),
            items: List.generate(12, (index) => index + 1)
                .map((sem) => DropdownMenuItem<int>(
                      value: sem,
                      child: Text('Semester $sem'),
                    ))
                .toList(),
            onChanged: widget.isLoading
                ? null
                : (val) {
                    if (val != null) {
                      setState(() => _selectedSemester = val);
                    }
                  },
          ),
          const SizedBox(height: 24),

          // Section: Study Goals
          _buildSectionHeader('Study Goals & Preferences'),
          const SizedBox(height: 12),

          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: TextFormField(
                  controller: _dailyGoalHoursCtrl,
                  enabled: !widget.isLoading,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                  ],
                  decoration: const InputDecoration(
                    labelText: 'Daily Goal (hrs)',
                    prefixIcon: Icon(Icons.today_outlined),
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return 'Required';
                    }
                    final numVal = double.tryParse(v);
                    if (numVal == null) return 'Invalid number';
                    if (numVal < 0 || numVal > 24) {
                      return 'Must be 0-24 hrs';
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextFormField(
                  controller: _weeklyGoalHoursCtrl,
                  enabled: !widget.isLoading,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                  ],
                  decoration: const InputDecoration(
                    labelText: 'Weekly Goal (hrs)',
                    prefixIcon: Icon(Icons.date_range_outlined),
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return 'Required';
                    }
                    final numVal = double.tryParse(v);
                    if (numVal == null) return 'Invalid number';
                    if (numVal < 0 || numVal > 168) {
                      return 'Must be 0-168 hrs';
                    }
                    final dailyVal = double.tryParse(_dailyGoalHoursCtrl.text.trim());
                    if (dailyVal != null && numVal < dailyVal) {
                      return 'Must be >= Daily';
                    }
                    return null;
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          DropdownButtonFormField<String>(
            initialValue: _selectedStudyTime,
            decoration: const InputDecoration(
              labelText: 'Preferred Study Time',
              prefixIcon: Icon(Icons.access_time),
              border: OutlineInputBorder(),
            ),
            items: _studyTimeOptions
                .map((time) => DropdownMenuItem<String>(
                      value: time,
                      child: Text(time),
                    ))
                .toList(),
            onChanged: widget.isLoading
                ? null
                : (val) {
                    if (val != null) {
                      setState(() => _selectedStudyTime = val);
                    }
                  },
          ),
          const SizedBox(height: 36),

          // Action Buttons: Save & Cancel
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: widget.isLoading ? null : () => context.pop(),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Cancel'),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: FilledButton(
                  onPressed: widget.isLoading ? null : _submit,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Save Profile',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppColors.primary,
          ),
        ),
        const Divider(height: 12),
      ],
    );
  }
}
