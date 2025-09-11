# 🔊 Background Audio Fix for Pomodoro Timer

## Problem Solved
Fixed the issue where Pomodoro session completion sounds would not play when the app was backgrounded or when the user wasn't actively using the app.

## Root Cause
- Mobile operating systems (iOS and Android) heavily restrict background audio playback for apps that aren't active music/media players
- The `AudioPlayer` from `audioplayers` package gets throttled or completely blocked when the app is backgrounded
- Custom audio files only played when the app was in the foreground

## Solution Implemented

### 1. Notification-Based Audio Playback
- **Primary solution**: Use notification system's built-in sound playback capability
- Notifications can play custom sounds even when the app is completely backgrounded
- Added custom sound files to platform-specific resource directories

### 2. Platform-Specific Sound Resources
- **Android**: Added `.mp3` files to `android/app/src/main/res/raw/`
  - `work_complete.mp3`
  - `break_complete.mp3` 
  - `session_complete.mp3`
- **iOS**: Added `.mp3` files to `ios/Runner/` 
  - These need to be added to the Xcode project bundle

### 3. Enhanced Notification Configuration
- **Android**: 
  - Uses `RawResourceAndroidNotificationSound` to play custom sounds
  - Set `importance: Importance.high` for reliable background playback
  - Added `category: AndroidNotificationCategory.alarm` to bypass Do Not Disturb
- **iOS**:
  - Uses `DarwinNotificationDetails` with custom sound files
  - Set `interruptionLevel: InterruptionLevel.timeSensitive` for priority playback

### 4. Improved AudioService Configuration
- Enhanced audio context configuration for better background behavior
- Set `AndroidUsageType.notification` for alert-style audio
- Configured iOS audio session for `AVAudioSessionCategory.playback`
- Added proper audio focus management

### 5. Dual Audio Approach
- **Foreground**: Uses AudioService for rich haptic feedback + audio
- **Background**: Relies on notification sound for guaranteed playback
- Both trigger simultaneously to ensure sound plays regardless of app state

## Files Modified

### Core Service Files
- `lib/core/services/notification_service.dart`
  - Enhanced `showSessionCompletionNotification()` with custom sounds
  - Added platform-specific sound configuration
  - Improved notification priority and category settings

- `lib/core/services/audio_service.dart`
  - Enhanced audio context configuration
  - Better background audio session management
  - Improved error handling and logging

### Pomodoro Logic
- `lib/features/pomodoro/presentation/bloc/pomodoro_bloc.dart`
  - Enhanced session completion handling
  - Added detailed logging for background audio debugging
  - Ensures both audio service and notification sounds trigger

### Platform Configuration
- `android/app/src/main/AndroidManifest.xml`
  - Added necessary background audio permissions
  - Added notification and wake lock permissions

### Resource Files
- Added sound files to both platforms:
  - `android/app/src/main/res/raw/[sound_files].mp3`
  - `ios/Runner/[sound_files].mp3`

## How It Works Now

### Session Completion Flow
1. Timer reaches zero in `PomodoroBloc`
2. **Immediate audio playback** via `AudioService` (foreground only)
3. **Notification with custom sound** via `NotificationService` (works in background)
4. Haptic feedback for tactile confirmation
5. UI state update to show completion

### Background Behavior
- When app is **backgrounded**: Notification sound plays reliably
- When app is **foreground**: Both notification and AudioService sounds play
- When device is **locked**: Notification sound still plays
- **Do Not Disturb**: Alarm category notifications can bypass (user setting dependent)

## Testing Scenarios

### ✅ Test Cases Covered
1. **App in foreground**: Both audio service and notification sounds play
2. **App backgrounded**: Notification sound plays reliably  
3. **Device locked**: Notification sound still audible
4. **Different session types**: Different sounds for work/break/long break completion
5. **Sound disabled in settings**: Respects user preferences

### 🔧 How to Test
1. Start a Pomodoro session (set to 1 minute for quick testing)
2. Background the app or lock device
3. Wait for session to complete
4. Should hear completion sound even when app is not visible
5. Check notification shows with appropriate message

## Permissions Required

### Android
- `WAKE_LOCK`: Keep device awake for audio playback
- `POST_NOTIFICATIONS`: Show completion notifications
- `MODIFY_AUDIO_SETTINGS`: Configure audio for alerts
- `FOREGROUND_SERVICE`: Background audio capability

### iOS
- Notification permissions (requested automatically)
- Sound files must be added to Xcode project bundle

## Technical Details

### Sound File Requirements
- **Format**: MP3 preferred (cross-platform support)
- **Duration**: Keep under 3 seconds for quick alerts
- **Quality**: 16kHz sample rate sufficient for notification sounds
- **Volume**: Pre-normalized to avoid sudden loud sounds

### Notification Channel Strategy
- **session_alerts**: High importance channel with custom sounds
- **pomodoro_timer**: Low importance for ongoing timer notifications
- Separate channels allow different sound behaviors

### Fallback Strategy
1. **Primary**: Custom notification sounds (most reliable)
2. **Secondary**: AudioService with enhanced configuration  
3. **Tertiary**: System default notification sound
4. **Last resort**: Haptic feedback only

## Future Improvements
- Add user option to select different completion sounds
- Implement progressive volume increase for deep focus sessions
- Add sound previews in settings
- Consider using WorkManager for guaranteed background execution

## Troubleshooting

### If sounds still don't play in background:
1. Check device notification settings for the app
2. Verify Do Not Disturb settings allow alarms/timers
3. Ensure sound files are properly embedded in platform resources
4. Check app has notification permissions granted
5. Test with different session types (work vs break)
