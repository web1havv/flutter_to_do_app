import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../providers/todo_provider.dart';
import '../widgets/todo_item.dart';
import '../models/todo_model.dart';
import 'add_task_screen.dart';

class TodoListScreen extends StatefulWidget {
  const TodoListScreen({super.key});

  @override
  State<TodoListScreen> createState() => _TodoListScreenState();
}

class _TodoListScreenState extends State<TodoListScreen> {
  final GlobalKey<AnimatedListState> _listKey = GlobalKey<AnimatedListState>();
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    // Load todos when screen initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<TodoProvider>(context, listen: false).loadTodos();
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Theme.of(context).primaryColor.withOpacity(0.1),
              Colors.black.withOpacity(0.9),
            ],
          ),
        ),
        child: _buildTodoList(),
      ),
      floatingActionButton: _buildFloatingActionButton(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      toolbarHeight: 100,
      flexibleSpace: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.deepPurple.withOpacity(0.8),
              Colors.black.withOpacity(0.8),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
      ),
      title: Column(
        children: [
          const Text(
            'My Tasks',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          Consumer<TodoProvider>(
            builder: (context, provider, _) {
              // Add null check
              final todos = provider.todos;
              final completedTasks = todos.where((t) => t.isCompleted).length;
              return Text(
                '${completedTasks} of ${todos.length} tasks completed',
                style: const TextStyle(fontSize: 14, color: Colors.white70),
              );
            },
          ),
        ],
      ),
      centerTitle: true,
      actions: [
        IconButton(
          icon: const Icon(Icons.filter_list),
          onPressed: _showFilterDialog,
        ),
      ],
    );
  }

  Widget _buildTodoList() {
    return Consumer<TodoProvider>(
      builder: (context, provider, _) {
        final todos = provider.sortedTodos; // Changed this line

        if (todos.isEmpty) {
          return _buildEmptyState();
        }

        return AnimatedList(
          key: _listKey,
          controller: _scrollController,
          initialItemCount: todos.length,
          itemBuilder: (context, index, animation) {
            if (index >= todos.length) return Container();
            final todo = todos[index];
            return _buildAnimatedItem(todo, animation, index);
          },
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.task_outlined,
            size: 80,
            color: Colors.white.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'No tasks yet',
            style: TextStyle(
              fontSize: 20,
              color: Colors.white.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tap + to add a new task',
            style: TextStyle(
              fontSize: 16,
              color: Colors.white.withOpacity(0.5),
            ),
          ),
        ],
      ),
    ).animate().fade(duration: 300.ms).scale(duration: 300.ms);
  }

  Widget _buildFloatingActionButton() {
    return FloatingActionButton(
      onPressed: () => _navigateToAddTask(context),
      child: const Icon(Icons.add),
    ).animate().scale(delay: 300.ms).shake(delay: 400.ms);
  }

  Widget _buildAnimatedItem(Todo todo, Animation<double> animation, int index) {
    return SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(1, 0),
        end: Offset.zero,
      ).animate(CurvedAnimation(
        parent: animation,
        curve: Curves.easeOut,
      )),
      child: FadeTransition(
        opacity: animation,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: TodoItem(todo: todo), // Simplified - removed callbacks
        ),
      ),
    );
  }

  void _deleteItem(int index) {
    final provider = Provider.of<TodoProvider>(context, listen: false);
    final removedTodo = provider.todos[index];

    _listKey.currentState?.removeItem(
      index,
      (context, animation) => _buildAnimatedItem(removedTodo, animation, index),
      duration: const Duration(milliseconds: 300),
    );

    provider.deleteTodo(removedTodo.id);
    _showSnackBar('Task deleted');
  }

  void _editItem(Todo todo, int index) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddTaskScreen(
          isEditing: true,
          todoToEdit: todo,
        ),
      ),
    );

    if (result != null && result is Todo && mounted) {
      final provider = Provider.of<TodoProvider>(context, listen: false);
      provider.updateTodo(result);

      // Rebuild the specific item with animation
      _listKey.currentState?.removeItem(
        index,
        (context, animation) => _buildAnimatedItem(todo, animation, index),
        duration: const Duration(milliseconds: 150),
      );

      _listKey.currentState?.insertItem(
        index,
        duration: const Duration(milliseconds: 300),
      );

      _showSnackBar('Task updated');
    }
  }

  void _navigateToAddTask(BuildContext context) async {
    final currentContext = context;
    final result = await Navigator.push(
      currentContext,
      MaterialPageRoute(builder: (context) => const AddTaskScreen()),
    );

    if (result != null && result is Todo && currentContext.mounted) {
      final provider = Provider.of<TodoProvider>(currentContext, listen: false);
      provider.addTodo(result);
      _listKey.currentState?.insertItem(0);
      _scrollToTop();
      _showSnackBar('Task added');
    }
  }

  void _scrollToTop() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Filter Tasks'),
        content: Consumer<TodoProvider>(
          builder: (context, provider, _) {
            return SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Categories',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  _buildFilterChip('All', provider),
                  ...provider.categories
                      .map((category) => _buildFilterChip(category, provider)),
                  const Divider(),
                  const Text('Priority',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  _buildPriorityFilterChip('All', provider),
                  ...Priority.values.map((priority) => _buildPriorityFilterChip(
                      priority.toString().split('.').last, provider)),
                ],
              ),
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  // Add this new method right after _showFilterDialog
  Widget _buildPriorityFilterChip(String label, TodoProvider provider) {
    final isSelected = provider.currentPriorityFilter == label;
    return ListTile(
      leading: Icon(
        isSelected ? Icons.check_circle : Icons.circle_outlined,
        color: isSelected ? Theme.of(context).primaryColor : Colors.grey,
      ),
      title: Text(label),
      onTap: () {
        provider.setPriorityFilter(label);
        Navigator.pop(context);
      },
      tileColor:
          isSelected ? Theme.of(context).primaryColor.withOpacity(0.1) : null,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
    );
  }

  Widget _buildFilterChip(String label, TodoProvider provider) {
    final isSelected = provider.currentFilter == label;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: ListTile(
        leading: Icon(
          isSelected ? Icons.check_circle : Icons.circle_outlined,
          color: isSelected ? Theme.of(context).primaryColor : Colors.grey,
        ),
        title: Text(label),
        onTap: () {
          provider.setFilter(label);
          Navigator.pop(context);
          _showSnackBar('Filtered by: $label');
        },
        tileColor:
            isSelected ? Theme.of(context).primaryColor.withOpacity(0.1) : null,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
        action: SnackBarAction(
          label: 'Dismiss',
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ),
      ),
    );
  }

  Future<bool> _confirmDelete() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Task'),
        content: const Text('Are you sure you want to delete this task?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    return result ?? false;
  }
}
