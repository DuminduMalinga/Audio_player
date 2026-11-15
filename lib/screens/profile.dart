import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../services/profile_provider.dart';
import '../widgets/common.dart';
import 'theme_provide.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  static const _musicTypes = [
    'Classical',
    'Rock',
    'Pop',
    'Rap',
    'Jazz',
    'EDM',
    'Other',
  ];

  final _name = TextEditingController();
  final _address = TextEditingController();
  final _phone = TextEditingController();
  final _picker = ImagePicker();

  String _musicType = 'Pop';
  File? _image;
  bool _imageChanged = false;

  @override
  void initState() {
    super.initState();
    final p = context.read<ProfileProvider>();
    _name.text = p.name;
    _address.text = p.address;
    _phone.text = p.phone;
    _musicType = _musicTypes.contains(p.favoriteMusic)
        ? p.favoriteMusic
        : 'Pop';
    _image = p.image;
  }

  @override
  void dispose() {
    _name.dispose();
    _address.dispose();
    _phone.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picked = await _picker.pickImage(source: ImageSource.gallery);
    if (picked != null && mounted) {
      setState(() {
        _image = File(picked.path);
        _imageChanged = true;
      });
    }
  }

  Future<void> _save() async {
    if (_name.text.trim().isEmpty) {
      showAppSnack(context, 'Please add your name');
      return;
    }
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    await context.read<ProfileProvider>().save(
      name: _name.text.trim(),
      address: _address.text.trim(),
      phone: _phone.text.trim(),
      favoriteMusic: _musicType,
      imagePath: _imageChanged ? _image?.path : null,
    );
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(const SnackBar(content: Text('Profile saved')));
    navigator.pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeProvider>();
    final name = _name.text.trim();

    return Scaffold(
      backgroundColor: theme.ground,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const AppBackButton(),
                  Text(
                    'EDIT PROFILE',
                    style: bodyStyle(
                      13,
                      weight: FontWeight.w700,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(width: 44),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 18, 24, 26),
              child: Column(
                children: [
                  SizedBox(
                    width: 120,
                    height: 120,
                    child: Stack(
                      children: [
                        Container(
                          width: 116,
                          height: 116,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: kInk,
                            border: Border.all(color: Colors.white, width: 5),
                            image: _image != null
                                ? DecorationImage(
                                    image: FileImage(_image!),
                                    fit: BoxFit.cover,
                                  )
                                : null,
                          ),
                          alignment: Alignment.center,
                          child: _image != null
                              ? null
                              : name.isEmpty
                              ? Icon(
                                  Icons.person_rounded,
                                  size: 56,
                                  color: theme.ground,
                                )
                              : Text(
                                  name.characters.first.toUpperCase(),
                                  style: displayStyle(52, color: theme.ground),
                                ),
                        ),
                        Positioned(
                          right: 0,
                          bottom: 0,
                          child: Tooltip(
                            message: 'Change profile photo',
                            child: Material(
                              color: Colors.white,
                              shape: CircleBorder(
                                side: BorderSide(color: theme.ground, width: 4),
                              ),
                              child: InkWell(
                                customBorder: const CircleBorder(),
                                onTap: _pickImage,
                                child: const SizedBox(
                                  width: 44,
                                  height: 44,
                                  child: Icon(
                                    Icons.photo_camera_outlined,
                                    size: 18,
                                    color: kInk,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    name.isEmpty ? 'Your name' : name,
                    style: displayStyle(36),
                  ),
                ],
              ),
            ),
            Expanded(
              child: AppSheet(
                child: SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(
                    22,
                    24,
                    22,
                    28 + MediaQuery.of(context).viewInsets.bottom,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _Field(
                        label: 'Name',
                        controller: _name,
                        hint: 'Enter your name',
                        onChanged: (_) => setState(() {}),
                      ),
                      const SizedBox(height: 14),
                      _Field(
                        label: 'Address',
                        controller: _address,
                        hint: 'Add your address',
                      ),
                      const SizedBox(height: 14),
                      _Field(
                        label: 'Phone',
                        controller: _phone,
                        hint: 'Add your phone number',
                        keyboardType: TextInputType.phone,
                      ),
                      const SizedBox(height: 18),
                      const SheetLabel('Favourite music type'),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (final g in _musicTypes)
                            PillChip(
                              label: g,
                              selected: g == _musicType,
                              selectedColor: theme.accent,
                              borderColor: const Color(0xFFE4E4E4),
                              selectedForeground: kInk,
                              onTap: () => setState(() => _musicType = g),
                            ),
                        ],
                      ),
                      const SizedBox(height: 28),
                      SizedBox(
                        width: double.infinity,
                        child: PrimaryButton(
                          label: 'Save changes',
                          onPressed: _save,
                        ),
                      ),
                      const SizedBox(height: 14),
                      Center(
                        child: Text(
                          'Saved only on this device.',
                          style: bodyStyle(
                            12,
                            weight: FontWeight.w500,
                            color: kMuted,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Field extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final String hint;
  final TextInputType? keyboardType;
  final ValueChanged<String>? onChanged;

  const _Field({
    required this.label,
    required this.controller,
    required this.hint,
    this.keyboardType,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    OutlineInputBorder border(Color c) => OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: BorderSide(color: c, width: 2),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: bodyStyle(
            12,
            weight: FontWeight.w700,
            color: kMuted,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          onChanged: onChanged,
          style: bodyStyle(15),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: bodyStyle(15, color: const Color(0xFF8A8A8A)),
            filled: true,
            fillColor: const Color(0xFFFAFAFA),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 15,
            ),
            enabledBorder: border(const Color(0xFFEDEDED)),
            focusedBorder: border(kInk),
            border: border(const Color(0xFFEDEDED)),
          ),
        ),
      ],
    );
  }
}
