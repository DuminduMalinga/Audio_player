🎵 Flutter Audio Player

A feature-rich cross-platform audio player built with Flutter. This app allows users to play local audio files, record audio, apply sound effects, manage favorites, customize themes, and more—designed for both Android and iOS. Enjoy a seamless music experience with waveform visualizations and intuitive controls.

Features
🎧 Audio Playback

    Play, pause, seek, and control volume for local audio files.
    
    Supports multiple file selection.

📂 Playlist Management

    Add songs to playlists.
    
    Shuffle, next/previous track support.

🎤 Audio Recording

    Record, pause, resume, and save audio files.
    
    Saved in /storage/emulated/0/Recordings on Android.

🎛 Sound Effects

    Apply presets like Pitch Up/Down, Faster/Slower, Darth Vader, Squirrel, and more.
    
    Adjust pitch and speed dynamically.

❤️ Favorites

    Add/remove songs to favorites.
    
    Play favorites separately.

📊 Waveform Visualization

    Real-time audio waveforms using audio_waveforms.

⚙️ Settings

    Customize app theme gradients.
    
    Playback speed (0.5x–2.0x).
    
    Equalizer presets (Normal, Pop, etc.).
    
    Crossfade, shuffle, and repeat modes.

👤 User Profile

    Edit name, address, phone, favorite music type, and profile image.
    
    Profile data stored via SharedPreferences.

✨ Welcome Screen

    Animated splash screen with gradient transitions.

📱 Cross-Platform Support

    Fully functional on Android and iOS.
    
    Handles permissions for storage, audio, and microphone.

🛠 Additional Tools

    File picker for audio selection.
    
    Image picker for profile.

Getting Started
    Flutter SDK (version 3.0+ recommended)
    
    Dart SDK (included with Flutter)
    
    Android Studio or VS Code
    
    Physical device or emulator (with permissions for audio/storage/microphone)

Installation

1. Clone the repository
2.     git clone https://github.com/DuminduMalinga/Audio_player.git
3. Navigate to project director
4.     cd Audio_player
5. Install dependencies
6.     flutter pub get
7. run the app
8.     flutter run


Usage:

    1. Launch the app and wait for the welcome screen to transition to the home screen.
    2. Use the "Pick File" button to select audio files from your device.
    3. Control playback with play/pause, next/previous, seek slider, and volume.
    4. Access recording via the mic icon: start/pause/resume/stop recordings.
    5. Apply sound effects to the current track.
    6. Add songs to favorites using the heart icon.
    7. Customize themes, playback speed, and other settings.
    8. Edit your profile details and profile image.


Code Structure:

    1. home_screen.dart — Main playback interface
    2. recording_screen.dart — Audio recording functionality
    3. sound_effects.dart — Sound effects presets
    4. favorites_screen.dart — Favorites management
    5. settings_screen.dart — App customization
    6. profile.dart — User profile editing
    7. theme_provider.dart — Theme state management
    8. welcome_screen.dart — Animated splash screen

dependencies:

      flutter:
        sdk: flutter
      just_audio: ^0.9.0
      audio_waveforms: ^1.0.0
      provider: ^6.0.0
      permission_handler: ^10.0.0
      device_info_plus: ^9.0.0
      path_provider: ^2.0.0
      file_picker: ^5.0.0
      flutter_sound: ^9.0.0
      image_picker: ^0.8.0
      shared_preferences: ^2.0.0

Acknowledgments:

    1. Built with Flutter
    2. Audio handling: just_audio and flutter_sound
    3. Waveform visualization: audio_waveforms
    4. State management: provider
    5. Thanks to the Flutter community for open-source packages and inspiration.
