import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../models/task_model.dart';
import '../providers/task_provider.dart';
import 'package:google_fonts/google_fonts.dart';

class TaskListScreen extends ConsumerWidget {
  const TaskListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final taskState = ref.watch(taskNotifierProvider);
    final allTasks = taskState.tasks;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text('Your Tasks', style: GoogleFonts.outfit(fontSize: 28, fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.auto_awesome_rounded, color: Color(0xFF8B5CF6)),
            onPressed: () => _showAIDialog(context, ref),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: taskState.statusFilter,
                dropdownColor: const Color(0xFF1E293B),
                icon: const Icon(Icons.filter_list_rounded, color: Colors.white70),
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                onChanged: (value) {
                  if (value != null) {
                    ref.read(taskNotifierProvider.notifier).onStatusFilterChanged(value);
                  }
                },
                items: ['All', 'To-Do', 'In Progress', 'Done']
                    .map((status) => DropdownMenuItem(value: status, child: Text(status)))
                    .toList(),
              ),
            ),
          )
        ],
      ),
      body: Stack(
        children: [
          // Background Gradient Animation
          Positioned(
            top: -100,
            left: -100,
            child: ImageFiltered(
              imageFilter: ImageFilter.blur(sigmaX: 100, sigmaY: 100),
              child: Container(
                width: 300,
                height: 300,
                decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFF8B5CF6)),
              ).animate(onPlay: (controller) => controller.repeat(reverse: true))
               .scaleXY(end: 1.5, duration: 4.seconds),
            )
          ),
          Positioned(
            bottom: -100,
            right: -100,
            child: ImageFiltered(
              imageFilter: ImageFilter.blur(sigmaX: 100, sigmaY: 100),
              child: Container(
                width: 300,
                height: 300,
                decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFF3B82F6)),
              ).animate(onPlay: (controller) => controller.repeat(reverse: true))
               .scaleXY(end: 1.5, duration: 5.seconds),
            )
          ),
          // Content
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(30),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withAlpha(25),
                          border: Border.all(color: Colors.white.withAlpha(25)),
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: TextField(
                          style: const TextStyle(color: Colors.white),
                          decoration: const InputDecoration(
                            hintText: 'Search tasks...',
                            hintStyle: TextStyle(color: Colors.white54),
                            prefixIcon: Icon(Icons.search, color: Colors.white54),
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(vertical: 15),
                          ),
                          onChanged: (value) {
                            ref.read(taskNotifierProvider.notifier).onSearchChanged(value);
                          },
                        ),
                      ),
                    ),
                  ).animate().fade().slideY(begin: -0.2),
                ),
                Expanded(
                  child: taskState.isLoading && taskState.tasks.isEmpty
                      ? const Center(child: CircularProgressIndicator())
                      : taskState.error != null
                          ? Center(child: Text('Error: ${taskState.error}', style: const TextStyle(color: Colors.red)))
                          : taskState.tasks.isEmpty
                              ? _buildEmptyState().animate().fade().scale()
                              : RefreshIndicator(
                                  onRefresh: () async {
                                    await ref.read(taskNotifierProvider.notifier).fetchTasks();
                                  },
                                  child: ListView.builder(
                                    physics: const AlwaysScrollableScrollPhysics(),
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                    itemCount: taskState.tasks.length,
                                    itemBuilder: (context, index) {
                                      final task = taskState.tasks[index];
                                      final isBlocked = task.blockedById != null &&
                                          allTasks.any((t) => t.id == task.blockedById && t.status != 'Done');
                                      final blockerTask = isBlocked
                                          ? allTasks.firstWhere((t) => t.id == task.blockedById)
                                          : null;

                                      return _TaskCard(
                                        task: task,
                                        isBlocked: isBlocked,
                                        blockerTask: blockerTask,
                                        searchQuery: taskState.searchQuery,
                                        onTap: () {
                                          context.push('/task/${task.id}', extra: task);
                                        },
                                        onDelete: () async {
                                          await ref.read(taskNotifierProvider.notifier).deleteTask(task.id!);
                                        },
                                      )
                                      .animate()
                                      .fade(delay: (index * 50).ms, duration: 300.ms)
                                      .slideX(begin: 0.1, delay: (index * 50).ms, duration: 300.ms);
                                    },
                                  ),
                                ),
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFF8B5CF6),
        foregroundColor: Colors.white,
        elevation: 8,
        onPressed: () => context.push('/create'),
        icon: const Icon(Icons.add_rounded),
        label: Text('New Task', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
      ).animate().scale(delay: 500.ms).shake(),
    );
  }

  void _showAIDialog(BuildContext context, WidgetRef ref) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: Row(
          children: [
            const Icon(Icons.auto_awesome_rounded, color: Color(0xFF8B5CF6)),
            const SizedBox(width: 8),
            Text('AI Task Planner', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20)),
          ],
        ),
        content: TextField(
          controller: controller,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: 'e.g. Plan my trip to Hawaii',
            hintStyle: const TextStyle(color: Colors.white54),
            filled: true,
            fillColor: Colors.white.withAlpha(15),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: Colors.white70)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF8B5CF6),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () {
              if (controller.text.isNotEmpty) {
                ref.read(taskNotifierProvider.notifier).generateAITasks(controller.text);
                Navigator.pop(ctx);
              }
            },
            child: const Text('Generate', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.task_alt_rounded, size: 80, color: Colors.white.withAlpha(100)),
        const SizedBox(height: 16),
        Text(
          "You're all caught up!",
          style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        const SizedBox(height: 8),
        const Text(
          "Tap below to add a new task",
          style: TextStyle(color: Colors.white70),
        ),
      ],
    );
  }
}

class _TaskCard extends StatelessWidget {
  final Task task;
  final bool isBlocked;
  final Task? blockerTask;
  final String searchQuery;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _TaskCard({
    required this.task,
    required this.isBlocked,
    required this.blockerTask,
    required this.searchQuery,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isBlocked ? Colors.grey.shade900.withAlpha(150) : const Color(0xFF1E293B).withAlpha(200),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isBlocked ? Colors.transparent : Colors.white.withAlpha(25),
        ),
        boxShadow: isBlocked ? [] : [
          BoxShadow(
            color: Colors.black.withAlpha(50),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
          child: InkWell(
            onTap: isBlocked ? null : onTap,
            borderRadius: BorderRadius.circular(20),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: _HighlightedText(
                          text: task.title,
                          highlight: searchQuery,
                          style: GoogleFonts.outfit(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: isBlocked ? Colors.white38 : Colors.white,
                            decoration: task.status == 'Done' ? TextDecoration.lineThrough : null,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      _StatusBadge(status: task.status, isBlocked: isBlocked),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    task.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: isBlocked ? Colors.white30 : Colors.white70,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.calendar_month_rounded, size: 16, color: isBlocked ? Colors.white30 : const Color(0xFF3B82F6)),
                          const SizedBox(width: 6),
                          Text(
                            DateFormat('MMM dd, yyyy').format(task.dueDate),
                            style: TextStyle(
                              fontSize: 13,
                              color: isBlocked ? Colors.white30 : const Color(0xFF3B82F6),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          if (task.recurrenceInterval != null) ...[
                            const SizedBox(width: 12),
                            Icon(Icons.repeat_rounded, size: 16, color: isBlocked ? Colors.white30 : const Color(0xFF8B5CF6)),
                            const SizedBox(width: 4),
                            Text(
                              task.recurrenceInterval!,
                              style: TextStyle(
                                fontSize: 13,
                                color: isBlocked ? Colors.white30 : const Color(0xFF8B5CF6),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ]
                        ],
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_sweep_rounded, color: Colors.redAccent, size: 22),
                        onPressed: onDelete,
                        constraints: const BoxConstraints(),
                        padding: EdgeInsets.zero,
                      )
                    ],
                  ),
                  if (isBlocked && blockerTask != null) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.redAccent.withAlpha(50),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.lock_rounded, size: 14, color: Colors.redAccent),
                          const SizedBox(width: 6),
                          Text(
                            'Blocked by: ${blockerTask!.title}',
                            style: const TextStyle(fontSize: 12, color: Colors.white, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ).animate().shimmer(duration: 2.seconds, delay: 1.seconds),
                  ]
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;
  final bool isBlocked;

  const _StatusBadge({required this.status, required this.isBlocked});

  @override
  Widget build(BuildContext context) {
    Color bgColor;
    Color textColor;
    
    if (isBlocked) {
      bgColor = Colors.white10;
      textColor = Colors.white38;
    } else {
      switch (status) {
        case 'Done':
          bgColor = const Color(0xFF10B981).withAlpha(50);
          textColor = const Color(0xFF34D399);
          break;
        case 'In Progress':
          bgColor = const Color(0xFF3B82F6).withAlpha(50);
          textColor = const Color(0xFF60A5FA);
          break;
        default:
          bgColor = const Color(0xFFF59E0B).withAlpha(50);
          textColor = const Color(0xFFFBBF24);
      }
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isBlocked ? Colors.transparent : textColor.withAlpha(100)),
      ),
      child: Text(
        status,
        style: TextStyle(color: textColor, fontSize: 12, fontWeight: FontWeight.bold),
      ),
    );
  }
}

class _HighlightedText extends StatelessWidget {
  final String text;
  final String highlight;
  final TextStyle? style;

  const _HighlightedText({
    required this.text,
    required this.highlight,
    this.style,
  });

  @override
  Widget build(BuildContext context) {
    if (highlight.isEmpty) return Text(text, style: style);
    
    final lowercaseText = text.toLowerCase();
    final lowercaseHighlight = highlight.toLowerCase();
    
    if (!lowercaseText.contains(lowercaseHighlight)) return Text(text, style: style);

    final startIndex = lowercaseText.indexOf(lowercaseHighlight);
    final endIndex = startIndex + highlight.length;

    return RichText(
      text: TextSpan(
        style: style ?? DefaultTextStyle.of(context).style,
        children: [
          TextSpan(text: text.substring(0, startIndex)),
          TextSpan(
            text: text.substring(startIndex, endIndex),
            style: const TextStyle(backgroundColor: Color(0xFFFDE047), color: Colors.black),
          ),
          TextSpan(text: text.substring(endIndex)),
        ],
      ),
    );
  }
}
