import 'package:dio/dio.dart';
import '../models/task_model.dart';

class ApiService {
  late final Dio _dio;

  ApiService() {
    _dio = Dio(BaseOptions(
      baseUrl: 'http://127.0.0.1:8000',
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 30),
    ));
  }

  Future<List<Task>> getTasks({String? status, String? search}) async {
    try {
      final queryParameters = <String, dynamic>{};
      if (status != null && status.isNotEmpty && status != 'All') {
        queryParameters['status'] = status;
      }
      if (search != null && search.isNotEmpty) {
        queryParameters['search'] = search;
      }

      final response = await _dio.get('/tasks', queryParameters: queryParameters);
      return (response.data as List).map((json) => Task.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to load tasks: $e');
    }
  }

  Future<Task> createTask(Task task) async {
    try {
      final response = await _dio.post('/tasks', data: task.toJson());
      return Task.fromJson(response.data);
    } on DioException catch (e) {
      throw Exception("Failed to create task: ${e.response?.data['detail'] ?? e.message}");
    }
  }

  Future<Task> updateTask(Task task) async {
    try {
      final response = await _dio.put('/tasks/${task.id}', data: task.toJson());
      return Task.fromJson(response.data);
    } on DioException catch (e) {
      throw Exception("Failed to update task: ${e.response?.data['detail'] ?? e.message}");
    }
  }

  Future<void> deleteTask(int id) async {
    try {
      await _dio.delete('/tasks/$id');
    } catch (e) {
      throw Exception('Failed to delete task: $e');
    }
  }

  Future<void> generateAITasks(String prompt) async {
    try {
      await _dio.post('/tasks/ai/generate', data: {'prompt': prompt});
    } on DioException catch (e) {
      throw Exception("Failed to generate AI tasks: ${e.response?.data['detail'] ?? e.message}");
    }
  }

  Future<Map<String, String>> polishTaskText(String title, String description) async {
    try {
      final response = await _dio.post('/tasks/ai/polish', data: {'title': title, 'description': description});
      return {
        'title': response.data['title']?.toString() ?? title,
        'description': response.data['description']?.toString() ?? description,
      };
    } on DioException catch (e) {
      throw Exception("Failed to polish text: ${e.response?.data['detail'] ?? e.message}");
    }
  }
}
