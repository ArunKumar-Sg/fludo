import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../models/task_model.dart';
import '../providers/task_provider.dart';
import '../providers/draft_provider.dart';

class TaskFormScreen extends ConsumerStatefulWidget {
  final Task? existingTask;

  const TaskFormScreen({super.key, this.existingTask});

  @override
  ConsumerState<TaskFormScreen> createState() => _TaskFormScreenState();
}

class _TaskFormScreenState extends ConsumerState<TaskFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _descController;
  DateTime? _selectedDate;
  String _selectedStatus = 'To-Do';
  int? _blockedById;
  String? _recurrenceInterval;
  bool _isSaving = false;
  bool _isPolishing = false;

  @override
  void initState() {
    super.initState();
    final draft = ref.read(draftProvider);
    if (widget.existingTask != null) {
      _titleController = TextEditingController(text: widget.existingTask!.title);
      _descController = TextEditingController(text: widget.existingTask!.description);
      _selectedDate = widget.existingTask!.dueDate;
      _selectedStatus = widget.existingTask!.status;
      _blockedById = widget.existingTask!.blockedById;
      _recurrenceInterval = widget.existingTask!.recurrenceInterval;
    } else if (draft.title.isNotEmpty || draft.description.isNotEmpty) {
      _titleController = TextEditingController(text: draft.title);
      _descController = TextEditingController(text: draft.description);
      _selectedDate = draft.dueDate ?? DateTime.now().add(const Duration(days: 1));
      _selectedStatus = draft.status;
      _blockedById = draft.blockedById;
      _recurrenceInterval = draft.recurrenceInterval;
    } else {
      _titleController = TextEditingController();
      _descController = TextEditingController();
      _selectedDate = DateTime.now().add(const Duration(days: 1));
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  void _saveDraft() {
    if (widget.existingTask == null && !_isSaving) {
      ref.read(draftProvider.notifier).updateDraft(
            TaskDraft(
              title: _titleController.text,
              description: _descController.text,
              dueDate: _selectedDate,
              status: _selectedStatus,
              blockedById: _blockedById,
              recurrenceInterval: _recurrenceInterval,
            ),
          );
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.dark(
            primary: Color(0xFF8B5CF6),
            onPrimary: Colors.white,
            surface: Color(0xFF1E293B),
            onSurface: Colors.white,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() => _selectedDate = picked);
      _saveDraft();
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate() || _selectedDate == null) return;
    
    if (widget.existingTask != null && _blockedById == widget.existingTask!.id) {
       ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('A task cannot block itself')),
      );
      return;
    }

    setState(() => _isSaving = true);

    final task = Task(
      id: widget.existingTask?.id,
      title: _titleController.text,
      description: _descController.text,
      dueDate: _selectedDate!,
      status: _selectedStatus,
      blockedById: _blockedById == -1 ? null : _blockedById,
      recurrenceInterval: _recurrenceInterval == 'None' ? null : _recurrenceInterval,
    );

    try {
      if (widget.existingTask == null) {
        await ref.read(taskNotifierProvider.notifier).createTask(task);
        ref.read(draftProvider.notifier).clearDraft();
      } else {
        await ref.read(taskNotifierProvider.notifier).updateTask(task);
      }
      if (mounted) context.pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: Colors.redAccent),
        );
        setState(() => _isSaving = false);
      }
    }
  }

  Future<void> _polishText() async {
    if (_titleController.text.isEmpty && _descController.text.isEmpty) return;
    setState(() => _isPolishing = true);
    try {
      final result = await ref.read(apiServiceProvider).polishTaskText(_titleController.text, _descController.text);
      setState(() {
        _titleController.text = result['title']!;
        _descController.text = result['description']!;
      });
      _saveDraft();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString(), style: const TextStyle(color: Colors.white)), backgroundColor: Colors.redAccent));
    } finally {
      if (mounted) setState(() => _isPolishing = false);
    }
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.white70),
      prefixIcon: Icon(icon, color: Colors.white54),
      filled: true,
      fillColor: Colors.white.withAlpha(15),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0xFF8B5CF6), width: 2),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: Colors.white.withAlpha(25)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final allTasks = ref.watch(taskNotifierProvider).tasks;
    final availableBlockers = allTasks
        .where((t) => t.id != widget.existingTask?.id && t.status != 'Done')
        .toList();

    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, result) {
        _saveDraft();
      },
      child: Scaffold(
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          title: Text(widget.existingTask == null ? 'New Task' : 'Edit Task', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        ),
        body: Stack(
          children: [
            Positioned(
              top: -50,
              right: -50,
              child: ImageFiltered(
                imageFilter: ImageFilter.blur(sigmaX: 100, sigmaY: 100),
                child: Container(
                  width: 250,
                  height: 250,
                  decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFF8B5CF6)),
                ),
              ).animate().fadeIn(duration: 1.seconds),
            ),
            SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: Form(
                  key: _formKey,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                      child: Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.white.withAlpha(15),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: Colors.white.withAlpha(25)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                      TextFormField(
                        controller: _titleController,
                        style: const TextStyle(color: Colors.white, fontSize: 18),
                        decoration: _inputDecoration('Task Title', Icons.title_rounded),
                        validator: (value) => value == null || value.isEmpty ? 'Please enter a title' : null,
                        onChanged: (_) => _saveDraft(),
                      ).animate().fade().slideY(begin: 0.1),
                      const SizedBox(height: 20),
                      TextFormField(
                        controller: _descController,
                        style: const TextStyle(color: Colors.white),
                        decoration: _inputDecoration('Description', Icons.notes_rounded),
                        maxLines: 4,
                        validator: (value) => value == null || value.isEmpty ? 'Please enter a description' : null,
                        onChanged: (_) => _saveDraft(),
                      ).animate().fade().slideY(begin: 0.1, delay: 50.ms),
                      const SizedBox(height: 12),
                      Align(
                        alignment: Alignment.centerRight,
                        child: OutlinedButton.icon(
                          onPressed: _isPolishing ? null : _polishText,
                          icon: _isPolishing 
                             ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF8B5CF6)))
                             : const Icon(Icons.auto_awesome, color: Color(0xFF8B5CF6)),
                          label: Text(_isPolishing ? 'Polishing...' : '✨ Magic Polish', style: const TextStyle(color: Color(0xFF8B5CF6))),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Color(0xFF8B5CF6)),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ).animate().fade().slideY(begin: 0.1, delay: 75.ms),
                      const SizedBox(height: 20),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withAlpha(15),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.white.withAlpha(25)),
                        ),
                        child: ListTile(
                          title: Text(
                            "Due Date: ${_selectedDate != null ? DateFormat('MMM dd, yyyy').format(_selectedDate!) : 'Select Date'}",
                            style: const TextStyle(color: Colors.white),
                          ),
                          leading: const Icon(Icons.calendar_month_rounded, color: Colors.white54),
                          onTap: () => _selectDate(context),
                        ),
                      ).animate().fade().slideY(begin: 0.1, delay: 100.ms),
                      const SizedBox(height: 20),
                      DropdownButtonFormField<String>(
                        dropdownColor: const Color(0xFF1E293B),
                        style: const TextStyle(color: Colors.white),
                        decoration: _inputDecoration('Status', Icons.flag_rounded),
                        initialValue: _selectedStatus,
                        items: ['To-Do', 'In Progress', 'Done']
                            .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                            .toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setState(() => _selectedStatus = value);
                            _saveDraft();
                          }
                        },
                      ).animate().fade().slideY(begin: 0.1, delay: 150.ms),
                      const SizedBox(height: 20),
                      DropdownButtonFormField<String?>(
                        dropdownColor: const Color(0xFF1E293B),
                        style: const TextStyle(color: Colors.white),
                        decoration: _inputDecoration('Recurrence (Optional)', Icons.repeat_rounded),
                        initialValue: _recurrenceInterval,
                        items: const [
                          DropdownMenuItem<String?>(value: null, child: Text('No Repeat')),
                          DropdownMenuItem<String?>(value: 'Daily', child: Text('Daily')),
                          DropdownMenuItem<String?>(value: 'Weekly', child: Text('Weekly')),
                        ],
                        onChanged: (value) {
                          setState(() => _recurrenceInterval = value);
                          _saveDraft();
                        },
                      ).animate().fade().slideY(begin: 0.1, delay: 200.ms),
                      const SizedBox(height: 20),
                      DropdownButtonFormField<int?>(
                        dropdownColor: const Color(0xFF1E293B),
                        style: const TextStyle(color: Colors.white),
                        decoration: _inputDecoration('Blocked By (Optional)', Icons.lock_rounded),
                        initialValue: _blockedById,
                        items: [
                          const DropdownMenuItem<int?>(value: null, child: Text('None')),
                          ...availableBlockers.map((t) => DropdownMenuItem<int?>(value: t.id, child: Text(t.title))),
                        ],
                        onChanged: (value) {
                          setState(() => _blockedById = value);
                          _saveDraft();
                        },
                      ).animate().fade().slideY(begin: 0.1, delay: 250.ms),
                      const SizedBox(height: 40),
                      SizedBox(
                        height: 56,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF8B5CF6),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            elevation: 8,
                          ),
                          onPressed: _isSaving ? null : _submit,
                          child: _isSaving
                              ? const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)),
                                    SizedBox(width: 12),
                                    Text('Saving...', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                                  ],
                                )
                              : const Text('Save Task', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        ),
                      ).animate().scale(delay: 300.ms),
                    ],
                  ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
  }
}
