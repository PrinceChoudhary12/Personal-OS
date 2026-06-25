// lib/features/student_ai/data/repositories/firestore_student_ai_repository.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/models/chat_message_model.dart';
import '../../domain/repositories/student_ai_repository.dart';

class FirestoreStudentAIRepository implements StudentAIRepository {
  final FirebaseFirestore _firestore;

  FirestoreStudentAIRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _chatCollection(String userId) =>
      _firestore.collection('users').doc(userId).collection('student_ai_chats');

  @override
  Future<List<ChatMessageModel>> getChatHistory(String userId) async {
    try {
      final snapshot = await _chatCollection(userId)
          .orderBy('timestamp', descending: false)
          .get();
      return snapshot.docs
          .map((doc) => ChatMessageModel.fromMap(doc.data(), doc.id))
          .toList();
    } catch (_) {
      return [];
    }
  }

  @override
  Future<void> saveMessage(String userId, ChatMessageModel message) async {
    try {
      if (message.id.isEmpty) {
        await _chatCollection(userId).add(message.toMap());
      } else {
        await _chatCollection(userId).doc(message.id).set(message.toMap());
      }
    } catch (_) {}
  }

  @override
  Future<void> clearChatHistory(String userId) async {
    try {
      final snapshot = await _chatCollection(userId).get();
      final batch = _firestore.batch();
      for (final doc in snapshot.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
    } catch (_) {}
  }

  @override
  Stream<String> streamResponse({
    required String prompt,
    required List<ChatMessageModel> history,
    required String userId,
    required String mode,
  }) async* {
    // 1. Fetch user data for Phase 2/3 connected mode context
    Map<String, dynamic> contextData = {};
    if (mode == 'connected' || mode == 'mentor') {
      contextData = await _fetchStudentContext(userId);
    }

    // 2. Generate response string based on prompt keywords and context
    final responseText = _generateAIResponse(prompt, mode, contextData);

    // 3. Stream the text word-by-word cumulatively with delay
    final words = responseText.split(' ');
    for (int i = 0; i < words.length; i++) {
      await Future.delayed(const Duration(milliseconds: 35));
      yield words.sublist(0, i + 1).join(' ');
    }
  }

  Future<Map<String, dynamic>> _fetchStudentContext(String userId) async {
    final Map<String, dynamic> data = {};
    try {
      // Fetch exams
      final examsSnap = await _firestore.collection('exams').where('userId', isEqualTo: userId).get();
      data['exams'] = examsSnap.docs.map((d) => d.data()).toList();

      // Fetch subjects
      final subsSnap = await _firestore.collection('subjects').where('userId', isEqualTo: userId).get();
      data['subjects'] = subsSnap.docs.map((d) => d.data()).toList();

      // Fetch attendance
      final attSnap = await _firestore.collection('attendance').where('userId', isEqualTo: userId).get();
      data['attendance'] = attSnap.docs.map((d) => d.data()).toList();

      // Fetch placements
      final placeSnap = await _firestore.collection('placement_progress').where('userId', isEqualTo: userId).get();
      data['placements'] = placeSnap.docs.map((d) => d.data()).toList();

      // Fetch goals
      final goalsSnap = await _firestore.collection('goals').where('userId', isEqualTo: userId).get();
      data['goals'] = goalsSnap.docs.map((d) => d.data()).toList();

      // Fetch focus sessions
      final focusSnap = await _firestore.collection('focus_sessions').where('userId', isEqualTo: userId).where('completed', isEqualTo: true).get();
      data['focus'] = focusSnap.docs.map((d) => d.data()).toList();

      // Fetch habits
      final habitsSnap = await _firestore.collection('habits').where('userId', isEqualTo: userId).get();
      data['habits'] = habitsSnap.docs.map((d) => d.data()).toList();

      // Fetch activities
      final actsSnap = await _firestore.collection('activities').where('userId', isEqualTo: userId).get();
      data['activities'] = actsSnap.docs.map((d) => d.data()).toList();
    } catch (_) {}
    return data;
  }

  String _generateAIResponse(String prompt, String mode, Map<String, dynamic> context) {
    final cleanPrompt = prompt.toLowerCase();
    
    // Base persona depending on the mode
    String prefix = "";
    if (mode == 'mentor') {
      prefix = "🎓 **[Student Mentor Mode Active]**\nAs your academic mentor, I am here to help you structure your habits, study schedules, and career strategies. Let's look at this constructively.\n\n";
    } else if (mode == 'connected') {
      prefix = "🔗 **[Connected Data Mode Active]**\nI've accessed your Personal OS metrics to give you context-rich updates.\n\n";
    }

    // Keyword matching & template generation
    if (mode == 'connected' || mode == 'mentor') {
      if (cleanPrompt.contains('what should i do today') ||
          cleanPrompt.contains('what to do today') ||
          cleanPrompt.contains('what today') ||
          cleanPrompt.contains('recommendations today') ||
          cleanPrompt.contains('suggest for today')) {
        final List<dynamic> exams = context['exams'] ?? [];
        final List<dynamic> habits = context['habits'] ?? [];
        final List<dynamic> goals = context['goals'] ?? [];
        final List<dynamic> focus = context['focus'] ?? [];

        final sb = StringBuffer();
        sb.write("$prefixHere is your dynamic daily action plan based on your Personal OS data:\n\n");

        // 1. Exams
        if (exams.isNotEmpty) {
          final upcoming = exams.where((ex) {
            final dateStr = ex['examDate'] as String? ?? '';
            if (dateStr.isEmpty) return false;
            final date = DateTime.tryParse(dateStr);
            if (date == null) return false;
            return date.difference(DateTime.now()).inDays <= 7;
          }).toList();

          if (upcoming.isNotEmpty) {
            sb.write("🚨 **Urgent Exam Prep:**\n");
            for (final ex in upcoming) {
              sb.write("  • **${ex['subject']}** is coming up very soon! Focus on: *${ex['syllabus']}*\n");
            }
            sb.write("\n");
          } else {
            final nextExam = exams.first;
            sb.write("📚 **Study Recommendation:**\n");
            sb.write("  • Spend 30 minutes revising for **${nextExam['subject']}** (Exam date: ${nextExam['examDate'].toString().split('T').first})\n\n");
          }
        } else {
          sb.write("📚 **Study Recommendation:**\n");
          sb.write("  • You have no upcoming exams. Use this time to explore new subjects or work on personal projects!\n\n");
        }

        // 2. Habits
        if (habits.isNotEmpty) {
          final now = DateTime.now();
          final todayStr = "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
          final pendingHabits = habits.where((h) {
            final List<dynamic> doneDates = h['completedDates'] ?? [];
            return !doneDates.contains(todayStr);
          }).toList();

          if (pendingHabits.isNotEmpty) {
            sb.write("🔄 **Habits to Complete Today:**\n");
            for (final h in pendingHabits) {
              sb.write("  • [ ] **${h['title']}** — *${h['description'] ?? 'Keep the streak going!'}*\n");
            }
            sb.write("\n");
          } else {
            sb.write("✅ **Habits Update:** Awesome job! All your daily habits are completed for today!\n\n");
          }
        }

        // 3. Goals
        final pendingGoals = goals.where((g) => g['isCompleted'] != true).toList();
        if (pendingGoals.isNotEmpty) {
          sb.write("🎯 **Priority Goals:**\n");
          for (final g in pendingGoals.take(2)) {
            sb.write("  • Continue working on: **${g['title']}**\n");
          }
          sb.write("\n");
        }

        // 4. Focus session tip
        final todayFocus = focus.where((s) {
          final start = DateTime.tryParse(s['startTime'] ?? '');
          return start != null && start.year == DateTime.now().year && start.month == DateTime.now().month && start.day == DateTime.now().day;
        }).fold<int>(0, (acc, s) => acc + (s['durationMinutes'] as num? ?? 0).toInt());

        sb.write("⚡ **Daily Focus Goal:**\n");
        if (todayFocus > 0) {
          sb.write("  • You have already logged **$todayFocus minutes** of focus today. Let's aim for another 25-minute Pomodoro session!\n");
        } else {
          sb.write("  • No focus sessions logged yet today. Jump into the **Focus Timer** page to start your first session!\n");
        }

        if (mode == 'mentor') {
          sb.write("\n💡 **Mentor's Advice:** Plan your day using the **Rule of 3**: write down 3 key outcomes you want to achieve today. Do the hardest task first (eat that frog!).");
        }

        return sb.toString();
      }

      if (cleanPrompt.contains('how productive') ||
          cleanPrompt.contains('how was my week') ||
          cleanPrompt.contains('productivity summary') ||
          cleanPrompt.contains('productivity insights') ||
          cleanPrompt.contains('my productivity')) {
        final List<dynamic> focus = context['focus'] ?? [];
        final List<dynamic> goals = context['goals'] ?? [];
        final List<dynamic> habits = context['habits'] ?? [];

        final now = DateTime.now();
        final weekAgo = now.subtract(const Duration(days: 7));

        final weekFocus = focus.where((s) {
          final start = DateTime.tryParse(s['startTime'] ?? '');
          return start != null && start.isAfter(weekAgo);
        }).fold<int>(0, (acc, s) => acc + (s['durationMinutes'] as num? ?? 0).toInt());

        final totalGoals = goals.length;
        final completedGoals = goals.where((g) => g['isCompleted'] == true).length;

        int maxStreak = 0;
        if (habits.isNotEmpty) {
          for (final h in habits) {
            final List<dynamic> completedDates = h['completedDates'] ?? [];
            final dates = completedDates
                .map((d) => DateTime.tryParse(d ?? ''))
                .where((d) => d != null)
                .map((d) => DateTime(d!.year, d.month, d.day))
                .toSet()
                .toList();

            if (dates.isNotEmpty) {
              dates.sort((a, b) => b.compareTo(a));
              final today = DateTime(now.year, now.month, now.day);
              final yesterday = today.subtract(const Duration(days: 1));
              if (dates.first == today || dates.first == yesterday) {
                int streak = 0;
                DateTime checkDate = dates.first;
                for (final d in dates) {
                  if (d == checkDate) {
                    streak++;
                    checkDate = checkDate.subtract(const Duration(days: 1));
                  } else {
                    break;
                  }
                }
                if (streak > maxStreak) maxStreak = streak;
              }
            }
          }
        }

        // Productivity evaluation
        String rating;
        String desc;
        if (weekFocus >= 150) {
          rating = "Elite / Ultra-Productive 🏆";
          desc = "Excellent work! You are in the flow state. Your focus output and consistency are outstanding.";
        } else if (weekFocus >= 60) {
          rating = "Solid Progress 📈";
          desc = "Good steady pace. You are maintaining a healthy balance of focused learning sessions.";
        } else {
          rating = "Developing Momentum 🎯";
          desc = "Start small. Even one 25-minute Pomodoro session today will kickstart your momentum.";
        }

        final sb = StringBuffer();
        sb.write("$prefixHere is your weekly productivity audit:\n\n");
        sb.write("📊 **Productivity Rating:** **$rating**\n\n");
        sb.write("• **Total Focus Time (7d):** $weekFocus minutes (${(weekFocus / 60.0).toStringAsFixed(1)} hours)\n");
        sb.write("• **Goals Completed:** $completedGoals out of $totalGoals total goals\n");
        if (habits.isNotEmpty) {
          sb.write("• **Habit Streaks:** Best current streak is **$maxStreak days** across ${habits.length} habits\n");
        }
        sb.write("\n📝 **Summary Insights:**\n$desc\n");

        if (mode == 'mentor') {
          sb.write("\n💡 **Mentor Strategy:** To improve next week, try time-blocking. Schedule your focus blocks in the **Scheduler** at the start of the week. This reduces decision fatigue and boosts commitment!");
        }

        return sb.toString();
      }

      if (cleanPrompt.contains('exam') || cleanPrompt.contains('test') || cleanPrompt.contains('revision') || cleanPrompt.contains('syllabus')) {
        final List<dynamic> exams = context['exams'] ?? [];
        if (exams.isEmpty) {
          return "$prefixYou don't have any upcoming exams tracked in your Exam Tracker. To add exams, syllabus requirements, and revision lists, go to the **Exam Tracker** module.";
        }
        final sb = StringBuffer();
        sb.write("$prefixHere is a summary of your upcoming exams:\n\n");
        for (final ex in exams) {
          final subject = ex['subject'] ?? 'Unknown Subject';
          final dateStr = ex['examDate'] as String? ?? '';
          final priority = ex['priority'] as String? ?? 'Medium';
          final syllabus = ex['syllabus'] as String? ?? '';
          
          DateTime? examDate;
          if (dateStr.isNotEmpty) {
            examDate = DateTime.tryParse(dateStr);
          }
          final days = examDate?.difference(DateTime.now()).inDays;
          final countdown = days != null ? (days >= 0 ? "$days days remaining" : "Passed") : "Date not set";
          
          sb.write("• **$subject** — Exam Date: ${dateStr.split('T').first} ($countdown) | Priority: $priority\n");
          if (syllabus.isNotEmpty) {
            sb.write("  *Syllabus:* $syllabus\n");
          }
        }
        if (mode == 'mentor') {
          sb.write("\n💡 **Mentor Study Tips:** Use **spaced repetition** to review topics. Spend 45 minutes on active recall, then take a 10-minute break. Focus on high-priority syllabus items first!");
        }
        return sb.toString();
      }

      if (cleanPrompt.contains('attendance') || cleanPrompt.contains('absent') || cleanPrompt.contains('class') || cleanPrompt.contains('warning') || cleanPrompt.contains('course')) {
        final List<dynamic> subjects = context['subjects'] ?? [];
        final List<dynamic> logs = context['attendance'] ?? [];
        if (subjects.isEmpty) {
          return "$prefixYou don't have any subjects tracked in your Student Hub. Go to **Student Hub > Subjects** to add your current courses and start logging class attendance.";
        }
        final sb = StringBuffer();
        sb.write("$prefixHere is your current course attendance summary:\n\n");
        final List<String> warnings = [];
        
        for (final s in subjects) {
          final id = s['id'] ?? '';
          final code = s['code'] ?? '';
          final name = s['name'] ?? '';
          final subLogs = logs.where((l) => l['subjectId'] == id).toList();
          final presents = subLogs.where((l) => l['status'] == 'present').length;
          final absents = subLogs.where((l) => l['status'] == 'absent').length;
          final total = presents + absents;
          
          final rate = total > 0 ? (presents / total) * 100.0 : 100.0;
          sb.write("• **$name ($code)**: ${rate.toStringAsFixed(1)}% attendance ($presents/$total attended)\n");
          if (rate < 75.0) {
            warnings.add("$name ($code)");
          }
        }
        if (warnings.isNotEmpty) {
          sb.write("\n⚠️ **Attendance Alerts (Below 75%):**\n");
          for (final w in warnings) {
            sb.write("  * $w requires immediate attendance to prevent eligibility issues!\n");
          }
        }
        if (mode == 'mentor') {
          sb.write("\n💡 **Mentor Attendance Advice:** Attendance is directly linked to academic success. If you are struggling with morning classes, adjust your study schedule to wind down early and prioritize sleep hygiene.");
        }
        return sb.toString();
      }

      if (cleanPrompt.contains('focus') || cleanPrompt.contains('study') || cleanPrompt.contains('timer') || cleanPrompt.contains('pomodoro')) {
        final List<dynamic> sessions = context['focus'] ?? [];
        final now = DateTime.now();
        final todayStart = DateTime(now.year, now.month, now.day);
        final weekAgo = now.subtract(const Duration(days: 7));
        
        final todayFocus = sessions.where((s) {
          final start = DateTime.tryParse(s['startTime'] ?? '');
          return start != null && start.isAfter(todayStart);
        }).fold<int>(0, (acc, s) => acc + (s['durationMinutes'] as num? ?? 0).toInt());

        final weekFocus = sessions.where((s) {
          final start = DateTime.tryParse(s['startTime'] ?? '');
          return start != null && start.isAfter(weekAgo);
        }).fold<int>(0, (acc, s) => acc + (s['durationMinutes'] as num? ?? 0).toInt());

        final sb = StringBuffer();
        sb.write("$prefixHere are your focus session statistics:\n");
        sb.write("• **Focus Today**: $todayFocus minutes\n");
        sb.write("• **Focus This Week**: ${(weekFocus / 60.0).toStringAsFixed(1)} hours ($weekFocus minutes)\n\n");
        
        if (mode == 'mentor') {
          sb.write("💡 **Mentor Productivity Tip:** Try launching a **Pomodoro session** of 25 minutes from the **Focus Timer** screen. Breaking your tasks into bite-sized blocks increases concentration and keeps burnout at bay.");
        } else {
          sb.write("Keep utilizing the **Focus Timer** to build solid learning periods and increase your productivity score.");
        }
        return sb.toString();
      }

      if (cleanPrompt.contains('placement') || cleanPrompt.contains('job') || cleanPrompt.contains('career') || cleanPrompt.contains('interview') || cleanPrompt.contains('resume')) {
        final List<dynamic> placements = context['placements'] ?? [];
        if (placements.isEmpty) {
          return "$prefixYou don't have any job or placement entries logged in your Student Hub. Go to **Student Hub > Placements** to track job applications, internship wishlists, and scheduled interviews.";
        }
        final sb = StringBuffer();
        sb.write("$prefixHere is your recruitment pipeline overview:\n\n");
        for (final p in placements) {
          final company = p['company'] ?? 'Unknown Company';
          final role = p['role'] ?? 'Unknown Role';
          final status = p['status'] ?? 'Wishlist';
          final salary = p['salary'] ?? '';
          sb.write("• **$company ($role)** — Status: **$status** ${salary.isNotEmpty ? '| Compensation: $salary' : ''}\n");
        }
        if (mode == 'mentor') {
          sb.write("\n🎯 **Mentor Placement Tips:** Prepare for interviews by researching core DSA concepts and system designs. Practice **STAR method** responses for behavioral questions. Good luck!");
        }
        return sb.toString();
      }

      if (cleanPrompt.contains('goal') || cleanPrompt.contains('achieve')) {
        final List<dynamic> goals = context['goals'] ?? [];
        if (goals.isEmpty) {
          return "$prefixYou don't have any custom goals tracked. Head to **Goals Tracker** to create short-term or long-term academic targets.";
        }
        final total = goals.length;
        final completed = goals.where((g) => g['isCompleted'] == true).length;
        final progress = total > 0 ? (completed / total * 100).toStringAsFixed(0) : '0';
        
        final sb = StringBuffer();
        sb.write("$prefixYou have completed **$completed of $total goals** ($progress% completion rate):\n\n");
        for (final g in goals) {
          final title = g['title'] ?? 'Goal';
          final done = g['isCompleted'] == true;
          sb.write("• [${done ? 'x' : ' '}] $title\n");
        }
        if (mode == 'mentor') {
          sb.write("\n💡 **Mentor Goal Strategy:** Keep your goals **SMART** (Specific, Measurable, Actionable, Relevant, Time-bound). Breakdown larger achievements into daily challenges.");
        }
        return sb.toString();
      }
    }

    // Phase 1 fallback or general templates
    if (cleanPrompt.contains('programming') || cleanPrompt.contains('code') || cleanPrompt.contains('coding')) {
      return "$prefix### 💻 Programming Basics\n\n"
          "Writing clean, readable, and maintainable code is key to being a software engineer.\n\n"
          "Here is an example of a simple recursive Fibonacci function in Dart:\n\n"
          "```dart\n"
          "int fibonacci(int n) {\n"
          "  if (n <= 1) return n;\n"
          "  return fibonacci(n - 1) + fibonacci(n - 2);\n"
          "}\n"
          "```\n\n"
          "**Best Practices:**\n"
          "• Use meaningful variable and function names.\n"
          "• Keep your functions small and focused on a single responsibility.\n"
          "• Always handle edge cases and potential errors.";
    }

    if (cleanPrompt.contains('dsa') || cleanPrompt.contains('binary search') || cleanPrompt.contains('tree') || cleanPrompt.contains('sort')) {
      return "$prefix### 🌳 Data Structures & Algorithms (DSA)\n\n"
          "Data structures organize data, while algorithms process it efficiently. For interviews, mastering DSA is critical.\n\n"
          "Here is a standard **Binary Search** implementation in Dart:\n\n"
          "```dart\n"
          "int binarySearch(List<int> list, int target) {\n"
          "  int min = 0;\n"
          "  int max = list.length - 1;\n"
          "  while (min <= max) {\n"
          "    int mid = min + ((max - min) >> 1);\n"
          "    if (list[mid] == target) return mid;\n"
          "    if (list[mid] < target) min = mid + 1;\n"
          "    else max = mid - 1;\n"
          "  }\n"
          "  return -1; // Not found\n"
          "}\n"
          "```\n\n"
          "**Time Complexity:** O(\\log N)\n"
          "**Space Complexity:** O(1)";
    }

    if (cleanPrompt.contains('dbms') || cleanPrompt.contains('database') || cleanPrompt.contains('sql')) {
      return "$prefix### 🗄️ Database Management Systems (DBMS)\n\n"
          "A DBMS manages data storage and querying. Relational databases use **SQL** for queries.\n\n"
          "Here is a SQL query to join `users` and `activities` tables and calculate average focus time per user:\n\n"
          "```sql\n"
          "SELECT \n"
          "  u.display_name,\n"
          "  AVG(a.duration) AS avg_duration\n"
          "FROM users u\n"
          "JOIN activities a ON u.uid = a.user_id\n"
          "GROUP BY u.uid, u.display_name\n"
          "HAVING avg_duration > 30;\n"
          "```\n\n"
          "**Key Concepts to Review:**\n"
          "• Database Normalization (1NF, 2NF, 3NF, BCNF)\n"
          "• Indexes (B-Trees and Hash Indexes) to speed up queries\n"
          "• ACID Transactions (Atomicity, Consistency, Isolation, Durability)";
    }

    if (cleanPrompt.contains('os') || cleanPrompt.contains('operating system') || cleanPrompt.contains('process') || cleanPrompt.contains('thread')) {
      return "$prefix### 🖥️ Operating Systems (OS)\n\n"
          "An Operating System manages hardware resource sharing. Core concepts include process management, memory allocation, and concurrency.\n\n"
          "**Process vs Thread:**\n"
          "• **Process:** An independent program in execution. Has its own address space, memory, and resources.\n"
          "• **Thread:** A subset of a process. Threads share the process's address space and variables, making communication faster but requiring synchronization.\n\n"
          "Here is a simple multi-threading snippet using isolates / async in Dart:\n\n"
          "```dart\n"
          "import 'dart:isolate';\n"
          "\n"
          "void computeHeavyTask(SendPort sendPort) {\n"
          "  int sum = 0;\n"
          "  for (int i = 0; i < 100000000; i++) sum += i;\n"
          "  sendPort.send(sum);\n"
          "}\n"
          "```";
    }

    if (cleanPrompt.contains('cn') || cleanPrompt.contains('computer network') || cleanPrompt.contains('tcp') || cleanPrompt.contains('ip')) {
      return "$prefix### 🌐 Computer Networks (CN)\n\n"
          "Computer networks allow devices to communicate. The internet runs on the TCP/IP stack.\n\n"
          "**TCP vs UDP:**\n"
          "• **TCP (Transmission Control Protocol):** Connection-oriented, reliable, guarantees order, performs flow control and congestion control. Used for HTTP, FTP, SMTP.\n"
          "• **UDP (User Datagram Protocol):** Connectionless, unreliable, faster, does not guarantee order. Used for video streaming, gaming, DNS.\n\n"
          "**HTTP Status Codes to Know:**\n"
          "• `200 OK` — Request succeeded.\n"
          "• `401 Unauthorized` — Authentication needed.\n"
          "• `404 Not Found` — Resource not found.\n"
          "• `500 Internal Server Error` — Server-side crash.";
    }

    if (cleanPrompt.contains('devops') || cleanPrompt.contains('docker') || cleanPrompt.contains('kubernetes') || cleanPrompt.contains('ci/cd')) {
      return "$prefix### ♾️ DevOps & CI/CD Pipelines\n\n"
          "DevOps bridges development and operations to shorten deployment cycles and automate workflows.\n\n"
          "Here is a basic `Dockerfile` template to containerize a Flutter web application:\n\n"
          "```dockerfile\n"
          "# Stage 1: Build\n"
          "FROM plugfox/flutter:stable AS build-env\n"
          "RUN flutter config --enable-web\n"
          "COPY . /app\n"
          "WORKDIR /app\n"
          "RUN flutter build web --release\n"
          "\n"
          "# Stage 2: Serve\n"
          "FROM nginx:alpine\n"
          "COPY --from=build-env /app/build/web /usr/share/nginx/html\n"
          "EXPOSE 80\n"
          "```";
    }

    if (cleanPrompt.contains('career') || cleanPrompt.contains('resume') || cleanPrompt.contains('placement') || cleanPrompt.contains('interview')) {
      return "$prefix### 💼 Career Suggestions & Placement Coach\n\n"
          "Preparing for your career requires a strong portfolio, well-structured resume, and thorough interview preparation.\n\n"
          "**Key Focus Areas:**\n"
          "• **Resume Building:** Keep it to 1 page. Use action verbs and describe outcomes quantitatively (e.g. *'Improved query latency by 40% via database indexing'*).\n"
          "• **Interview Prep:** Solidify your fundamentals in OOP, DSA, DBMS, and System Design. Practice mock interviews.\n"
          "• **Projects:** Build full-stack applications with clear use cases. Publish your code on GitHub and provide detailed READMEs.";
    }

    // Phase 1 fallback or general templates
    if (cleanPrompt.contains('pomodoro') || cleanPrompt.contains('how to study')) {
      return "$prefixThe **Pomodoro Technique** is a time management method developed by Francesco Cirillo in the late 1980s. It uses a timer to break work down into intervals, traditionally 25 minutes in length, separated by short breaks. These intervals are named *pomodoros*.\n\nSteps:\n1. Choose a task.\n2. Start a 25-minute timer (use our Focus Timer).\n3. Work on the task until the timer rings.\n4. Take a short 5-minute break.\n5. Every 4 pomodoros, take a longer 15-30 minute break.";
    }

    if (cleanPrompt.contains('active recall') || cleanPrompt.contains('feynman')) {
      return "$prefix**Active Recall** involves testing yourself on the material you are trying to learn, forcing your brain to retrieve the information. It is much more effective than passive reading.\n\n**The Feynman Technique** is a mental model for learning:\n1. Choose a concept you want to learn.\n2. Explain it to a child (or write it in simple terms).\n3. Identify gaps in your explanation and go back to the source material.\n4. Simplify your explanation and use analogies.";
    }

    if (cleanPrompt.contains('hello') || cleanPrompt.contains('hi ') || cleanPrompt.contains('hey')) {
      if (mode == 'mentor') {
        return "$prefixHello! I am your academic mentor. What study challenges are you facing today? I can help you structure your revision plans, analyze your attendance logs, or prepare for upcoming exam count downs.";
      }
      return "$prefixHello! I'm your Student AI Assistant. How can I help you today? You can select **Connected Data Mode** or **Student Mentor Mode** at the top to access custom insights and coaching.";
    }

    // Default general response
    return "$prefixI am here to assist you with your academic inquiries. Try asking me about:\n"
        "• *'What is active recall and how do I apply it?'*\n"
        "• *'Explain the Pomodoro Technique.'*\n"
        "• *'Summarize my upcoming exams.'* (Connected Mode)\n"
        "• *'Check my course attendance and alerts.'* (Connected Mode)\n"
        "• *'Show my placement pipeline.'* (Connected Mode)\n\n"
        "Please let me know how I can guide your learning journey!";
  }
}
