import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/todo_model.dart';
import '../providers/todo_provider.dart';
import '../screens/add_task_screen.dart'; // Add this import

class TodoItem extends StatefulWidget {
  final Todo todo;

  const TodoItem({super.key, required this.todo});

  @override
  State<TodoItem> createState() => _TodoItemState();
}

class _TodoItemState extends State<TodoItem>
    with SingleTickerProviderStateMixin {
  late AnimationController _checkController;
  late Animation<double> _scaleAnimation;
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    _checkController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _checkController, curve: Curves.elasticOut),
    );

    if (widget.todo.isCompleted) _checkController.forward();
  }

  @override
  void dispose() {
    _checkController.dispose();
    super.dispose();
  }

  Color _getPriorityColor() {
    switch (widget.todo.priority) {
      case Priority.high:
        return Colors.red.shade300;
      case Priority.medium:
        return Colors.amber.shade300;
      case Priority.low:
        return Colors.green.shade300;
    }
  }

  String _getTimeRemaining() {
    if (widget.todo.deadline == null) return 'No deadline';
    final now = DateTime.now();
    final difference = widget.todo.deadline!.difference(now);

    if (difference.isNegative) return 'Overdue';
    if (difference.inDays > 0) return '${difference.inDays}d left';
    if (difference.inHours > 0) return '${difference.inHours}h left';
    return '${difference.inMinutes}m left';
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: 300.ms,
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              _getPriorityColor().withOpacity(0.1),
              Colors.black.withOpacity(0.3),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(15),
          boxShadow: _isHovered
              ? [
                  BoxShadow(
                    color: _getPriorityColor().withOpacity(0.2),
                    blurRadius: 10,
                    spreadRadius: 1,
                  )
                ]
              : null,
        ),
        child: Dismissible(
          key: Key(widget.todo.id),
          direction: DismissDirection.endToStart,
          background: _buildDismissBackground(),
          confirmDismiss: (_) => _confirmDismiss(context),
          onDismissed: (_) => _deleteItem(context),
          child: _buildTodoContent(),
        ),
      ),
    ).animate().fadeIn().slideX(begin: 0.2);
  }

  Widget _buildTodoContent() {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      leading: _buildPriorityIndicator(),
      title: _buildTitle(),
      subtitle: _buildSubtitle(),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildStatusIndicator(),
          IconButton(
            icon: const Icon(Icons.edit, color: Colors.white70),
            onPressed: () => _editTodo(context),
          ),
        ],
      ),
      onTap: () => _editTodo(context),
    );
  }

  void _editTodo(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddTaskScreen(
          isEditing: true,
          todoToEdit: widget.todo,
        ),
      ),
    );
  }

  // Rest of the methods remain unchanged
  Widget _buildDismissBackground() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.3),
        borderRadius: BorderRadius.circular(15),
      ),
      alignment: Alignment.centerRight,
      padding: const EdgeInsets.only(right: 20),
      child: const Icon(Icons.delete_forever, color: Colors.red),
    );
  }

  Widget _buildPriorityIndicator() {
    return Container(
      width: 4,
      height: 40,
      decoration: BoxDecoration(
        color: _getPriorityColor(),
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }

  Widget _buildTitle() {
    return Text(
      widget.todo.title,
      style: TextStyle(
        fontSize: 16,
        color: Colors.white.withOpacity(widget.todo.isCompleted ? 0.5 : 0.9),
        decoration: widget.todo.isCompleted ? TextDecoration.lineThrough : null,
        decorationColor: _getPriorityColor(),
        decorationThickness: 2,
      ),
    );
  }

  Widget _buildSubtitle() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 4),
        Row(
          children: [
            const Icon(Icons.access_time, size: 14),
            const SizedBox(width: 6),
            Text(
              _getTimeRemaining(),
              style: TextStyle(color: _getPriorityColor(), fontSize: 12),
            ),
          ],
        ),
        if (widget.todo.category.isNotEmpty) ...[
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(Icons.category, size: 14),
              const SizedBox(width: 6),
              Text(
                widget.todo.category,
                style: TextStyle(color: _getPriorityColor(), fontSize: 12),
              ),
            ],
          ),
        ],
        if (widget.todo.notes != null) ...[
          const SizedBox(height: 4),
          Text(
            widget.todo.notes!,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 12,
              fontStyle: FontStyle.italic,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ],
    );
  }

  Widget _buildStatusIndicator() {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: IconButton(
        icon: Icon(
          widget.todo.isCompleted ? Icons.check_circle : Icons.circle_outlined,
          color: widget.todo.isCompleted ? Colors.green : Colors.grey,
        ),
        onPressed: () => _toggleCompletion(context),
      ),
    );
  }

  Future<bool?> _confirmDismiss(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Delete'),
        content: const Text('Are you sure you want to delete this task?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _toggleCompletion(BuildContext context) {
    final newStatus = !widget.todo.isCompleted;
    context.read<TodoProvider>().updateTodo(
          widget.todo.copyWith(isCompleted: newStatus),
        );

    if (newStatus) {
      _checkController.forward();
    } else {
      _checkController.reverse();
    }
  }

  void _deleteItem(BuildContext context) {
    context.read<TodoProvider>().deleteTodo(widget.todo.id);
  }
}
