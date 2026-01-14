import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/todo_model.dart';

class TodoProvider extends ChangeNotifier {
  List<Todo> _todos = [];
  late SharedPreferences _prefs;
  bool _isInitialized = false;

  List<Todo> get todos => _todos;
  bool get isInitialized => _isInitialized;

  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
    await _loadTodos();
    _isInitialized = true;
    notifyListeners();
  }

  Future<void> _loadTodos() async {
    final jsonString = _prefs.getString('todos');
    if (jsonString != null) {
      try {
        final List<dynamic> jsonList = jsonDecode(jsonString);
        _todos = jsonList.map((item) => Todo.fromJson(item as Map<String, dynamic>)).toList();
      } catch (e) {
        debugPrint('Erreur lors du chargement des TODO: $e');
        _todos = [];
      }
    }
    notifyListeners();
  }

  Future<void> _saveTodos() async {
    try {
      final jsonString = jsonEncode(_todos.map((todo) => todo.toJson()).toList());
      await _prefs.setString('todos', jsonString);
      notifyListeners();
    } catch (e) {
      debugPrint('Erreur lors de la sauvegarde des TODO: $e');
    }
  }

  Future<void> addTodo(String title, String description, TodoPriority priority) async {
    final newTodo = Todo(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      description: description,
      createdAt: DateTime.now(),
      priority: priority,
    );
    _todos.add(newTodo);
    await _saveTodos();
  }

  Future<void> updateTodo(String id, String title, String description, TodoPriority priority) async {
    final index = _todos.indexWhere((todo) => todo.id == id);
    if (index != -1) {
      _todos[index] = _todos[index].copyWith(
        title: title,
        description: description,
        priority: priority,
      );
      await _saveTodos();
    }
  }

  Future<void> toggleTodoCompletion(String id) async {
    final index = _todos.indexWhere((todo) => todo.id == id);
    if (index != -1) {
      final todo = _todos[index];
      _todos[index] = todo.copyWith(
        isCompleted: !todo.isCompleted,
        completedAt: !todo.isCompleted ? DateTime.now() : null,
      );
      await _saveTodos();
    }
  }

  Future<void> deleteTodo(String id) async {
    _todos.removeWhere((todo) => todo.id == id);
    await _saveTodos();
  }

  List<Todo> get sortedTodos {
    final sorted = [..._todos];
    sorted.sort((a, b) {
      if (a.isCompleted != b.isCompleted) {
        return a.isCompleted ? 1 : -1;
      }
      return b.priority.index.compareTo(a.priority.index);
    });
    return sorted;
  }

  List<Todo> get completedTodos => _todos.where((todo) => todo.isCompleted).toList();
  List<Todo> get pendingTodos => _todos.where((todo) => !todo.isCompleted).toList();

  Map<String, int> getStatistics() {
    return {
      'total': _todos.length,
      'completed': completedTodos.length,
      'pending': pendingTodos.length,
    };
  }
}