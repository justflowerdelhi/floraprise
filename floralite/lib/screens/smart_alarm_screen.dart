import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/scheduler_task.dart';
import '../models/smart_alert.dart';
import '../services/smart_alert_engine.dart';

class SmartAlarmScreen extends StatefulWidget {
  final SchedulerTask task;
  final SmartAlert alert;
  final AlertQueue? queue;

  const SmartAlarmScreen({
    super.key,
    required this.task,
    required this.alert,
    this.queue,
  });

  @override
  State<SmartAlarmScreen> createState() => _SmartAlarmScreenState();
}

class _SmartAlarmScreenState extends State<SmartAlarmScreen>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _countdownController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _countdownAnimation;
  Timer? _countdownTimer;
  int _remainingSeconds = 0;

  @override
  void initState() {
    super.initState();
    
    // Keep screen on
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

    // Pulse animation
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Countdown animation
    _countdownController = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    );

    // Start countdown
    _startCountdown();

    // Acknowledge alert immediately when screen opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      SmartAlertEngine.instance.acknowledgeAlert(widget.task.id!);
    });
  }

  void _startCountdown() {
    final now = DateTime.now();
    final deadline = widget.task.deadlineAt ?? widget.task.effectiveReminderAt;
    _remainingSeconds = deadline.difference(now).inSeconds;

    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _remainingSeconds--;
        if (_remainingSeconds <= 0) {
          timer.cancel();
        }
      });
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _countdownController.dispose();
    _countdownTimer?.cancel();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    SystemChrome.setPreferredOrientations(DeviceOrientation.values);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDelivery = widget.task.type == TaskType.delivery;

    return Scaffold(
      backgroundColor: _getPriorityColor(),
      body: SafeArea(
        child: Column(
          children: [
            // Status bar spacer
            const SizedBox(height: 24),
            
            // Queue indicator
            if (widget.queue != null && widget.queue!.count > 1)
              _buildQueueIndicator(),
            
            // Main content
            Expanded(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Priority badge
                      _buildPriorityBadge(),
                      
                      const SizedBox(height: 32),
                      
                      // Countdown animation
                      _buildCountdownAnimation(),
                      
                      const SizedBox(height: 32),
                      
                      // Task title
                      _buildTaskTitle(),
                      
                      const SizedBox(height: 16),
                      
                      // Order number
                      if (widget.task.linkedOrderId != null)
                        _buildOrderNumber(),
                      
                      const SizedBox(height: 8),
                      
                      // Customer info
                      if (widget.task.linkedCustomerId != null)
                        _buildCustomerInfo(),
                      
                      const SizedBox(height: 8),
                      
                      // Task type badge
                      _buildTaskTypeBadge(),
                      
                      const SizedBox(height: 48),
                      
                      // Action buttons
                      _buildActionButtons(isDelivery),
                    ],
                  ),
                ),
              ),
            ),
            
            // Bottom dismiss button
            _buildDismissButton(),
          ],
        ),
      ),
    );
  }

  Color _getPriorityColor() {
    switch (widget.alert.level) {
      case AlertLevel.critical:
        return const Color(0xFFD32F2F);
      case AlertLevel.important:
        return const Color(0xFFFF5722);
      case AlertLevel.reminder:
        return const Color(0xFF1976D2);
      case AlertLevel.info:
        return const Color(0xFF424242);
    }
  }

  Widget _buildQueueIndicator() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.queue, color: Colors.white, size: 20),
          const SizedBox(width: 8),
          Text(
            '${widget.queue!.current!.taskId} of ${widget.queue!.count}',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 8),
          if (widget.queue!.count > 1)
            TextButton(
              onPressed: _showNextInQueue,
              child: const Text(
                'Next',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPriorityBadge() {
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _pulseAnimation.value,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(30),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 12,
                  spreadRadius: 4,
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _getPriorityIcon(),
                  color: _getPriorityColor(),
                  size: 28,
                ),
                const SizedBox(width: 12),
                Text(
                  widget.alert.level.name.toUpperCase(),
                  style: TextStyle(
                    color: _getPriorityColor(),
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  IconData _getPriorityIcon() {
    switch (widget.alert.level) {
      case AlertLevel.critical:
        return Icons.warning_rounded;
      case AlertLevel.important:
        return Icons.priority_high_rounded;
      case AlertLevel.reminder:
        return Icons.notifications_active_rounded;
      case AlertLevel.info:
        return Icons.info_rounded;
    }
  }

  Widget _buildCountdownAnimation() {
    return SizedBox(
      width: 200,
      height: 200,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Background circle
          Container(
            width: 200,
            height: 200,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withOpacity(0.2),
            ),
          ),
          // Progress circle
          SizedBox(
            width: 200,
            height: 200,
            child: CustomPaint(
              painter: _CountdownPainter(
                progress: _remainingSeconds > 0 ? 1.0 : 0.0,
                color: Colors.white,
              ),
            ),
          ),
          // Time display
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _formatDuration(_remainingSeconds),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Text(
                'REMAINING',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                  letterSpacing: 2,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatDuration(int seconds) {
    if (seconds <= 0) return '00:00';
    final hours = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;
    final secs = seconds % 60;
    
    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
    }
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  Widget _buildTaskTitle() {
    return Text(
      widget.task.title,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 32,
        fontWeight: FontWeight.bold,
      ),
      textAlign: TextAlign.center,
      maxLines: 3,
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _buildOrderNumber() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.receipt_long, color: Colors.white, size: 20),
          const SizedBox(width: 8),
          Text(
            'Order #${widget.task.linkedOrderId}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomerInfo() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.person, color: Colors.white, size: 20),
          const SizedBox(width: 8),
          Text(
            'Customer ID: ${widget.task.linkedCustomerId}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTaskTypeBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white54, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _getTaskTypeIcon(),
            color: Colors.white,
            size: 18,
          ),
          const SizedBox(width: 8),
          Text(
            widget.task.type.name.toUpperCase(),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w600,
              letterSpacing: 1,
            ),
          ),
        ],
      ),
    );
  }

  IconData _getTaskTypeIcon() {
    switch (widget.task.type) {
      case TaskType.delivery:
        return Icons.local_shipping_rounded;
      case TaskType.pickup:
        return Icons.shopping_bag_rounded;
      case TaskType.appointment:
        return Icons.event_rounded;
      case TaskType.meeting:
        return Icons.groups_rounded;
      case TaskType.purchase:
        return Icons.shopping_cart_rounded;
      case TaskType.reminder:
        return Icons.alarm_rounded;
      case TaskType.personalTask:
        return Icons.task_alt_rounded;
    }
  }

  Widget _buildActionButtons(bool isDelivery) {
    final buttons = <Widget>[];

    if (isDelivery) {
      // Delivery-specific buttons
      buttons.addAll([
        _buildActionButton(
          icon: Icons.map_rounded,
          label: 'Navigate',
          onPressed: _navigateToLocation,
          color: Colors.blue,
        ),
        const SizedBox(height: 12),
        _buildActionButton(
          icon: Icons.phone_rounded,
          label: 'Call Customer',
          onPressed: _callCustomer,
          color: Colors.green,
        ),
        const SizedBox(height: 12),
        _buildActionButton(
          icon: Icons.directions_car_rounded,
          label: 'Call Driver',
          onPressed: _callDriver,
          color: Colors.orange,
        ),
        const SizedBox(height: 12),
      ]);
    }

    // Common buttons
    if (widget.task.linkedOrderId != null) {
      buttons.add(_buildActionButton(
        icon: Icons.open_in_new_rounded,
        label: 'Open Order',
        onPressed: _openOrder,
        color: Colors.purple,
      ));
      buttons.add(const SizedBox(height: 12));
    }

    buttons.add(_buildActionButton(
      icon: Icons.check_circle_rounded,
      label: 'Mark Completed',
      onPressed: _markCompleted,
      color: Colors.green,
    ));
    buttons.add(const SizedBox(height: 12));

    // Snooze buttons
    if (widget.alert.canSnooze) {
      buttons.add(Row(
        children: [
          Expanded(
            child: _buildActionButton(
              icon: Icons.snooze_rounded,
              label: '5 min',
              onPressed: () => _snooze(5),
              color: Colors.amber,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildActionButton(
              icon: Icons.snooze_rounded,
              label: '10 min',
              onPressed: () => _snooze(10),
              color: Colors.amber,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildActionButton(
              icon: Icons.snooze_rounded,
              label: '15 min',
              onPressed: () => _snooze(15),
              color: Colors.amber,
            ),
          ),
        ],
      ));
      buttons.add(const SizedBox(height: 12));
    }

    return Column(children: buttons);
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
    required Color color,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 24),
        label: Text(
          label,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }

  Widget _buildDismissButton() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: TextButton.icon(
        onPressed: _dismiss,
        icon: const Icon(Icons.close, color: Colors.white54),
        label: const Text(
          'Dismiss',
          style: TextStyle(color: Colors.white54, fontSize: 16),
        ),
      ),
    );
  }

  void _showNextInQueue() {
    // Acknowledge current and let engine advance queue
    SmartAlertEngine.instance.acknowledgeAlert(widget.task.id!);
    Navigator.of(context).pop();
  }

  void _navigateToLocation() {
    SmartAlertEngine.instance.acknowledgeAlert(widget.task.id!);
    Navigator.of(context).pop();
    // TODO: Navigate to location
  }

  void _callCustomer() {
    SmartAlertEngine.instance.acknowledgeAlert(widget.task.id!);
    Navigator.of(context).pop();
    // TODO: Call customer
  }

  void _callDriver() {
    SmartAlertEngine.instance.acknowledgeAlert(widget.task.id!);
    Navigator.of(context).pop();
    // TODO: Call driver
  }

  void _openOrder() {
    SmartAlertEngine.instance.acknowledgeAlert(widget.task.id!);
    Navigator.of(context).pop();
    // TODO: Navigate to order screen
  }

  void _markCompleted() {
    SmartAlertEngine.instance.completeAlert(widget.task.id!);
    Navigator.of(context).pop();
  }

  void _snooze(int minutes) {
    SmartAlertEngine.instance.snoozeAlert(
      widget.task.id!,
      Duration(minutes: minutes),
    );
    Navigator.of(context).pop();
  }

  void _dismiss() {
    SmartAlertEngine.instance.dismissAlert(widget.task.id!);
    Navigator.of(context).pop();
  }
}

class _CountdownPainter extends CustomPainter {
  final double progress;
  final Color color;

  _CountdownPainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 8;
    final strokeWidth = 8.0;

    // Background circle
    final backgroundPaint = Paint()
      ..color = color.withOpacity(0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;
    canvas.drawCircle(center, radius, backgroundPaint);

    // Progress arc
    if (progress > 0) {
      final progressPaint = Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round;
      
      final startAngle = -math.pi / 2;
      final sweepAngle = 2 * math.pi * progress;
      
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        false,
        progressPaint,
      );
    }
  }

  @override
  bool shouldRepaint(_CountdownPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
