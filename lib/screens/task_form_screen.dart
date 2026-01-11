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
  final _descriptionController = TextEditingController();
  
  String _selectedCategory = 'Intellectual';
  int _selectedPriority = 2; // 1=High, 2=Medium, 3=Low
  int _estimatedMinutes = 30;
  DateTime? _selectedDueDate;
  TimeOfDay? _selectedTime;
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
    _descriptionController.dispose();
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
  
  Future<void> _selectTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    
    if (time != null) {
      setState(() => _selectedTime = time);
    }
  }
  
  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isLoading = true);
    
    // Combine date and time if both are selected
    DateTime? finalDueDate = _selectedDueDate;
    if (_selectedDueDate != null && _selectedTime != null) {
      finalDueDate = DateTime(
        _selectedDueDate!.year,
        _selectedDueDate!.month,
        _selectedDueDate!.day,
        _selectedTime!.hour,
        _selectedTime!.minute,
      );
    }
    
    final success = await widget.taskProvider.createTask(
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim().isEmpty 
          ? null 
          : _descriptionController.text.trim(),
      category: _selectedCategory,
      priority: _selectedPriority,
      dueDate: finalDueDate,
      estimatedMinutes: _estimatedMinutes,
    );
    
    if (!mounted) return;
    
    setState(() => _isLoading = false);
    
    if (success) {
      Navigator.of(context).pop(true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✓ Task added successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(widget.taskProvider.error ?? 'Failed to create task'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('Add Task', style: TextStyle(fontWeight: FontWeight.bold)),
        elevation: 0,
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // Header Section
            const Text(
              'Create a New Task',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Fill in the details below to add your task',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 24),
            
            // Title Card
            _buildCard(
              child: TextFormField(
                controller: _titleController,
                decoration: InputDecoration(
                  labelText: 'Task Title *',
                  hintText: 'e.g., Complete project report',
                  prefixIcon: const Icon(Icons.task_alt, color: Colors.blue),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.white,
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
            ),
            
            const SizedBox(height: 16),
            
            // Description Card
            _buildCard(
              child: TextFormField(
                controller: _descriptionController,
                decoration: InputDecoration(
                  labelText: 'Description',
                  hintText: 'Add more details about your task...',
                  prefixIcon: const Icon(Icons.description, color: Colors.blue),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                ),
                maxLines: 3,
                enabled: !_isLoading,
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Category Card
            _buildCard(
              child: DropdownButtonFormField<String>(
                value: _selectedCategory,
                decoration: InputDecoration(
                  labelText: 'Category *',
                  prefixIcon: const Icon(Icons.category, color: Colors.blue),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.white,
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
            ),
            
            const SizedBox(height: 20),
            
            // Priority Section
            _buildSectionCard(
              title: 'Priority Level',
              icon: Icons.flag,
              child: Row(
                children: [
                  _buildPriorityChip('High', 1, Colors.red),
                  const SizedBox(width: 8),
                  _buildPriorityChip('Medium', 2, Colors.orange),
                  const SizedBox(width: 8),
                  _buildPriorityChip('Low', 3, Colors.green),
                ],
              ),
            ),
            
            const SizedBox(height: 20),
            
            // Duration Section
            _buildSectionCard(
              title: 'Estimated Duration',
              icon: Icons.timer,
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'How long will this take?',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade700,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.blue.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '$_estimatedMinutes min',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.blue,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  SliderTheme(
                    data: SliderThemeData(
                      activeTrackColor: Colors.blue,
                      inactiveTrackColor: Colors.blue.withValues(alpha: 0.2),
                      thumbColor: Colors.blue,
                      overlayColor: Colors.blue.withValues(alpha: 0.2),
                      valueIndicatorColor: Colors.blue,
                    ),
                    child: Slider(
                      value: _estimatedMinutes.toDouble(),
                      min: 15,
                      max: 240,
                      divisions: 15,
                      label: '$_estimatedMinutes min',
                      onChanged: _isLoading ? null : (value) {
                        setState(() => _estimatedMinutes = value.toInt());
                      },
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 20),
            
            // Due Date & Time Section
            _buildSectionCard(
              title: 'Due Date & Time',
              icon: Icons.event,
              trailing: (_selectedDueDate != null || _selectedTime != null)
                  ? TextButton.icon(
                      onPressed: () {
                        setState(() {
                          _selectedDueDate = null;
                          _selectedTime = null;
                        });
                      },
                      icon: const Icon(Icons.clear, size: 16),
                      label: const Text('Clear'),
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        minimumSize: const Size(50, 30),
                      ),
                    )
                  : null,
              child: Column(
                children: [
                  // Due Date
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _isLoading ? null : _selectDueDate,
                      icon: Icon(
                        Icons.calendar_today,
                        color: _selectedDueDate != null ? Colors.blue : null,
                      ),
                      label: Text(
                        _selectedDueDate == null
                            ? 'Set Due Date'
                            : _formatDate(_selectedDueDate!),
                        style: TextStyle(
                          color: _selectedDueDate != null ? Colors.blue : null,
                          fontWeight: _selectedDueDate != null ? FontWeight.bold : null,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.all(16),
                        backgroundColor: _selectedDueDate != null 
                            ? Colors.blue.withValues(alpha: 0.1) 
                            : null,
                        side: BorderSide(
                          color: _selectedDueDate != null 
                              ? Colors.blue 
                              : Colors.grey.shade300,
                          width: _selectedDueDate != null ? 2 : 1,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 12),
                  
                  // Time
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _isLoading ? null : _selectTime,
                      icon: Icon(
                        Icons.access_time,
                        color: _selectedTime != null ? Colors.blue : null,
                      ),
                      label: Text(
                        _selectedTime == null
                            ? 'Set Time'
                            : _selectedTime!.format(context),
                        style: TextStyle(
                          color: _selectedTime != null ? Colors.blue : null,
                          fontWeight: _selectedTime != null ? FontWeight.bold : null,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.all(16),
                        backgroundColor: _selectedTime != null 
                            ? Colors.blue.withValues(alpha: 0.1) 
                            : null,
                        side: BorderSide(
                          color: _selectedTime != null 
                              ? Colors.blue 
                              : Colors.grey.shade300,
                          width: _selectedTime != null ? 2 : 1,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  
                  // Preview selected date/time
                  if (_selectedDueDate != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 16),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.blue.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: Colors.blue.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.info_outline, size: 18, color: Colors.blue),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _getDateTimePreview(),
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.blue.shade700,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
            
            const SizedBox(height: 32),
            
            // Submit Button
            Container(
              width: double.infinity,
              height: 56,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF3B82F6), Color(0xFF2563EB)],
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.blue.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ElevatedButton(
                onPressed: _isLoading ? null : _handleSubmit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 3,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add_circle_outline, size: 24),
                          SizedBox(width: 8),
                          Text(
                            'Create Task',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 20),
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
  
  Widget _buildCard({required Widget child}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );
  }
  
  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required Widget child,
    Widget? trailing,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.blue.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(icon, color: Colors.blue, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
              if (trailing != null) trailing,
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
  
  Widget _buildPriorityChip(String label, int value, Color color) {
    final isSelected = _selectedPriority == value;
    return Expanded(
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: _isLoading ? null : (selected) {
          setState(() => _selectedPriority = value);
        },
        selectedColor: color.withValues(alpha: 0.3),
        checkmarkColor: color,
        labelStyle: TextStyle(
          color: isSelected ? color : Colors.grey.shade700,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
    );
  }
  
  String _getDateTimePreview() {
    if (_selectedDueDate == null) return '';
    
    final now = DateTime.now();
    final selectedDate = DateTime(_selectedDueDate!.year, _selectedDueDate!.month, _selectedDueDate!.day);
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    
    String dateStr;
    if (selectedDate == today) {
      dateStr = 'Today';
    } else if (selectedDate == tomorrow) {
      dateStr = 'Tomorrow';
    } else {
      dateStr = _formatDate(_selectedDueDate!);
    }
    
    if (_selectedTime != null) {
      return 'Due: $dateStr at ${_selectedTime!.format(context)}';
    } else {
      return 'Due: $dateStr (no specific time)';
    }
  }
}