import 'package:flutter/material.dart';
import '../providers/task_provider.dart';

class TaskFormScreen extends StatefulWidget {
  final TaskProvider taskProvider;
  
  const TaskFormScreen({super.key, required this.taskProvider});

  @override
  State<TaskFormScreen> createState() => _TaskFormScreenState();
}

class _TaskFormScreenState extends State<TaskFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  
  String _selectedCategory = 'Intellectual';
  DateTime? _selectedDueDate;
  bool _isLoading = false;
  
  final List<String> _categories = [
    'Intellectual',
    'Physical Health',
    'Mental Wellbeing',
    'Social Growth',
    'Skill Development & Career',
    'Hobbies/Passion',
    'Financial',
  ];
  
  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }
  
  Future<void> _selectDueDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    
    if (date != null) {
      setState(() => _selectedDueDate = date);
    }
  }
  
  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isLoading = true);
    
    final success = await widget.taskProvider.createTask(
      title: _titleController.text.trim(),
      category: _selectedCategory,
      priority: 2, // Medium priority by default
      dueDate: _selectedDueDate,
    );
    
    if (!mounted) return;
    
    setState(() => _isLoading = false);
    
    if (success) {
      Navigator.of(context).pop(true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✓ Task added!'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Task'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Title
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Task Title',
                hintText: 'What needs to be done?',
                prefixIcon: Icon(Icons.task_alt),
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter a task title';
                }
                return null;
              },
              enabled: !_isLoading,
              autofocus: true,
            ),
            
            const SizedBox(height: 16),
            
            // Category
            DropdownButtonFormField<String>(
              value: _selectedCategory,
              decoration: const InputDecoration(
                labelText: 'Category',
                prefixIcon: Icon(Icons.category),
                border: OutlineInputBorder(),
              ),
              items: _categories.map((category) {
                return DropdownMenuItem(
                  value: category,
                  child: Text(category),
                );
              }).toList(),
              onChanged: _isLoading ? null : (value) {
                setState(() => _selectedCategory = value!);
              },
            ),
            
            const SizedBox(height: 16),
            
            // Due Date
            OutlinedButton.icon(
              onPressed: _isLoading ? null : _selectDueDate,
              icon: const Icon(Icons.calendar_today),
              label: Text(
                _selectedDueDate == null
                    ? 'Set Due Date (Optional)'
                    : 'Due: ${_formatDate(_selectedDueDate!)}',
              ),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.all(16),
                alignment: Alignment.centerLeft,
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Submit Button
            ElevatedButton(
              onPressed: _isLoading ? null : _handleSubmit,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.all(16),
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Text(
                      'Add Task',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
            ),
          ],
        ),
      ),
    );
  }
  
  String _formatDate(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
  }
}