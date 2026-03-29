import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:async';
import '../models/task_model.dart';
import '../services/api_service.dart';

final apiServiceProvider = Provider<ApiService>((ref) {
  return ApiService();
});

class TaskState {
  final bool isLoading;
  final List<Task> tasks;
  final String? error;
  final String searchQuery;
  final String statusFilter;

  TaskState({
    this.isLoading = false,
    this.tasks = const [],
    this.error,
    this.searchQuery = '',
    this.statusFilter = 'All',
  });

  TaskState copyWith({
    bool? isLoading,
    List<Task>? tasks,
    String? error,
    String? searchQuery,
    String? statusFilter,
  }) {
    return TaskState(
      isLoading: isLoading ?? this.isLoading,
      tasks: tasks ?? this.tasks,
      error: error,
      searchQuery: searchQuery ?? this.searchQuery,
      statusFilter: statusFilter ?? this.statusFilter,
    );
  }
}

class TaskNotifier extends Notifier<TaskState> {
  Timer? _debounce;

  @override
  TaskState build() {
    Future.microtask(() => fetchTasks());
    return TaskState();
  }

  Future<void> fetchTasks({String? status, String? search}) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final tasks = await ref.read(apiServiceProvider).getTasks(
        status: status ?? state.statusFilter, 
        search: search ?? state.searchQuery
      );
      state = state.copyWith(isLoading: false, tasks: tasks);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  void onSearchChanged(String query) {
    state = state.copyWith(searchQuery: query);
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      fetchTasks();
    });
  }

  void onStatusFilterChanged(String status) {
    state = state.copyWith(statusFilter: status);
    fetchTasks();
  }

  Future<void> createTask(Task task) async {
    try {
      await ref.read(apiServiceProvider).createTask(task);
      await fetchTasks();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> updateTask(Task task) async {
    try {
      await ref.read(apiServiceProvider).updateTask(task);
      await fetchTasks();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> generateAITasks(String prompt) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await ref.read(apiServiceProvider).generateAITasks(prompt);
      await fetchTasks();
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> deleteTask(int id) async {
    try {
      await ref.read(apiServiceProvider).deleteTask(id);
      await fetchTasks();
    } catch (e) {
      state = state.copyWith(error: e.toString());
      rethrow;
    }
  }
}

final taskNotifierProvider = NotifierProvider<TaskNotifier, TaskState>(TaskNotifier.new);
