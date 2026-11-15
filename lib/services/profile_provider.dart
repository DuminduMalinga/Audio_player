import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Locally stored profile. Shared so the Home / Settings avatars update
/// as soon as the profile is saved.
class ProfileProvider extends ChangeNotifier {
  String name = '';
  String address = '';
  String phone = '';
  String favoriteMusic = 'Pop';
  String? imagePath;

  File? get image {
    final p = imagePath;
    if (p == null || p.isEmpty) return null;
    final f = File(p);
    return f.existsSync() ? f : null;
  }

  /// First letter of the name, or null when no name is saved yet.
  String? get initial {
    final n = name.trim();
    return n.isEmpty ? null : String.fromCharCode(n.runes.first).toUpperCase();
  }

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    name = prefs.getString('name') ?? '';
    address = prefs.getString('address') ?? '';
    phone = prefs.getString('phone') ?? '';
    favoriteMusic = prefs.getString('favoriteMusic') ?? 'Pop';
    imagePath = prefs.getString('profileImagePath');
    notifyListeners();
  }

  Future<void> save({
    required String name,
    required String address,
    required String phone,
    required String favoriteMusic,
    String? imagePath,
  }) async {
    this.name = name;
    this.address = address;
    this.phone = phone;
    this.favoriteMusic = favoriteMusic;
    if (imagePath != null) this.imagePath = imagePath;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('name', name);
    await prefs.setString('address', address);
    await prefs.setString('phone', phone);
    await prefs.setString('favoriteMusic', favoriteMusic);
    if (imagePath != null) await prefs.setString('profileImagePath', imagePath);
  }
}
