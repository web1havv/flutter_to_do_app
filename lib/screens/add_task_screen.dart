import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../models/todo_model.dart';
import '../providers/todo_provider.dart';

class AddTaskScreen extends StatefulWidget {
  final bool isEditing;
  final Todo? todoToEdit;

  const AddTaskScreen({
    super.key,
    this.isEditing = false,
    this.todoToEdit,
  });

  @override
  State<AddTaskScreen> createState() => _AddTaskScreenState();
}

class _AddTaskScreenState extends State<AddTaskScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _notesController;
  DateTime? _selectedDate;
  String? _selectedCategory;
  Priority _selectedPriority = Priority.medium;

  @override
  void initState() {
    super.initState();
    _titleController =
        TextEditingController(text: widget.todoToEdit?.title ?? '');
    _notesController =
        TextEditingController(text: widget.todoToEdit?.notes ?? '');
    _selectedDate = widget.todoToEdit?.deadline;
    _selectedCategory = widget.todoToEdit?.category;
    _selectedPriority = widget.todoToEdit?.priority ?? Priority.medium;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<TodoProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isEditing ? 'Edit Task' : 'New Task'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Theme.of(context).scaffoldBackgroundColor,
              Theme.of(context).scaffoldBackgroundColor.withOpacity(0.8),
            ],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: ListView(
              children: [
                _buildTitleField(),
                const SizedBox(height: 20),
                _buildDateTimePicker(),
                const SizedBox(height: 20),
                _buildCategorySelector(provider),
                const SizedBox(height: 20),
                _buildPrioritySelector(),
                const SizedBox(height: 20),
                _buildNotesField(),
                const SizedBox(height: 30),
                _buildSubmitButton(),
              ]
                  .animate(interval: 50.ms)
                  .fadeIn(duration: 300.ms)
                  .slideX(begin: 0.2, duration: 300.ms),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _selectDateTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (date != null) {
      final time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.now(),
      );

      if (time != null) {
        setState(() {
          _selectedDate = DateTime(
            date.year,
            date.month,
            date.day,
            time.hour,
            time.minute,
          );
        });
      }
    }
  }

  Widget _buildTitleField() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: TextFormField(
        controller: _titleController,
        decoration: const InputDecoration(
          labelText: 'Task Title',
          prefixIcon: Icon(Icons.title),
          border: InputBorder.none,
          contentPadding: EdgeInsets.all(16),
        ),
        validator: (value) => value!.isEmpty ? 'Enter task title' : null,
      ),
    );
  }

  Widget _buildDateTimePicker() {
    return InkWell(
      onTap: _selectDateTime,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            const Icon(Icons.calendar_today),
            const SizedBox(width: 12),
            Text(
              _selectedDate != null
                  ? DateFormat('MMM dd, yyyy - HH:mm').format(_selectedDate!)
                  : 'Select Date & Time',
              style: const TextStyle(fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategorySelector(TodoProvider provider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Category', style: TextStyle(fontSize: 16)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: provider.categories.map((category) {
            final isSelected = _selectedCategory == category;
            return InkWell(
              onTap: () => setState(() => _selectedCategory = category),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: isSelected
                      ? Theme.of(context).primaryColor.withOpacity(0.3)
                      : Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected
                        ? Theme.of(context).primaryColor
                        : Colors.transparent,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isSelected ? Icons.check_circle : Icons.circle_outlined,
                      size: 20,
                      color: isSelected
                          ? Theme.of(context).primaryColor
                          : Colors.white70,
                    ),
                    const SizedBox(width: 8),
                    Text(category),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildPrioritySelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Priority', style: TextStyle(fontSize: 16)),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: Priority.values.map((priority) {
            final isSelected = _selectedPriority == priority;
            return InkWell(
              onTap: () => setState(() => _selectedPriority = priority),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: isSelected
                      ? _getPriorityColor(priority).withOpacity(0.3)
                      : Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected
                        ? _getPriorityColor(priority)
                        : Colors.transparent,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _getPriorityIcon(priority),
                      color: isSelected
                          ? _getPriorityColor(priority)
                          : Colors.white70,
                    ),
                    const SizedBox(width: 8),
                    Text(priority.toString().split('.').last),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildNotesField() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: TextFormField(
        controller: _notesController,
        maxLines: 3,
        decoration: const InputDecoration(
          labelText: 'Notes (Optional)',
          alignLabelWithHint: true,
          prefixIcon: Icon(Icons.note),
          border: InputBorder.none,
          contentPadding: EdgeInsets.all(16),
        ),
      ),
    );
  }

  Widget _buildSubmitButton() {
    return ElevatedButton(
      onPressed: _submitForm,
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      child: Text(
        widget.isEditing ? 'Update Task' : 'Create Task',
        style: const TextStyle(fontSize: 16),
      ),
    );
  }

  IconData _getPriorityIcon(Priority priority) {
    switch (priority) {
      case Priority.high:
        return Icons.flag;
      case Priority.medium:
        return Icons.flag_outlined;
      case Priority.low:
        return Icons.outlined_flag;
    }
  }

  Color _getPriorityColor(Priority priority) {
    switch (priority) {
      case Priority.high:
        return Colors.red;
      case Priority.medium:
        return Colors.orange;
      case Priority.low:
        return Colors.green;
    }
  }

  void _submitForm() {
    if (_formKey.currentState!.validate() && _selectedCategory != null) {
      final updatedTodo = Todo(
        id: widget.todoToEdit?.id ?? DateTime.now().toString(),
        title: _titleController.text,
        deadline: _selectedDate,
        priority: _selectedPriority,
        category: _selectedCategory!,
        notes: _notesController.text.isNotEmpty ? _notesController.text : null,
        isCompleted: widget.todoToEdit?.isCompleted ?? false,
      );

      final provider = Provider.of<TodoProvider>(context, listen: false);
      if (widget.isEditing) {
        provider.updateTodo(updatedTodo);
      } else {
        provider.addTodo(updatedTodo);
      }

      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill all required fields'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
}
