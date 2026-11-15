import 'package:flutter_test/flutter_test.dart';

import 'package:audio_player/services/player_service.dart';

void main() {
  test('track helpers derive title, folder and extension from a path', () {
    const path = '/storage/emulated/0/Music/Golden Hour.mp3';
    expect(trackTitle(path), 'Golden Hour');
    expect(trackSource(path), 'Music');
    expect(trackExtension(path), 'MP3');
  });

  test('formatDuration pads minutes and seconds', () {
    expect(formatDuration(const Duration(minutes: 3, seconds: 5)), '03:05');
    expect(formatDuration(const Duration(hours: 1, minutes: 2, seconds: 3)), '01:02:03');
  });
}
