# Notification System

## Purpose

A notification system provides immediate feedback to players about important events: achievements unlocked, items collected, errors, and game state changes. It enhances user experience by making the game feel responsive and rewarding.

## Dependencies

```yaml
dependencies:
  flutter:
    sdk: flutter
```

No additional packages required - uses Flutter's built-in SnackBar and custom overlays.

---

## Notification Types

### 1. Achievement Unlocks
**When**: Player completes an achievement
**Style**: Celebratory, prominent, with icon and sound
**Duration**: 3-4 seconds

### 2. Item Collection
**When**: Player collects currency, power-ups, etc.
**Style**: Brief, non-intrusive
**Duration**: 1-2 seconds

### 3. Game Events
**When**: Level up, new high score, etc.
**Style**: Informative, encouraging
**Duration**: 2-3 seconds

### 4. Errors/Warnings
**When**: Purchase failed, invalid action, etc.
**Style**: Clear, explaining the issue
**Duration**: 3-4 seconds

### 5. Success Confirmations
**When**: Purchase completed, settings saved, etc.
**Style**: Positive, reassuring
**Duration**: 2-3 seconds

---

## Implementation Patterns

### 1. SnackBar Notifications (Built-in)

**Best for**: Quick, non-critical messages

```dart
void showNotification(BuildContext context, {
  required String message,
  NotificationType type = NotificationType.info,
  Duration duration = const Duration(seconds: 2),
}) {
  final color = _getColorForType(type);
  final icon = _getIconForType(type);

  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Row(
        children: [
          Icon(icon, color: Colors.white),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
      backgroundColor: color,
      duration: duration,
      behavior: SnackBarBehavior.floating,
      margin: EdgeInsets.all(16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      action: type == NotificationType.error
          ? SnackBarAction(
              label: 'Dismiss',
              textColor: Colors.white,
              onPressed: () {
                ScaffoldMessenger.of(context).hideCurrentSnackBar();
              },
            )
          : null,
    ),
  );
}

enum NotificationType { success, error, warning, info }

Color _getColorForType(NotificationType type) {
  switch (type) {
    case NotificationType.success:
      return AppColors.success;
    case NotificationType.error:
      return AppColors.error;
    case NotificationType.warning:
      return AppColors.warning;
    case NotificationType.info:
      return AppColors.info;
  }
}

IconData _getIconForType(NotificationType type) {
  switch (type) {
    case NotificationType.success:
      return Icons.check_circle;
    case NotificationType.error:
      return Icons.error;
    case NotificationType.warning:
      return Icons.warning;
    case NotificationType.info:
      return Icons.info;
  }
}
```

**Usage**:
```dart
showNotification(
  context,
  message: 'Skin purchased!',
  type: NotificationType.success,
);

showNotification(
  context,
  message: 'Not enough crystals',
  type: NotificationType.error,
  duration: Duration(seconds: 3),
);
```

---

### 2. Achievement Unlock Notification

**Special case**: Prominent, celebratory notification

```dart
void showAchievementUnlock(
  BuildContext context,
  Achievement achievement,
) {
  // Play sound
  ServiceLocator.audioService.playSound('achievement.mp3');

  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Container(
        padding: EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            // Trophy icon
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.neonAmber.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.emoji_events,
                color: AppColors.neonAmber,
                size: 32,
              ),
            ),
            SizedBox(width: 16),

            // Text content
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Achievement Unlocked!',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textWhite70,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    achievement.name,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.neonAmber,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      backgroundColor: AppColors.darkNavy,
      duration: Duration(seconds: 4),
      behavior: SnackBarBehavior.floating,
      margin: EdgeInsets.all(16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: AppColors.neonAmber,
          width: 2,
        ),
      ),
    ),
  );
}
```

**Integration with AchievementService**:
```dart
// In GameScreen or main app:
@override
void initState() {
  super.initState();

  _achievementSubscription = widget.achievementService
      .onAchievementUnlocked
      .listen((achievement) {
    showAchievementUnlock(context, achievement);
  });
}

@override
void dispose() {
  _achievementSubscription?.cancel();
  super.dispose();
}
```

---

### 3. Custom Toast Overlay (Advanced)

**Best for**: In-game notifications that don't interrupt gameplay

```dart
class GameToast {
  static OverlayEntry? _currentEntry;

  static void show(
    BuildContext context, {
    required String message,
    IconData? icon,
    Duration duration = const Duration(seconds: 2),
  }) {
    // Remove existing toast
    _currentEntry?.remove();

    // Create overlay entry
    _currentEntry = OverlayEntry(
      builder: (context) => _GameToastWidget(
        message: message,
        icon: icon,
        duration: duration,
        onDismiss: () {
          _currentEntry?.remove();
          _currentEntry = null;
        },
      ),
    );

    // Insert into overlay
    Overlay.of(context).insert(_currentEntry!);
  }
}

class _GameToastWidget extends StatefulWidget {
  final String message;
  final IconData? icon;
  final Duration duration;
  final VoidCallback onDismiss;

  const _GameToastWidget({
    required this.message,
    required this.icon,
    required this.duration,
    required this.onDismiss,
  });

  @override
  State<_GameToastWidget> createState() => _GameToastWidgetState();
}

class _GameToastWidgetState extends State<_GameToastWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: Duration(milliseconds: 300),
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(
      begin: Offset(0, -1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    ));

    _fadeAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(_controller);

    _controller.forward();

    // Auto-dismiss
    Future.delayed(widget.duration, () {
      _controller.reverse().then((_) => widget.onDismiss());
    });
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 80,
      left: 16,
      right: 16,
      child: SlideTransition(
        position: _slideAnimation,
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Material(
            color: Colors.transparent,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.overlayDark,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: AppColors.neonCyan,
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (widget.icon != null) ...[
                    Icon(widget.icon, color: AppColors.neonCyan, size: 20),
                    SizedBox(width: 12),
                  ],
                  Expanded(
                    child: Text(
                      widget.message,
                      style: TextStyle(
                        color: AppColors.textWhite,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
```

**Usage**:
```dart
// In-game (doesn't require Scaffold)
GameToast.show(
  context,
  message: 'Level 5!',
  icon: Icons.trending_up,
);
```

---

### 4. HUD Feedback (In-Game)

**Best for**: Real-time stat updates during gameplay

```dart
class HudFeedback extends StatefulWidget {
  final String value;
  final IconData icon;

  const HudFeedback({
    required this.value,
    required this.icon,
  });

  @override
  State<HudFeedback> createState() => _HudFeedbackState();
}

class _HudFeedbackState extends State<HudFeedback>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  String _previousValue = '';

  @override
  void initState() {
    super.initState();
    _previousValue = widget.value;

    _controller = AnimationController(
      duration: Duration(milliseconds: 200),
      vsync: this,
    );
  }

  @override
  void didUpdateWidget(HudFeedback oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.value != widget.value) {
      // Value changed - pulse animation
      _controller.forward(from: 0);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final scale = 1.0 + (0.2 * _controller.value);
        return Transform.scale(
          scale: scale,
          child: child,
        );
      },
      child: HudStatIndicator(
        icon: widget.icon,
        value: widget.value,
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
```

---

### 5. Dialog Notifications

**Best for**: Important events requiring acknowledgment

```dart
Future<void> showSuccessDialog(
  BuildContext context, {
  required String title,
  required String message,
}) async {
  return GameDialog.show(
    context: context,
    title: title,
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.check_circle,
          color: AppColors.success,
          size: 64,
        ),
        SizedBox(height: 16),
        Text(
          message,
          style: TextStyle(
            fontSize: 16,
            color: AppColors.textWhite,
          ),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: 24),
        GameButton(
          label: 'OK',
          onPressed: () => Navigator.pop(context),
        ),
      ],
    ),
  );
}
```

---

## Notification Manager Service

### Centralized Notification Handler

```dart
class NotificationManager {
  static void showMessage(
    BuildContext context, {
    required String message,
    NotificationType type = NotificationType.info,
    bool playSound = true,
  }) {
    showNotification(context, message: message, type: type);

    if (playSound) {
      final sound = type == NotificationType.error
          ? 'error.mp3'
          : type == NotificationType.success
              ? 'success.mp3'
              : 'notification.mp3';

      ServiceLocator.audioService.playSound(sound, volume: 0.5);
    }
  }

  static void showAchievement(
    BuildContext context,
    Achievement achievement,
  ) {
    showAchievementUnlock(context, achievement);
  }

  static void showError(
    BuildContext context,
    String message,
  ) {
    showMessage(
      context,
      message: message,
      type: NotificationType.error,
    );
  }

  static void showSuccess(
    BuildContext context,
    String message,
  ) {
    showMessage(
      context,
      message: message,
      type: NotificationType.success,
    );
  }
}
```

---

## Best Practices

1. **Don't overwhelm**: Limit concurrent notifications
2. **Appropriate duration**: 2-4 seconds for most messages
3. **Clear language**: Short, actionable messages
4. **Audio feedback**: Pair visual with sound when appropriate
5. **Positioning**: Top for important, bottom for casual
6. **Non-blocking**: Use SnackBar/Toast, not dialogs for minor events
7. **Consistent styling**: Use theme colors and patterns

---

## Common Use Cases

### Purchase Success
```dart
NotificationManager.showSuccess(
  context,
  'Skin purchased successfully!',
);
```

### Purchase Failed
```dart
NotificationManager.showError(
  context,
  'Not enough crystals to purchase this skin',
);
```

### Level Up
```dart
GameToast.show(
  context,
  message: 'Level ${gameLoopManager.level}!',
  icon: Icons.trending_up,
);
```

### New High Score
```dart
showSuccessDialog(
  context,
  title: 'New High Score!',
  message: 'You scored ${score} points!',
);
```

---

## Testing Checklist

- [ ] Achievement notifications appear on unlock
- [ ] Error messages show for failed actions
- [ ] Success messages show for completed actions
- [ ] Notifications don't block gameplay
- [ ] Sound plays with notifications (if enabled)
- [ ] Multiple notifications queue properly
- [ ] Notifications dismiss automatically
- [ ] Manual dismiss works (for errors)

---

## Next Steps

After implementing notifications:
- Connect to **Achievement System** (04) for unlock events
- Integrate with **Audio System** (03) for notification sounds
- Use in **Shared UI Components** (01) for user feedback
