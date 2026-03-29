class AppConstants {
  // App Info
  static const String appName = 'TimeWarden';
  static const String appVersion = '1.0.0';

  // Firestore Collections
  static const String usersCollection = 'users';
  static const String habitsCollection = 'habits';
  static const String journalCollection = 'journal';
  static const String pomodoroCollection = 'pomodoros';
  static const String streaksCollection = 'streaks';

  // Habit Categories
  static const List<String> habitCategories = [
    'Health',
    'Learning',
    'Productivity',
    'Fitness',
    'Mindfulness',
    'Social',
    'Creative',
    'Other',
  ];

  // Default Colors for Habits
  static const List<String> habitColors = [
    '#FF6B6B', // Red
    '#4ECDC4', // Teal
    '#45B7D1', // Blue
    '#96CEB4', // Green
    '#FFEAA7', // Yellow
    '#DDA0DD', // Plum
    '#98D8C8', // Mint
    '#F7DC6F', // Light Yellow
  ];

  // Animation Durations
  static const Duration shortAnimation = Duration(milliseconds: 200);
  static const Duration mediumAnimation = Duration(milliseconds: 400);
  static const Duration longAnimation = Duration(milliseconds: 600);

  // Spacing
  static const double paddingSmall = 8.0;
  static const double paddingMedium = 16.0;
  static const double paddingLarge = 24.0;
  static const double paddingXLarge = 32.0;

  // Border Radius
  static const double radiusSmall = 8.0;
  static const double radiusMedium = 12.0;
  static const double radiusLarge = 16.0;

  // Text Limits
  static const int habitNameMaxLength = 50;
  static const int habitDescriptionMaxLength = 200;
  static const int journalEntryMaxLength = 5000;
}
