# Calendar Reminders Implementation Guide for Flutter

## Overview

This guide provides comprehensive guidelines for implementing calendar reminders in Flutter apps that work reliably across all Android devices and manufacturers. It addresses common issues encountered with different OEM customizations and calendar providers.

## Common Issues and Root Causes

### Device-Specific Problems

1. **Samsung Devices (OneUI)**
   - Stricter Event field validation
   - Multiple calendar providers (Samsung Calendar + Google Calendar)
   - Required fields: `eventId`, `location`, `allDay`

2. **Xiaomi Devices (MIUI)**
   - Custom calendar app with different requirements
   - Sometimes requires explicit timezone handling
   - May have permission restrictions

3. **OnePlus/Oppo (ColorOS/OxygenOS)**
   - Calendar provider inconsistencies
   - May require specific calendar selection logic

4. **Google Pixel/Stock Android**
   - Generally more permissive but can have API level differences
   - Google Calendar integration specifics

### Common Error Scenarios

- "Calendar ID must be provided" - null or empty calendar ID
- "Event with title and start/end date required" - missing required fields
- "Permission denied" - insufficient calendar permissions
- "No writable calendars found" - all calendars are read-only
- "Invalid timezone" - timezone handling issues

## Implementation Best Practices

### 1. Dependency Setup

```yaml
dependencies:
  device_calendar: ^4.3.0
  permission_handler: ^12.0.1
  timezone: ^0.10.1
```

### 2. Permission Handling

```dart
import 'package:permission_handler/permission_handler.dart';

Future<bool> _requestCalendarPermission() async {
  var status = await Permission.calendar.status;
  
  if (status.isDenied) {
    status = await Permission.calendar.request();
  }
  
  if (status.isPermanentlyDenied) {
    // Guide user to settings
    await openAppSettings();
    return false;
  }
  
  return status.isGranted;
}
```

### 3. Calendar Selection Logic

```dart
import 'package:device_calendar/device_calendar.dart';

Future<Calendar?> _selectBestCalendar(DeviceCalendarPlugin plugin) async {
  final calendarsResult = await plugin.retrieveCalendars();
  
  if (!calendarsResult.isSuccess || 
      calendarsResult.data == null || 
      calendarsResult.data!.isEmpty) {
    return null;
  }
  
  final calendars = calendarsResult.data!;
  
  // Step 1: Find writable calendars
  final writableCalendars = calendars
      .where((c) => c.isReadOnly == false && 
                   c.id != null && 
                   c.id!.isNotEmpty)
      .toList();
  
  if (writableCalendars.isEmpty) {
    // Fallback: use any available calendar
    final anyCalendar = calendars.firstWhere(
      (c) => c.id != null && c.id!.isNotEmpty,
      orElse: () => calendars.first,
    );
    return anyCalendar;
  }
  
  // Step 2: Prefer Google Calendar if available
  final googleCalendar = writableCalendars.firstWhere(
    (c) => c.name?.toLowerCase().contains('google') == true ||
           c.accountName?.toLowerCase().contains('google') == true,
    orElse: () => writableCalendars.first,
  );
  
  return googleCalendar;
}
```

### 4. Robust Event Creation

```dart
import 'package:timezone/timezone.dart' as tz;

Future<bool> createCalendarReminder({
  required String title,
  required String description,
  required DateTime startTime,
  required Duration duration,
  String? location,
  int reminderMinutes = 30,
}) async {
  try {
    final plugin = DeviceCalendarPlugin();
    
    // Step 1: Check permissions
    if (!await _requestCalendarPermission()) {
      _showError('Calendar permission is required to set reminders.');
      return false;
    }
    
    // Step 2: Select calendar
    final calendar = await _selectBestCalendar(plugin);
    if (calendar?.id == null) {
      _showError('No suitable calendar found on device.');
      return false;
    }
    
    print('Using calendar: ${calendar!.name} (ID: ${calendar.id})');
    
    // Step 3: Prepare event data
    final tz.TZDateTime tzStartTime = tz.TZDateTime.from(startTime, tz.local);
    final tz.TZDateTime tzEndTime = tz.TZDateTime.from(
      startTime.add(duration), 
      tz.local
    );
    
    // Step 4: Create event with all required fields
    final event = Event(
      calendar.id!,
      // Required fields
      eventId: null, // Let the system generate
      title: title,
      start: tzStartTime,
      end: tzEndTime,
      
      // Recommended fields (especially for Samsung)
      description: description,
      location: location ?? '',
      allDay: false,
      
      // Reminder setup
      reminders: reminderMinutes > 0 ? [Reminder(minutes: reminderMinutes)] : null,
      
      // Additional stability fields
      availability: Availability.Busy,
      status: EventStatus.Confirmed,
    );
    
    print('Creating event: $title at $tzStartTime');
    
    // Step 5: Create event with error handling
    final result = await plugin.createOrUpdateEvent(event);
    
    if (result?.isSuccess == true) {
      print('Event created successfully');
      _showSuccess('Reminder set successfully!');
      return true;
    } else {
      final errorMsg = result?.errors?.map((e) => e.errorMessage).join(', ') ?? 'Unknown error';
      print('Event creation failed: $errorMsg');
      _showError('Failed to create reminder: $errorMsg');
      return false;
    }
    
  } catch (e) {
    print('Calendar reminder error: $e');
    _showError('Error creating reminder: ${e.toString()}');
    return false;
  }
}
```

### 5. Error Handling and User Feedback

```dart
void _showError(String message) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message),
      backgroundColor: Colors.red,
      action: SnackBarAction(
        label: 'Retry',
        onPressed: () {
          // Retry logic
        },
      ),
    ),
  );
}

void _showSuccess(String message) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message),
      backgroundColor: Colors.green,
    ),
  );
}
```

## Complete Working Example

```dart
class CalendarReminderService {
  final DeviceCalendarPlugin _plugin = DeviceCalendarPlugin();
  
  Future<bool> setMatchReminder({
    required String homeTeam,
    required String awayTeam,
    required DateTime matchTime,
    String? venue,
  }) async {
    final title = 'Match: $homeTeam vs $awayTeam';
    final description = 'Football match reminder from Luckia Sports Lounge';
    
    return await createCalendarReminder(
      title: title,
      description: description,
      startTime: matchTime,
      duration: const Duration(hours: 2),
      location: venue ?? 'Luckia Sports Lounge',
      reminderMinutes: 30,
    );
  }
  
  // Implementation of createCalendarReminder method here...
}
```

## Testing Strategy

### Device Testing Checklist

Test on the following device categories:

1. **Samsung Devices** (Galaxy S, Note, A series)
   - OneUI 4.0+ with Samsung Calendar
   - Google Calendar as default
   - Mixed calendar setup

2. **Xiaomi Devices** (Mi, Redmi)
   - MIUI Calendar
   - Google Calendar integration
   - Permission restrictions

3. **Google Pixel** (Stock Android)
   - Pure Google Calendar
   - Different Android API levels

4. **OnePlus/Oppo** (OxygenOS/ColorOS)
   - Custom calendar implementations

5. **Other Manufacturers** (Huawei, Motorola, etc.)

### Test Scenarios

For each device, verify:

- [ ] Permission request flow
- [ ] Calendar selection logic
- [ ] Event creation success
- [ ] Reminder notification
- [ ] Error handling for denied permissions
- [ ] Multiple calendar app scenarios
- [ ] Timezone handling
- [ ] Long event titles/descriptions

### Debug Information to Collect

When issues occur, collect:

```dart
// Add this debug logging
void logCalendarDebugInfo() async {
  final calendarsResult = await _plugin.retrieveCalendars();
  print('=== CALENDAR DEBUG INFO ===');
  print('Calendars result success: ${calendarsResult.isSuccess}');
  print('Number of calendars: ${calendarsResult.data?.length ?? 0}');
  
  calendarsResult.data?.forEach((calendar) {
    print('Calendar: ${calendar.name}');
    print('  ID: ${calendar.id}');
    print('  Account: ${calendar.accountName}');
    print('  Read-only: ${calendar.isReadOnly}');
    print('  Default: ${calendar.isDefault}');
    print('  Color: ${calendar.color}');
  });
  print('=== END DEBUG INFO ===');
}
```

## Common Pitfalls to Avoid

1. **Don't assume calendar availability**
   - Always check if calendars exist and are writable

2. **Don't ignore timezone handling**
   - Use `tz.TZDateTime` for proper timezone support

3. **Don't skip field validation**
   - Validate calendar ID before creating events
   - Provide all recommended Event fields

4. **Don't forget error handling**
   - Handle null results and error states gracefully

5. **Don't hardcode calendar selection**
   - Implement flexible calendar selection logic

6. **Don't ignore permissions**
   - Always check and request permissions properly

## Android API Level Considerations

- **API 23+**: Runtime permissions required
- **API 26+**: Notification channels for reminders
- **API 29+**: Scoped storage affects some calendar operations
- **API 31+**: Exact alarm permissions may be needed

## Troubleshooting Guide

### Issue: "No calendars found"
**Solutions:**
- Check calendar permissions
- Verify calendar apps are installed
- Check for device-specific calendar restrictions

### Issue: "Event creation failed"
**Solutions:**
- Validate all required Event fields
- Check calendar write permissions
- Verify timezone handling
- Add debug logging to identify specific error

### Issue: "Reminder not showing"
**Solutions:**
- Check notification permissions
- Verify reminder time settings
- Test with different reminder intervals
- Check device notification settings

## Conclusion

Following these guidelines ensures reliable calendar reminder functionality across all Android devices. The key is defensive programming: validate everything, handle errors gracefully, and provide clear user feedback.

Regular testing on different devices and Android versions is essential for maintaining compatibility as the ecosystem evolves.