import 'package:flutter/material.dart';
import '../providers/task_provider.dart';
import '../models/task.dart';

class TaskFormScreen extends StatefulWidget {
  final TaskProvider taskProvider;
  final Task? initialTask;
  
  const TaskFormScreen({super.key, required this.taskProvider, this.initialTask});

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
  bool _priorityManuallyChanged = false;
  
  // Two-date system
  DateTime? _selectedDeadline;
  TimeOfDay? _deadlineTime;
  DateTime? _selectedScheduledDate;
  TimeOfDay? _scheduledTime;
  
  bool _isLoading = false;
  
  // Recurring task fields
  String _scheduleType = 'one-time'; // 'one-time', 'daily', 'weekly', 'weekend', 'custom'
  List<int> _scheduledDays = []; // 1=Monday, 7=Sunday
  
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
  void initState() {
    super.initState();
    // Prefill when editing an existing task
    final t = widget.initialTask;
    if (t != null) {
      _titleController.text = t.title;
      _descriptionController.text = t.description ?? '';
      _selectedCategory = t.category;
      _selectedPriority = t.priority;
      _estimatedMinutes = t.estimatedMinutes ?? _estimatedMinutes;
      
      // Handle deadline
      _selectedDeadline = t.deadline;
      if (t.deadline != null) {
        _deadlineTime = TimeOfDay(
          hour: t.deadline!.hour,
          minute: t.deadline!.minute,
        );
      }
      
      // Handle scheduled date/time
      _selectedScheduledDate = t.scheduledDateTime;
      if (t.scheduledDateTime != null) {
        _scheduledTime = TimeOfDay(
          hour: t.scheduledDateTime!.hour,
          minute: t.scheduledDateTime!.minute,
        );
      }
      
      // Handle recurring task scheduled time
      if (t.scheduledTime != null && _scheduledTime == null) {
        final parts = t.scheduledTime!.split(':');
        if (parts.length >= 2) {
          final h = int.tryParse(parts[0]) ?? 0;
          final m = int.tryParse(parts[1]) ?? 0;
          _scheduledTime = TimeOfDay(hour: h, minute: m);
        }
      }
      
      _scheduleType = t.scheduleType ?? 'one-time';
      _scheduledDays = List<int>.from(t.scheduledDays ?? []);
      if (_scheduleType == 'weekend' && _scheduledDays.isEmpty) {
        _scheduledDays = [DateTime.saturday, DateTime.sunday];
      }
      
      // If editing, we consider priority already "maintained"
      _priorityManuallyChanged = true;
    } else {
      // Add listeners for keyword-based priority suggestions for NEW tasks
      _titleController.addListener(_onInputChanged);
      _descriptionController.addListener(_onInputChanged);
    }
  }

  void _onInputChanged() {
    if (_priorityManuallyChanged || widget.initialTask != null) return;

    final text = '${_titleController.text} ${_descriptionController.text}'.toLowerCase();
    
    // Keywords that trigger High Priority
    final highPriorityKeywords = [
      'urgent', 'critical', 'emergency', 'asap', 'immediately', 
      'instant', 'hotpack', 'now', 'deadline', 'alert', 'quick', 'mandatory'
    ];

    bool shouldBeHigh = false;
    for (var kw in highPriorityKeywords) {
      if (text.contains(kw)) {
        shouldBeHigh = true;
        break;
      }
    }

    if (shouldBeHigh && _selectedPriority != 1) {
      setState(() => _selectedPriority = 1);
    } else if (!shouldBeHigh && _selectedPriority == 1) {
      // If none of the keywords are present, and it was auto-set to High,
      // revert it back to Medium if not manually changed.
      setState(() => _selectedPriority = 2);
    }
  }
  
  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }
  
  Future<void> _selectDeadlineDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDeadline ?? DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    
    if (date != null) {
      setState(() => _selectedDeadline = date);
    }
  }
  
  Future<void> _selectDeadlineTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: _deadlineTime ?? TimeOfDay.now(),
    );
    
    if (time != null) {
      setState(() => _deadlineTime = time);
    }
  }
  
  Future<void> _selectScheduledDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedScheduledDate ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    
    if (date != null) {
      setState(() => _selectedScheduledDate = date);
    }
  }
  
  Future<void> _selectScheduledDateTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: _scheduledTime ?? TimeOfDay.now(),
    );
    
    if (time != null) {
      setState(() => _scheduledTime = time);
    }
  }
  
  Future<void> _selectScheduledTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: _scheduledTime ?? TimeOfDay.now(),
    );
    
    if (time != null) {
      setState(() => _scheduledTime = time);
    }
  }
  
  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isLoading = true);
    
    // Combine deadline date and time if both are selected
    DateTime? finalDeadline = _selectedDeadline;
    if (_selectedDeadline != null && _deadlineTime != null) {
      finalDeadline = DateTime(
        _selectedDeadline!.year,
        _selectedDeadline!.month,
        _selectedDeadline!.day,
        _deadlineTime!.hour,
        _deadlineTime!.minute,
      );
    }
    
    // Combine scheduled date and time if both are selected
    DateTime? finalScheduledDateTime = _selectedScheduledDate;
    if (_selectedScheduledDate != null && _scheduledTime != null) {
      finalScheduledDateTime = DateTime(
        _selectedScheduledDate!.year,
        _selectedScheduledDate!.month,
        _selectedScheduledDate!.day,
        _scheduledTime!.hour,
        _scheduledTime!.minute,
      );
    }
    
    // Format scheduled time for recurring tasks
    String? formattedScheduledTime;
    if (_scheduleType != 'one-time' && _scheduledTime != null) {
      formattedScheduledTime = '${_scheduledTime!.hour.toString().padLeft(2, '0')}:${_scheduledTime!.minute.toString().padLeft(2, '0')}';
    }
    
    final scheduledDaysForSubmission = _getScheduledDaysForSubmission();

    bool success = false;
    if (widget.initialTask == null) {
      success = await widget.taskProvider.createTask(
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim().isEmpty 
            ? null 
            : _descriptionController.text.trim(),
        category: _selectedCategory,
        priority: _selectedPriority,
        deadline: finalDeadline,
        scheduledDateTime: finalScheduledDateTime,
        estimatedMinutes: _estimatedMinutes,
        scheduleType: _scheduleType != 'one-time' ? _scheduleType : null,
        scheduledTime: formattedScheduledTime,
        scheduledDays: scheduledDaysForSubmission,
      );
    } else {
      // Update existing task
      success = await widget.taskProvider.updateTask(
        taskId: widget.initialTask!.id,
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim().isEmpty 
            ? null 
            : _descriptionController.text.trim(),
        category: _selectedCategory,
        priority: _selectedPriority,
        deadline: finalDeadline,
        scheduledDateTime: finalScheduledDateTime,
        estimatedMinutes: _estimatedMinutes,
        scheduleType: _scheduleType != 'one-time' ? _scheduleType : null,
        scheduledTime: formattedScheduledTime,
        scheduledDays: scheduledDaysForSubmission,
      );
    }
    
    if (!mounted) return;
    
    setState(() => _isLoading = false);
    
    if (success) {
      Navigator.of(context).pop(true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(widget.initialTask == null ? '✓ Task added successfully!' : '✓ Task updated successfully!'),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC);
    final topBarColor = isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC);
    final textColor = isDark ? Colors.white : const Color(0xFF1E293B);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: Text(widget.initialTask != null ? 'Edit Task' : 'Add Task', 
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        elevation: 0,
        backgroundColor: topBarColor,
        foregroundColor: textColor,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // Header Section
            Text(
              widget.initialTask != null ? 'Edit Task' : 'Create a New Task',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              widget.initialTask != null ? 'Update fields to edit the task' : 'Fill in the details below to add your task',
              style: TextStyle(
                fontSize: 14,
                color: isDark ? Colors.grey.shade400 : const Color(0xFF64748B),
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
                  prefixIcon: const Icon(Icons.task_alt, color: Color(0xFF4F46E5)),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                ),
                style: const TextStyle(color: Color(0xFF1E293B), fontWeight: FontWeight.w600),
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
                initialValue: _selectedCategory,
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
                  _buildPriorityChip('High', 1, const Color(0xFFEF4444)),
                  const SizedBox(width: 8),
                  _buildPriorityChip('Medium', 2, const Color(0xFFF59E0B)),
                  const SizedBox(width: 8),
                  _buildPriorityChip('Low', 3, const Color(0xFF10B981)),
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
                          color: Colors.blue.withAlpha((255 * 0.1).toInt()),
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
                      activeTrackColor: const Color(0xFF4F46E5),
                      inactiveTrackColor: const Color(0xFF4F46E5).withValues(alpha: 0.1),
                      thumbColor: const Color(0xFF4F46E5),
                      overlayColor: const Color(0xFF4F46E5).withValues(alpha: 0.1),
                      valueIndicatorColor: const Color(0xFF4F46E5),
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
            
            // Scheduled Time Section (When you plan to work on it) - Moved above deadline
            _buildSectionCard(
              title: 'Scheduled Time',
              icon: Icons.today,
              trailing: (_selectedScheduledDate != null)
                  ? TextButton.icon(
                      onPressed: () {
                        setState(() {
                          _selectedScheduledDate = null;
                          _scheduledTime = null;
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
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      // Scheduled Date
                      Expanded(
                        flex: 2,
                        child: OutlinedButton.icon(
                          onPressed: _isLoading ? null : _selectScheduledDate,
                          icon: Icon(
                            Icons.today,
                            color: _selectedScheduledDate != null ? Colors.green.shade600 : null,
                            size: 20,
                          ),
                          label: Text(
                            _selectedScheduledDate == null
                                ? 'Pick Date'
                                : _formatDate(_selectedScheduledDate!),
                            style: TextStyle(
                              color: _selectedScheduledDate != null ? Colors.green.shade600 : null,
                              fontWeight: _selectedScheduledDate != null ? FontWeight.bold : null,
                              fontSize: 13,
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                            backgroundColor: _selectedScheduledDate != null 
                                ? Colors.green.shade50 
                                : null,
                            side: BorderSide(
                              color: _selectedScheduledDate != null 
                                  ? Colors.green.shade300
                                  : Colors.grey.shade300,
                              width: _selectedScheduledDate != null ? 2 : 1,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                      
                      const SizedBox(width: 12),
                      
                      // Scheduled Time
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: (_isLoading || _selectedScheduledDate == null) ? null : _selectScheduledDateTime,
                          icon: Icon(
                            Icons.access_time,
                            color: _scheduledTime != null ? Colors.green.shade600 : null,
                            size: 20,
                          ),
                          label: Text(
                            _scheduledTime == null
                                ? 'Time'
                                : _scheduledTime!.format(context),
                            style: TextStyle(
                              color: _scheduledTime != null ? Colors.green.shade600 : null,
                              fontWeight: _scheduledTime != null ? FontWeight.bold : null,
                              fontSize: 13,
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
                            backgroundColor: _scheduledTime != null 
                                ? Colors.green.shade50 
                                : null,
                            side: BorderSide(
                              color: _scheduledTime != null 
                                  ? Colors.green.shade300
                                  : Colors.grey.shade300,
                              width: _scheduledTime != null ? 2 : 1,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  
                  // Quick time buttons
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _buildQuickTimeChip('Today', () {
                        setState(() => _selectedScheduledDate = DateTime.now());
                      }),
                      _buildQuickTimeChip('Tomorrow', () {
                        setState(() => _selectedScheduledDate = DateTime.now().add(const Duration(days: 1)));
                      }),
                      _buildQuickTimeChip('Next Week', () {
                        setState(() => _selectedScheduledDate = DateTime.now().add(const Duration(days: 7)));
                      }),
                    ],
                  ),
                  
                  // Scheduled Preview
                  if (_selectedScheduledDate != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.green.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: Colors.green.shade200,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.work_outline, size: 18, color: Colors.green.shade600),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _getScheduledPreview(),
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.green.shade700,
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
            
            const SizedBox(height: 20),
            
            // Deadline Section (When it MUST be completed)
            _buildSectionCard(
              title: 'Deadline',
              icon: Icons.event,
              trailing: (_selectedDeadline != null)
                  ? TextButton.icon(
                      onPressed: () {
                        setState(() {
                          _selectedDeadline = null;
                          _deadlineTime = null;
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
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      // Deadline Date
                      Expanded(
                        flex: 2,
                        child: OutlinedButton.icon(
                          onPressed: _isLoading ? null : _selectDeadlineDate,
                          icon: Icon(
                            Icons.calendar_today,
                            color: _selectedDeadline != null ? Colors.red.shade600 : null,
                            size: 20,
                          ),
                          label: Text(
                            _selectedDeadline == null
                                ? 'Set Date'
                                : _formatDate(_selectedDeadline!),
                            style: TextStyle(
                              color: _selectedDeadline != null ? Colors.red.shade600 : null,
                              fontWeight: _selectedDeadline != null ? FontWeight.bold : null,
                              fontSize: 13,
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                            backgroundColor: _selectedDeadline != null 
                                ? Colors.red.shade50 
                                : null,
                            side: BorderSide(
                              color: _selectedDeadline != null 
                                  ? Colors.red.shade300
                                  : Colors.grey.shade300,
                              width: _selectedDeadline != null ? 2 : 1,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                      
                      const SizedBox(width: 12),
                      
                      // Deadline Time
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: (_isLoading || _selectedDeadline == null) ? null : _selectDeadlineTime,
                          icon: Icon(
                            Icons.access_time,
                            color: _deadlineTime != null ? Colors.red.shade600 : null,
                            size: 20,
                          ),
                          label: Text(
                            _deadlineTime == null
                                ? 'Time'
                                : _deadlineTime!.format(context),
                            style: TextStyle(
                              color: _deadlineTime != null ? Colors.red.shade600 : null,
                              fontWeight: _deadlineTime != null ? FontWeight.bold : null,
                              fontSize: 13,
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
                            backgroundColor: _deadlineTime != null 
                                ? Colors.red.shade50 
                                : null,
                            side: BorderSide(
                              color: _deadlineTime != null 
                                  ? Colors.red.shade300
                                  : Colors.grey.shade300,
                              width: _deadlineTime != null ? 2 : 1,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  
                  // Deadline Preview
                  if (_selectedDeadline != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: Colors.red.shade200,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.schedule, size: 18, color: Colors.red.shade600),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _getDeadlinePreview(),
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.red.shade700,
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
            
            const SizedBox(height: 20),
            
            // Recurring Schedule Section
            _buildSectionCard(
              title: 'Recurring Schedule',
              icon: Icons.repeat,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Schedule Type Selector
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _buildScheduleTypeChip('One-time', 'one-time'),
                      _buildScheduleTypeChip('Daily', 'daily'),
                      _buildScheduleTypeChip('Weekly', 'weekly'),
                      _buildScheduleTypeChip('Weekend', 'weekend'),
                      _buildScheduleTypeChip('Custom', 'custom'),
                    ],
                  ),
                  
                  // Show scheduled time picker for recurring tasks
                  if (_scheduleType != 'one-time') ...[
                    const SizedBox(height: 16),
                    const Text(
                      'Scheduled Time',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: _isLoading ? null : _selectScheduledTime,
                        icon: Icon(
                          Icons.schedule,
                          color: _scheduledTime != null ? Colors.blue : null,
                        ),
                        label: Text(
                          _scheduledTime == null
                              ? 'Set Recurring Time'
                              : _scheduledTime!.format(context),
                          style: TextStyle(
                            color: _scheduledTime != null ? Colors.blue : null,
                            fontWeight: _scheduledTime != null ? FontWeight.bold : null,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.all(16),
                          backgroundColor: _scheduledTime != null 
                              ? Colors.blue.withAlpha((255 * 0.1).toInt()) 
                              : null,
                          side: BorderSide(
                            color: _scheduledTime != null 
                                ? Colors.blue 
                                : Colors.grey.shade300,
                            width: _scheduledTime != null ? 2 : 1,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ],
                  
                  // Show day selector for weekly/custom patterns
                  if (_scheduleType == 'weekly' || _scheduleType == 'custom') ...[
                    const SizedBox(height: 16),
                    const Text(
                      'Select Days',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _buildDayChip('Mon', 1),
                        _buildDayChip('Tue', 2),
                        _buildDayChip('Wed', 3),
                        _buildDayChip('Thu', 4),
                        _buildDayChip('Fri', 5),
                        _buildDayChip('Sat', 6),
                        _buildDayChip('Sun', 7),
                      ],
                    ),
                  ],
                  
                  // Info message
                  if (_scheduleType != 'one-time')
                    Padding(
                      padding: const EdgeInsets.only(top: 16),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.green.withAlpha((255 * 0.1).toInt()),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: Colors.green.withAlpha((255 * 0.3).toInt()),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.info_outline, size: 18, color: Colors.green),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _getRecurringInfoText(),
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.green.shade700,
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
                    color: Colors.blue.withAlpha((255 * 0.3).toInt()),
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
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(widget.initialTask == null ? Icons.add_circle_outline : Icons.edit, size: 24),
                          const SizedBox(width: 8),
                          Text(
                            widget.initialTask == null ? 'Create Task' : 'Update Task',
                            style: const TextStyle(
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
  
  Widget _buildScheduleTypeChip(String label, String value) {
    final isSelected = _scheduleType == value;
    return ChoiceChip(
      label: Text(
        label,
        style: TextStyle(
          fontSize: 13,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      selected: isSelected,
      onSelected: _isLoading
          ? null
          : (selected) {
              if (!selected) return;
              setState(() {
                _scheduleType = value;
                if (value == 'one-time') {
                  _scheduledTime = null;
                  _scheduledDays.clear();
                } else if (value == 'daily') {
                  _scheduledDays.clear();
                } else if (value == 'weekend') {
                  _scheduledDays
                    ..clear()
                    ..addAll([DateTime.saturday, DateTime.sunday]);
                } else if (value == 'weekly' || value == 'custom') {
                  if (_scheduledDays.isEmpty) {
                    final currentDay = DateTime.now().weekday;
                    _scheduledDays.add(currentDay);
                  }
                }
              });
            },
      selectedColor: Colors.blue,
      backgroundColor: Colors.grey.shade200,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : Colors.black87,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
    );
  }
  
  Widget _buildDayChip(String label, int day) {
    final isSelected = _scheduledDays.contains(day);
    return FilterChip(
      label: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      selected: isSelected,
      onSelected: _isLoading ? null : (selected) {
        setState(() {
          if (selected) {
            if (!_scheduledDays.contains(day)) {
              _scheduledDays.add(day);
            }
          } else {
            _scheduledDays.remove(day);
          }
        });
      },
      selectedColor: Colors.blue,
      backgroundColor: Colors.grey.shade200,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : Colors.black87,
      ),
      checkmarkColor: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    );
  }
  
  Widget _buildCard({required Widget child}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha((255 * (isDark ? 0.3 : 0.1)).toInt()),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(color: isDark ? Colors.grey.shade800 : Colors.transparent),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha((255 * (isDark ? 0.3 : 0.1)).toInt()),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(color: isDark ? Colors.grey.shade800 : Colors.transparent),
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
                      color: Colors.blue.withAlpha((255 * 0.1).toInt()),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(icon, color: Colors.blue, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black87,
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
        onSelected: _isLoading
            ? null
            : (selected) {
                setState(() {
                  _selectedPriority = value;
                  _priorityManuallyChanged = true;
                });
              },
        selectedColor: color.withAlpha((255 * 0.3).toInt()),
        checkmarkColor: color,
        labelStyle: TextStyle(
          color: isSelected ? color : Colors.grey.shade700,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
    );
  }

  String _getRecurringInfoText() {
    switch (_scheduleType) {
      case 'daily':
        return 'Task will repeat daily at the scheduled time';
      case 'weekend':
        return 'Task will repeat every Saturday and Sunday at the scheduled time';
      case 'weekly':
        return 'Task will repeat on selected days at the scheduled time';
      case 'custom':
        return 'Task will repeat on your custom-selected days at the scheduled time';
      default:
        return '';
    }
  }

  List<int>? _getScheduledDaysForSubmission() {
    if (_scheduleType == 'weekend') {
      if (_scheduledDays.isEmpty) {
        return [DateTime.saturday, DateTime.sunday];
      }
      return List<int>.from(_scheduledDays);
    }

    if ((_scheduleType == 'weekly' || _scheduleType == 'custom') && _scheduledDays.isNotEmpty) {
      return List<int>.from(_scheduledDays);
    }

    return null;
  }
  
  String _getDeadlinePreview() {
    if (_selectedDeadline == null) return '';
    
    final now = DateTime.now();
    final selectedDate = DateTime(_selectedDeadline!.year, _selectedDeadline!.month, _selectedDeadline!.day);
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    
    String dateStr;
    if (selectedDate == today) {
      dateStr = 'Today';
    } else if (selectedDate == tomorrow) {
      dateStr = 'Tomorrow';
    } else {
      final difference = selectedDate.difference(today).inDays;
      if (difference > 0) {
        dateStr = 'In $difference day${difference > 1 ? 's' : ''}';
      } else {
        dateStr = '${difference.abs()} day${difference.abs() > 1 ? 's' : ''} ago';
      }
    }
    
    if (_deadlineTime != null) {
      return 'Deadline: $dateStr at ${_deadlineTime!.format(context)}';
    } else {
      return 'Deadline: $dateStr (any time)';
    }
  }
  
  String _getScheduledPreview() {
    if (_selectedScheduledDate == null) return '';
    
    final now = DateTime.now();
    final selectedDate = DateTime(_selectedScheduledDate!.year, _selectedScheduledDate!.month, _selectedScheduledDate!.day);
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    
    String dateStr;
    if (selectedDate == today) {
      dateStr = 'Today';
    } else if (selectedDate == tomorrow) {
      dateStr = 'Tomorrow';
    } else {
      final difference = selectedDate.difference(today).inDays;
      if (difference > 0) {
        dateStr = 'In $difference day${difference > 1 ? 's' : ''}';
      } else {
        dateStr = '${difference.abs()} day${difference.abs() > 1 ? 's' : ''} ago';
      }
    }
    
    if (_scheduledTime != null) {
      return 'Scheduled: $dateStr at ${_scheduledTime!.format(context)}';
    } else {
      return 'Scheduled: $dateStr (any time)';
    }
  }
  
  Widget _buildQuickTimeChip(String label, VoidCallback onPressed) {
    return InkWell(
      onTap: _isLoading ? null : onPressed,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.blue.shade50,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Colors.blue.shade200,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.blue.shade700,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}