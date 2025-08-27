import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import '../../../../core/services/audio_service.dart';

class SoundTestPage extends StatefulWidget {
  const SoundTestPage({super.key});

  @override
  State<SoundTestPage> createState() => _SoundTestPageState();
}

class _SoundTestPageState extends State<SoundTestPage> with TickerProviderStateMixin {
  final audioService = AudioService();
  final AudioPlayer _testPlayer = AudioPlayer();
  late TabController _tabController;

  // Sample online sounds you can try immediately
  final Map<String, String> _sampleSounds = {
    'Success Bell': 'https://freesound.org/data/previews/316/316776_4939433-lq.mp3',
    'Gentle Chime': 'https://freesound.org/data/previews/173/173859_2538033-lq.mp3',
    'Work Bell': 'https://freesound.org/data/previews/243/243749_4486188-lq.mp3',
    'Break Chime': 'https://freesound.org/data/previews/203/203121_3123451-lq.mp3',
    'Notification': 'https://freesound.org/data/previews/154/154115_2538033-lq.mp3',
  };

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _testPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sound Test & Sources'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Current'),
            Tab(text: 'Samples'),
            Tab(text: 'Sources'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildCurrentSoundsTab(),
          _buildSampleSoundsTab(),
          _buildSoundSourcesTab(),
        ],
      ),
    );
  }

  Widget _buildCurrentSoundsTab() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            '🎵 Current Pomodoro Sounds',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          
          Expanded(
            child: ListView(
              children: [
                _buildSoundButton(
                  context: context,
                  title: '🎯 Session Start',
                  subtitle: 'Energizing start sound',
                  onPressed: () => audioService.playPomodoroSound(PomodoroSoundType.sessionStart),
                ),
                
                _buildSoundButton(
                  context: context,
                  title: '✅ Session Complete',
                  subtitle: 'Success celebration',
                  onPressed: () => audioService.playPomodoroSound(PomodoroSoundType.sessionComplete),
                ),
                
                _buildSoundButton(
                  context: context,
                  title: '🧘 Break Start',
                  subtitle: 'Relaxing break sound',
                  onPressed: () => audioService.playPomodoroSound(PomodoroSoundType.breakStart),
                ),
                
                _buildSoundButton(
                  context: context,
                  title: '💪 Break Complete',
                  subtitle: 'Back to work motivation',
                  onPressed: () => audioService.playPomodoroSound(PomodoroSoundType.breakComplete),
                ),
                
                _buildSoundButton(
                  context: context,
                  title: '🎉 Final Complete',
                  subtitle: 'Victory fanfare',
                  onPressed: () => audioService.playPomodoroSound(PomodoroSoundType.finalBreakComplete),
                ),
                
                Row(
                  children: [
                    Expanded(
                      child: _buildSoundButton(
                        context: context,
                        title: '⏸️ Pause',
                        subtitle: 'Gentle pause',
                        onPressed: () => audioService.playPomodoroSound(PomodoroSoundType.sessionPause),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _buildSoundButton(
                        context: context,
                        title: '▶️ Resume',
                        subtitle: 'Ready to continue',
                        onPressed: () => audioService.playPomodoroSound(PomodoroSoundType.sessionResume),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSampleSoundsTab() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '🎵 Try Real Sound Samples',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'These are actual sound files from freesound.org:',
            style: TextStyle(
              fontSize: 14, 
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7)
            ),
          ),
          const SizedBox(height: 16),
          
          Expanded(
            child: ListView.builder(
              itemCount: _sampleSounds.length,
              itemBuilder: (context, index) {
                final entry = _sampleSounds.entries.elementAt(index);
                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  child: ListTile(
                    leading: const Icon(Icons.play_circle_fill, size: 36, color: Colors.blue),
                    title: Text(
                      entry.key, 
                      style: const TextStyle(fontWeight: FontWeight.w600)
                    ),
                    subtitle: const Text('Tap to hear this sound'),
                    trailing: const Icon(Icons.volume_up),
                    onTap: () => _playSampleSound(entry.value, entry.key),
                  ),
                );
              },
            ),
          ),
          
          const SizedBox(height: 16),
          
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceVariant,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '💡 Like what you hear?',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                SizedBox(height: 8),
                Text('1. Note which sounds you prefer'),
                Text('2. Check the "Sources" tab to download similar ones'),
                Text('3. I\'ll help you integrate them into the app'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSoundSourcesTab() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '📥 Best Sound Sources',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          
          Expanded(
            child: ListView(
              children: [
                _buildSourceCard(
                  title: '🆓 Freesound.org',
                  description: 'Huge library of free sounds',
                  url: 'freesound.org',
                  license: 'Creative Commons',
                  searchTerms: 'notification, bell, chime, success',
                  icon: Icons.library_music,
                ),
                
                _buildSourceCard(
                  title: '🎬 Zapsplat.com',
                  description: 'Professional quality sounds',
                  url: 'zapsplat.com',
                  license: 'Royalty-free (free account)',
                  searchTerms: 'UI sounds, notification, bell',
                  icon: Icons.movie,
                ),
                
                _buildSourceCard(
                  title: '📺 BBC Sound Effects',
                  description: 'BBC\'s sound archive - completely free',
                  url: 'sound-effects.bbcrewind.co.uk',
                  license: 'Free for all uses',
                  searchTerms: 'bells, chimes, electronic',
                  icon: Icons.radio,
                ),
                
                _buildSourceCard(
                  title: '🎵 Pixabay',
                  description: 'Free sounds, no attribution needed',
                  url: 'pixabay.com/sound-effects',
                  license: 'No attribution required',
                  searchTerms: 'notification, bell, positive',
                  icon: Icons.music_note,
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 16),
          
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '🛠️ Quick Setup:',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 8),
                const Text('1. Pick a source above & download 5-6 sounds'),
                const Text('2. Save them to a folder on your computer'),
                const Text('3. Let me know when ready!'),
                const Text('4. I\'ll integrate them into the app'),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => _showDetailedGuide(context),
                    icon: const Icon(Icons.help_outline),
                    label: const Text('Show Detailed Guide'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSourceCard({
    required String title,
    required String description,
    required String url,
    required String license,
    required String searchTerms,
    required IconData icon,
  }) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: ListTile(
        leading: Icon(icon, size: 32, color: Colors.blue),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(description),
            const SizedBox(height: 4),
            Text('Search: $searchTerms', style: const TextStyle(fontStyle: FontStyle.italic)),
            Text('License: $license', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
            Text(url, style: const TextStyle(color: Colors.blue, fontSize: 12)),
          ],
        ),
        trailing: const Icon(Icons.open_in_new),
        onTap: () => _showSourceDetails(context, title, description, url, license, searchTerms),
      ),
    );
  }

  Widget _buildSoundButton({
    required BuildContext context,
    required String title,
    required String subtitle,
    required VoidCallback onPressed,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Column(
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _playSampleSound(String url, String name) async {
    try {
      print('🔊 Playing sample: $name');
      await _testPlayer.play(UrlSource(url));
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('🔊 Playing: $name'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      print('❌ Error playing sample: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Could not play: $name'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showSourceDetails(BuildContext context, String title, String description, String url, String license, String searchTerms) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(description),
            const SizedBox(height: 12),
            Text('Website: $url', style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('License: $license'),
            const SizedBox(height: 8),
            Text('Search for: $searchTerms'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Got it!'),
          ),
        ],
      ),
    );
  }

  void _showDetailedGuide(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('🔧 Custom Sound Setup'),
        content: const SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Step 1: Download Sounds 🎵',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              Text('• Visit freesound.org (easiest start)'),
              Text('• Search: "notification bell", "success chime"'),
              Text('• Download 5-6 different .mp3/.wav files'),
              Text('• Keep files under 3 seconds each'),
              SizedBox(height: 16),
              
              Text(
                'Step 2: Organize 📁',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              Text('• Create a folder on your desktop'),
              Text('• Name files clearly:'),
              Text('  - work_start.mp3 (energetic)'),
              Text('  - work_complete.mp3 (success)'),
              Text('  - break_start.mp3 (gentle)'),
              Text('  - break_complete.mp3 (motivating)'),
              Text('  - session_complete.mp3 (celebration)'),
              SizedBox(height: 16),
              
              Text(
                'Step 3: Integration 🛠️',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              Text('• Tell me "I have my sound files ready"'),
              Text('• I\'ll create the assets folder structure'),
              Text('• I\'ll update pubspec.yaml'),
              Text('• I\'ll modify AudioService to use your sounds'),
              Text('• You\'ll have custom Pomodoro audio!'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Let\'s do it!'),
          ),
        ],
      ),
    );
  }
}
