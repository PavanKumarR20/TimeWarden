class JournalTemplate {
  final String id;
  final String name;
  final String icon;
  final String description;
  final String content;
  final List<String> prompts;

  const JournalTemplate({
    required this.id,
    required this.name,
    required this.icon,
    required this.description,
    required this.content,
    required this.prompts,
  });

  static const List<JournalTemplate> defaultTemplates = [
    JournalTemplate(
      id: 'daily_reflection',
      name: 'Daily Reflection',
      icon: '💭',
      description: 'Reflect on your day with guided prompts',
      content: '''What was the highlight of my day?

What challenged me today?

What am I grateful for?

How did I grow today?

What do I want to improve tomorrow?''',
      prompts: [
        'What was the highlight of my day?',
        'What challenged me today?',
        'What am I grateful for?',
        'How did I grow today?',
        'What do I want to improve tomorrow?',
      ],
    ),
    JournalTemplate(
      id: 'gratitude',
      name: 'Gratitude Journal',
      icon: '🙏',
      description: 'Focus on the positive moments and people',
      content: '''Three things I'm grateful for today:

1. 

2. 

3. 

Someone who made my day better:

A small moment that brought me joy:

Why today was meaningful:''',
      prompts: [
        'Three things I\'m grateful for today',
        'Someone who made my day better',
        'A small moment that brought me joy',
        'Why today was meaningful',
      ],
    ),
    JournalTemplate(
      id: 'productivity',
      name: 'Productivity Review',
      icon: '🎯',
      description: 'Track accomplishments and plan ahead',
      content: '''What I accomplished today:

Pomodoro sessions completed:

Biggest win:

What I learned:

Tomorrow's priorities:

How I can improve my focus:''',
      prompts: [
        'What I accomplished today',
        'Pomodoro sessions completed',
        'Biggest win',
        'What I learned',
        'Tomorrow\'s priorities',
        'How I can improve my focus',
      ],
    ),
    JournalTemplate(
      id: 'mood_tracker',
      name: 'Mood & Energy',
      icon: '🌈',
      description: 'Track your emotional patterns',
      content: '''How I felt today:

Energy level (1-10):

What influenced my mood:

Coping strategies that helped:

What I need more of:

Self-care I practiced:''',
      prompts: [
        'How I felt today',
        'Energy level (1-10)',
        'What influenced my mood',
        'Coping strategies that helped',
        'What I need more of',
        'Self-care I practiced',
      ],
    ),
    JournalTemplate(
      id: 'creative',
      name: 'Creative Thoughts',
      icon: '🎨',
      description: 'Capture ideas and inspiration',
      content: '''Ideas that sparked today:

Something that inspired me:

Creative project thoughts:

Random observations:

Future possibilities:''',
      prompts: [
        'Ideas that sparked today',
        'Something that inspired me',
        'Creative project thoughts',
        'Random observations',
        'Future possibilities',
      ],
    ),
    JournalTemplate(
      id: 'problem_solving',
      name: 'Problem Solving',
      icon: '🧩',
      description: 'Work through challenges methodically',
      content: '''Challenge I'm facing:

What I've tried so far:

Different perspectives to consider:

Potential solutions:

Next steps:

Who could help me:''',
      prompts: [
        'Challenge I\'m facing',
        'What I\'ve tried so far',
        'Different perspectives to consider',
        'Potential solutions',
        'Next steps',
        'Who could help me',
      ],
    ),
    JournalTemplate(
      id: 'free_write',
      name: 'Free Writing',
      icon: '✍️',
      description: 'No structure, just write what\'s on your mind',
      content: '''What's on my mind right now...

''',
      prompts: [
        'What\'s on my mind right now',
        'Stream of consciousness',
        'No rules, just write',
      ],
    ),
    JournalTemplate(
      id: 'goals_dreams',
      name: 'Goals & Dreams',
      icon: '✨',
      description: 'Explore aspirations and plan your future',
      content: '''What I'm working towards:

Progress I made today:

Obstacles I need to overcome:

Skills I want to develop:

My vision for the future:

One small step for tomorrow:''',
      prompts: [
        'What I\'m working towards',
        'Progress I made today',
        'Obstacles I need to overcome',
        'Skills I want to develop',
        'My vision for the future',
        'One small step for tomorrow',
      ],
    ),
  ];

  static JournalTemplate? getTemplateById(String id) {
    try {
      return defaultTemplates.firstWhere((template) => template.id == id);
    } catch (e) {
      return null;
    }
  }
}
