import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:sverd_barbershop/presentation/pages/auth/auth_page.dart';
import 'package:sverd_barbershop/core/services/notification_service.dart';
import 'package:sverd_barbershop/core/theme/colors.dart';

class ProfileTab extends StatefulWidget {
  const ProfileTab({super.key});

  @override
  State<ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends State<ProfileTab> {
  final _fullNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _kesanPesanController = TextEditingController();

  String _email = 'user@email.com';
  String _displayName = 'Guest';
  bool _isEditing = false;

  String _imagePath = '';

  // --- TAMBAHKAN INSTANCE NOTIFICATION SERVICE ---
  final NotificationService _notificationService = NotificationService();

  // Notification settings
  bool _notificationEnabled = false;
  int _notificationInterval = 30; // Default

  @override
  void initState() {
    super.initState();
    _loadProfileData();
    _loadNotificationSettings(); // <-- Fungsi ini akan dimodifikasi
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _phoneController.dispose();
    _kesanPesanController.dispose();
    super.dispose();
  }

  void _loadProfileData() {
    final box = Hive.box('sverd_box');
    final currentUser = box.get('currentUser') ?? {};
    final String emailKey = currentUser['email'] ?? '';

    if (emailKey.isNotEmpty) {
      final userData = box.get(emailKey) ?? {};
      _email = emailKey;
      _displayName = userData['username'] ?? 'Guest';
      _fullNameController.text = userData['fullName'] ?? _displayName;
      _phoneController.text = userData['phone'] ?? '';
      _kesanPesanController.text = userData['kesanPesan'] ?? '';
      _imagePath = userData['imagePath'] ?? '';
    }

    if (mounted) {
      setState(() {});
    }
  }

  // --- MODIFIKASI FUNGSI INI ---
  void _loadNotificationSettings() {
    setState(() {
      // Ambil data dari service (yang membaca dari Hive)
      _notificationEnabled = _notificationService.isNotificationEnabled();
      _notificationInterval = _notificationService.getNotificationInterval();
    });
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      if (kIsWeb) {
        setState(() {
          _imagePath = pickedFile.path;
        });
      } else {
        final appDir = await getApplicationDocumentsDirectory();
        final fileName = p.basename(pickedFile.path);
        final savedImage = await File(
          pickedFile.path,
        ).copy('${appDir.path}/$fileName');
        setState(() {
          _imagePath = savedImage.path;
        });
      }
    }
  }

  void _saveUpdates() {
    final box = Hive.box('sverd_box');
    final userData = box.get(_email);

    if (userData != null) {
      userData['username'] = _fullNameController.text;
      userData['fullName'] = _fullNameController.text;
      userData['phone'] = _phoneController.text;
      userData['kesanPesan'] = _kesanPesanController.text;
      userData['imagePath'] = _imagePath;

      box.put(_email, userData);

      final currentUserData = box.get('currentUser');
      currentUserData['username'] = _fullNameController.text;
      box.put('currentUser', currentUserData);

      setState(() {
        _displayName = _fullNameController.text;
        _isEditing = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Profile berhasil diperbarui!"),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  void _cancelEdit() {
    _loadProfileData();
    setState(() {
      _isEditing = false;
    });
  }

  void logout() {
    final box = Hive.box('sverd_box');
    box.delete('currentUser');

    if (mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const AuthPage()),
        (route) => false,
      );
    }
  }

  ImageProvider _buildProfileImage() {
    if (_imagePath.isEmpty) {
      return const AssetImage('');
    }
    if (kIsWeb) {
      return NetworkImage(_imagePath);
    }
    return FileImage(File(_imagePath));
  }

  // --- MODIFIKASI FUNGSI NOTIFIKASI ---
  Future<void> _toggleNotification(bool value) async {
    setState(() {
      _notificationEnabled = value;
    });

    try {
      if (value) {
        // Panggil fungsi schedule baru
        await _notificationService.scheduleRepeatingNotification(
          intervalDays: _notificationInterval,
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Notifikasi diaktifkan! Akan muncul setiap $_notificationInterval hari.',
              ),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        // Panggil fungsi cancel baru
        await _notificationService.cancelAllNotifications();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Notifikasi dinonaktifkan'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error mengubah notifikasi: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
      _loadNotificationSettings(); // Kembalikan ke state semula jika error
    }
  }

  Future<void> _updateNotificationInterval(int days) async {
    setState(() {
      _notificationInterval = days;
    });

    // Jika notifikasi sedang aktif, jadwalkan ulang dengan interval baru
    if (_notificationEnabled) {
      await _notificationService.scheduleRepeatingNotification(
          intervalDays: days);
    } else {
      // Jika tidak aktif, cukup simpan intervalnya untuk nanti
      await _notificationService.updateNotificationInterval(days);
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Interval notifikasi diubah menjadi $days hari.'),
          backgroundColor: Colors.blue,
        ),
      );
    }
  }

  Future<void> _testNotification() async {
    await _notificationService.showTestNotification(); // Panggil fungsi tes
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Test notifikasi akan muncul dalam 5 detik.',
          ),
          backgroundColor: Colors.purple,
          duration: Duration(seconds: 4),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final Color avatarBgColor = kSecondaryTextColor.withAlpha(51);
    final Color avatarIconColor = kSecondaryTextColor.withAlpha(204);
    final Color dividerColor = kSecondaryTextColor.withAlpha(76);

    return Scaffold(
      backgroundColor: kBackgroundColor,
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ... (Widget Profil Anda yang sudah ada) ...
              Center(
                child: Stack(
                  children: [
                    CircleAvatar(
                      radius: 50,
                      backgroundColor: avatarBgColor,
                      backgroundImage: _buildProfileImage(),
                      child: _imagePath.isEmpty
                          ? Icon(Icons.person, size: 60, color: avatarIconColor)
                          : null,
                    ),
                    if (_isEditing)
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          decoration: const BoxDecoration(
                            color: kPrimaryColor,
                            shape: BoxShape.circle,
                          ),
                          child: IconButton(
                            icon: const Icon(
                              Icons.edit,
                              color: kLightTextColor,
                              size: 20,
                            ),
                            onPressed: _pickImage,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Text(
                _displayName,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: kTextColor,
                ),
              ),
              const SizedBox(height: 32),

              // Personal Information
              _buildSectionTitle('Informasi Pribadi'),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20.0,
                  vertical: 12.0,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12.0),
                  border: Border.all(color: dividerColor),
                ),
                child: Column(
                  children: [
                    _buildEditableRow('Username', _fullNameController),
                    const Divider(height: 12),
                    _buildInfoRow('Email', _email),
                    const Divider(height: 12),
                    _buildEditableRow('No HP', _phoneController),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // --- BAGIAN INI YANG DIMODIFIKASI ---
              _buildSectionTitle('Pengaturan Notifikasi'),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(20.0),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12.0),
                  border: Border.all(color: dividerColor),
                ),
                child: Column(
                  children: [
                    // Toggle Notification
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(
                              _notificationEnabled
                                  ? Icons.notifications_active
                                  : Icons.notifications_off_outlined,
                              color: kPrimaryColor,
                              size: 20,
                            ),
                            const SizedBox(width: 12),
                            const Text(
                              'Notifikasi Pengingat',
                              style: TextStyle(
                                color: kTextColor,
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        Switch(
                          value: _notificationEnabled,
                          onChanged: _toggleNotification,
                          activeColor: kPrimaryColor,
                        ),
                      ],
                    ),
                    if (_notificationEnabled) ...[
                      const Divider(height: 24),
                      // Interval Selector
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Ulangi Notifikasi Setiap:',
                            style: TextStyle(
                              color: kSecondaryTextColor,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            // GANTI INTERVAL DI SINI
                            children: [14, 30, 60].map((days) {
                              final isSelected = _notificationInterval == days;
                              return InkWell(
                                onTap: () => _updateNotificationInterval(days),
                                borderRadius: BorderRadius.circular(20),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? kPrimaryColor
                                        : Colors.transparent,
                                    border: Border.all(
                                      color: isSelected
                                          ? kPrimaryColor
                                          : kSecondaryTextColor,
                                    ),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    '$days hari',
                                    style: TextStyle(
                                      color: isSelected
                                          ? kLightTextColor
                                          : kTextColor,
                                      fontSize: 13,
                                      fontWeight: isSelected
                                          ? FontWeight.bold
                                          : FontWeight.normal,
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                      const Divider(height: 24),
                      // Test Notification Button
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: _testNotification,
                          icon: const Icon(Icons.notification_add),
                          label: const Text('Tes Notifikasi'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: kPrimaryColor,
                            side: const BorderSide(color: kPrimaryColor),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              // --- AKHIR BAGIAN MODIFIKASI ---
              const SizedBox(height: 32),

              // ... (Widget Kesan dan Pesan & Tombol) ...
              _buildSectionTitle('Kesan dan Pesan'),
              const SizedBox(height: 12),
              TextField(
                controller: _kesanPesanController,
                readOnly: !_isEditing,
                maxLines: 5,
                decoration: InputDecoration(
                  hintText: 'kesan dan pesan ....',
                  hintStyle: const TextStyle(color: kSecondaryTextColor),
                  filled: true,
                  fillColor: _isEditing
                      ? Colors.white
                      : kBackgroundColor.withAlpha(128),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: dividerColor),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: _isEditing ? kPrimaryColor : dividerColor,
                      width: _isEditing ? 2 : 1,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // Buttons
              if (_isEditing)
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: _cancelEdit,
                        child: const Text(
                          'Batal',
                          style: TextStyle(
                            color: kSecondaryTextColor,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _saveUpdates,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: kPrimaryColor,
                          foregroundColor: kLightTextColor,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                        child: const Text("Simpan"),
                      ),
                    ),
                  ],
                )
              else
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _isEditing = true;
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kDarkComponentColor,
                    foregroundColor: kLightTextColor,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: const Text("Edit Profil"),
                ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: logout,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: kLightTextColor,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                child: const Text("Log out"),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: kTextColor,
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 15, color: kSecondaryTextColor),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 15,
              color: kTextColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEditableRow(String label, TextEditingController controller) {
    return Row(
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 15, color: kSecondaryTextColor),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: TextField(
            controller: controller,
            readOnly: !_isEditing,
            textAlign: TextAlign.end,
            decoration: const InputDecoration(
              isDense: true,
              contentPadding: EdgeInsets.symmetric(vertical: 12.0),
              border: InputBorder.none,
              focusedBorder: InputBorder.none,
              enabledBorder: InputBorder.none,
              hintText: '...',
              hintStyle: TextStyle(color: kSecondaryTextColor),
            ),
            style: const TextStyle(
              fontSize: 15,
              color: kTextColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}
