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
      text: "Great things never come from comfort zones.",
      author: "Neil Strauss",
    ),
    const Quote(
      text: "Dream big and dare to fail.",
      author: "Norman Vaughan",
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
      text: "Progress is impossible without change.",
      author: "George Bernard Shaw",
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
      text: "Small steps every day lead to big changes in a year.",
      author: "James Clear",
    ),

    // Movies & Inspiration
    const Quote(
      text: "Do or do not, there is no try.",
      author: "Yoda, Star Wars",
    ),
    const Quote(
      text: "Yesterday is history, tomorrow is a mystery, but today is a gift.",
      author: "Master Oogway, Kung Fu Panda",
    ),
    const Quote(
      text: "It's not who I am underneath, but what I do that defines me.",
      author: "Batman",
    ),
    const Quote(
      text: "The way to get started is to quit talking and begin doing.",
      author: "Walt Disney",
    ),
    const Quote(
      text:
          "All we have to decide is what to do with the time that is given us.",
      author: "Gandalf, Lord of the Rings",
    ),

    // Anime & Manga Wisdom
    const Quote(
      text: "If you don't take risks, you can't create a future.",
      author: "Monkey D. Luffy, One Piece",
    ),
    const Quote(
      text:
          "The moment you think of giving up, think of the reason why you held on so long.",
      author: "Natsu Dragneel, Fairy Tail",
    ),
    const Quote(
      text: "Hard work is what makes your dreams come true.",
      author: "Rock Lee, Naruto",
    ),
    const Quote(
      text:
          "A lesson without pain is meaningless. For you cannot gain anything without sacrificing something else in return.",
      author: "Edward Elric, Fullmetal Alchemist",
    ),
    const Quote(
      text:
          "It's not the face that makes someone a monster, it's the choices they make with their lives.",
      author: "Naruto Uzumaki, Naruto",
    ),

    // Time Management & Focus
    const Quote(
      text:
          "Time is the most valuable thing we have, because it is the most irrevocable.",
      author: "Dietrich Bonhoeffer",
    ),
    const Quote(
      text: "The key to productivity is to focus on one thing at a time.",
      author: "Brian Tracy",
    ),
    const Quote(
      text: "Until we can manage time, we can manage nothing else.",
      author: "Peter Drucker",
    ),
    const Quote(
      text:
          "Efficiency is doing things right; effectiveness is doing the right things.",
      author: "Peter Drucker",
    ),
    const Quote(
      text:
          "The successful warrior is the average person with laser-like focus.",
      author: "Bruce Lee",
    ),

    // Productivity & Achievement
    const Quote(
      text:
          "Productivity is never an accident. It is always the result of a commitment to excellence.",
      author: "Paul J. Meyer",
    ),
    const Quote(
      text: "The most productive people are those who ask the right questions.",
      author: "Tim Ferriss",
    ),
    const Quote(
      text: "What gets measured gets managed.",
      author: "Peter Drucker",
    ),
    const Quote(
      text:
          "Don't confuse activity with productivity. Many people are simply busy being busy.",
      author: "Robin Sharma",
    ),
    const Quote(
      text: "The way we spend our time defines who we are.",
      author: "Jonathan Estrin",
    ),

    // Modern Motivational
    const Quote(
      text: "Your only limit is your mind.",
      author: "Tony Robbins",
    ),
    const Quote(
      text: "Good things happen to those who hustle.",
      author: "Anaïs Nin",
    ),
    const Quote(
      text: "Life is 10% what happens to you and 90% how you react to it.",
      author: "Charles R. Swindoll",
    ),
    const Quote(
      text:
          "The only person you are destined to become is the person you decide to be.",
      author: "Ralph Waldo Emerson",
    ),
    const Quote(
      text: "Believe you can and you're halfway there.",
      author: "Theodore Roosevelt",
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
        return _quotes.take(5).toList(); // 0-4
      case QuoteTheme.motivation:
        return _quotes.skip(5).take(5).toList(); // 5-9
      case QuoteTheme.growth:
        return _quotes.skip(10).take(5).toList(); // 10-14
      case QuoteTheme.focus:
        return _quotes.skip(15).take(5).toList(); // 15-19
      case QuoteTheme.habits:
        return _quotes.skip(20).take(5).toList(); // 20-24
      case QuoteTheme.movies:
        return _quotes.skip(25).take(5).toList(); // 25-29
      case QuoteTheme.anime:
        return _quotes.skip(30).take(5).toList(); // 30-34
      case QuoteTheme.timeManagement:
        return _quotes.skip(35).take(5).toList(); // 35-39
      case QuoteTheme.achievement:
        return _quotes.skip(40).take(5).toList(); // 40-44
      case QuoteTheme.modern:
        return _quotes.skip(45).take(5).toList(); // 45-49
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
  movies,
  anime,
  timeManagement,
  achievement,
  modern,
}
