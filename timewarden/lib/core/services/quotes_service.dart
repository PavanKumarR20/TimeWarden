import 'dart:math';

class QuotesService {
  static final List<Quote> _quotes = [
    // Productivity & Time Management
    const Quote(
      text: "Time is what we want most, but what we use worst.",
      author: "William Penn",
    ),
    const Quote(
      text:
          "The key is not to prioritize what's on your schedule, but to schedule your priorities.",
      author: "Stephen Covey",
    ),
    const Quote(
      text: "You may delay, but time will not.",
      author: "Benjamin Franklin",
    ),
    const Quote(
      text: "Focus on being productive instead of busy.",
      author: "Tim Ferriss",
    ),
    const Quote(
      text: "The way to get started is to quit talking and begin doing.",
      author: "Walt Disney",
    ),

    // Motivation & Success
    const Quote(
      text:
          "Success is not final, failure is not fatal: it is the courage to continue that counts.",
      author: "Winston Churchill",
    ),
    const Quote(
      text: "The only way to do great work is to love what you do.",
      author: "Steve Jobs",
    ),
    const Quote(
      text: "Don't watch the clock; do what it does. Keep going.",
      author: "Sam Levenson",
    ),
    const Quote(
      text: "Your limitation—it's only your imagination.",
      author: "Unknown",
    ),
    const Quote(
      text: "Push yourself, because no one else is going to do it for you.",
      author: "Unknown",
    ),

    // Growth & Persistence
    const Quote(
      text: "The expert in anything was once a beginner.",
      author: "Helen Hayes",
    ),
    const Quote(
      text: "Every moment is a fresh beginning.",
      author: "T.S. Eliot",
    ),
    const Quote(
      text: "It always seems impossible until it's done.",
      author: "Nelson Mandela",
    ),
    const Quote(
      text: "Small progress is still progress.",
      author: "Unknown",
    ),
    const Quote(
      text:
          "You don't have to be great to get started, but you have to get started to be great.",
      author: "Les Brown",
    ),

    // Focus & Mindfulness
    const Quote(
      text:
          "Concentrate all your thoughts upon the work at hand. The sun's rays do not burn until brought to a focus.",
      author: "Alexander Graham Bell",
    ),
    const Quote(
      text: "Quality is not an act, it is a habit.",
      author: "Aristotle",
    ),
    const Quote(
      text: "What you do today can improve all your tomorrows.",
      author: "Ralph Marston",
    ),
    const Quote(
      text: "The future depends on what you do today.",
      author: "Mahatma Gandhi",
    ),
    const Quote(
      text: "Today is the first day of the rest of your life.",
      author: "John Denver",
    ),

    // Habits & Consistency
    const Quote(
      text:
          "We are what we repeatedly do. Excellence, then, is not an act, but a habit.",
      author: "Aristotle",
    ),
    const Quote(
      text: "Habits are the compound interest of self-improvement.",
      author: "James Clear",
    ),
    const Quote(
      text: "The secret of getting ahead is getting started.",
      author: "Mark Twain",
    ),
    const Quote(
      text: "A year from now you may wish you had started today.",
      author: "Karen Lamb",
    ),
    const Quote(
      text: "Progress, not perfection.",
      author: "Unknown",
    ),
  ];

  /// Get a quote for today based on the current date
  /// This ensures the same quote appears all day
  static Quote getQuoteOfTheDay() {
    final now = DateTime.now();
    final dayOfYear = now.difference(DateTime(now.year, 1, 1)).inDays;
    final index = dayOfYear % _quotes.length;
    return _quotes[index];
  }

  /// Get a random quote (for testing or variety)
  static Quote getRandomQuote() {
    final random = Random();
    return _quotes[random.nextInt(_quotes.length)];
  }

  /// Get all quotes
  static List<Quote> getAllQuotes() => List.unmodifiable(_quotes);

  /// Get quotes by category/theme
  static List<Quote> getQuotesByTheme(QuoteTheme theme) {
    switch (theme) {
      case QuoteTheme.productivity:
        return _quotes.take(5).toList();
      case QuoteTheme.motivation:
        return _quotes.skip(5).take(5).toList();
      case QuoteTheme.growth:
        return _quotes.skip(10).take(5).toList();
      case QuoteTheme.focus:
        return _quotes.skip(15).take(5).toList();
      case QuoteTheme.habits:
        return _quotes.skip(20).take(5).toList();
    }
  }
}

class Quote {
  final String text;
  final String author;

  const Quote({
    required this.text,
    required this.author,
  });

  @override
  String toString() => '"$text" - $author';
}

enum QuoteTheme {
  productivity,
  motivation,
  growth,
  focus,
  habits,
}
