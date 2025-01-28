import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/todo_model.dart';

class TodoProvider with ChangeNotifier {
  final List<Todo> _todos = [];
  static const String _prefsKey = 'todos';

  final List<String> _categories = [
    'Personal',
    'Work',
    'Shopping',
    'Health',
    'Finance',
    'Education'
  ];
  String _currentFilter = 'All';

  List<Todo> get todos => _applyFilter(_todos);
  List<String> get categories => _categories;
  String get currentFilter => _currentFilter;

  Future<void> loadTodos() async {
    await _loadFromPrefs();
  }

  Future<void> _loadFromPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final todosData = prefs.getStringList(_prefsKey) ?? [];

      _todos.clear();
      _todos.addAll(todosData.map((todoStr) {
        final parts = todoStr.split('|||');
        return Todo(
          id: parts[0],
          title: parts[1],
          isCompleted: parts[2] == 'true',
          deadline: parts[3].isNotEmpty ? DateTime.parse(parts[3]) : null,
          priority: Priority.values[int.parse(parts[4])],
          category: parts[5],
          notes: parts[6].isNotEmpty ? parts[6] : null,
        );
      }));

      notifyListeners();
    } catch (e) {
      if (kDebugMode) print('Error loading todos: $e');
    }
  }

  Future<void> _saveToPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(
          _prefsKey,
          _todos
              .map((todo) =>
                  '${todo.id}|||${todo.title}|||${todo.isCompleted}|||'
                  '${todo.deadline?.toIso8601String() ?? ""}|||'
                  '${todo.priority.index}|||${todo.category}|||${todo.notes ?? ""}')
              .toList());
    } catch (e) {
      if (kDebugMode) print('Error saving todos: $e');
    }
  }

  List<Todo> _applyFilter(List<Todo> todos) {
    if (_currentFilter == 'All') return todos;
    return todos.where((todo) => todo.category == _currentFilter).toList();
  }

  void addTodo(Todo todo) {
    _todos.insert(0, todo);
    _saveToPrefs();
    notifyListeners();
  }

  void updateTodo(Todo updatedTodo) {
    final index = _todos.indexWhere((t) => t.id == updatedTodo.id);
    if (index != -1) {
      _todos[index] = updatedTodo;
      _saveToPrefs();
      notifyListeners();
    }
  }

  void deleteTodo(String id) {
    final index = _todos.indexWhere((todo) => todo.id == id);
    if (index != -1) {
      _todos.removeAt(index);
      _saveToPrefs();
      notifyListeners();
    }
  }

  void toggleTodoStatus(String id) {
    final index = _todos.indexWhere((t) => t.id == id);
    if (index != -1) {
      _todos[index] =
          _todos[index].copyWith(isCompleted: !_todos[index].isCompleted);
      _saveToPrefs();
      notifyListeners();
    }
  }

  void updateDeadline(String id, DateTime deadline) {
    final index = _todos.indexWhere((t) => t.id == id);
    if (index != -1) {
      _todos[index] = _todos[index].copyWith(deadline: deadline);
      _saveToPrefs();
      notifyListeners();
    }
  }

  void updatePriority(String id, Priority priority) {
    final index = _todos.indexWhere((t) => t.id == id);
    if (index != -1) {
      _todos[index] = _todos[index].copyWith(priority: priority);
      _saveToPrefs();
      notifyListeners();
    }
  }

  void updateCategory(String id, String category) {
    final index = _todos.indexWhere((t) => t.id == id);
    if (index != -1) {
      _todos[index] = _todos[index].copyWith(category: category);
      _saveToPrefs();
      notifyListeners();
    }
  }

  void setFilter(String filter) {
    _currentFilter = filter;
    notifyListeners();
  }

  Todo? getTodoById(String id) {
    try {
      return _todos.firstWhere((todo) => todo.id == id);
    } catch (e) {
      return null;
    }
  }

  // Add these at the end of TodoProvider class, before the last }
  String _priorityFilter = 'All';
  String get currentPriorityFilter => _priorityFilter;

  List<Todo> _sortByPriority(List<Todo> todos) {
    return List.from(todos)
      ..sort((a, b) {
        return b.priority.index.compareTo(a.priority.index);
      });
  }

  List<Todo> get sortedTodos {
    var filteredList = _todos;

    if (_currentFilter != 'All') {
      filteredList = filteredList
          .where((todo) => todo.category == _currentFilter)
          .toList();
    }

    if (_priorityFilter != 'All') {
      Priority selectedPriority = Priority.values
          .firstWhere((p) => p.toString().split('.').last == _priorityFilter);
      filteredList = filteredList
          .where((todo) => todo.priority == selectedPriority)
          .toList();
    }

    return _sortByPriority(filteredList);
  }

  void setPriorityFilter(String priority) {
    _priorityFilter = priority;
    notifyListeners();
  }
}
