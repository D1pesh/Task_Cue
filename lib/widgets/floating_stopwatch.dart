import 'package:flutter/material.dart';
import 'dart:async';

/// Floating Stopwatch Widget with Pause/Resume - Small Hovering Button
class FloatingStopwatch extends StatefulWidget {
  final String taskTitle;
  final VoidCallback onPause;
  final VoidCallback onResume;
  final VoidCallback onStop;
  final bool isPaused;
  final int elapsedSeconds;
  final ValueChanged<int>? onSnooze;
  final int currentXP;
  final int pauseCount;
  final int snoozeCount;

  const FloatingStopwatch({
    super.key,
    required this.taskTitle,
    required this.onPause,
    required this.onResume,
    required this.onStop,
    this.isPaused = false,
    this.elapsedSeconds = 0,
    this.onSnooze,
    this.currentXP = 0,
    this.pauseCount = 0,
    this.snoozeCount = 0,
  });

  @override
  State<FloatingStopwatch> createState() => _FloatingStopwatchState();
}

class _FloatingStopwatchState extends State<FloatingStopwatch> 
    with SingleTickerProviderStateMixin {
  Timer? _timer;
  late int _seconds;
  bool _expanded = false;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _seconds = widget.elapsedSeconds;
    if (!widget.isPaused) {
      _startTimer();
    }
    
    // Pulse animation for running state
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.08).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    if (!widget.isPaused) {
      _pulseController.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(FloatingStopwatch oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isPaused && !oldWidget.isPaused) {
      _stopTimer();
      _pulseController.stop();
    } else if (!widget.isPaused && oldWidget.isPaused) {
      _startTimer();
      _pulseController.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!widget.isPaused) {
        setState(() {
          _seconds++;
        });
      }
    });
  }

  void _stopTimer() {
    _timer?.cancel();
  }

  String _formatTime(int seconds) {
    final hours = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;
    final secs = seconds % 60;
    
    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
    }
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: widget.isPaused ? 1.0 : _pulseAnimation.value,
          child: child,
        );
      },
      child: GestureDetector(
        onTap: () {
          setState(() {
            _expanded = !_expanded;
          });
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          padding: EdgeInsets.symmetric(
            horizontal: _expanded ? 16 : 12,
            vertical: _expanded ? 12 : 8,
          ),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: widget.isPaused
                  ? [const Color(0xFFFF9800), const Color(0xFFF57C00)]
                  : [const Color(0xFF4CAF50), const Color(0xFF2E7D32)],
            ),
            borderRadius: BorderRadius.circular(_expanded ? 16 : 28),
            boxShadow: [
              BoxShadow(
                color: (widget.isPaused 
                    ? Colors.orange 
                    : Colors.green).withAlpha((255 * 0.4).toInt()),
                blurRadius: 16,
                spreadRadius: 2,
                offset: const Offset(0, 4),
              ),
              BoxShadow(
                color: Colors.black.withAlpha((255 * 0.2).toInt()),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Timer Display
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    widget.isPaused ? Icons.pause : Icons.timer,
                    color: Colors.white,
                    size: _expanded ? 20 : 16,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _formatTime(_seconds),
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: _expanded ? 16 : 14,
                      fontWeight: FontWeight.bold,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withAlpha((255 * 0.2).toInt()),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.stars, color: Colors.white, size: 14),
                        const SizedBox(width: 4),
                        Text(
                          '${widget.currentXP} XP',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              
              // Expanded Controls
              if (_expanded) ...[
                const SizedBox(height: 12),
                
                // Task Title
                Container(
                  constraints: const BoxConstraints(maxWidth: 200),
                  child: Text(
                    widget.taskTitle,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                
                const SizedBox(height: 12),
                
                // Control Buttons
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Pause/Resume Button
                    GestureDetector(
                      onTap: widget.isPaused ? widget.onResume : widget.onPause,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withAlpha((255 * 0.2).toInt()),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Icon(
                          widget.isPaused ? Icons.play_arrow : Icons.pause,
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
                    ),
                    
                    const SizedBox(width: 12),
                    
                    // Snooze Button
                    GestureDetector(
                      onTap: () => _showSnoozeDialog(context),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withAlpha((255 * 0.2).toInt()),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Icon(
                          Icons.snooze,
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
                    ),
                    
                    const SizedBox(width: 12),
                    
                    // Stop Button
                    GestureDetector(
                      onTap: () => _showStopDialog(context),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withAlpha((255 * 0.2).toInt()),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Icon(
                          Icons.stop,
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _showSnoozeDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => SnoozeDialog(
        onSnooze: (minutes) {
          widget.onSnooze?.call(minutes);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Task snoozed for $minutes minutes'),
              backgroundColor: Colors.orange,
            ),
          );
        },
      ),
    );
  }

  

  void _showStopDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Stop Timer'),
        content: const Text('Are you sure you want to stop the timer and complete this task?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              widget.onStop();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Stop & Complete'),
          ),
        ],
      ),
    );
  }
}

/// Draggable Floating Timer Wrapper
class DraggableFloatingTimer extends StatefulWidget {
  final Widget child;
  
  const DraggableFloatingTimer({
    super.key,
    required this.child,
  });

  @override
  State<DraggableFloatingTimer> createState() => _DraggableFloatingTimerState();
}

class _DraggableFloatingTimerState extends State<DraggableFloatingTimer> {
  Offset _position = const Offset(20, 100);

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    
    return Positioned(
      left: _position.dx,
      top: _position.dy,
      child: Draggable(
        feedback: Material(
          color: Colors.transparent,
          child: widget.child,
        ),
        childWhenDragging: Opacity(
          opacity: 0.5,
          child: widget.child,
        ),
        onDragEnd: (details) {
          setState(() {
            _position = Offset(
              details.offset.dx.clamp(0, screenSize.width - 100),
              details.offset.dy.clamp(0, screenSize.height - 100),
            );
          });
        },
        child: widget.child,
      ),
    );
  }
}

/// Snooze Dialog
class SnoozeDialog extends StatefulWidget {
  final Function(int) onSnooze;
  
  const SnoozeDialog({
    super.key,
    required this.onSnooze,
  });

  @override
  State<SnoozeDialog> createState() => _SnoozeDialogState();
}

class _SnoozeDialogState extends State<SnoozeDialog> {
  int _selectedMinutes = 10;
  final List<int> _snoozeOptions = [5, 10, 15, 30, 60];

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Row(
              children: [
                Icon(Icons.snooze, color: Colors.orange, size: 24),
                const SizedBox(width: 12),
                const Text(
                  'Snooze Task',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            const Text(
              'How long would you like to snooze this task?',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
            
            const SizedBox(height: 20),
            
            // Snooze Options
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _snoozeOptions.map((minutes) {
                final isSelected = minutes == _selectedMinutes;
                
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedMinutes = minutes;
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? Colors.orange
                          : Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected
                            ? Colors.orange
                            : Colors.transparent,
                        width: 2,
                      ),
                    ),
                    child: Text(
                      '$minutes min',
                      style: TextStyle(
                        color: isSelected ? Colors.white : Colors.black87,
                        fontWeight: isSelected
                            ? FontWeight.bold
                            : FontWeight.normal,
                        fontSize: 14,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            
            const SizedBox(height: 24),
            
            // Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      widget.onSnooze(_selectedMinutes);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Snooze'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
