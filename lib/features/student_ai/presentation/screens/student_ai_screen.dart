// lib/features/student_ai/presentation/screens/student_ai_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_colors.dart';
import '../providers/student_ai_providers.dart';
import '../../domain/models/chat_message_model.dart';

class StudentAiScreen extends ConsumerStatefulWidget {
  const StudentAiScreen({super.key});

  @override
  ConsumerState<StudentAiScreen> createState() => _StudentAiScreenState();
}

class _StudentAiScreenState extends ConsumerState<StudentAiScreen> {
  final TextEditingController _inputController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  // Search variables
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();

  // Selected prompt category
  String _selectedCategory = 'DSA & Programming';

  final Map<String, List<String>> _promptCategories = {
    'DSA & Programming': [
      'Explain binary search trees.',
      'How to study algorithms effectively?',
      'Write a quicksort implementation.',
    ],
    'OS & DBMS': [
      'What is ACID in databases?',
      'Explain process scheduling in OS.',
      'How do database indexes work?',
    ],
    'DevOps & Cloud': [
      'What is Docker and why use it?',
      'Explain CI/CD pipelines.',
      'How container scaling works in Kubernetes?',
    ],
    'Career Advice': [
      'How do I prepare for a placement interview?',
      'What should I put in my coding resume?',
      'How to build a software engineering portfolio?',
    ]
  };

  @override
  void dispose() {
    _inputController.dispose();
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(studentAiChatNotifierProvider);
    final notifier = ref.read(studentAiChatNotifierProvider.notifier);
    final messages = ref.watch(studentAiFilteredMessagesProvider);

    // Scroll to bottom when list changes or typing state changes
    ref.listen(studentAiFilteredMessagesProvider, (prev, next) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
    });

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
      appBar: AppBar(
        backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
        elevation: 0,
        title: _isSearching
            ? TextField(
                controller: _searchController,
                style: TextStyle(color: textPrimary),
                autofocus: true,
                decoration: const InputDecoration(
                  hintText: 'Search chat messages...',
                  hintStyle: TextStyle(color: AppColors.darkTextSecondary),
                  border: InputBorder.none,
                ),
                onChanged: (val) {
                  ref.read(studentAiSearchQueryProvider.notifier).state = val;
                },
              )
            : Text(
                'Student AI Assistant',
                style: GoogleFonts.outfit(
                  fontWeight: FontWeight.w900,
                  fontSize: 22,
                  letterSpacing: -0.6,
                  color: textPrimary,
                ),
              ),
        centerTitle: false,
        actions: [
          // Search Icon Button
          IconButton(
            icon: Icon(
              _isSearching ? Icons.close_rounded : Icons.search_rounded,
              color: textPrimary,
            ),
            onPressed: () {
              setState(() {
                if (_isSearching) {
                  _isSearching = false;
                  _searchController.clear();
                  ref.read(studentAiSearchQueryProvider.notifier).state = '';
                } else {
                  _isSearching = true;
                }
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete_sweep_rounded, color: AppColors.error),
            tooltip: 'Clear Chat History',
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  backgroundColor: isDark ? AppColors.darkSurfaceCard : AppColors.lightCard,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  title: Text('Clear Chat History?', style: TextStyle(color: textPrimary)),
                  content: Text('This will delete all messages permanently.', style: TextStyle(color: textPrimary)),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        notifier.clearHistory();
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(backgroundColor: AppColors.error, foregroundColor: Colors.white),
                      child: const Text('Clear'),
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          // --- Capsule Mode Selector ---
          _buildModeSelector(context, state.mode, notifier),
          const Divider(height: 1, color: AppColors.darkBorder),

          // --- Chat Messages List ---
          Expanded(
            child: state.messages.isEmpty
                ? _buildEmptyState(state.mode, notifier)
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      final msg = messages[index];
                      return _buildMessageBubble(msg);
                    },
                  ),
          ),

          // --- Typing Indicator ---
          if (state.isTyping) const _TypingIndicator(),

          // --- Suggested prompts row (when chat has messages) ---
          if (state.messages.isNotEmpty && state.suggestedQuestions.isNotEmpty && !_isSearching)
            _buildSuggestedQuestionsRow(state.suggestedQuestions, notifier),

          // --- Input Footer ---
          _buildInputFooter(state.isTyping, notifier, isDark, textPrimary),
        ],
      ),
    );
  }

  Widget _buildModeSelector(
    BuildContext context,
    String currentMode,
    StudentAiChatNotifier notifier,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Center(
        child: Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: AppColors.darkSidebar,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.darkBorder),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildModeOption('generic', 'Generic Chat', currentMode == 'generic', notifier),
              _buildModeOption('connected', 'Connected Data', currentMode == 'connected', notifier),
              _buildModeOption('mentor', 'Student Mentor', currentMode == 'mentor', notifier),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildModeOption(
    String mode,
    String label,
    bool isActive,
    StudentAiChatNotifier notifier,
  ) {
    return GestureDetector(
      onTap: () {
        notifier.setMode(mode);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        decoration: BoxDecoration(
          gradient: isActive ? AppColors.primaryGradient : null,
          borderRadius: BorderRadius.circular(16),
          boxShadow: isActive ? AppColors.primaryGlow : null,
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: isActive ? Colors.white : AppColors.darkTextSecondary,
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(
    String mode,
    StudentAiChatNotifier notifier,
  ) {
    String description = '';
    IconData icon = Icons.smart_toy_outlined;
    if (mode == 'generic') {
      description = 'Ask generic study, productivity, or programming questions.';
      icon = Icons.chat_bubble_outline_rounded;
    } else if (mode == 'connected') {
      description = 'Connects directly with your focus hours, grades, exams, and attendance metrics.';
      icon = Icons.insights_rounded;
    } else {
      description = 'Professional student mentor providing custom study plans and feedback.';
      icon = Icons.school_outlined;
    }

    final questions = _promptCategories[_selectedCategory] ?? [];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              shape: BoxShape.circle,
              boxShadow: AppColors.primaryGlow,
            ),
            child: Icon(icon, color: Colors.white, size: 40),
          ),
          const SizedBox(height: 24),
          Text(
            'Start a conversation',
            style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 20),
          ),
          const SizedBox(height: 8),
          Text(
            description,
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(color: AppColors.darkTextSecondary, fontSize: 13, height: 1.45),
          ),
          const SizedBox(height: 40),

          // Horizontal prompt categories list
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _promptCategories.keys.map((cat) {
                final isSel = cat == _selectedCategory;
                return Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: ChoiceChip(
                    label: Text(
                      cat,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: isSel ? Colors.white : AppColors.darkTextSecondary,
                      ),
                    ),
                    selected: isSel,
                    selectedColor: AppColors.primary,
                    backgroundColor: AppColors.darkSurfaceCard,
                    side: BorderSide(color: isSel ? AppColors.primary : AppColors.darkBorder),
                    onSelected: (_) {
                      setState(() {
                        _selectedCategory = cat;
                      });
                    },
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 20),

          // Prompts list
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: questions.length,
            itemBuilder: (context, idx) {
              final q = questions[idx];
              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                child: InkWell(
                  onTap: () => notifier.sendMessage(q),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: AppColors.darkSurfaceCard,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.darkBorder),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.bolt_rounded, color: AppColors.accent, size: 16),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            q,
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: AppColors.darkTextPrimary,
                            ),
                          ),
                        ),
                        const Icon(Icons.arrow_forward_ios_rounded, color: AppColors.darkTextSecondary, size: 12),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessageModel msg) {
    final isUser = msg.sender == 'user';
    return Padding(
      padding: const EdgeInsets.only(bottom: 20.0),
      child: Row(
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) const Padding(
            padding: EdgeInsets.only(right: 12.0),
            child: _AIAvatar(),
          ),
          Flexible(
            child: GestureDetector(
              onLongPress: () {
                Clipboard.setData(ClipboardData(text: msg.content));
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Message copied to clipboard', style: GoogleFonts.inter(fontSize: 12)),
                    duration: const Duration(seconds: 1),
                    behavior: SnackBarBehavior.floating,
                    backgroundColor: AppColors.primary,
                  ),
                );
              },
              child: Container(
                padding: const EdgeInsets.all(18),
                constraints: const BoxConstraints(maxWidth: 600),
                decoration: BoxDecoration(
                  color: isUser ? AppColors.primary : AppColors.darkSurfaceCard,
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(18),
                    topRight: const Radius.circular(18),
                    bottomLeft: isUser ? const Radius.circular(18) : const Radius.circular(2),
                    bottomRight: isUser ? const Radius.circular(2) : const Radius.circular(18),
                  ),
                  border: isUser ? null : Border.all(color: AppColors.darkBorder),
                  boxShadow: isUser ? AppColors.primaryGlow : AppColors.cardShadow,
                ),
                child: isUser
                    ? Text(
                        msg.content,
                        style: GoogleFonts.inter(fontSize: 14, color: Colors.white, height: 1.45),
                      )
                    : AppMarkdown(text: msg.content),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuggestedQuestionsRow(List<String> suggestions, StudentAiChatNotifier notifier) {
    return Container(
      height: 48,
      margin: const EdgeInsets.only(bottom: 12),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 24),
        itemCount: suggestions.length,
        itemBuilder: (context, index) {
          final s = suggestions[index];
          return Padding(
            padding: const EdgeInsets.only(right: 10.0),
            child: ActionChip(
              label: Text(
                s,
                style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              backgroundColor: AppColors.darkSurfaceCard,
              side: const BorderSide(color: AppColors.darkBorder),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              onPressed: () => notifier.sendMessage(s),
            ),
          );
        },
      ),
    );
  }

  Widget _buildInputFooter(bool isTyping, StudentAiChatNotifier notifier, bool isDark, Color textPrimary) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurfaceCard : AppColors.lightCard,
        border: const Border(top: BorderSide(color: AppColors.darkBorder)),
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkBackground : AppColors.lightBackground,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.darkBorder),
                ),
                child: TextField(
                  controller: _inputController,
                  enabled: !isTyping,
                  style: GoogleFonts.inter(fontSize: 14, color: textPrimary),
                  decoration: InputDecoration(
                    hintText: isTyping ? 'Assistant is working...' : 'Ask student AI assistant...',
                    hintStyle: GoogleFonts.inter(color: AppColors.darkTextSecondary, fontSize: 13),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                  ),
                  onSubmitted: (text) {
                    if (text.trim().isNotEmpty) {
                      notifier.sendMessage(text);
                      _inputController.clear();
                    }
                  },
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
                icon: const Icon(Icons.send_rounded, color: Colors.white, size: 18),
                onPressed: isTyping
                    ? null
                    : () {
                        final text = _inputController.text.trim();
                        if (text.isNotEmpty) {
                          notifier.sendMessage(text);
                          _inputController.clear();
                        }
                      },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AIAvatar extends StatefulWidget {
  const _AIAvatar();

  @override
  State<_AIAvatar> createState() => _AIAvatarState();
}

class _AIAvatarState extends State<_AIAvatar> with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        final scale = 1.0 + (_pulseController.value * 0.12);
        final opacity = 0.4 - (_pulseController.value * 0.3);
        return Stack(
          alignment: Alignment.center,
          children: [
            Transform.scale(
              scale: scale,
              child: Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.primary.withValues(alpha: opacity),
                    width: 2.5,
                  ),
                ),
              ),
            ),
            Container(
              width: 32,
              height: 32,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: AppColors.primaryGradient,
              ),
              child: const Center(
                child: Icon(
                  Icons.smart_toy_rounded,
                  color: Colors.white,
                  size: 16,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _TypingIndicator extends StatefulWidget {
  const _TypingIndicator();

  @override
  State<_TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<_TypingIndicator> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          const _AIAvatar(),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.darkSurfaceCard,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
                bottomRight: Radius.circular(16),
                bottomLeft: Radius.circular(2),
              ),
              border: Border.all(color: AppColors.darkBorder),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(3, (index) {
                return AnimatedBuilder(
                  animation: _controller,
                  builder: (context, child) {
                    final delay = index * 0.2;
                    double value = (_controller.value - delay);
                    if (value < 0) value += 1.0;
                    if (value > 1.0) value -= 1.0;

                    final double offset = -6.0 * (value > 0.5 ? (1.0 - value) * 2 : value * 2);

                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 2),
                      transform: Matrix4.translationValues(0, offset, 0),
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                    );
                  },
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}

class AppMarkdown extends StatelessWidget {
  final String text;
  const AppMarkdown({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    if (text.isEmpty) return const SizedBox();

    final List<Widget> widgets = [];
    final parts = text.split('```');

    for (int i = 0; i < parts.length; i++) {
      final part = parts[i];
      if (i % 2 == 1) {
        // Code Block
        final lines = part.split('\n');
        String language = 'code';
        String code = part;
        if (lines.isNotEmpty && lines.first.trim().isNotEmpty && lines.first.trim().length < 15) {
          language = lines.first.trim();
          code = lines.sublist(1).join('\n').trim();
        } else {
          code = part.trim();
        }
        widgets.add(_buildCodeBlock(context, language, code));
      } else {
        // Text Block
        if (part.trim().isNotEmpty) {
          widgets.add(_buildTextBlock(context, part));
        }
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: widgets,
    );
  }

  Widget _buildCodeBlock(BuildContext context, String language, String code) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF0B1220), // Darker background
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.darkBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: const BoxDecoration(
              color: Color(0xFF0F172A),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  language.toUpperCase(),
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: AppColors.darkTextSecondary,
                  ),
                ),
                InkWell(
                  onTap: () {
                    Clipboard.setData(ClipboardData(text: code));
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Code copied to clipboard', style: GoogleFonts.inter(fontSize: 12)),
                        duration: const Duration(seconds: 1),
                        behavior: SnackBarBehavior.floating,
                        backgroundColor: AppColors.success,
                      ),
                    );
                  },
                  child: Row(
                    children: [
                      const Icon(Icons.copy_rounded, color: AppColors.darkTextSecondary, size: 12),
                      const SizedBox(width: 4),
                      Text(
                        'Copy',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color: AppColors.darkTextSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Text(
                code,
                style: GoogleFonts.firaCode(
                  fontSize: 13,
                  color: const Color(0xFFE2E8F0),
                  height: 1.4,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextBlock(BuildContext context, String content) {
    final lines = content.split('\n');
    final children = <Widget>[];

    for (int i = 0; i < lines.length; i++) {
      final line = lines[i];
      if (line.trim().isEmpty) {
        children.add(const SizedBox(height: 8));
        continue;
      }

      if (line.startsWith('### ')) {
        children.add(Padding(
          padding: const EdgeInsets.only(top: 12, bottom: 6),
          child: Text(
            line.replaceFirst('### ', ''),
            style: GoogleFonts.outfit(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ));
        continue;
      }
      if (line.startsWith('## ')) {
        children.add(Padding(
          padding: const EdgeInsets.only(top: 14, bottom: 8),
          child: Text(
            line.replaceFirst('## ', ''),
            style: GoogleFonts.outfit(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ));
        continue;
      }
      if (line.startsWith('# ')) {
        children.add(Padding(
          padding: const EdgeInsets.only(top: 16, bottom: 10),
          child: Text(
            line.replaceFirst('# ', ''),
            style: GoogleFonts.outfit(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ));
        continue;
      }

      final isBullet = line.trim().startsWith('•') || line.trim().startsWith('*') || line.trim().startsWith('-');
      final cleanLine = isBullet ? line.replaceFirst(RegExp(r'^[•\*\-]\s*'), '').trim() : line;

      final spans = _parseInlineStyles(cleanLine);

      children.add(
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 3.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (isBullet) ...[
                const Padding(
                  padding: EdgeInsets.only(top: 7.0, right: 10.0, left: 4.0),
                  child: Icon(Icons.circle, size: 5, color: AppColors.primary),
                ),
              ],
              Expanded(
                child: RichText(
                  text: TextSpan(
                    style: GoogleFonts.inter(fontSize: 14, height: 1.45, color: const Color(0xFFE2E8F0)),
                    children: spans,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: children,
    );
  }

  List<TextSpan> _parseInlineStyles(String text) {
    final List<TextSpan> spans = [];
    final boldRegex = RegExp(r'\*\*(.*?)\*\*');
    final italicRegex = RegExp(r'\*(.*?)\*');

    int index = 0;
    while (index < text.length) {
      final boldMatch = boldRegex.firstMatch(text.substring(index));
      final italicMatch = italicRegex.firstMatch(text.substring(index));

      if (boldMatch == null && italicMatch == null) {
        spans.add(TextSpan(text: text.substring(index)));
        break;
      }

      final isBoldFirst = boldMatch != null &&
          (italicMatch == null || boldMatch.start < italicMatch.start);

      final match = (isBoldFirst ? boldMatch : italicMatch)!;
      final matchStart = index + match.start;
      final matchEnd = index + match.end;

      if (matchStart > index) {
        spans.add(TextSpan(text: text.substring(index, matchStart)));
      }

      final content = match.group(1) ?? '';
      spans.add(
        TextSpan(
          text: content,
          style: TextStyle(
            fontWeight: isBoldFirst ? FontWeight.bold : FontWeight.normal,
            fontStyle: isBoldFirst ? FontStyle.normal : FontStyle.italic,
            color: isBoldFirst ? Colors.white : const Color(0xFF94A3B8),
          ),
        ),
      );

      index = matchEnd;
    }

    return spans;
  }
}
