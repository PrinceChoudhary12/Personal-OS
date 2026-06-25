// lib/features/student_ai/presentation/widgets/student_ai_quick_ask_widget.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_colors.dart';
import '../providers/student_ai_providers.dart';

class StudentAiQuickAskWidget extends ConsumerStatefulWidget {
  const StudentAiQuickAskWidget({super.key});

  @override
  ConsumerState<StudentAiQuickAskWidget> createState() => _StudentAiQuickAskWidgetState();
}

class _StudentAiQuickAskWidgetState extends ConsumerState<StudentAiQuickAskWidget> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    // Send the message in provider
    ref.read(studentAiChatNotifierProvider.notifier).sendMessage(text);
    _controller.clear();

    // Navigate to student AI screen
    context.go('/student-ai');
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? AppColors.darkSurfaceCard : AppColors.lightCard;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final textPrimary = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor),
        boxShadow: AppColors.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: AppColors.primaryGlow,
                ),
                child: const Icon(Icons.smart_toy_rounded, color: Colors.white, size: 16),
              ),
              const SizedBox(width: 12),
              Text(
                'Quick Ask Student AI',
                style: GoogleFonts.outfit(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkBackground : AppColors.lightBackground,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: borderColor),
                  ),
                  child: TextField(
                    controller: _controller,
                    style: GoogleFonts.inter(fontSize: 14, color: textPrimary),
                    decoration: InputDecoration(
                      hintText: 'Ask about study tips, exams, or attendance...',
                      hintStyle: GoogleFonts.inter(color: AppColors.darkTextSecondary, fontSize: 13),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                    ),
                    onSubmitted: (_) => _submit(),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Container(
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  shape: BoxShape.circle,
                  boxShadow: AppColors.primaryGlow,
                ),
                child: IconButton(
                  icon: const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 18),
                  onPressed: _submit,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
